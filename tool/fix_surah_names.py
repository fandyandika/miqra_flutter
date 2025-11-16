import json

# Perbaikan yang perlu dilakukan
fixes = {
    # name_id fixes
    'name_id': {
        74: "Al-Muddassir",
        88: "Al-Ghasiyah",
        102: "At-Takasur",
        106: "Quraisy",
    },
    # name_id_translation fixes
    'name_id_translation': {
        1: "Pembuka",
        2: "Sapi",
        4: "Perempuan",
        33: "Golongan Yang Berserikat",
        74: "Orang Berselimut",
        88: "Hari Kiamat Yang Menutupi",
        102: "Berbangga-Bangga",
        106: "Orang-Orang Quraisy",
    }
}

# Load data dari file
with open('assets/data/derived/surah_meta_merge.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

surahs = data['surahs']
changes_made = []

print("Memperbaiki data surah...\n")

for surah in surahs:
    num = surah['surah']
    
    # Fix name_id
    if num in fixes['name_id']:
        old_value = surah.get('name_id', '')
        new_value = fixes['name_id'][num]
        if old_value != new_value:
            surah['name_id'] = new_value
            changes_made.append(f"Surah {num}: name_id '{old_value}' → '{new_value}'")
    
    # Fix name_id_translation
    if num in fixes['name_id_translation']:
        old_value = surah.get('name_id_translation', '')
        new_value = fixes['name_id_translation'][num]
        if old_value != new_value:
            surah['name_id_translation'] = new_value
            changes_made.append(f"Surah {num}: name_id_translation '{old_value}' → '{new_value}'")

# Save kembali ke file
with open('assets/data/derived/surah_meta_merge.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Total perubahan: {len(changes_made)}")
for change in changes_made:
    print(f"  ✓ {change}")
print("\n✅ File berhasil diperbarui!")

