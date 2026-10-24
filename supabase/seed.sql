-- Local test data only. Reference data (regions, categories) lives in
-- migrations/000010_reference_data.sql.

-- ---------------------------------------------------------------------------
-- LOCAL TEST ACCOUNTS ONLY (Part II §38.1 test-account matrix). Never load
-- this into a hosted project: the admin password below is public.
-- `supabase db reset` loads this file; `supabase db push` never does.
-- Password for every account: VittoTest123!
-- ---------------------------------------------------------------------------
do $$
declare
  acct record;
begin
  for acct in
    select * from (values
      ('b0000000-0000-0000-0000-000000000001'::uuid, 'admin@vitto.test',     'Vitto Admin', 'NG', 'en'),
      ('b0000000-0000-0000-0000-000000000002'::uuid, 'ada.ng@vitto.test',    'Ada Okafor',  'NG', 'en'),
      ('b0000000-0000-0000-0000-000000000003'::uuid, 'chidi.ng@vitto.test',  'Chidi Eze',   'NG', 'en'),
      ('b0000000-0000-0000-0000-000000000004'::uuid, 'koffi.bj@vitto.test',  'Koffi Hounsa','BJ', 'fr'),
      ('b0000000-0000-0000-0000-000000000005'::uuid, 'awa.bj@vitto.test',    'Awa Dossou',  'BJ', 'fr'),
      ('b0000000-0000-0000-0000-000000000006'::uuid, 'suspended@vitto.test', 'Suspended User', 'NG', 'en')
    ) as v(id, email, name, country, locale)
  loop
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values (
      '00000000-0000-0000-0000-000000000000', acct.id, 'authenticated', 'authenticated',
      acct.email, extensions.crypt('VittoTest123!', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('display_name', acct.name, 'country_code', acct.country,
                         'preferred_locale', acct.locale),
      now(), now(), '', '', '', '');
    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (
      gen_random_uuid(), acct.id, acct.id::text,
      jsonb_build_object('sub', acct.id::text, 'email', acct.email, 'email_verified', true),
      'email', now(), now(), now());
  end loop;
end
$$;

insert into private.admin_users (user_id) values ('b0000000-0000-0000-0000-000000000001');
update public.profiles set city = 'Lagos', region_code = 'LA' where id = 'b0000000-0000-0000-0000-000000000002';
update public.profiles set city = 'Abuja', region_code = 'FC' where id = 'b0000000-0000-0000-0000-000000000003';
update public.profiles set city = 'Cotonou', region_code = 'LI' where id = 'b0000000-0000-0000-0000-000000000004';
update public.profiles set city = 'Porto-Novo', region_code = 'OU' where id = 'b0000000-0000-0000-0000-000000000005';
update public.profiles set suspended_at = now() where id = 'b0000000-0000-0000-0000-000000000006';
