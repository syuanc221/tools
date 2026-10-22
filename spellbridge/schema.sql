-- 秘法雙橋 SPELLBRIDGE: run once in Supabase → SQL Editor
create table if not exists public.docs(
  path text primary key,
  coll text not null,
  id text not null,
  owner uuid not null default auth.uid(),
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create index if not exists docs_coll_idx on public.docs(coll);
alter table public.docs enable row level security;
alter table public.docs replica identity full;

-- everyone may read players, guilds and guild chat; private saves only by their owner
drop policy if exists docs_read on public.docs;
create policy docs_read on public.docs for select
  using (coll in ('players','guilds','chat') or owner = auth.uid());

-- each signed-in player writes only their own documents
drop policy if exists docs_insert on public.docs;
create policy docs_insert on public.docs for insert to authenticated
  with check (owner = auth.uid() and (
    path in ('players/'||auth.uid(), 'guilds/'||auth.uid(), 'chat/'||auth.uid())
    or path like 'data/users/'||auth.uid()||'/%'));
drop policy if exists docs_update on public.docs;
create policy docs_update on public.docs for update to authenticated
  using (owner = auth.uid())
  with check (owner = auth.uid() and (
    path in ('players/'||auth.uid(), 'guilds/'||auth.uid(), 'chat/'||auth.uid())
    or path like 'data/users/'||auth.uid()||'/%'));
drop policy if exists docs_delete on public.docs;
create policy docs_delete on public.docs for delete to authenticated
  using (owner = auth.uid());

-- live updates for guild lists, rankings and chat
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;
