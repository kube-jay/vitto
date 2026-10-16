-- VT-026 / VT-029: Payment and Payout ledger. Payment = buyer pays;
-- Payout = seller receives. They are separate records and events (Part I §12).
-- Only the service role (Edge Functions) writes here.

create type public.payment_status as enum
  ('initialized', 'pending', 'successful', 'failed', 'refunded');
create type public.payout_status as enum
  ('not_eligible', 'eligible', 'requested', 'paid', 'failed', 'reversed');

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals (id),
  provider text not null,
  provider_reference text not null,
  amount_minor bigint not null check (amount_minor > 0),
  currency public.currency_code not null,
  status public.payment_status not null default 'pending',
  idempotency_key text not null,
  checkout_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  verified_at timestamptz,
  unique (provider, provider_reference),
  unique (deal_id, idempotency_key)
);
create index payments_deal_idx on public.payments (deal_id);
create trigger payments_touch_updated_at
  before update on public.payments
  for each row execute function private.touch_updated_at();

create table public.payment_events (
  id bigint generated always as identity primary key,
  provider text not null,
  event_id text not null,
  event_type text not null,
  reference text,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  outcome text,
  unique (provider, event_id)
);

create table public.payouts (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null unique references public.deals (id),
  provider text not null,
  provider_reference text,
  amount_minor bigint not null check (amount_minor > 0),
  currency public.currency_code not null,
  status public.payout_status not null default 'not_eligible',
  eligible_at timestamptz,
  requested_at timestamptz,
  paid_at timestamptz,
  attempts integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger payouts_touch_updated_at
  before update on public.payouts
  for each row execute function private.touch_updated_at();

alter table public.payments enable row level security;
alter table public.payment_events enable row level security;
alter table public.payouts enable row level security;

create policy "participants read payments" on public.payments
  for select to authenticated
  using (private.is_deal_participant(deal_id) or private.is_admin());
create policy "participants read payouts" on public.payouts
  for select to authenticated
  using (private.is_deal_participant(deal_id) or private.is_admin());
create policy "admins read payment events" on public.payment_events
  for select to authenticated using (private.is_admin());

revoke all on public.payments, public.payment_events, public.payouts from anon, authenticated;
grant select (id, deal_id, provider, provider_reference, amount_minor, currency, status,
              checkout_url, created_at, updated_at, verified_at)
  on public.payments to authenticated;
grant select on public.payouts, public.payment_events to authenticated;

alter publication supabase_realtime add table public.payments;

------------------------------------------------------------------------------
-- Service-role functions (called by Edge Functions only)
------------------------------------------------------------------------------

-- Records a hosted-checkout session for an online Deal. Idempotent per key.
create function public.payment_record_initialized(
  p_deal_id uuid, p_provider text, p_reference text, p_amount_minor bigint,
  p_currency public.currency_code, p_idempotency_key text, p_checkout_url text)
returns public.payments
language plpgsql
security definer
set search_path = ''
as $$
declare
  d public.deals;
  p public.payments;
begin
  select * into p from public.payments
   where deal_id = p_deal_id and idempotency_key = p_idempotency_key;
  if found then
    return p;
  end if;

  select * into d from public.deals where id = p_deal_id for update;
  if not found or d.transaction_type is distinct from 'online'
     or d.status <> 'awaiting_payment' then
    raise exception 'invalid_state' using errcode = 'P0001';
  end if;
  if p_amount_minor <> d.agreed_amount_minor or p_currency <> d.currency then
    raise exception 'validation_error' using errcode = 'P0001', detail = 'amount_mismatch';
  end if;
  if exists (select 1 from public.payments where deal_id = d.id and status = 'successful') then
    raise exception 'conflict' using errcode = 'P0001', detail = 'already_paid';
  end if;

  insert into public.payments (deal_id, provider, provider_reference, amount_minor, currency,
                               status, idempotency_key, checkout_url)
  values (d.id, p_provider, p_reference, p_amount_minor, p_currency, 'pending',
          p_idempotency_key, p_checkout_url)
  returning * into p;
  insert into public.deal_events (deal_id, actor_id, event, note)
  values (d.id, d.buyer_id, 'payment_initialized', p_provider || ':' || p_reference);
  return p;
end
$$;

-- Applies a provider-verified result. Duplicate events are no-ops; amounts
-- must match the Deal snapshot; a successful Payment never triggers a Payout.
create function public.payment_apply_verified(
  p_provider text, p_reference text, p_status public.payment_status,
  p_amount_minor bigint, p_currency public.currency_code,
  p_event_id text default null, p_event_type text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.payments;
  d public.deals;
  ev_id bigint;
  v_outcome text;
begin
  if p_event_id is not null then
    insert into public.payment_events (provider, event_id, event_type, reference)
    values (p_provider, p_event_id, coalesce(p_event_type, 'unknown'), p_reference)
    on conflict (provider, event_id) do nothing
    returning id into ev_id;
    if ev_id is null then
      return jsonb_build_object('ok', true, 'duplicate', true);
    end if;
  end if;

  select * into p from public.payments
   where provider = p_provider and provider_reference = p_reference for update;
  if not found then
    v_outcome := 'unknown_reference';
  elsif p.status in ('successful', 'refunded') then
    v_outcome := 'already_final';
  elsif p_status = 'successful'
        and (p_amount_minor <> p.amount_minor or p_currency <> p.currency) then
    v_outcome := 'amount_mismatch';
    insert into public.audit_logs (actor_id, action, target_kind, target_id, metadata)
    values (null, 'payment_amount_mismatch', 'payment', p.id,
            jsonb_build_object('expected', p.amount_minor, 'got', p_amount_minor,
                               'currency', p_currency));
  elsif p_status = 'successful' then
    update public.payments set status = 'successful', verified_at = now()
     where id = p.id returning * into p;
    select * into d from public.deals where id = p.deal_id for update;
    if d.status = 'awaiting_payment' and d.transaction_type = 'online' then
      perform private.deal_set_status(d, 'paid', null, 'payment_verified',
                                      p_provider || ':' || p_reference);
      v_outcome := 'deal_paid';
    else
      -- e.g. Deal cancelled meanwhile: needs admin refund review.
      v_outcome := 'paid_but_deal_' || d.status::text;
      insert into public.audit_logs (actor_id, action, target_kind, target_id, metadata)
      values (null, 'payment_needs_review', 'deal', d.id,
              jsonb_build_object('payment_id', p.id, 'deal_status', d.status));
    end if;
  elsif p_status = 'failed' then
    update public.payments set status = 'failed' where id = p.id;
    v_outcome := 'payment_failed';
  else
    v_outcome := 'still_pending';
  end if;

  if ev_id is not null then
    update public.payment_events set processed_at = now(), outcome = v_outcome where id = ev_id;
  end if;
  return jsonb_build_object('ok', v_outcome in ('deal_paid', 'payment_failed', 'still_pending',
                                              'already_final'),
                            'outcome', v_outcome);
end
$$;

-- Records a payout attempt result. Refuses unless the Deal is eligible.
create function public.payout_record(
  p_deal_id uuid, p_status public.payout_status, p_provider_reference text,
  p_error text default null)
returns public.payouts
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.payouts;
  d public.deals;
begin
  select * into d from public.deals where id = p_deal_id;
  select * into po from public.payouts where deal_id = p_deal_id for update;
  if not found or d.status <> 'completed'
     or po.status not in ('eligible', 'failed', 'requested') then
    raise exception 'invalid_state' using errcode = 'P0001', detail = 'payout_not_eligible';
  end if;
  update public.payouts
     set status = p_status,
         provider_reference = coalesce(p_provider_reference, provider_reference),
         attempts = attempts + case when p_status = 'requested' then 1 else 0 end,
         requested_at = case when p_status = 'requested' then now() else requested_at end,
         paid_at = case when p_status = 'paid' then now() else paid_at end,
         last_error = p_error
   where id = po.id
  returning * into po;
  return po;
end
$$;

revoke execute on function public.payment_record_initialized(
  uuid, text, text, bigint, public.currency_code, text, text) from public, anon, authenticated;
revoke execute on function public.payment_apply_verified(
  text, text, public.payment_status, bigint, public.currency_code, text, text)
  from public, anon, authenticated;
revoke execute on function public.payout_record(uuid, public.payout_status, text, text)
  from public, anon, authenticated;
grant execute on function public.payment_record_initialized(
  uuid, text, text, bigint, public.currency_code, text, text) to service_role;
grant execute on function public.payment_apply_verified(
  text, text, public.payment_status, bigint, public.currency_code, text, text) to service_role;
grant execute on function public.payout_record(uuid, public.payout_status, text, text)
  to service_role;
