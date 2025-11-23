# Production Setup Guide

## 🔒 Security Status

✅ **Development setup is secure:**
- `.env.dev` (root) - gitignored, contains real credentials
- `.env` (root) - gitignored, contains real credentials (bundled with app)
- `.env.example` - safe to commit (template only)

## 🚀 Production Build

### ⚠️ Important: Do NOT bundle credentials in production!

For production builds, you should **NOT** include `.env` with real credentials. Instead, use `--dart-define` flags.

### Option 1: Build with --dart-define (Recommended)

```bash
# Android
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_production_url \
  --dart-define=SUPABASE_ANON_KEY=your_production_key \
  --dart-define=SENTRY_DSN=your_production_sentry_dsn

# iOS
flutter build ios --release \
  --dart-define=SUPABASE_URL=your_production_url \
  --dart-define=SUPABASE_ANON_KEY=your_production_key \
  --dart-define=SENTRY_DSN=your_production_sentry_dsn
```

### Option 2: Use CI/CD Secrets

If using CI/CD (GitHub Actions, GitLab CI, etc.), inject secrets as environment variables:

```yaml
# Example GitHub Actions
- name: Build APK
  run: |
    flutter build apk --release \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
      --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
```

### Option 3: Remove .env before production build

If you must use .env approach, ensure it's removed before production build:

```bash
# Remove .env before building
rm .env

# Build (will use --dart-define if provided, or fail safely)
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## 📋 Priority Order

The app uses this priority order (see `lib/core/env/env.dart`):

1. **`--dart-define`** (highest priority - for production)
2. **`.env` (root)** (fallback - for development)

## ✅ Pre-Production Checklist

- [ ] Remove or empty `.env` before production build
- [ ] Use `--dart-define` flags in production build command
- [ ] Verify credentials are NOT in the built APK/IPA
- [ ] Test production build locally before deploying
- [ ] Set up CI/CD secrets if using automated builds
- [ ] Use different Supabase project for production (recommended)

## 🔍 Verify Credentials Not in Build

To verify credentials are not bundled:

```bash
# Android - check APK contents
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -i "\.env"

# Should return nothing (no .env files in APK)
```

## 📝 Notes

- **Development**: `.env` in project root is fine (gitignored)
- **Production**: Use `--dart-define` (secure, not bundled)
- **CI/CD**: Use secrets management (most secure)

## 🆘 Troubleshooting

If app fails to start in production:
1. Check if `--dart-define` flags are correctly passed
2. Verify credentials format (no quotes needed)
3. Check app logs for "Supabase credentials missing" error

