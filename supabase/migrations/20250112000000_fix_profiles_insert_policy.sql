-- ============================================
-- Fix RLS Policy for Profiles INSERT
-- Migration: Fix Profiles Insert Policy
-- Created: 2025-01-12
-- ============================================
-- 
-- Problem: The existing policy "Own profile only" only has USING clause,
-- which doesn't allow INSERT operations during signup.
-- 
-- Solution: Add separate INSERT policy that allows users to create
-- their own profile with id = auth.uid()

-- Drop existing policy if exists
drop policy if exists "Own profile only" on profiles;

-- Policy for SELECT, UPDATE, DELETE (existing rows)
create policy "Users can view own profile" on profiles
  for select
  using (auth.uid() = id);

create policy "Users can update own profile" on profiles
  for update
  using (auth.uid() = id);

create policy "Users can delete own profile" on profiles
  for delete
  using (auth.uid() = id);

-- Policy for INSERT (new profile creation during signup)
create policy "Users can insert own profile" on profiles
  for insert
  with check (auth.uid() = id);

