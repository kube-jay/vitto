-- VT-014 / VT-016: Listing-linked Conversations, Messages and structured Offers.

------------------------------------------------------------------------------
-- Conversations (one per buyer per Listing)
------------------------------------------------------------------------------
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  unique (listing_id, buyer_id),
  check (buyer_id <> seller_id)
);
create index conversations_buyer_idx on public.conversations (buyer_id, last_message_at desc);
create index conversations_seller_idx on public.conversations (seller_id, last_message_at desc);

create function private.is_conversation_participant(p_conversation_id uuid)
returns boolean
language sql stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id
      and (select auth.uid()) in (c.buyer_id, c.seller_id)
  )
$$;
grant execute on function private.is_conversation_participant(uuid) to authenticated;

alter table public.conversations enable row level security;
create policy "participants read conversations" on public.conversations
  for select to authenticated
  using ((select auth.uid()) in (buyer_id, seller_id) or private.is_admin());
revoke all on public.conversations from anon, authenticated;
grant select on public.conversations to authenticated;

-- Participants keep seeing the Listing after it is reserved or sold.
create policy "conversation participants read listing" on public.listings
  for select to authenticated
  using (exists (
    select 1 from public.conversations c
    where c.listing_id = listings.id and (select auth.uid()) in (c.buyer_id, c.seller_id)
  ));

-- Participants also see the other party's profile even if later suspended.
create policy "conversation participants read profiles" on public.profiles
  for select to authenticated
  using (exists (
    select 1 from public.conversations c
    where (select auth.uid()) in (c.buyer_id, c.seller_id)
      and profiles.id in (c.buyer_id, c.seller_id)
  ));

------------------------------------------------------------------------------
-- Offers (Part I §9) – immutable history, server transitions only
------------------------------------------------------------------------------
create type public.offer_status as enum
  ('pending', 'accepted', 'rejected', 'countered', 'expired', 'cancelled');

create table public.offers (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  proposer_id uuid not null references public.profiles (id),
  recipient_id uuid not null references public.profiles (id),
  amount_minor bigint not null check (amount_minor > 0),
  currency public.currency_code not null,
  status public.offer_status not null default 'pending',
  parent_offer_id uuid references public.offers (id),
  expires_at timestamptz not null,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  check (proposer_id <> recipient_id)
);
create index offers_conversation_idx on public.offers (conversation_id, created_at);
create index offers_listing_pending_idx on public.offers (listing_id) where status = 'pending';
-- DEC-12: one pending Offer per Conversation at a time.
create unique index offers_one_pending_per_conversation
  on public.offers (conversation_id) where status = 'pending';

alter table public.offers enable row level security;
create policy "participants read offers" on public.offers
  for select to authenticated
  using ((select auth.uid()) in (proposer_id, recipient_id) or private.is_admin());
revoke all on public.offers from anon, authenticated;
grant select on public.offers to authenticated;

------------------------------------------------------------------------------
-- Messages (text only; system rows describe Offer/Deal events)
------------------------------------------------------------------------------
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles (id),
  body text not null default '' check (char_length(body) <= 2000),
  system_type text check (system_type in (
    'offer_created', 'offer_accepted', 'offer_rejected', 'offer_countered',
    'offer_cancelled', 'deal_update')),
  offer_id uuid references public.offers (id),
  created_at timestamptz not null default now(),
  check (system_type is not null or char_length(btrim(body)) >= 1)
);
create index messages_conversation_idx on public.messages (conversation_id, created_at);

alter table public.messages enable row level security;
create policy "participants read messages" on public.messages
  for select to authenticated
  using (private.is_conversation_participant(conversation_id) or private.is_admin());
create policy "participants send text messages" on public.messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and system_type is null
    and offer_id is null
    and private.is_conversation_participant(conversation_id)
    and private.is_active_user()
  );
revoke all on public.messages from anon, authenticated;
grant select on public.messages to authenticated;
grant insert (conversation_id, body) on public.messages to authenticated;

create function private.messages_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations set last_message_at = new.created_at
   where id = new.conversation_id;
  return new;
end
$$;
create trigger messages_after_insert
  after insert on public.messages
  for each row execute function private.messages_after_insert();

-- Basic abuse control: 20 text messages per minute per user.
create function private.messages_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.system_type is null and (
    select count(*) from public.messages
    where sender_id = new.sender_id
      and system_type is null
      and created_at > now() - interval '1 minute') >= 20 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  return new;
end
$$;
create trigger messages_rate_limit
  before insert on public.messages
  for each row execute function private.messages_rate_limit();

-- Read markers for unread badges.
create table public.conversation_reads (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
alter table public.conversation_reads enable row level security;
create policy "users manage own read markers" on public.conversation_reads
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and private.is_conversation_participant(conversation_id)
  );
revoke all on public.conversation_reads from anon, authenticated;
grant select, delete on public.conversation_reads to authenticated;
grant insert (conversation_id, last_read_at), update (last_read_at)
  on public.conversation_reads to authenticated;

------------------------------------------------------------------------------
-- Server actions
------------------------------------------------------------------------------
create function private.require_user()
returns uuid
language plpgsql stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'unauthenticated' using errcode = 'P0001';
  end if;
  if not private.is_active_user() then
    raise exception 'forbidden' using errcode = 'P0001', detail = 'Account suspended';
  end if;
  return uid;
end
$$;

create function private.expire_stale_offers(p_conversation_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.offers set status = 'expired', responded_at = now()
   where conversation_id = p_conversation_id
     and status = 'pending' and expires_at < now();
$$;

-- Opens (or returns) the buyer's Conversation about a Listing.
create function public.start_conversation(p_listing_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  l public.listings;
  conv_id uuid;
begin
  select id into conv_id from public.conversations
   where listing_id = p_listing_id and buyer_id = uid;
  if conv_id is not null then
    return conv_id;
  end if;

  select * into l from public.listings where id = p_listing_id;
  if not found or l.status <> 'active' or exists (
    select 1 from public.profiles where id = l.seller_id and suspended_at is not null
  ) then
    raise exception 'listing_not_available' using errcode = 'P0001';
  end if;
  if l.seller_id = uid then
    raise exception 'forbidden' using errcode = 'P0001',
      detail = 'You cannot message yourself';
  end if;

  insert into public.conversations (listing_id, buyer_id, seller_id)
  values (l.id, uid, l.seller_id)
  on conflict (listing_id, buyer_id) do nothing
  returning id into conv_id;
  if conv_id is null then
    select id into conv_id from public.conversations
     where listing_id = p_listing_id and buyer_id = uid;
  end if;
  return conv_id;
end
$$;

-- Buyer proposes a price (Part I §9). DEC-03: fixed-price Listings accept
-- only an Offer equal to the price.
create function public.offer_create(p_conversation_id uuid, p_amount_minor bigint)
returns public.offers
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  c public.conversations;
  l public.listings;
  o public.offers;
begin
  select * into c from public.conversations where id = p_conversation_id for update;
  if not found or c.buyer_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  select * into l from public.listings where id = c.listing_id;
  if l.status <> 'active' or exists (
    select 1 from public.profiles where id = l.seller_id and suspended_at is not null
  ) then
    raise exception 'listing_not_available' using errcode = 'P0001';
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 then
    raise exception 'validation_error' using errcode = 'P0001', detail = 'amount';
  end if;
  if not l.negotiable and p_amount_minor <> l.price_minor then
    raise exception 'validation_error' using errcode = 'P0001',
      detail = 'fixed_price';
  end if;

  perform private.expire_stale_offers(c.id);
  if exists (select 1 from public.offers where conversation_id = c.id and status = 'pending') then
    raise exception 'conflict' using errcode = 'P0001', detail = 'offer_pending';
  end if;
  if (select count(*) from public.offers
      where proposer_id = uid and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  insert into public.offers (conversation_id, listing_id, proposer_id, recipient_id,
                             amount_minor, currency, expires_at)
  values (c.id, l.id, uid, l.seller_id, p_amount_minor, l.currency,
          now() + interval '48 hours')
  returning * into o;

  insert into public.messages (conversation_id, sender_id, system_type, offer_id)
  values (c.id, uid, 'offer_created', o.id);
  return o;
end
$$;

create function public.offer_cancel(p_offer_id uuid)
returns public.offers
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  o public.offers;
begin
  select * into o from public.offers where id = p_offer_id for update;
  if not found or o.proposer_id <> uid then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if o.status <> 'pending' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  update public.offers set status = 'cancelled', responded_at = now()
   where id = o.id returning * into o;
  insert into public.messages (conversation_id, sender_id, system_type, offer_id)
  values (o.conversation_id, uid, 'offer_cancelled', o.id);
  return o;
end
$$;

revoke execute on function public.start_conversation(uuid) from public, anon;
revoke execute on function public.offer_create(uuid, bigint) from public, anon;
revoke execute on function public.offer_cancel(uuid) from public, anon;
grant execute on function public.start_conversation(uuid) to authenticated;
grant execute on function public.offer_create(uuid, bigint) to authenticated;
grant execute on function public.offer_cancel(uuid) to authenticated;

alter publication supabase_realtime add table public.messages, public.offers;
