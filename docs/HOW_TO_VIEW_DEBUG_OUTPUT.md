# Cara Melihat Debug Output di Flutter/Cursor

## Di Terminal Cursor

1. **Buka terminal di Cursor** (biasanya di bawah editor)
2. **Jalankan app:**
   ```bash
   flutter run
   ```
3. **Debug output akan muncul di terminal** - cari baris yang dimulai dengan:
   - `=== SIGNUP ATTEMPT ===`
   - `Response.user: ...`
   - `=== AuthException CAUGHT ===`
   - `Is duplicate: ...`

## Di VS Code / Cursor Debug Console

1. **Buka Debug Console** (View → Debug Console atau `Ctrl+Shift+Y`)
2. **Atau buka Output panel** (View → Output)
3. **Pilih "Debug Console"** dari dropdown di Output panel

## Di Flutter DevTools

1. **Buka Flutter DevTools** (biasanya link muncul di terminal setelah `flutter run`)
2. **Atau buka manual:** `http://localhost:9100`
3. **Pergi ke tab "Logging"** untuk melihat semua debug output

## Tips

- **Filter output:** Di terminal, tekan `Ctrl+F` untuk search keyword seperti "SIGNUP" atau "AuthException"
- **Clear terminal:** Tekan `Ctrl+L` untuk clear terminal
- **Hot restart:** Tekan `R` di terminal untuk restart app tanpa kehilangan debug output

