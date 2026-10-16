-- VT-010 / VT-013: Listings, images, storage buckets, favorites, search.

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------
create function private.is_active_user()
returns boolean
language sql stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and suspended_at is null
  )
$$;
grant execute on function private.is_active_user() to authenticated;

-- unaccent() is only STABLE; this wrapper pins the dictionary so it can be
-- used in a generated column (search must match "telephone" and "téléphone").
create function private.f_unaccent(text)
returns text
language sql immutable parallel safe strict
set search_path = ''
as $$
  select extensions.unaccent('extensions.unaccent'::regdictionary, $1)
$$;
grant execute on function private.f_unaccent(text) to anon, authenticated;

------------------------------------------------------------------------------
-- Listings (Part I §6)
------------------------------------------------------------------------------
create type public.listing_status as enum
  ('draft', 'active', 'reserved', 'sold', 'archived', 'suspended');
create type public.listing_condition as enum ('new', 'used');

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  category_id uuid not null references public.categories (id),
  title text not null check (char_length(btrim(title)) between 3 and 100),
  description text not null default ''
    check (char_length(description) <= 5000),
  price_minor bigint not null check (price_minor > 0),
  currency public.currency_code not null,
  negotiable boolean not null default true,
  condition public.listing_condition not null,
  country_code public.country_code not null,
  region_code text,
  city text not null check (char_length(btrim(city)) between 1 and 80),
  status public.listing_status not null default 'draft',
  suspended_from public.listing_status,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search tsvector generated always as (
    to_tsvector('simple',
      private.f_unaccent(coalesce(title, '') || ' ' || coalesce(description, '')))
  ) stored,
  -- DEC-08: currency is fixed by the Listing country, never converted.
  constraint listings_currency_matches_country
    check (currency = private.currency_for_country(country_code)),
  foreign key (country_code, region_code)
    references public.regions (country_code, code)
);

create index listings_discovery_idx
  on public.listings (status, country_code, category_id, created_at desc);
create index listings_seller_idx on public.listings (seller_id, status);
create index listings_search_idx on public.listings using gin (search);

-- Currency is derived server-side; clients never send it.
create function private.listings_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.currency := private.currency_for_country(new.country_code);
  new.updated_at := now();
  return new;
end
$$;

create trigger listings_before_write
  before insert or update on public.listings
  for each row execute function private.listings_before_write();

alter table public.listings enable row level security;

-- Only active Listings of non-suspended sellers are public. Owners and admins
-- see everything; Conversation participants keep access after reservation.
create policy "listings readable" on public.listings
  for select to anon, authenticated
  using (
    (status = 'active' and exists (
      select 1 from public.profiles p
      where p.id = seller_id and p.suspended_at is null))
    or seller_id = (select auth.uid())
    or private.is_admin()
  );

create policy "active users create draft listings" on public.listings
  for insert to authenticated
  with check (
    seller_id = (select auth.uid())
    and status = 'draft'
    and private.is_active_user()
  );

create policy "owners edit own listings" on public.listings
  for update to authenticated
  using (
    seller_id = (select auth.uid())
    and status in ('draft', 'active', 'archived')
  )
  with check (seller_id = (select auth.uid()));

create policy "owners delete own drafts" on public.listings
  for delete to authenticated
  using (seller_id = (select auth.uid()) and status = 'draft');

revoke all on public.listings from anon, authenticated;
grant select on public.listings to anon, authenticated;
grant insert (category_id, title, description, price_minor, negotiable,
              condition, country_code, region_code, city)
  on public.listings to authenticated;
grant update (category_id, title, description, price_minor, negotiable,
              condition, country_code, region_code, city)
  on public.listings to authenticated;
grant delete on public.listings to authenticated;

------------------------------------------------------------------------------
-- Listing images (1–8 per Listing)
------------------------------------------------------------------------------
create table public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  storage_path text not null unique,
  sort_order smallint not null default 0 check (sort_order between 0 and 7),
  created_at timestamptz not null default now()
);
create index listing_images_listing_idx on public.listing_images (listing_id, sort_order);

create function private.listing_images_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  remaining int;
  st public.listing_status;
begin
  if tg_op = 'INSERT' then
    if (select count(*) from public.listing_images where listing_id = new.listing_id) >= 8 then
      raise exception 'validation_error' using errcode = 'P0001',
        detail = 'A Listing can have at most 8 images';
    end if;
    return new;
  end if;
  -- An active Listing must keep at least one image.
  select status into st from public.listings where id = old.listing_id;
  select count(*) into remaining from public.listing_images
    where listing_id = old.listing_id and id <> old.id;
  if st = 'active' and remaining = 0 then
    raise exception 'validation_error' using errcode = 'P0001',
      detail = 'An active Listing needs at least one image';
  end if;
  return old;
end
$$;

create trigger listing_images_guard
  before insert or delete on public.listing_images
  for each row execute function private.listing_images_guard();

alter table public.listing_images enable row level security;

create policy "images follow listing visibility" on public.listing_images
  for select to anon, authenticated
  using (exists (select 1 from public.listings l where l.id = listing_id));

create policy "owners add images" on public.listing_images
  for insert to authenticated
  with check (
    storage_path like (select auth.uid())::text || '/%'
    and exists (
      select 1 from public.listings l
      where l.id = listing_id
        and l.seller_id = (select auth.uid())
        and l.status in ('draft', 'active', 'archived'))
  );

create policy "owners reorder images" on public.listing_images
  for update to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = (select auth.uid())))
  with check (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = (select auth.uid())));

create policy "owners remove images" on public.listing_images
  for delete to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id
      and l.seller_id = (select auth.uid())
      and l.status in ('draft', 'active', 'archived')));

revoke all on public.listing_images from anon, authenticated;
grant select on public.listing_images to anon, authenticated;
grant insert (listing_id, storage_path, sort_order) on public.listing_images to authenticated;
grant update (sort_order) on public.listing_images to authenticated;
grant delete on public.listing_images to authenticated;

------------------------------------------------------------------------------
-- Status changes by the owner (reserved/sold come from Deals, suspended
-- from admins).
------------------------------------------------------------------------------
create function public.listing_set_status(p_listing_id uuid, p_status public.listing_status)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  l public.listings;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = 'P0001';
  end if;
  select * into l from public.listings where id = p_listing_id for update;
  if not found or l.seller_id <> auth.uid() then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  if not (
    (l.status = 'draft' and p_status in ('active', 'archived')) or
    (l.status = 'active' and p_status = 'archived') or
    (l.status = 'archived' and p_status = 'active')
  ) then
    raise exception 'invalid_state' using errcode = 'P0001',
      detail = format('%s -> %s is not allowed', l.status, p_status);
  end if;

  if p_status = 'active' then
    if not private.is_active_user() then
      raise exception 'forbidden' using errcode = 'P0001';
    end if;
    if not exists (select 1 from public.listing_images where listing_id = l.id) then
      raise exception 'validation_error' using errcode = 'P0001',
        detail = 'Add at least one image before publishing';
    end if;
  end if;

  update public.listings
     set status = p_status,
         published_at = case when p_status = 'active'
                             then coalesce(published_at, now()) else published_at end
   where id = l.id
  returning * into l;
  return l;
end
$$;
revoke execute on function public.listing_set_status(uuid, public.listing_status) from public, anon;
grant execute on function public.listing_set_status(uuid, public.listing_status) to authenticated;

------------------------------------------------------------------------------
-- Discovery search (Part I §7). SECURITY INVOKER: RLS still applies.
------------------------------------------------------------------------------
create function public.search_listings(
  p_query text default null,
  p_country public.country_code default null,
  p_region text default null,
  p_category uuid default null,
  p_min_price bigint default null,
  p_max_price bigint default null,
  p_condition public.listing_condition default null,
  p_negotiable boolean default null,
  p_sort text default 'newest'
)
returns setof public.listings
language plpgsql stable
set search_path = ''
as $$
declare
  tsq tsquery;
  words text;
begin
  words := btrim(regexp_replace(
    private.f_unaccent(lower(coalesce(p_query, ''))), '[^[:alnum:]]+', ' ', 'g'));
  if words <> '' then
    tsq := to_tsquery('simple',
      array_to_string(array(
        select w || ':*' from unnest(string_to_array(words, ' ')) w where w <> ''
      ), ' & '));
  end if;

  return query
  select l.* from public.listings l
  where l.status = 'active'
    and (tsq is null or l.search @@ tsq)
    and (p_country is null or l.country_code = p_country)
    and (p_region is null or l.region_code = p_region)
    and (p_category is null or l.category_id in (
          select c.id from public.categories c
          where c.id = p_category or c.parent_id = p_category))
    and (p_min_price is null or l.price_minor >= p_min_price)
    and (p_max_price is null or l.price_minor <= p_max_price)
    and (p_condition is null or l.condition = p_condition)
    and (p_negotiable is null or l.negotiable = p_negotiable)
  order by
    case when p_sort = 'price_asc' then l.price_minor end asc,
    case when p_sort = 'price_desc' then l.price_minor end desc,
    l.published_at desc nulls last, l.created_at desc;
end
$$;
grant execute on function public.search_listings(
  text, public.country_code, text, uuid, bigint, bigint,
  public.listing_condition, boolean, text) to anon, authenticated;

------------------------------------------------------------------------------
-- Favorites
------------------------------------------------------------------------------
create table public.favorites (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

alter table public.favorites enable row level security;
create policy "users read own favorites" on public.favorites
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users add visible listings" on public.favorites
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.listings l where l.id = listing_id)
  );
create policy "users remove own favorites" on public.favorites
  for delete to authenticated using (user_id = (select auth.uid()));

revoke all on public.favorites from anon, authenticated;
grant select, delete on public.favorites to authenticated;
grant insert (listing_id) on public.favorites to authenticated;

------------------------------------------------------------------------------
-- Storage buckets: public listing images and avatars. Paths start with the
-- owner's user id: "<uid>/<listing-id>/<file>" and "<uid>/<file>".
------------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('listing-images', 'listing-images', true, 5242880,
   array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars', 'avatars', true, 2097152,
   array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "owners upload listing images" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and private.is_active_user()
  );
create policy "owners delete listing images" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "owners upload avatars" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "owners delete avatars" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
