-- ============================================
-- Fix RLS Policies for Streaks and User Settings INSERT
-- Migration: Fix Streaks and Settings Insert Policies
-- Created: 2025-01-12
-- ============================================
-- 
-- Ensure INSERT policies exist for streaks and user_settings tables

-- Drop existing policies if they exist
drop policy if exists "Own streak only" on streaks;
drop policy if exists "Own settings only" on user_settings;

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

