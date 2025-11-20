-- Patch existing reading_sessions table to align with latest schema
-- Run this in Supabase SQL Editor if you created the table before 2025-02-19

-- 1) Ensure updated_at column exists
alter table public.reading_sessions
  add column if not exists updated_at timestamptz not null default now();

-- 2) Ensure reading_mode supports manual entries
alter table public.reading_sessions
  drop constraint if exists reading_sessions_reading_mode_check;

alter table public.reading_sessions
  add constraint reading_sessions_reading_mode_check
  check (reading_mode in ('surah', 'focus', 'manual'));

-- 3) Upsert helper to keep updated_at fresh
create or replace function public.set_reading_sessions_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_reading_sessions_updated_at on public.reading_sessions;
create trigger trg_reading_sessions_updated_at
  before update on public.reading_sessions
  for each row
  execute function public.set_reading_sessions_updated_at();


