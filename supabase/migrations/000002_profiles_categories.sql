-- VT-007 / VT-009: User profiles, admin capability, regions and categories.
-- One normal User account buys and sells; there is no buyer/seller role column.

------------------------------------------------------------------------------
-- Admin capability (ENG-04): server-only table, never a user-writable column.
------------------------------------------------------------------------------
create table private.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  granted_by uuid references auth.users (id),
  granted_at timestamptz not null default now()
);

create function private.is_admin()
returns boolean
language sql stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from private.admin_users where user_id = (select auth.uid())
  )
$$;

grant usage on schema private to authenticated;
grant execute on function private.is_admin() to authenticated;

------------------------------------------------------------------------------
-- Regions (Nigeria states / Benin departments) – reference data.
------------------------------------------------------------------------------
create table public.regions (
  country_code public.country_code not null,
  code text not null,
  name text not null,
  primary key (country_code, code)
);

alter table public.regions enable row level security;
create policy "regions are public" on public.regions
  for select to anon, authenticated using (true);
grant select on public.regions to anon, authenticated;

------------------------------------------------------------------------------
-- Profiles (Part I §5)
------------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
    check (char_length(btrim(display_name)) between 1 and 60),
  avatar_path text,
  country_code public.country_code not null,
  region_code text,
  city text check (city is null or char_length(city) <= 80),
  preferred_locale text not null default 'en'
    check (preferred_locale in ('en', 'fr')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  suspended_at timestamptz,
  foreign key (country_code, region_code)
    references public.regions (country_code, code)
);

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function private.touch_updated_at();

alter table public.profiles enable row level security;

create policy "public can read non-suspended profiles" on public.profiles
  for select to anon, authenticated
  using (suspended_at is null or id = (select auth.uid()) or private.is_admin());

create policy "users update own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Column-level grants: users may only edit safe fields, never suspended_at,
-- joined_at or id. Inserts happen through the auth trigger below.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant update (display_name, avatar_path, country_code, region_code, city, preferred_locale)
  on public.profiles to authenticated;

-- Create the profile when a User signs up. The sign-up form sends
-- display_name, country_code and preferred_locale in user metadata.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  country public.country_code :=
    coalesce(nullif(meta ->> 'country_code', ''), 'NG')::public.country_code;
begin
  insert into public.profiles (id, display_name, country_code, preferred_locale)
  values (
    new.id,
    coalesce(nullif(btrim(meta ->> 'display_name'), ''), split_part(new.email, '@', 1)),
    country,
    coalesce(nullif(meta ->> 'preferred_locale', ''),
             case country when 'BJ' then 'fr' else 'en' end)
  );
  return new;
end
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

------------------------------------------------------------------------------
-- Categories (Part I §19) – bilingual names, admin-managed.
------------------------------------------------------------------------------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id) on delete restrict,
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name_en text not null check (char_length(name_en) between 1 and 60),
  name_fr text not null check (char_length(name_fr) between 1 and 60),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_unique_sibling_slug unique nulls not distinct (parent_id, slug)
);

create trigger categories_touch_updated_at
  before update on public.categories
  for each row execute function private.touch_updated_at();

alter table public.categories enable row level security;

create policy "public reads active categories" on public.categories
  for select to anon, authenticated
  using (active or private.is_admin());

create policy "admins manage categories" on public.categories
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

revoke all on public.categories from anon, authenticated;
grant select on public.categories to anon;
grant select, insert, update, delete on public.categories to authenticated;
