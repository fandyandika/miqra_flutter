# Supabase Setup Guide

This directory contains Supabase migrations for the Miqra app database schema.

## Prerequisites

1. **Install Supabase CLI**
   ```bash
   # Windows (via Scoop)
   scoop install supabase
   
   # Or download from:
   # https://github.com/supabase/cli/releases
   ```

2. **Verify Installation**
   ```bash
   supabase --version
   ```

## Setup Steps

### 1. Login to Supabase
```bash
supabase login
```
This will open your browser to authenticate.

### 2. Link Project to Supabase
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

**How to get PROJECT_REF:**
- Go to Supabase Dashboard → Your Project → Settings → General
- Copy the "Reference ID" (format: `xxxxxxxxxxxxxx`)

### 3. Push Migrations to Database
```bash
supabase db push
```

This will execute all migrations in `supabase/migrations/` that haven't been applied yet.

## Common Commands

### Create New Migration
```bash
supabase migration new add_feature_name
```
Creates a new migration file with timestamp: `YYYYMMDDHHMMSS_add_feature_name.sql`

### Check Migration Status
```bash
supabase migration list
```

### Generate Migration from Database Changes
```bash
supabase db diff -f migration_name
```
Compares your local database with remote and generates a migration file.

### Reset Database (⚠️ DANGER: Deletes all data)
```bash
supabase db reset
```

## Migration File Naming

**Format:** `YYYYMMDDHHMMSS_description.sql`

**Examples:**
- `20250111000000_initial_schema.sql`
- `20250115143000_add_leaderboard_table.sql`
- `20250120180000_add_notification_settings.sql`

**Important:**
- Timestamp determines execution order
- Use descriptive names
- Never modify existing migration files (create new ones instead)

## Current Schema

The initial migration (`20250111000000_initial_schema.sql`) creates:

1. **profiles** - User profile information
2. **streaks** - Reading streak tracking
3. **user_settings** - User preferences and settings
4. **checkins** - Daily reading check-ins

All tables have:
- Row Level Security (RLS) enabled
- Owner-only access policies
- Proper indexes for performance
- Auto-update triggers for `updated_at` fields

## Troubleshooting

### "Project not linked"
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### "Migration already applied"
- Check migration history: `supabase migration list`
- If needed, manually mark as applied in Supabase Dashboard

### "Permission denied"
- Ensure you're logged in: `supabase login`
- Check project access in Supabase Dashboard

## Best Practices

1. ✅ Always test migrations locally first
2. ✅ Use descriptive migration names
3. ✅ Never modify existing migration files
4. ✅ Commit migrations to version control
5. ✅ Review SQL before pushing to production
6. ✅ Use `if not exists` for idempotent migrations

## Resources

- [Supabase CLI Docs](https://supabase.com/docs/reference/cli)
- [Migration Guide](https://supabase.com/docs/guides/cli/local-development#database-migrations)

