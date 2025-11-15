-- #5A: Reading Sessions Table and RPC Function Setup
-- Execute this in Supabase SQL Editor

-- 1) Create reading_sessions table
create table if not exists public.reading_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  surah_number smallint not null,
  ayah_start smallint not null,
  ayah_end smallint not null,
  letters_count integer not null,
  hasanat integer not null,
  reading_mode text not null check (reading_mode in ('surah','focus')),
  created_at timestamptz not null default now(),
  notes text
);

create index if not exists idx_reading_sessions_user_created
  on public.reading_sessions (user_id, created_at desc);

create index if not exists idx_reading_sessions_user_surah
  on public.reading_sessions (user_id, surah_number);

-- 2) Create RPC function log_reading_session
-- Note: References ayah_letter_counts table (created in STEP 0)
create or replace function public.log_reading_session(
  p_surah smallint,
  p_ayah_start smallint,
  p_ayah_end smallint,
  p_mode text default 'surah'
) returns public.reading_sessions
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_letters integer;
  v_session public.reading_sessions;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Calculate total letters from ayah_letter_counts table
  select coalesce(sum(letters_count), 0)
  into v_letters
  from public.ayah_letter_counts
  where surah_number = p_surah
    and ayah_number between p_ayah_start and p_ayah_end;

  if v_letters <= 0 then
    raise exception 'No letter_count data for surah %, ayat %-%', p_surah, p_ayah_start, p_ayah_end;
  end if;

  -- Insert session record
  insert into public.reading_sessions (
    user_id,
    surah_number,
    ayah_start,
    ayah_end,
    letters_count,
    hasanat,
    reading_mode
  ) values (
    v_user_id,
    p_surah,
    p_ayah_start,
    p_ayah_end,
    v_letters,
    v_letters * 10,  -- hasanat = letters_count * 10
    p_mode
  )
  returning * into v_session;

  return v_session;
end;
$$;

-- 3) Row Level Security policies
alter table public.reading_sessions enable row level security;

create policy "Users can view own sessions"
  on public.reading_sessions
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own sessions"
  on public.reading_sessions
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own sessions"
  on public.reading_sessions
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

