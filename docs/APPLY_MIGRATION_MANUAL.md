# Apply Migration Manually (Jika `supabase db push` Stuck)

Jika `supabase db push` stuck di "Initialising login role...", gunakan cara manual ini:

## Cara 1: Via Supabase Dashboard SQL Editor

1. Buka Supabase Dashboard: https://supabase.com/dashboard
2. Pilih project Anda
3. Pergi ke **SQL Editor**
4. Copy-paste SQL berikut dan klik **Run**:

```sql
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
```

5. Pastikan query berhasil (harus ada pesan "Success")

## Cara 2: Re-login Supabase CLI

Jika ingin tetap pakai CLI, coba re-login:

```bash
supabase logout
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push --yes
```

## Verifikasi

Setelah apply migration, test sign up lagi. Error RLS seharusnya sudah hilang.

