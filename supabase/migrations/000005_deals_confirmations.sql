-- VT-018 / VT-021 / VT-022: Deals, atomic Offer acceptance, online/offline
-- completion, handover codes, confirmation problems and disputes.

create type public.deal_status as enum
  ('awaiting_payment', 'paid', 'awaiting_handover', 'completed', 'cancelled', 'disputed');
create type public.transaction_type as enum ('online', 'offline');

alter table public.profiles
  add column completed_deals_count integer not null default 0;

create table public.deals (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id),
  accepted_offer_id uuid not null unique references public.offers (id),
  conversation_id uuid not null references public.conversations (id),
  buyer_id uuid not null references public.profiles (id),
  seller_id uuid not null references public.profiles (id),
  original_amount_minor bigint not null check (original_amount_minor > 0),
  agreed_amount_minor bigint not null check (agreed_amount_minor > 0),
  currency public.currency_code not null,
  transaction_type public.transaction_type,           -- NULL until chosen (DEC-11)
  status public.deal_status not null default 'awaiting_payment',
  confirmation_problem_at timestamptz,
  confirmation_problem_note text check (char_length(confirmation_problem_note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  cancelled_at timestamptz,
  disputed_at timestamptz,
  check (buyer_id <> seller_id)
);
-- DEC-04: one live Deal per single-item Listing.
create unique index deals_one_open_per_listing
  on public.deals (listing_id) where status <> 'cancelled';
create index deals_buyer_idx on public.deals (buyer_id, status);
create index deals_seller_idx on public.deals (seller_id, status);

create trigger deals_touch_updated_at
  before update on public.deals
  for each row execute function private.touch_updated_at();

create function private.is_deal_participant(p_deal_id uuid)
returns boolean
language sql stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.deals d
    where d.id = p_deal_id and (select auth.uid()) in (d.buyer_id, d.seller_id)
  )
$$;
grant execute on function private.is_deal_participant(uuid) to authenticated;

alter table public.deals enable row level security;
create policy "participants read deals" on public.deals
  for select to authenticated
  using ((select auth.uid()) in (buyer_id, seller_id) or private.is_admin());
revoke all on public.deals from anon, authenticated;
grant select on public.deals to authenticated;

-- Append-only state history.
create table public.deal_events (
  id bigint generated always as identity primary key,
  deal_id uuid not null references public.deals (id) on delete cascade,
  actor_id uuid references public.profiles (id),
  event text not null,
  from_status public.deal_status,
  to_status public.deal_status,
  note text,
  created_at timestamptz not null default now()
);
create index deal_events_deal_idx on public.deal_events (deal_id, created_at);
alter table public.deal_events enable row level security;
create policy "participants read deal events" on public.deal_events
  for select to authenticated
  using (private.is_deal_participant(deal_id) or private.is_admin());
revoke all on public.deal_events from anon, authenticated;
grant select on public.deal_events to authenticated;

-- Offline: both parties confirm (Part I §15).
create table public.deal_confirmations (
  deal_id uuid not null references public.deals (id) on delete cascade,
  user_id uuid not null references public.profiles (id),
  confirmed_at timestamptz not null default now(),
  primary key (deal_id, user_id)
);
alter table public.deal_confirmations enable row level security;
create policy "participants read confirmations" on public.deal_confirmations
  for select to authenticated
  using (private.is_deal_participant(deal_id) or private.is_admin());
revoke all on public.deal_confirmations from anon, authenticated;
grant select on public.deal_confirmations to authenticated;

-- Online: hashed 6-digit code, never readable by clients (Part I §13).
create table private.handover_codes (
  deal_id uuid primary key references public.deals (id) on delete cascade,
  code_hash text not null,
  expires_at timestamptz not null,
  attempt_count integer not null default 0,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

alter publication supabase_realtime add table public.deals;

------------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------------
create function private.deal_set_status(
  p_deal public.deals, p_to public.deal_status, p_actor uuid, p_event text, p_note text default null)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  d public.deals;
begin
  update public.deals
     set status = p_to,
         completed_at = case when p_to = 'completed' then now() else completed_at end,
         cancelled_at = case when p_to = 'cancelled' then now() else cancelled_at end,
         disputed_at = case when p_to = 'disputed' then now() else disputed_at end
   where id = p_deal.id
  returning * into d;
  insert into public.deal_events (deal_id, actor_id, event, from_status, to_status, note)
  values (p_deal.id, p_actor, p_event, p_deal.status, p_to, p_note);
  insert into public.messages (conversation_id, sender_id, system_type, body)
  values (p_deal.conversation_id, coalesce(p_actor, p_deal.seller_id), 'deal_update', p_to::text);
  return d;
end
$$;

-- Completion: Listing sold, reputation counters, payout eligibility for
-- online Deals. Payment and Payout stay separate records.
create function private.complete_deal(p_deal public.deals, p_actor uuid, p_event text)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  d public.deals;
  pay record;
begin
  d := private.deal_set_status(p_deal, 'completed', p_actor, p_event);
  update public.listings set status = 'sold' where id = d.listing_id;
  update public.profiles set completed_deals_count = completed_deals_count + 1
   where id in (d.buyer_id, d.seller_id);

  if d.transaction_type = 'online' then
    select * into pay from public.payments
     where deal_id = d.id and status = 'successful'
     order by verified_at desc limit 1;
    if found then
      insert into public.payouts (deal_id, provider, amount_minor, currency, status, eligible_at)
      values (d.id, pay.provider, d.agreed_amount_minor, d.currency, 'eligible', now())
      on conflict (deal_id) do update
        set status = 'eligible', eligible_at = now()
        where public.payouts.status = 'not_eligible';
    end if;
  end if;
  return d;
end
$$;

create function private.lock_deal_for(p_deal_id uuid, p_uid uuid)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  d public.deals;
begin
  select * into d from public.deals where id = p_deal_id for update;
  if not found or p_uid not in (d.buyer_id, d.seller_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  return d;
end
$$;

------------------------------------------------------------------------------
-- Offer responses. Accepting creates exactly one Deal (Part II §31.2).
------------------------------------------------------------------------------
create function public.offer_respond(
  p_offer_id uuid, p_action text, p_counter_amount_minor bigint default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  o public.offers;
  c public.conversations;
  l public.listings;
  new_offer public.offers;
  d public.deals;
begin
  select * into o from public.offers where id = p_offer_id for update;
  if not found or o.recipient_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if o.status <> 'pending' or o.expires_at < now() then
    raise exception 'invalid_state' using errcode = 'P0001',
      detail = case when o.status = 'pending' then 'offer_expired' else o.status::text end;
  end if;
  select * into c from public.conversations where id = o.conversation_id;

  if p_action = 'reject' then
    update public.offers set status = 'rejected', responded_at = now()
     where id = o.id returning * into o;
    insert into public.messages (conversation_id, sender_id, system_type, offer_id)
    values (c.id, uid, 'offer_rejected', o.id);
    return jsonb_build_object('offer', to_jsonb(o));

  elsif p_action = 'counter' then
    select * into l from public.listings where id = o.listing_id;
    if l.status <> 'active' then
      raise exception 'listing_not_available' using errcode = 'P0001';
    end if;
    if not l.negotiable then
      raise exception 'validation_error' using errcode = 'P0001', detail = 'fixed_price';
    end if;
    if p_counter_amount_minor is null or p_counter_amount_minor <= 0 then
      raise exception 'validation_error' using errcode = 'P0001', detail = 'amount';
    end if;
    update public.offers set status = 'countered', responded_at = now()
     where id = o.id returning * into o;
    insert into public.offers (conversation_id, listing_id, proposer_id, recipient_id,
                               amount_minor, currency, parent_offer_id, expires_at)
    values (c.id, o.listing_id, uid, o.proposer_id, p_counter_amount_minor, o.currency,
            o.id, now() + interval '48 hours')
    returning * into new_offer;
    insert into public.messages (conversation_id, sender_id, system_type, offer_id)
    values (c.id, uid, 'offer_countered', new_offer.id);
    return jsonb_build_object('offer', to_jsonb(o), 'counter_offer', to_jsonb(new_offer));

  elsif p_action = 'accept' then
    -- Serialize competing acceptances on the same Listing.
    select * into l from public.listings where id = o.listing_id for update;
    if l.status <> 'active' or exists (
      select 1 from public.profiles
      where id in (c.buyer_id, c.seller_id) and suspended_at is not null
    ) then
      raise exception 'listing_not_available' using errcode = 'P0001';
    end if;
    if o.currency <> l.currency then
      raise exception 'validation_error' using errcode = 'P0001', detail = 'currency';
    end if;

    update public.offers set status = 'accepted', responded_at = now()
     where id = o.id returning * into o;
    update public.listings set status = 'reserved' where id = l.id;
    insert into public.deals (listing_id, accepted_offer_id, conversation_id, buyer_id,
                              seller_id, original_amount_minor, agreed_amount_minor, currency)
    values (l.id, o.id, c.id, c.buyer_id, c.seller_id, l.price_minor, o.amount_minor, o.currency)
    returning * into d;
    insert into public.deal_events (deal_id, actor_id, event, to_status)
    values (d.id, uid, 'created', d.status);

    -- Competing pending Offers on this Listing can no longer succeed.
    update public.offers set status = 'expired', responded_at = now()
     where listing_id = l.id and status = 'pending';

    insert into public.messages (conversation_id, sender_id, system_type, offer_id)
    values (c.id, uid, 'offer_accepted', o.id);
    return jsonb_build_object('offer', to_jsonb(o), 'deal_id', d.id);
  end if;

  raise exception 'validation_error' using errcode = 'P0001', detail = 'action';
end
$$;

------------------------------------------------------------------------------
-- Deal actions
------------------------------------------------------------------------------

-- DEC-11: choose online or offline after the Deal is created.
create function public.deal_select_mode(p_deal_id uuid, p_mode public.transaction_type)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
begin
  if not (d.status = 'awaiting_payment'
          or (d.status = 'awaiting_handover' and d.transaction_type = 'offline')) then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.payments
             where deal_id = d.id and status in ('pending', 'successful')) then
    raise exception 'payment_pending' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.deal_confirmations where deal_id = d.id) then
    raise exception 'invalid_state' using errcode = 'P0001', detail = 'already_confirmed';
  end if;

  update public.deals set transaction_type = p_mode where id = d.id returning * into d;
  return private.deal_set_status(
    d,
    case p_mode when 'online' then 'awaiting_payment'::public.deal_status
                else 'awaiting_handover'::public.deal_status end,
    uid, 'mode_' || p_mode::text);
end
$$;

-- Offline: each party confirms independently; both → completed.
create function public.deal_confirm_offline(p_deal_id uuid)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
begin
  if d.transaction_type is distinct from 'offline' or d.status <> 'awaiting_handover' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  insert into public.deal_confirmations (deal_id, user_id) values (d.id, uid)
  on conflict do nothing;
  insert into public.deal_events (deal_id, actor_id, event)
  values (d.id, uid, 'offline_confirmed');
  if (select count(*) from public.deal_confirmations where deal_id = d.id) = 2 then
    d := private.complete_deal(d, uid, 'completed_offline');
  end if;
  return d;
end
$$;

-- Online: Buyer generates the code after payment is verified (DEC-13).
create function public.deal_handover_code(p_deal_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
  code text;
  expires timestamptz := now() + interval '15 minutes';
begin
  if d.buyer_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if d.transaction_type is distinct from 'online'
     or d.status not in ('paid', 'awaiting_handover') then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;

  code := lpad(((('x' || encode(extensions.gen_random_bytes(4), 'hex'))::bit(32)::bigint)
                % 1000000)::text, 6, '0');
  insert into private.handover_codes (deal_id, code_hash, expires_at)
  values (d.id, extensions.crypt(code, extensions.gen_salt('bf', 8)), expires)
  on conflict (deal_id) do update
    set code_hash = excluded.code_hash, expires_at = excluded.expires_at,
        attempt_count = 0, consumed_at = null, created_at = now();

  if d.status = 'paid' then
    perform private.deal_set_status(d, 'awaiting_handover', uid, 'code_generated');
  else
    insert into public.deal_events (deal_id, actor_id, event)
    values (d.id, uid, 'code_regenerated');
  end if;
  return jsonb_build_object('code', code, 'expires_at', expires);
end
$$;

-- Seller submits the Buyer's code. Returns a result instead of raising on a
-- wrong code so the attempt counter is persisted.
create function public.deal_confirm_online(p_deal_id uuid, p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
  hc private.handover_codes;
begin
  if d.seller_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if d.transaction_type is distinct from 'online' or d.status <> 'awaiting_handover' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;

  select * into hc from private.handover_codes where deal_id = d.id for update;
  if not found or hc.consumed_at is not null then
    return jsonb_build_object('ok', false, 'error', 'no_active_code');
  end if;
  if hc.expires_at < now() then
    return jsonb_build_object('ok', false, 'error', 'code_expired');
  end if;
  if hc.attempt_count >= 5 then
    return jsonb_build_object('ok', false, 'error', 'code_locked');
  end if;

  update private.handover_codes set attempt_count = attempt_count + 1 where deal_id = d.id;
  if p_code is null or p_code !~ '^\d{6}$'
     or extensions.crypt(p_code, hc.code_hash) <> hc.code_hash then
    insert into public.deal_events (deal_id, actor_id, event) values (d.id, uid, 'code_rejected');
    return jsonb_build_object('ok', false, 'error', 'invalid_code',
                              'attempts_left', 5 - (hc.attempt_count + 1));
  end if;

  update private.handover_codes set consumed_at = now() where deal_id = d.id;
  d := private.complete_deal(d, uid, 'completed_online_code');
  return jsonb_build_object('ok', true, 'status', d.status);
end
$$;

-- Part I §14: Seller says the item was handed over, Buyer has not confirmed.
create function public.deal_report_confirmation_problem(p_deal_id uuid, p_note text default null)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
begin
  if d.seller_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if d.transaction_type is distinct from 'online'
     or d.status not in ('paid', 'awaiting_handover') then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  update public.deals
     set confirmation_problem_at = now(), confirmation_problem_note = left(p_note, 1000)
   where id = d.id returning * into d;
  insert into public.deal_events (deal_id, actor_id, event, note)
  values (d.id, uid, 'confirmation_problem', p_note);
  return d;
end
$$;

-- Buyer answers "Did you receive the item?".
create function public.deal_buyer_answer(p_deal_id uuid, p_received boolean, p_note text default null)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
begin
  if d.buyer_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if d.transaction_type is distinct from 'online'
     or d.status not in ('paid', 'awaiting_handover')
     or d.confirmation_problem_at is null then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if p_received then
    return private.complete_deal(d, uid, 'completed_buyer_confirmed');
  end if;
  d := private.deal_set_status(d, 'disputed', uid, 'buyer_reported_problem', p_note);
  insert into public.reports (reporter_id, target_kind, target_id, reason, details)
  values (uid, 'deal', d.id, 'item_not_received', coalesce(p_note, ''));
  return d;
end
$$;

-- Either party escalates to an admin; payout stays frozen.
create function public.deal_raise_dispute(p_deal_id uuid, p_reason text, p_details text default null)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
begin
  if d.status not in ('paid', 'awaiting_handover') then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  d := private.deal_set_status(d, 'disputed', uid, 'dispute_raised', p_details);
  insert into public.reports (reporter_id, target_kind, target_id, reason, details)
  values (uid, 'deal', d.id, coalesce(p_reason, 'other'), coalesce(p_details, ''));
  return d;
end
$$;

-- DEC-07: cancel before money moves or before both offline confirmations.
create function public.deal_cancel(p_deal_id uuid, p_reason text default null)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals := private.lock_deal_for(p_deal_id, uid);
begin
  if not (d.status = 'awaiting_payment'
          or (d.status = 'awaiting_handover' and d.transaction_type = 'offline')) then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.payments
             where deal_id = d.id and status in ('pending', 'successful')) then
    raise exception 'payment_pending' using errcode = 'P0001';
  end if;
  d := private.deal_set_status(d, 'cancelled', uid, 'cancelled', p_reason);
  update public.listings set status = 'active'
   where id = d.listing_id and status = 'reserved';
  return d;
end
$$;

do $$
declare
  fn text;
begin
  foreach fn in array array[
    'public.offer_respond(uuid, text, bigint)',
    'public.deal_select_mode(uuid, public.transaction_type)',
    'public.deal_confirm_offline(uuid)',
    'public.deal_handover_code(uuid)',
    'public.deal_confirm_online(uuid, text)',
    'public.deal_report_confirmation_problem(uuid, text)',
    'public.deal_buyer_answer(uuid, boolean, text)',
    'public.deal_raise_dispute(uuid, text, text)',
    'public.deal_cancel(uuid, text)'
  ] loop
    execute format('revoke execute on function %s from public, anon', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
end
$$;
