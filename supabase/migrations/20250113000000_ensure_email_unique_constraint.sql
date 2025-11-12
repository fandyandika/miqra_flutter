-- ============================================
-- Ensure Email Unique Constraint (Case-Insensitive)
-- Migration: Ensure Email Unique Constraint
-- Created: 2025-01-13
-- ============================================
-- 
-- This migration ensures that email addresses are unique in the profiles table,
-- regardless of case (e.g., "Test@example.com" and "test@example.com" are treated as the same).
-- 
-- Best Practice: Database-level constraints are the ultimate authority for data integrity.
-- Application-level checks are good for UX, but database constraints prevent data corruption.

-- Step 1: Verify existing unique constraint exists
-- The initial schema already has: email text unique not null
-- But PostgreSQL unique constraints are case-sensitive by default.
-- We need a case-insensitive unique index.

-- Drop existing unique constraint if it exists (we'll replace with case-insensitive index)
-- Note: We can't drop the constraint directly if it's part of the column definition,
-- so we'll create a case-insensitive unique index instead

-- Create case-insensitive unique index for email
-- This ensures "Test@example.com" and "test@example.com" are treated as duplicates
create unique index if not exists profiles_email_unique_lower 
  on profiles (lower(trim(email)));

-- Step 2: Add check constraint to ensure email is not empty after trim
alter table profiles 
  add constraint profiles_email_not_empty 
  check (trim(email) != '');

-- Step 3: Update trigger function to check for duplicate email before insert
-- This provides an additional safety layer
create or replace function public.handle_new_user()
returns trigger as $$
declare
  email_lower text;
begin
  -- Normalize email (lowercase and trim)
  email_lower := lower(trim(new.email));
  
  -- Check if email already exists in profiles (case-insensitive)
  if exists (
    select 1 from public.profiles 
    where lower(trim(email)) = email_lower
  ) then
    raise exception 'Email % is already registered', new.email;
  end if;

  -- Insert into profiles
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );

  -- Insert into user_settings with defaults
  insert into public.user_settings (user_id)
  values (new.id);

  -- Insert into streaks with defaults
  insert into public.streaks (user_id)
  values (new.id);

  return new;
end;
$$ language plpgsql security definer;

-- Step 4: Ensure trigger exists
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================
-- Verification Queries (Run these to verify)
-- ============================================
-- 
-- Check if unique index exists:
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'profiles' AND indexname = 'profiles_email_unique_lower';

-- Check constraint:
SELECT conname, contype 
FROM pg_constraint 
WHERE conrelid = 'profiles'::regclass AND conname = 'profiles_email_not_empty';

-- ============================================
-- TEST QUERIES (Use existing user IDs)
-- ============================================
-- 
-- IMPORTANT: profiles.id is a foreign key to auth.users.id
-- So we can only test with existing user IDs or use the actual signup flow
--
-- Option 1: Test with UPDATE (using existing user)
-- First, get a real user ID:
-- SELECT id, email FROM auth.users LIMIT 1;
--
-- Then test duplicate email (this should fail):
-- UPDATE profiles 
-- SET email = 'test@example.com' 
-- WHERE id = (SELECT id FROM auth.users LIMIT 1);
--
-- UPDATE profiles 
-- SET email = 'TEST@EXAMPLE.COM' 
-- WHERE id = (SELECT id FROM auth.users LIMIT 1); 
-- -- Should fail: duplicate key value violates unique constraint
--
-- Option 2: Test via actual signup flow in Flutter app (RECOMMENDED)
-- 1. Signup with email: test@example.com
-- 2. Try to signup again with: TEST@EXAMPLE.COM
-- 3. Should fail with error: "Email is already registered"

