-- VT-024 / VT-025 / VT-031: Ratings, Reports, dispute evidence, audit log
-- and admin operations.

------------------------------------------------------------------------------
-- Audit log (append-only; written by server functions)
------------------------------------------------------------------------------
create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users (id),
  action text not null,
  target_kind text,
  target_id uuid,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index audit_logs_target_idx on public.audit_logs (target_kind, target_id);
alter table public.audit_logs enable row level security;
create policy "admins read audit log" on public.audit_logs
  for select to authenticated using (private.is_admin());
revoke all on public.audit_logs from anon, authenticated;
grant select on public.audit_logs to authenticated;

create function private.audit(p_action text, p_kind text, p_target uuid, p_meta jsonb default '{}')
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_logs (actor_id, action, target_kind, target_id, metadata)
  values (auth.uid(), p_action, p_kind, p_target, coalesce(p_meta, '{}'));
$$;

------------------------------------------------------------------------------
-- Ratings (Part I §16): one per direction per completed Deal
------------------------------------------------------------------------------
alter table public.profiles
  add column rating_count integer not null default 0,
  add column rating_sum integer not null default 0;

create table public.ratings (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals (id),
  author_id uuid not null references public.profiles (id),
  recipient_id uuid not null references public.profiles (id),
  stars smallint not null check (stars between 1 and 5),
  comment text check (char_length(comment) <= 500),
  hidden_at timestamptz,
  created_at timestamptz not null default now(),
  unique (deal_id, author_id),
  check (author_id <> recipient_id)
);
create index ratings_recipient_idx on public.ratings (recipient_id, created_at desc);

alter table public.ratings enable row level security;
create policy "visible ratings are public" on public.ratings
  for select to anon, authenticated
  using (hidden_at is null or author_id = (select auth.uid()) or private.is_admin());
revoke all on public.ratings from anon, authenticated;
grant select on public.ratings to anon, authenticated;

create function public.rating_submit(p_deal_id uuid, p_stars smallint, p_comment text default null)
returns public.ratings
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_user();
  d public.deals;
  r public.ratings;
begin
  select * into d from public.deals where id = p_deal_id;
  if not found or uid not in (d.buyer_id, d.seller_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if d.status <> 'completed' then
    raise exception 'invalid_state' using errcode = 'P0001', detail = 'deal_not_completed';
  end if;
  if p_stars is null or p_stars not between 1 and 5 then
    raise exception 'validation_error' using errcode = 'P0001', detail = 'stars';
  end if;

  insert into public.ratings (deal_id, author_id, recipient_id, stars, comment)
  values (d.id, uid,
          case when uid = d.buyer_id then d.seller_id else d.buyer_id end,
          p_stars, nullif(btrim(left(p_comment, 500)), ''))
  on conflict (deal_id, author_id) do nothing
  returning * into r;
  if r.id is null then
    raise exception 'conflict' using errcode = 'P0001', detail = 'already_rated';
  end if;

  update public.profiles
     set rating_count = rating_count + 1, rating_sum = rating_sum + r.stars
   where id = r.recipient_id;
  return r;
end
$$;

------------------------------------------------------------------------------
-- Reports (user / listing / deal / message)
------------------------------------------------------------------------------
create type public.report_target as enum ('user', 'listing', 'deal', 'message');
create type public.report_status as enum ('open', 'reviewing', 'resolved', 'dismissed');

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references public.profiles (id),
  target_kind public.report_target not null,
  target_id uuid not null,
  reason text not null check (reason in (
    'prohibited_item', 'scam', 'offensive', 'wrong_info', 'no_show',
    'item_not_received', 'other')),
  details text not null default '' check (char_length(details) <= 2000),
  status public.report_status not null default 'open',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users (id),
  resolution_note text
);
create index reports_status_idx on public.reports (status, created_at desc);
create index reports_target_idx on public.reports (target_kind, target_id);

alter table public.reports enable row level security;
create policy "users read own reports" on public.reports
  for select to authenticated
  using (reporter_id = (select auth.uid()) or private.is_admin());
create policy "active users file reports" on public.reports
  for insert to authenticated
  with check (reporter_id = (select auth.uid()) and private.is_active_user());
revoke all on public.reports from anon, authenticated;
grant select on public.reports to authenticated;
grant insert (target_kind, target_id, reason, details) on public.reports to authenticated;

create function private.reports_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.reports
      where reporter_id = new.reporter_id and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  return new;
end
$$;
create trigger reports_rate_limit
  before insert on public.reports
  for each row execute function private.reports_rate_limit();

------------------------------------------------------------------------------
-- Dispute evidence (private bucket "dispute-evidence/<deal-id>/<uid>/<file>")
------------------------------------------------------------------------------
create table public.dispute_evidence (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals (id),
  uploader_id uuid not null default auth.uid() references public.profiles (id),
  storage_path text not null unique,
  note text check (char_length(note) <= 1000),
  created_at timestamptz not null default now()
);
alter table public.dispute_evidence enable row level security;
create policy "participants read evidence" on public.dispute_evidence
  for select to authenticated
  using (private.is_deal_participant(deal_id) or private.is_admin());
create policy "participants add evidence" on public.dispute_evidence
  for insert to authenticated
  with check (
    uploader_id = (select auth.uid())
    and private.is_deal_participant(deal_id)
    and storage_path like deal_id::text || '/' || (select auth.uid())::text || '/%'
  );
revoke all on public.dispute_evidence from anon, authenticated;
grant select on public.dispute_evidence to authenticated;
grant insert (deal_id, storage_path, note) on public.dispute_evidence to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dispute-evidence', 'dispute-evidence', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy "participants upload evidence" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'dispute-evidence'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and private.is_deal_participant(((storage.foldername(name))[1])::uuid)
  );
create policy "participants and admins read evidence" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'dispute-evidence'
    and (private.is_deal_participant(((storage.foldername(name))[1])::uuid)
         or private.is_admin())
  );

------------------------------------------------------------------------------
-- Admin operations (Part I §18). Every action is audited.
------------------------------------------------------------------------------
create function public.current_user_is_admin()
returns boolean
language sql stable
security definer
set search_path = ''
as $$ select private.is_admin() $$;

create function private.require_admin()
returns uuid
language plpgsql stable
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  return auth.uid();
end
$$;

create function public.admin_list_users(p_query text default null, p_limit int default 50)
returns table (
  id uuid, email text, display_name text, country_code public.country_code, city text,
  joined_at timestamptz, suspended_at timestamptz, completed_deals_count int,
  rating_count int, rating_sum int, is_admin boolean)
language plpgsql stable
security definer
set search_path = ''
as $$
begin
  perform private.require_admin();
  return query
  select p.id, u.email::text, p.display_name, p.country_code, p.city, p.joined_at,
         p.suspended_at, p.completed_deals_count, p.rating_count, p.rating_sum,
         exists (select 1 from private.admin_users a where a.user_id = p.id)
    from public.profiles p join auth.users u on u.id = p.id
   where p_query is null or p_query = ''
      or p.display_name ilike '%' || p_query || '%'
      or u.email ilike '%' || p_query || '%'
   order by p.joined_at desc
   limit least(coalesce(p_limit, 50), 200);
end
$$;

create function public.admin_set_user_suspension(p_user_id uuid, p_suspend boolean, p_reason text)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  pr public.profiles;
begin
  perform private.require_admin();
  update public.profiles
     set suspended_at = case when p_suspend then now() else null end
   where id = p_user_id returning * into pr;
  if not found then
    raise exception 'validation_error' using errcode = 'P0001';
  end if;
  perform private.audit(case when p_suspend then 'user_suspended' else 'user_restored' end,
                        'user', p_user_id, jsonb_build_object('reason', p_reason));
  return pr;
end
$$;

create function public.admin_set_listing_suspension(p_listing_id uuid, p_suspend boolean, p_reason text)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  l public.listings;
begin
  perform private.require_admin();
  select * into l from public.listings where id = p_listing_id for update;
  if not found then
    raise exception 'validation_error' using errcode = 'P0001';
  end if;
  if p_suspend and l.status <> 'suspended' then
    update public.listings set suspended_from = status, status = 'suspended'
     where id = l.id returning * into l;
  elsif not p_suspend and l.status = 'suspended' then
    update public.listings
       set status = coalesce(suspended_from, 'archived'), suspended_from = null
     where id = l.id returning * into l;
  end if;
  perform private.audit(case when p_suspend then 'listing_suspended' else 'listing_restored' end,
                        'listing', p_listing_id, jsonb_build_object('reason', p_reason));
  return l;
end
$$;

create function public.admin_update_report(p_report_id uuid, p_status public.report_status, p_note text)
returns public.reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_admin();
  r public.reports;
begin
  update public.reports
     set status = p_status,
         resolution_note = p_note,
         resolved_at = case when p_status in ('resolved', 'dismissed') then now() end,
         resolved_by = case when p_status in ('resolved', 'dismissed') then uid end
   where id = p_report_id returning * into r;
  if not found then
    raise exception 'validation_error' using errcode = 'P0001';
  end if;
  perform private.audit('report_' || p_status::text, 'report', p_report_id,
                        jsonb_build_object('note', p_note));
  return r;
end
$$;

-- DEC-07: admin decides a disputed Deal. No money moves automatically;
-- refunds are processed manually in the provider dashboard.
create function public.admin_resolve_dispute(p_deal_id uuid, p_disposition text, p_note text)
returns public.deals
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := private.require_admin();
  d public.deals;
begin
  select * into d from public.deals where id = p_deal_id for update;
  if not found or d.status <> 'disputed' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;

  if p_disposition = 'complete' then
    d := private.complete_deal(d, uid, 'admin_completed');
  elsif p_disposition = 'cancel' then
    d := private.deal_set_status(d, 'cancelled', uid, 'admin_cancelled', p_note);
    update public.listings set status = 'active'
     where id = d.listing_id and status = 'reserved';
    update public.payouts set status = 'not_eligible' where deal_id = d.id;
  else
    raise exception 'validation_error' using errcode = 'P0001', detail = 'disposition';
  end if;

  update public.reports
     set status = 'resolved', resolved_at = now(), resolved_by = uid, resolution_note = p_note
   where target_kind = 'deal' and target_id = d.id and status in ('open', 'reviewing');
  perform private.audit('dispute_' || p_disposition, 'deal', d.id,
                        jsonb_build_object('note', p_note));
  return d;
end
$$;

create function public.admin_hide_rating(p_rating_id uuid, p_hide boolean, p_reason text)
returns public.ratings
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.ratings;
begin
  perform private.require_admin();
  select * into r from public.ratings where id = p_rating_id for update;
  if not found then
    raise exception 'validation_error' using errcode = 'P0001';
  end if;
  if p_hide and r.hidden_at is null then
    update public.ratings set hidden_at = now() where id = r.id returning * into r;
    update public.profiles set rating_count = rating_count - 1, rating_sum = rating_sum - r.stars
     where id = r.recipient_id;
  elsif not p_hide and r.hidden_at is not null then
    update public.ratings set hidden_at = null where id = r.id returning * into r;
    update public.profiles set rating_count = rating_count + 1, rating_sum = rating_sum + r.stars
     where id = r.recipient_id;
  end if;
  perform private.audit(case when p_hide then 'rating_hidden' else 'rating_restored' end,
                        'rating', r.id, jsonb_build_object('reason', p_reason));
  return r;
end
$$;

-- Admins may write categories directly (RLS); log it too.
create function private.categories_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.audit('category_' || lower(tg_op), 'category',
                        coalesce(new.id, old.id), '{}');
  return coalesce(new, old);
end
$$;
create trigger categories_audit
  after insert or update or delete on public.categories
  for each row execute function private.categories_audit();

do $$
declare
  fn text;
begin
  foreach fn in array array[
    'public.rating_submit(uuid, smallint, text)',
    'public.current_user_is_admin()',
    'public.admin_list_users(text, int)',
    'public.admin_set_user_suspension(uuid, boolean, text)',
    'public.admin_set_listing_suspension(uuid, boolean, text)',
    'public.admin_update_report(uuid, public.report_status, text)',
    'public.admin_resolve_dispute(uuid, text, text)',
    'public.admin_hide_rating(uuid, boolean, text)'
  ] loop
    execute format('revoke execute on function %s from public, anon', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
end
$$;
