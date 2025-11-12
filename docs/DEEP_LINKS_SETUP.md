# Deep Links Setup untuk Supabase Auth

## Masalah
Ketika user klik link verifikasi email atau reset password dari Supabase, mereka diarahkan ke `localhost` yang tidak bekerja di mobile app.

## Solusi
Setup **Deep Links** (Custom URL Scheme) agar link dari email membuka app langsung.

## Yang Sudah Dikonfigurasi

### 1. ✅ Android Deep Links
File: `android/app/src/main/AndroidManifest.xml`
- Added intent filter dengan scheme: `miqra://auth`

### 2. ✅ iOS Deep Links  
File: `ios/Runner/Info.plist`
- Added `CFBundleURLTypes` dengan scheme: `miqra`

### 3. ✅ Auth Methods Configuration
File: `lib/features/auth/data/repositories/auth_repository.dart`
- Added `emailRedirectTo: 'miqra://auth'` di `signUp()`
- Added `redirectTo: 'miqra://auth'` di `resetPassword()`
- Added `emailRedirectTo: 'miqra://auth'` di `resendVerificationEmail()`

## Konfigurasi di Supabase Dashboard

**PENTING:** Anda perlu menambahkan redirect URL di Supabase Dashboard:

1. Buka Supabase Dashboard: https://supabase.com/dashboard/project/nvywodsukylrpfbcavhv
2. Pergi ke **Authentication** → **URL Configuration**
3. Di bagian **Redirect URLs**, tambahkan:
   ```
   miqra://auth
   ```
4. Klik **Save**

## Cara Kerja

1. User klik link di email (verification atau reset password)
2. Supabase redirect ke `miqra://auth` (bukan localhost)
3. Mobile OS detect custom scheme `miqra://`
4. App terbuka dan Supabase Flutter SDK otomatis handle deep link
5. Supabase SDK otomatis update auth state (session, user, dll)
6. App detect auth state change via `authStateProvider`
7. User otomatis di-redirect ke screen yang sesuai:
   - Jika email verified → redirect ke home (`/`)
   - Jika email belum verified → redirect ke verify screen (`/verify-email`)

**Catatan:** Supabase Flutter SDK akan otomatis handle semua ini. Tidak perlu manual parsing deep link URL.

## Test Deep Links

### Android
```bash
adb shell am start -a android.intent.action.VIEW -d "miqra://auth"
```

### iOS Simulator
```bash
xcrun simctl openurl booted "miqra://auth"
```

## Catatan

- Deep link scheme: `miqra://auth`
- Supabase akan otomatis append query parameters (token, type, dll)
- App akan handle auth state change secara otomatis
- Tidak perlu manual parsing deep link URL

## Troubleshooting

Jika deep link tidak bekerja:
1. Pastikan redirect URL sudah ditambahkan di Supabase Dashboard
2. Hot restart app (bukan hot reload)
3. Test dengan command di atas
4. Cek logs untuk melihat apakah deep link diterima

