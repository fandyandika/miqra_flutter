# Supabase Helper Scripts

This folder contains SQL scripts that are helper files for manual application via Supabase SQL Editor.

## ⚠️ Important

These scripts are **NOT** migrations. They are helper files for:
- Quick fixes that need to be applied manually
- Verification queries
- One-time setup scripts

## Official Migrations

Official database migrations are in `supabase/migrations/` and should be applied via:
```bash
supabase db push
```

## Files in this folder

- `APPLY_EMAIL_UNIQUE_CONSTRAINT.sql` - Apply email unique constraint (case-insensitive)
- `APPLY_THIS_SQL.sql` - Quick fix for RLS policies
- `COPY_PASTE_THIS.sql` - Comprehensive RLS and trigger fixes
- `QUICK_VERIFY.sql` - Quick verification queries
- `VERIFY_FIX.sql` - Detailed verification queries

## Usage

1. Copy the SQL from the file
2. Paste into Supabase Dashboard → SQL Editor
3. Run the query
4. Verify the changes

## Note

These files are gitignored by default. If you need to commit them, remove from `.gitignore`.

