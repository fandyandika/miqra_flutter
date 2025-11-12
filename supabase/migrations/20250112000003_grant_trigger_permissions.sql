-- ============================================
-- Grant Permissions for Trigger Function
-- Migration: Grant Trigger Permissions
-- Created: 2025-01-12
-- ============================================
-- 
-- Ensure the trigger function has proper permissions

-- Grant execute permission on the function
grant execute on function public.handle_new_user() to authenticated;
grant execute on function public.handle_new_user() to anon;

-- Ensure function owner has proper permissions
alter function public.handle_new_user() owner to postgres;

