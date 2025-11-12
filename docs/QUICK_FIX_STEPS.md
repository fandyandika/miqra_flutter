# 🚀 Quick Fix Steps - Apply SQL Migration

## Step 1: Buka Supabase Dashboard
1. Buka: https://supabase.com/dashboard/project/nvywodsukylrpfbcavhv
2. Login jika diperlukan

## Step 2: Buka SQL Editor
1. Klik menu **SQL Editor** di sidebar kiri
2. Klik tombol **New Query**

## Step 3: Copy & Paste SQL
Copy SQL berikut dan paste di SQL Editor:

```sql
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

## Step 4: Run SQL
1. Klik tombol **Run** (atau tekan Ctrl+Enter)
2. Pastikan muncul pesan **Success** (bukan error)

## Step 5: Verify (Optional)
1. Pergi ke **Database** → **Tables** → `profiles`
2. Klik tab **Policies**
3. Pastikan ada policy: **"Users can insert own profile"**

## Step 6: Test Sign Up
1. Hot restart Flutter app (tekan `R` di terminal)
2. Coba sign up dengan email baru
3. Seharusnya berhasil tanpa error RLS! ✅

---

**Note:** File `APPLY_THIS_SQL.sql` di root project berisi SQL yang sama.

