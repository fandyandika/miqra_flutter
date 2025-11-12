# Email Unique Constraint - Database Level Protection

## Masalah
User bisa signup dengan email yang sama (case berbeda), misalnya:
- `Test@example.com`
- `test@example.com`
- `TEST@EXAMPLE.COM`

Ini dianggap sebagai email berbeda oleh PostgreSQL default unique constraint (case-sensitive).

## Solusi: Database-Level Constraints

### Best Practice Expert Database:
1. **Database constraints adalah ultimate authority** - tidak bisa di-bypass
2. **Application-level checks** - untuk UX yang lebih baik (error message cepat)
3. **Case-insensitive unique index** - untuk email addresses
4. **Trigger function validation** - additional safety layer

## Yang Sudah Diterapkan

### 1. ✅ Case-Insensitive Unique Index
```sql
create unique index profiles_email_unique_lower 
  on profiles (lower(trim(email)));
```
- Memastikan email unique regardless of case
- `Test@example.com` dan `test@example.com` dianggap sama

### 2. ✅ Email Not Empty Constraint
```sql
alter table profiles 
  add constraint profiles_email_not_empty 
  check (trim(email) != '');
```
- Memastikan email tidak kosong setelah trim

### 3. ✅ Trigger Function Validation
- Check duplicate email SEBELUM insert
- Raise exception jika email sudah ada
- Case-insensitive comparison

### 4. ✅ Application-Level Check
- Check email exists di `AuthRepository.signUp()` SEBELUM signup
- Memberikan error message yang user-friendly
- Tidak redirect ke verify screen jika duplicate

## Cara Kerja (Multi-Layer Protection)

### Layer 1: Application Check (UX)
```
User input email → Check di profiles table → Error jika exists
```
- **Keuntungan**: Error message cepat, user-friendly
- **Kekurangan**: Bisa di-bypass jika ada bug di code

### Layer 2: Database Unique Index (Data Integrity)
```
INSERT INTO profiles → PostgreSQL check unique index → Error jika duplicate
```
- **Keuntungan**: Tidak bisa di-bypass, ultimate protection
- **Kekurangan**: Error message kurang user-friendly (database error)

### Layer 3: Trigger Function (Additional Safety)
```
INSERT INTO auth.users → Trigger check email → Raise exception jika duplicate
```
- **Keuntungan**: Catch duplicate SEBELUM insert ke profiles
- **Kekurangan**: Error message dari database

## Test

### ⚠️ Important: profiles.id is Foreign Key
`profiles.id` is a foreign key to `auth.users.id`, so we cannot insert directly with random UUIDs.

### Test 1: Via UPDATE (Using Existing User)
```sql
-- Get a real user ID first
SELECT id, email FROM auth.users LIMIT 1;

-- Test duplicate email (should fail)
UPDATE profiles 
SET email = 'test@example.com' 
WHERE id = 'YOUR_USER_ID_HERE';

-- Try to update to same email with different case (should fail)
UPDATE profiles 
SET email = 'TEST@EXAMPLE.COM' 
WHERE id = 'YOUR_USER_ID_HERE';
-- Error: duplicate key value violates unique constraint "profiles_email_unique_lower"
```

### Test 2: Via Application Signup (RECOMMENDED)
1. Signup dengan `test@example.com` → Success
2. Signup dengan `TEST@EXAMPLE.COM` → Should fail with error message: "This email is already registered. Please sign in instead."

## Migration File

File: `supabase/migrations/20250113000000_ensure_email_unique_constraint.sql`

**Cara Apply:**
1. Via Supabase CLI: `supabase db push`
2. Via SQL Editor: Copy-paste SQL dari file migration

## Verification

### Check Unique Index Exists
```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'profiles' 
  AND indexname = 'profiles_email_unique_lower';
```

### Check Constraint Exists
```sql
SELECT conname, contype 
FROM pg_constraint 
WHERE conrelid = 'profiles'::regclass 
  AND conname = 'profiles_email_not_empty';
```

## Catatan Penting

1. **Database constraints tidak bisa di-bypass** - ini adalah ultimate protection
2. **Application checks untuk UX** - memberikan error message yang lebih baik
3. **Case-insensitive untuk email** - best practice untuk email addresses
4. **Multi-layer protection** - defense in depth strategy

## Troubleshooting

### Jika masih bisa signup dengan email duplicate:
1. Pastikan migration sudah di-apply
2. Check unique index exists: `SELECT * FROM pg_indexes WHERE tablename = 'profiles';`
3. Check trigger function: `SELECT * FROM pg_proc WHERE proname = 'handle_new_user';`
4. Test langsung di SQL Editor dengan INSERT statement

