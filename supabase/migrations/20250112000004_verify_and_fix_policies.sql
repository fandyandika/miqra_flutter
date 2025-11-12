-- ============================================
-- Verify and Fix RLS Policies
-- Migration: Verify and Fix Policies
-- Created: 2025-01-12
-- ============================================
-- 
-- Ensure all policies are correctly set up

-- Drop ALL existing policies and recreate them cleanly
drop policy if exists "Own profile only" on profiles;
drop policy if exists "Users can view own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;
drop policy if exists "Users can delete own profile" on profiles;
drop policy if exists "Users can insert own profile" on profiles;

drop policy if exists "Own streak only" on streaks;
drop policy if exists "Users can view own streak" on streaks;
drop policy if exists "Users can insert own streak" on streaks;
drop policy if exists "Users can update own streak" on streaks;
drop policy if exists "Users can delete own streak" on streaks;

drop policy if exists "Own settings only" on user_settings;
drop policy if exists "Users can view own settings" on user_settings;
drop policy if exists "Users can insert own settings" on user_settings;
drop policy if exists "Users can update own settings" on user_settings;
drop policy if exists "Users can delete own settings" on user_settings;

-- Profiles policies
create policy "Users can view own profile" on profiles
  for select
  using (auth.uid() = id);

create policy "Users can insert own profile" on profiles
  for insert
  with check (auth.uid() = id);

create policy "Users can update own profile" on profiles
  for update
  using (auth.uid() = id);

create policy "Users can delete own profile" on profiles
  for delete
  using (auth.uid() = id);

-- Streaks policies
create policy "Users can view own streak" on streaks
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own streak" on streaks
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own streak" on streaks
  for update
  using (auth.uid() = user_id);

create policy "Users can delete own streak" on streaks
  for delete
  using (auth.uid() = user_id);

-- User Settings policies
create policy "Users can view own settings" on user_settings
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own settings" on user_settings
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own settings" on user_settings
  for update
  using (auth.uid() = user_id);

create policy "Users can delete own settings" on user_settings
  for delete
  using (auth.uid() = user_id);

