-- Manual Log Support: Update reading_sessions table and RPC function
-- Execute this in Supabase SQL Editor

-- Step 1: Update reading_mode check constraint to include 'manual'
alter table public.reading_sessions
  drop constraint if exists reading_sessions_reading_mode_check;

alter table public.reading_sessions
  add constraint reading_sessions_reading_mode_check
  check (reading_mode in ('surah', 'focus', 'manual'));

-- Step 2: Verify RPC function supports all modes (no changes needed)
-- The existing log_reading_session function already accepts p_mode as text
-- and passes it to reading_mode column, so it will work with 'manual' mode

-- Verification query (optional - run to verify):
-- select constraint_name, check_clause 
-- from information_schema.check_constraints 
-- where constraint_name = 'reading_sessions_reading_mode_check';

