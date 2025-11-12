# Sign Up Fix - Checklist

## ✅ Yang Sudah Dilakukan

1. ✅ **RLS Policies Fixed** - Policy INSERT sudah dibuat dengan role `authenticated`
2. ✅ **Database Trigger Created** - Auto-create profile saat signup
3. ✅ **Code Updated** - Auth repository dengan retry logic dan fallback

## 📋 Langkah Selanjutnya

### 1. Apply SQL Migration (Jika Belum)

**Via Supabase Dashboard:**
1. Buka: https://supabase.com/dashboard/project/nvywodsukylrpfbcavhv
2. Pergi ke **SQL Editor**
3. Copy-paste SQL dari `APPLY_THIS_SQL.sql` atau `supabase/migrations/20250112000005_final_fix_policies.sql`
4. Klik **Run**

**Atau via CLI (jika tidak stuck):**
```bash
supabase db push --yes
```

### 2. Verify Trigger Exists

Di Supabase Dashboard:
1. Pergi ke **Database** → **Triggers**
2. Pastikan ada trigger: `on_auth_user_created` pada table `auth.users`

### 3. Verify Policies

Di Supabase Dashboard:
1. Pergi ke **Database** → **Tables** → `profiles`
2. Klik **Policies**
3. Pastikan ada policy: **"Users can insert own profile"** dengan:
   - Operation: INSERT
   - Target roles: authenticated
   - WITH CHECK: `(auth.uid() = id)`

### 4. Test Sign Up

1. **Hot restart app** (bukan hot reload)
   ```bash
   # Di terminal Flutter, tekan 'R' untuk hot restart
   # Atau stop dan run lagi: flutter run
   ```

2. **Coba sign up dengan email baru** (belum pernah digunakan)
   - Full Name: Test User
   - Email: test@example.com (atau email baru)
   - Password: (minimal 6 karakter)

3. **Expected Result:**
   - ✅ Sign up berhasil
   - ✅ Tidak ada error RLS
   - ✅ User bisa login setelah sign up

### 5. Jika Masih Error

**Check:**
- Apakah SQL migration sudah di-run?
- Apakah trigger sudah ada?
- Apakah policy sudah benar?
- Apakah menggunakan email baru (belum pernah sign up)?

**Debug:**
- Cek error message lengkap
- Cek Supabase Dashboard → Logs untuk melihat error detail
- Cek apakah profile ter-create di table `profiles`

## 🎯 Expected Flow

1. User klik "Sign Up"
2. `auth.signUp()` dipanggil → User dibuat di `auth.users`
3. **Trigger** `on_auth_user_created` jalan → Auto-create profile, settings, streaks
4. Code menunggu 500ms → Verify profile exists
5. Jika profile exists → Success ✅
6. Jika profile tidak exists → Fallback manual insert

## 📝 Notes

- Trigger adalah primary method (lebih reliable)
- Manual insert adalah fallback (jika trigger gagal)
- Code sudah handle race condition dengan retry logic

