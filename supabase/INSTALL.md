# Supabase CLI Installation Guide

## Windows Installation

### Option 1: Using Scoop (Recommended)

1. **Install Scoop** (if not already installed):
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   iwr -useb get.scoop.sh | iex
   ```

2. **Install Supabase CLI**:
   ```powershell
   scoop install supabase
   ```

3. **Verify Installation**:
   ```powershell
   supabase --version
   ```

### Option 2: Manual Download

1. **Download Binary**:
   - Go to: https://github.com/supabase/cli/releases
   - Download: `supabase_windows_amd64.zip` (or appropriate for your system)

2. **Extract and Add to PATH**:
   - Extract the zip file
   - Copy `supabase.exe` to a folder (e.g., `C:\tools\supabase\`)
   - Add folder to PATH:
     - Open System Properties → Environment Variables
     - Edit "Path" variable
     - Add: `C:\tools\supabase\`
     - Click OK

3. **Verify Installation**:
   ```powershell
   supabase --version
   ```

### Option 3: Using Chocolatey

```powershell
choco install supabase
```

## Next Steps

After installation, follow the setup guide in `README.md`:

1. Login: `supabase login`
2. Link project: `supabase link --project-ref YOUR_PROJECT_REF`
3. Push migrations: `supabase db push`

## Troubleshooting

### "supabase: command not found"
- Ensure Supabase CLI is in your PATH
- Restart terminal after adding to PATH
- Verify with: `where supabase` (Windows)

### "Permission denied"
- Run PowerShell as Administrator (if needed)
- Check PATH environment variable

## Resources

- [Supabase CLI GitHub](https://github.com/supabase/cli)
- [Official Installation Guide](https://supabase.com/docs/reference/cli/installing-and-updating)

