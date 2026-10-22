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

-- ===== analytics, problem reports, admin (applied 2026-10-22 as migrations analytics_reports_admin + admin_stats_fix_daily_group) =====
-- admins: who may read analytics and reports (no policies: only security definer functions read it)
create table if not exists public.admins (uid uuid primary key);
alter table public.admins enable row level security;
-- insert into public.admins(uid) values ('<admin auth uid>');
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.admins where uid = auth.uid()) $$;
-- events: insert-only for players (anon or signed in), admins read
create table if not exists public.events (
  id bigint generated always as identity primary key, at timestamptz not null default now(), uid uuid default auth.uid(),
  dev text not null check (char_length(dev) between 1 and 40), sid text not null check (char_length(sid) between 1 and 40),
  name text not null check (char_length(name) between 1 and 40),
  props jsonb not null default '{}'::jsonb check (pg_column_size(props) <= 4000), ver text check (char_length(ver) <= 40));
create index if not exists events_at_idx on public.events (at);
create index if not exists events_name_at_idx on public.events (name, at);
alter table public.events enable row level security;
create policy events_insert on public.events for insert to anon, authenticated with check (uid is null or uid = (select auth.uid()));
create policy events_read on public.events for select to authenticated using ((select public.is_admin()));
-- reports: in-game problem reports, admins read and mark done
create table if not exists public.reports (
  id bigint generated always as identity primary key, at timestamptz not null default now(), uid uuid default auth.uid(),
  dev text check (char_length(dev) <= 40), kind text not null default 'bug' check (kind in ('bug','idea','other')),
  msg text not null check (char_length(msg) between 1 and 2000), contact text check (char_length(contact) <= 200),
  ctx jsonb not null default '{}'::jsonb check (pg_column_size(ctx) <= 8000), status text not null default 'open' check (status in ('open','done')));
create index if not exists reports_at_idx on public.reports (at);
alter table public.reports enable row level security;
create policy reports_insert on public.reports for insert to anon, authenticated with check (status = 'open' and (uid is null or uid = (select auth.uid())));
create policy reports_read on public.reports for select to authenticated using ((select public.is_admin()));
create policy reports_update on public.reports for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
-- admin_stats(days): dashboard aggregates in Taipei days; raises unless is_admin(). Full body: see the admin_stats_fix_daily_group migration
-- (daily devices/users/sessions/battles/wins/pulls/chests/upgrades/ad_filled/ad_unfilled/errors, totals, screens, modes, top errors).
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
