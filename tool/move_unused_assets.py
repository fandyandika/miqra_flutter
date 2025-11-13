#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Move unused assets to _unused/ folder.
Keep audio/ folder as it will be used later.
"""

import sys
import shutil
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
UNUSED = ASSETS / "_unused"

# Files/folders to move (relative to assets/data)
TO_MOVE = [
    # Unused (duplicate dari SQL)
    "translation/",
    "transliteration/",
    
    # Tafsir (belum ada fitur)
    "tafsir/",
    
    # Deprecated tajwid
    "quran/tajweedcpfair/",
    "quran/miqra_tajwid.db",
    
    # Tool/development only
    "quran/quran-tajweed-master/",
    "quran/quran-uthmani.xml",
    "quran/indopak/",
    "quran/cpfair/",
    
    # Metadata sources (already merged)
    "metadata/daftar-surat.json",
    "metadata/juz.json",
    "metadata/page_map.json",
    "metadata/surah_meta_final.json",
    "metadata/surah.json",
]

# Keep these (will be used later)
KEEP = [
    "audio/",  # Will be used for audio feature
]

def move_item(src_path: Path, dest_path: Path):
    """Move file or directory to destination."""
    if not src_path.exists():
        print(f"⚠️  SKIP: {src_path} tidak ditemukan")
        return False
    
    try:
        # Create parent directory if needed
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Move
        shutil.move(str(src_path), str(dest_path))
        print(f"✅ MOVED: {src_path.relative_to(ASSETS)} → _unused/{src_path.relative_to(ASSETS)}")
        return True
    except Exception as e:
        print(f"❌ ERROR: Gagal pindah {src_path}: {e}")
        return False

def main():
    print("=" * 70)
    print("MEMINDAHKAN UNUSED ASSETS KE _unused/")
    print("=" * 70)
    print()
    
    # Create _unused directory
    UNUSED.mkdir(parents=True, exist_ok=True)
    print(f"📁 Created: {UNUSED}")
    print()
    
    moved_count = 0
    skipped_count = 0
    
    for item in TO_MOVE:
        src = ASSETS / item
        dest = UNUSED / item
        
        if move_item(src, dest):
            moved_count += 1
        else:
            skipped_count += 1
    
    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"✅ Moved: {moved_count} items")
    print(f"⚠️  Skipped: {skipped_count} items")
    print()
    print("📁 Unused assets location: assets/data/_unused/")
    print()
    print("✅ KEPT (will be used later):")
    for item in KEEP:
        keep_path = ASSETS / item
        if keep_path.exists():
            print(f"   - {item}")
    print()
    print("=" * 70)
    print("SELESAI!")
    print("=" * 70)
    print()
    print("Catatan:")
    print("- File-file sudah dipindah ke assets/data/_unused/")
    print("- Audio/ tetap di assets/data/audio/ (akan digunakan nanti)")
    print("- Jika yakin tidak diperlukan, bisa hapus folder _unused/")
    print("=" * 70)

if __name__ == "__main__":
    main()

