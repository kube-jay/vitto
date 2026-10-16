-- Read markers are written with an upsert (INSERT … ON CONFLICT DO UPDATE),
-- which also needs UPDATE on every column in the payload. The RLS
-- WITH CHECK still limits rows to the caller's own conversations.
grant update (conversation_id, last_read_at) on public.conversation_reads to authenticated;
