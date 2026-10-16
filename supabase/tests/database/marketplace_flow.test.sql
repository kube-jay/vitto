-- End-to-end server rules for Listing → Offer → Deal → completion → Rating.
-- Covers acceptance tests AT-01..AT-17 (Part II §43.2) at the database level.
begin;
create extension if not exists pgtap with schema extensions;
select plan(52);

-- Actors ---------------------------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data) values
  ('a0000000-0000-0000-0000-000000000001', 'seller@test.vitto', '{"display_name":"Seller","country_code":"NG"}'),
  ('a0000000-0000-0000-0000-000000000002', 'buyer1@test.vitto', '{"display_name":"Buyer One","country_code":"NG"}'),
  ('a0000000-0000-0000-0000-000000000003', 'buyer2@test.vitto', '{"display_name":"Buyer Two","country_code":"NG"}'),
  ('a0000000-0000-0000-0000-000000000004', 'stranger@test.vitto', '{"display_name":"Stranger","country_code":"BJ"}'),
  ('a0000000-0000-0000-0000-000000000005', 'admin@test.vitto', '{"display_name":"Admin","country_code":"NG"}');
insert into private.admin_users (user_id) values ('a0000000-0000-0000-0000-000000000005');

create temp table t (k text primary key, v text);
grant all on t to authenticated, anon, service_role;

-- 1. Listing lifecycle ---------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';

with ins as (
  insert into public.listings (category_id, title, description, price_minor, negotiable,
                               condition, country_code, region_code, city)
  values ((select id from public.categories where slug = 'electronics'),
          'Samsung TV 43 inch', 'Works perfectly', 15000000, true, 'used', 'NG', 'LA', 'Ikeja')
  returning id)
insert into t select 'L1', id::text from ins;

select is((select currency::text from public.listings where id = (select v::uuid from t where k='L1')),
  'NGN', 'currency derived from country (DEC-08)');
select throws_ok(
  $$select public.listing_set_status((select v::uuid from t where k='L1'), 'active')$$,
  'P0001', 'validation_error', 'cannot publish without an image');

insert into public.listing_images (listing_id, storage_path)
values ((select v::uuid from t where k='L1'),
        'a0000000-0000-0000-0000-000000000001/l1/1.jpg');
select is((public.listing_set_status((select v::uuid from t where k='L1'), 'active')).status::text,
  'active', 'owner publishes listing with an image');

select throws_ok(
  $$update public.listings set status = 'sold' where id = (select v::uuid from t where k='L1')$$,
  '42501', null, 'owner cannot change status directly');

-- AT-01: anonymous visitors see only active Listings
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.search_listings('samsung')
           where id = (select v::uuid from t where k='L1')), 1,
  'anon finds the active listing by text search');
select is((select count(*)::int from public.search_listings('tele')
           where id = (select v::uuid from t where k='L1')), 0,
  'search does not match unrelated words');

-- AT-03: non-owner cannot edit
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000004","role":"authenticated"}';
update public.listings set title = 'Hacked' where id = (select v::uuid from t where k='L1');
reset role;
select is((select title from public.listings where id = (select v::uuid from t where k='L1')),
  'Samsung TV 43 inch', 'non-owner update has no effect (AT-03)');

-- 2. Conversations and Offers ---------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.start_conversation((select v::uuid from t where k='L1'))$$,
  'P0001', 'forbidden', 'seller cannot open a conversation with themself');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
insert into t select 'C1', public.start_conversation((select v::uuid from t where k='L1'))::text;
insert into public.messages (conversation_id, body)
values ((select v::uuid from t where k='C1'), 'Hello, is it available?');
insert into t select 'O1', (public.offer_create((select v::uuid from t where k='C1'), 12000000)).id::text;
select throws_ok(
  $$select public.offer_create((select v::uuid from t where k='C1'), 12500000)$$,
  'P0001', 'conflict', 'only one pending offer per conversation (DEC-12)');
select throws_ok(
  $$select public.offer_respond((select v::uuid from t where k='O1'), 'accept')$$,
  'P0001', 'forbidden', 'proposer cannot accept own offer');

-- AT-04: outsider sees nothing
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000004","role":"authenticated"}';
select is((select count(*)::int from public.messages), 0, 'outsider cannot read messages (AT-04)');
select is((select count(*)::int from public.offers), 0, 'outsider cannot read offers');
select is((select count(*)::int from public.conversations), 0, 'outsider cannot read conversations');
select throws_ok(
  $$insert into public.messages (conversation_id, body) values ((select v::uuid from t where k='C1'), 'spam')$$,
  '42501', null, 'outsider cannot post into a conversation');

-- Seller counters
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
insert into t select 'O2',
  (public.offer_respond((select v::uuid from t where k='O1'), 'counter', 13500000)->'counter_offer'->>'id');
select is((select status::text from public.offers where id = (select v::uuid from t where k='O1')),
  'countered', 'original offer marked countered');
select is((select recipient_id::text from public.offers where id = (select v::uuid from t where k='O2')),
  'a0000000-0000-0000-0000-000000000002', 'counter-offer goes to the buyer');

-- Competing buyer
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000003","role":"authenticated"}';
insert into t select 'C2', public.start_conversation((select v::uuid from t where k='L1'))::text;
insert into t select 'O3', (public.offer_create((select v::uuid from t where k='C2'), 14000000)).id::text;

-- AT-05: buyer accepts the counter → one Deal at the agreed amount
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
insert into t select 'D1',
  (public.offer_respond((select v::uuid from t where k='O2'), 'accept')->>'deal_id');
select is((select agreed_amount_minor from public.deals where id = (select v::uuid from t where k='D1')),
  13500000::bigint, 'deal uses the accepted offer amount (AT-05)');
select is((select original_amount_minor from public.deals where id = (select v::uuid from t where k='D1')),
  15000000::bigint, 'deal keeps the original listing price');

reset role;
select is((select status::text from public.listings where id = (select v::uuid from t where k='L1')),
  'reserved', 'listing reserved after acceptance');
select is((select status::text from public.offers where id = (select v::uuid from t where k='O3')),
  'expired', 'competing pending offer expired');

-- AT-06: the competing acceptance loses deterministically
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.offer_respond((select v::uuid from t where k='O3'), 'accept')$$,
  'P0001', 'invalid_state', 'second acceptance fails (AT-06)');
reset role;
select is((select count(*)::int from public.deals where listing_id = (select v::uuid from t where k='L1')),
  1, 'exactly one deal per listing');

-- 3. Offline completion ---------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select throws_ok(
  $$select public.rating_submit((select v::uuid from t where k='D1'), 5::smallint, 'great')$$,
  'P0001', 'invalid_state', 'cannot rate before completion');
select is((public.deal_select_mode((select v::uuid from t where k='D1'), 'offline')).status::text,
  'awaiting_handover', 'offline mode → awaiting_handover (DEC-11)');
select is((public.deal_confirm_offline((select v::uuid from t where k='D1'))).status::text,
  'awaiting_handover', 'one confirmation is not enough (AT-07)');
select throws_ok(
  $$select public.rating_submit((select v::uuid from t where k='D1'), 5::smallint, null)$$,
  'P0001', 'invalid_state', 'rating still locked after one confirmation (AT-07)');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((public.deal_confirm_offline((select v::uuid from t where k='D1'))).status::text,
  'completed', 'both confirmations complete the deal (AT-08)');
reset role;
select is((select status::text from public.listings where id = (select v::uuid from t where k='L1')),
  'sold', 'listing sold after completion');

-- Ratings
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select is((public.rating_submit((select v::uuid from t where k='D1'), 5::smallint, 'Great seller')).recipient_id::text,
  'a0000000-0000-0000-0000-000000000001', 'buyer rates seller');
select throws_ok(
  $$select public.rating_submit((select v::uuid from t where k='D1'), 1::smallint, null)$$,
  'P0001', 'conflict', 'cannot rate twice (AT-16)');
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000004","role":"authenticated"}';
select throws_ok(
  $$select public.rating_submit((select v::uuid from t where k='D1'), 1::smallint, null)$$,
  'P0001', 'forbidden', 'outsider cannot rate (AT-15)');
reset role;
select results_eq(
  $$select rating_count, rating_sum, completed_deals_count from public.profiles
    where id = 'a0000000-0000-0000-0000-000000000001'$$,
  $$values (1, 5, 1)$$, 'seller reputation counters updated');

-- 4. Online completion ----------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
with ins as (
  insert into public.listings (category_id, title, price_minor, negotiable, condition,
                               country_code, region_code, city)
  values ((select id from public.categories where slug = 'phones-tablets'),
          'iPhone 12', 30000000, false, 'used', 'NG', 'LA', 'Yaba')
  returning id)
insert into t select 'L2', id::text from ins;
insert into public.listing_images (listing_id, storage_path)
values ((select v::uuid from t where k='L2'), 'a0000000-0000-0000-0000-000000000001/l2/1.jpg');
select public.listing_set_status((select v::uuid from t where k='L2'), 'active');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
insert into t select 'C3', public.start_conversation((select v::uuid from t where k='L2'))::text;
select throws_ok(
  $$select public.offer_create((select v::uuid from t where k='C3'), 25000000)$$,
  'P0001', 'validation_error', 'fixed-price listing rejects a lower offer (DEC-03)');
insert into t select 'O4', (public.offer_create((select v::uuid from t where k='C3'), 30000000)).id::text;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.offer_respond((select v::uuid from t where k='O4'), 'counter', 31000000)$$,
  'P0001', 'validation_error', 'fixed-price listing cannot be countered (DEC-03)');
insert into t select 'D2', (public.offer_respond((select v::uuid from t where k='O4'), 'accept')->>'deal_id');
select public.deal_select_mode((select v::uuid from t where k='D2'), 'online');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select throws_ok(
  $$select public.deal_handover_code((select v::uuid from t where k='D2'))$$,
  'P0001', 'invalid_state', 'no handover code before verified payment (AT-09)');
select throws_ok(
  $$select public.payment_apply_verified('mock', 'ref-1', 'successful', 30000000, 'NGN')$$,
  '42501', null, 'clients cannot mark payments successful');

-- Provider side (service role)
reset role;
set local role service_role;
select public.payment_record_initialized((select v::uuid from t where k='D2'), 'mock', 'ref-1',
  30000000, 'NGN', 'key-1', 'https://mock.invalid/ref-1');
select is((public.payment_apply_verified('mock', 'ref-1', 'successful', 1000, 'NGN', 'evt-0', 'charge.success'))->>'outcome',
  'amount_mismatch', 'wrong amount is rejected (AT-11)');
select is((public.payment_apply_verified('mock', 'ref-1', 'successful', 30000000, 'NGN', 'evt-1', 'charge.success'))->>'outcome',
  'deal_paid', 'verified payment marks the deal paid');
select is((public.payment_apply_verified('mock', 'ref-1', 'successful', 30000000, 'NGN', 'evt-1', 'charge.success'))->>'duplicate',
  'true', 'duplicate webhook is a no-op (AT-10)');
reset role;
select is((select count(*)::int from public.payouts where deal_id = (select v::uuid from t where k='D2')),
  0, 'payment does not create a payout (AT-12)');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
insert into t select 'CODE', public.deal_handover_code((select v::uuid from t where k='D2'))->>'code';
select matches((select v from t where k='CODE'), '^\d{6}$', 'buyer receives a 6-digit code');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((public.deal_confirm_online((select v::uuid from t where k='D2'),
           case when (select v from t where k='CODE') = '000000' then '000001' else '000000' end))->>'attempts_left',
  '4', 'wrong code is rejected and counted (AT-13)');
select is((public.deal_confirm_online((select v::uuid from t where k='D2'), (select v from t where k='CODE')))->>'ok',
  'true', 'correct code completes the deal');
reset role;
select is((select status::text from public.payouts where deal_id = (select v::uuid from t where k='D2')),
  'eligible', 'payout becomes eligible only after handover');

-- 5. Confirmation problem → dispute → admin ------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
with ins as (
  insert into public.listings (category_id, title, price_minor, condition, country_code, city)
  values ((select id from public.categories where slug = 'fashion'),
          'Leather bag', 2000000, 'new', 'NG', 'Abuja')
  returning id)
insert into t select 'L3', id::text from ins;
insert into public.listing_images (listing_id, storage_path)
values ((select v::uuid from t where k='L3'), 'a0000000-0000-0000-0000-000000000001/l3/1.jpg');
select public.listing_set_status((select v::uuid from t where k='L3'), 'active');
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000003","role":"authenticated"}';
insert into t select 'C4', public.start_conversation((select v::uuid from t where k='L3'))::text;
insert into t select 'O5', (public.offer_create((select v::uuid from t where k='C4'), 1800000)).id::text;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
insert into t select 'D3', (public.offer_respond((select v::uuid from t where k='O5'), 'accept')->>'deal_id');
select public.deal_select_mode((select v::uuid from t where k='D3'), 'online');
reset role;
set local role service_role;
select public.payment_record_initialized((select v::uuid from t where k='D3'), 'mock', 'ref-3',
  1800000, 'NGN', 'key-3', null);
select public.payment_apply_verified('mock', 'ref-3', 'successful', 1800000, 'NGN', 'evt-3', 'charge.success');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.deal_cancel((select v::uuid from t where k='D3'))$$,
  'P0001', 'invalid_state', 'paid deal cannot be cancelled by a participant (DEC-07)');
select public.deal_report_confirmation_problem((select v::uuid from t where k='D3'), 'Handed over yesterday');
set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000003","role":"authenticated"}';
select is((public.deal_buyer_answer((select v::uuid from t where k='D3'), false, 'Never received')).status::text,
  'disputed', 'disagreement → disputed (AT-14)');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}';
select throws_ok(
  $$select public.admin_resolve_dispute((select v::uuid from t where k='D3'), 'cancel', 'x')$$,
  'P0001', 'forbidden', 'non-admin cannot resolve disputes');

set local request.jwt.claims = '{"sub":"a0000000-0000-0000-0000-000000000005","role":"authenticated"}';
select is((select count(*)::int from public.reports
           where target_kind = 'deal' and target_id = (select v::uuid from t where k='D3')),
  1, 'admin sees the dispute report');
select is((public.admin_resolve_dispute((select v::uuid from t where k='D3'), 'cancel', 'Refund buyer')).status::text,
  'cancelled', 'admin cancels the disputed deal');
select is((select status::text from public.listings where id = (select v::uuid from t where k='L3')),
  'active', 'listing returns to active after admin cancel');

-- AT-17: suspended listing disappears from public view
select public.admin_set_listing_suspension((select v::uuid from t where k='L3'), true, 'Test');
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.listings where id = (select v::uuid from t where k='L3')),
  0, 'suspended listing is not public (AT-17)');
reset role;
select ok((select count(*) from public.audit_logs) >= 2, 'admin actions are audited');

select * from finish();
rollback;
