-- ============================================
-- Final Fix: Ensure INSERT Policy Works
-- Migration: Final Fix Policies
-- Created: 2025-01-12
-- ============================================

-- Drop and recreate INSERT policy with explicit role
drop policy if exists "Users can insert own profile" on profiles;

-- Create INSERT policy that explicitly allows authenticated users
-- This ensures users can insert their own profile during signup
create policy "Users can insert own profile" on profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

-- Also ensure the trigger function has proper permissions
grant usage on schema public to authenticated;
grant usage on schema public to anon;

