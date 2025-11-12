-- ============================================
-- Add Trigger to Auto-Create Profile on Signup
-- Migration: Add Profile Auto-Creation Trigger
-- Created: 2025-01-12
-- ============================================
-- 
-- This trigger automatically creates a profile, user_settings, and streaks
-- when a new user signs up in auth.users
-- This is more reliable than client-side insertion

-- Function to handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
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

-- Create trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

