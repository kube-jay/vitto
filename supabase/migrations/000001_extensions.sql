-- VT-003 / VT-004: base extensions, private schema and shared helpers.

create extension if not exists pgcrypto with schema extensions;
create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- Security-definer helpers live here; not exposed through the Data API.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Market enums (Part I §3). Country and currency are fixed pairs (DEC-08).
create type public.country_code as enum ('NG', 'BJ');
create type public.currency_code as enum ('NGN', 'XOF');

create function private.currency_for_country(c public.country_code)
returns public.currency_code
language sql immutable
set search_path = ''
as $$
  select case c when 'NG' then 'NGN'::public.currency_code
                when 'BJ' then 'XOF'::public.currency_code end
$$;

-- Server-managed updated_at; clients cannot forge timestamps.
create function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end
$$;
