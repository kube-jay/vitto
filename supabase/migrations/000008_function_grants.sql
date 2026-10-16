-- Least-privilege EXECUTE grants on helper functions in the private schema.
-- Postgres grants EXECUTE to PUBLIC by default; the private schema is not
-- exposed through the Data API, but we still lock it down explicitly.

grant usage on schema private to anon, authenticated;
revoke execute on all functions in schema private from public, anon, authenticated;

-- Used by RLS policies, check constraints, generated columns and invoker
-- functions, so the calling role needs them.
grant execute on function private.is_admin() to anon, authenticated;
grant execute on function private.f_unaccent(text) to anon, authenticated;
grant execute on function private.currency_for_country(public.country_code) to anon, authenticated;
grant execute on function private.is_active_user() to authenticated;
grant execute on function private.is_conversation_participant(uuid) to authenticated;
grant execute on function private.is_deal_participant(uuid) to authenticated;
