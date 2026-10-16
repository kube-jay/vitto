-- Run with: npx supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

-- Two users and one admin
insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'ng1@test.vitto', '{"display_name":"Ada","country_code":"NG"}'),
  ('22222222-2222-2222-2222-222222222222', 'bj1@test.vitto', '{"display_name":"Koffi","country_code":"BJ"}'),
  ('33333333-3333-3333-3333-333333333333', 'admin@test.vitto', '{"display_name":"Admin","country_code":"NG"}');
insert into private.admin_users (user_id) values ('33333333-3333-3333-3333-333333333333');

select is(
  (select preferred_locale from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  'fr', 'Benin sign-up defaults to French');

-- Anonymous visitor
set local role anon;
select is((select count(*)::int from public.profiles), 3, 'anon reads public profiles');
select ok((select count(*) from public.categories) > 0, 'anon reads active categories');
select throws_ok(
  $$insert into public.categories (slug, name_en, name_fr) values ('x','X','X')$$,
  '42501', null, 'anon cannot create categories');

-- Normal user
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

update public.profiles set city = 'Lagos' where id = '11111111-1111-1111-1111-111111111111';
select is(
  (select city from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Lagos', 'user edits own profile');

update public.profiles set city = 'Hacked' where id = '22222222-2222-2222-2222-222222222222';
select is(
  (select city from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  null, 'user cannot edit another profile');

select throws_ok(
  $$update public.profiles set suspended_at = now() where id = '11111111-1111-1111-1111-111111111111'$$,
  '42501', null, 'user cannot set suspended_at');

select throws_ok(
  $$select private.is_admin() from private.admin_users$$,
  '42501', null, 'user cannot read admin table');

select throws_ok(
  $$insert into public.categories (slug, name_en, name_fr) values ('x','X','X')$$,
  '42501', null, 'non-admin cannot create categories');

-- Admin
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
insert into public.categories (slug, name_en, name_fr) values ('test-cat', 'Test', 'Test');
select is((select count(*)::int from public.categories where slug = 'test-cat'), 1,
  'admin creates categories');

select * from finish();
rollback;
