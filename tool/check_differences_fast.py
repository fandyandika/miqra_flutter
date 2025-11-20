import json
import os
import sys

# Data yang diharapkan
expected_data = [
  {"name_id": "Al-Fatihah", "name_id_translation": "Pembuka"},
  {"name_id": "Al-Baqarah", "name_id_translation": "Sapi"},
  {"name_id": "Ali 'Imran", "name_id_translation": "Keluarga Imran"},
  {"name_id": "An-Nisa'", "name_id_translation": "Perempuan"},
  {"name_id": "Al-Ma'idah", "name_id_translation": "Hidangan"},
  {"name_id": "Al-An'am", "name_id_translation": "Binatang Ternak"},
  {"name_id": "Al-A'raf", "name_id_translation": "Tempat Tertinggi"},
  {"name_id": "Al-Anfal", "name_id_translation": "Rampasan Perang"},
  {"name_id": "At-Tawbah", "name_id_translation": "Pengampunan"},
  {"name_id": "Yunus", "name_id_translation": "Yunus"},
  {"name_id": "Hud", "name_id_translation": "Hud"},
  {"name_id": "Yusuf", "name_id_translation": "Yusuf"},
  {"name_id": "Ar-Ra'd", "name_id_translation": "Guruh"},
  {"name_id": "Ibrahim", "name_id_translation": "Ibrahim"},
  {"name_id": "Al-Hijr", "name_id_translation": "Hijr"},
  {"name_id": "An-Nahl", "name_id_translation": "Lebah"},
  {"name_id": "Al-Isra'", "name_id_translation": "Memperjalankan di Malam Hari"},
  {"name_id": "Al-Kahf", "name_id_translation": "Gua"},
  {"name_id": "Maryam", "name_id_translation": "Maryam"},
  {"name_id": "Taha", "name_id_translation": "Taha"},
  {"name_id": "Al-Anbiya'", "name_id_translation": "Para Nabi"},
  {"name_id": "Al-Hajj", "name_id_translation": "Haji"},
  {"name_id": "Al-Mu'minun", "name_id_translation": "Orang-Orang Mukmin"},
  {"name_id": "An-Nur", "name_id_translation": "Cahaya"},
  {"name_id": "Al-Furqan", "name_id_translation": "Pembeda"},
  {"name_id": "Asy-Syu'ara'", "name_id_translation": "Para Penyair"},
  {"name_id": "An-Naml", "name_id_translation": "Semut"},
  {"name_id": "Al-Qasas", "name_id_translation": "Kisah-Kisah"},
  {"name_id": "Al-Ankabut", "name_id_translation": "Laba-Laba"},
  {"name_id": "Ar-Rum", "name_id_translation": "Romawi"},
  {"name_id": "Luqman", "name_id_translation": "Luqman"},
  {"name_id": "As-Sajdah", "name_id_translation": "Sajdah"},
  {"name_id": "Al-Ahzab", "name_id_translation": "Golongan Yang Berserikat"},
  {"name_id": "Saba'", "name_id_translation": "Saba'"},
  {"name_id": "Fatir", "name_id_translation": "Pencipta"},
  {"name_id": "Yasin", "name_id_translation": "Yasin"},
  {"name_id": "As-Saffat", "name_id_translation": "Barisan-Barisan"},
  {"name_id": "Sad", "name_id_translation": "Sad"},
  {"name_id": "Az-Zumar", "name_id_translation": "Rombongan"},
  {"name_id": "Ghafir", "name_id_translation": "Maha Pengampun"},
  {"name_id": "Fussilat", "name_id_translation": "Dijelaskan"},
  {"name_id": "Asy-Syura", "name_id_translation": "Musyawarah"},
  {"name_id": "Az-Zukhruf", "name_id_translation": "Perhiasan dari Emas"},
  {"name_id": "Ad-Dukhan", "name_id_translation": "Kabut Asap"},
  {"name_id": "Al-Jasiyah", "name_id_translation": "Berlutut"},
  {"name_id": "Al-Ahqaf", "name_id_translation": "Ahqaf"},
  {"name_id": "Muhammad", "name_id_translation": "Nabi Muhammad"},
  {"name_id": "Al-Fath", "name_id_translation": "Kemenangan"},
  {"name_id": "Al-Hujurat", "name_id_translation": "Kamar-Kamar"},
  {"name_id": "Qaf", "name_id_translation": "Qaf"},
  {"name_id": "Az-Zariyat", "name_id_translation": "Yang Menerbangkan"},
  {"name_id": "At-Tur", "name_id_translation": "Gunung"},
  {"name_id": "An-Najm", "name_id_translation": "Bintang"},
  {"name_id": "Al-Qamar", "name_id_translation": "Bulan"},
  {"name_id": "Ar-Rahman", "name_id_translation": "Yang Maha Pengasih"},
  {"name_id": "Al-Waqi'ah", "name_id_translation": "Hari Kiamat Yang Pasti Terjadi"},
  {"name_id": "Al-Hadid", "name_id_translation": "Besi"},
  {"name_id": "Al-Mujadalah", "name_id_translation": "Gugatan"},
  {"name_id": "Al-Hasyr", "name_id_translation": "Pengusiran"},
  {"name_id": "Al-Mumtahanah", "name_id_translation": "Wanita Yang Diuji"},
  {"name_id": "As-Saff", "name_id_translation": "Barisan"},
  {"name_id": "Al-Jumu'ah", "name_id_translation": "Jumat"},
  {"name_id": "Al-Munafiqun", "name_id_translation": "Orang-Orang Munafik"},
  {"name_id": "At-Tagabun", "name_id_translation": "Pengungkapan Kesalahan"},
  {"name_id": "At-Talaq", "name_id_translation": "Talak"},
  {"name_id": "At-Tahrim", "name_id_translation": "Pengharaman"},
  {"name_id": "Al-Mulk", "name_id_translation": "Kerajaan"},
  {"name_id": "Al-Qalam", "name_id_translation": "Pena"},
  {"name_id": "Al-Haqqah", "name_id_translation": "Hari Kiamat Yang Pasti Terjadi"},
  {"name_id": "Al-Ma'arij", "name_id_translation": "Tempat-Tempat Naik"},
  {"name_id": "Nuh", "name_id_translation": "Nuh"},
  {"name_id": "Al-Jinn", "name_id_translation": "Jin"},
  {"name_id": "Al-Muzzammil", "name_id_translation": "Orang Berkelumun"},
  {"name_id": "Al-Muddassir", "name_id_translation": "Orang Berselimut"},
  {"name_id": "Al-Qiyamah", "name_id_translation": "Hari Kiamat"},
  {"name_id": "Al-Insan", "name_id_translation": "Manusia"},
  {"name_id": "Al-Mursalat", "name_id_translation": "Malaikat Yang Diutus"},
  {"name_id": "An-Naba'", "name_id_translation": "Berita"},
  {"name_id": "An-Nazi'at", "name_id_translation": "Yang Mencabut Dengan Keras"},
  {"name_id": "Abasa", "name_id_translation": "Berwajah Masam"},
  {"name_id": "At-Takwir", "name_id_translation": "Penggulungan"},
  {"name_id": "Al-Infitar", "name_id_translation": "Terbelah"},
  {"name_id": "Al-Mutaffifin", "name_id_translation": "Orang-Orang Yang Curang"},
  {"name_id": "Al-Insyiqaq", "name_id_translation": "Terbelah"},
  {"name_id": "Al-Buruj", "name_id_translation": "Gugusan Bintang"},
  {"name_id": "At-Tariq", "name_id_translation": "Yang Datang Pada Malam Hari"},
  {"name_id": "Al-A'la", "name_id_translation": "Yang Maha Tinggi"},
  {"name_id": "Al-Ghasiyah", "name_id_translation": "Hari Kiamat Yang Menutupi"},
  {"name_id": "Al-Fajr", "name_id_translation": "Fajar"},
  {"name_id": "Al-Balad", "name_id_translation": "Negeri"},
  {"name_id": "Asy-Syams", "name_id_translation": "Matahari"},
  {"name_id": "Al-Lail", "name_id_translation": "Malam"},
  {"name_id": "Ad-Duha", "name_id_translation": "Duha"},
  {"name_id": "Asy-Syarh", "name_id_translation": "Pelapangan"},
  {"name_id": "At-Tin", "name_id_translation": "Buah Tin"},
  {"name_id": "Al-'Alaq", "name_id_translation": "Segumpal Darah"},
  {"name_id": "Al-Qadr", "name_id_translation": "Al-Qadar"},
  {"name_id": "Al-Bayyinah", "name_id_translation": "Bukti Nyata"},
  {"name_id": "Az-Zalzalah", "name_id_translation": "Guncangan"},
  {"name_id": "Al-'Adiyat", "name_id_translation": "Kuda Perang Yang Berlari Kencang"},
  {"name_id": "Al-Qari'ah", "name_id_translation": "Al-Qari'ah"},
  {"name_id": "At-Takasur", "name_id_translation": "Berbangga-Bangga"},
  {"name_id": "Al-'Asr", "name_id_translation": "Masa"},
  {"name_id": "Al-Humazah", "name_id_translation": "Pengumpat"},
  {"name_id": "Al-Fil", "name_id_translation": "Gajah"},
  {"name_id": "Quraisy", "name_id_translation": "Orang-Orang Quraisy"},
  {"name_id": "Al-Ma'un", "name_id_translation": "Bantuan"},
  {"name_id": "Al-Kausar", "name_id_translation": "Nikmat Yang Banyak"},
  {"name_id": "Al-Kafirun", "name_id_translation": "Orang-Orang Kafir"},
  {"name_id": "An-Nasr", "name_id_translation": "Pertolongan"},
  {"name_id": "Al-Lahab", "name_id_translation": "Gejolak Api"},
  {"name_id": "Al-Ikhlas", "name_id_translation": "Ikhlas"},
  {"name_id": "Al-Falaq", "name_id_translation": "Fajar"},
  {"name_id": "An-Nas", "name_id_translation": "Manusia"}
]

# Load JSON dengan error handling
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
json_path = os.path.join(project_root, 'assets', 'data', 'derived', 'surah_meta_merge.json')

try:
    # Flush output immediately untuk melihat progress
    sys.stdout.write("Loading JSON...")
    sys.stdout.flush()
    
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    sys.stdout.write(" Done.\n")
    sys.stdout.flush()
    
    surahs = data['surahs']
    diffs = []
    
    sys.stdout.write("Comparing data...")
    sys.stdout.flush()
    
    for i, exp in enumerate(expected_data):
        surah = surahs[i]
        num = surah['surah']
        act_name = surah.get('name_id', '')
        act_trans = surah.get('name_id_translation', '')
        
        if exp['name_id'] != act_name:
            diffs.append({'num': num, 'field': 'name_id', 'exp': exp['name_id'], 'act': act_name})
        
        if exp['name_id_translation'] != act_trans:
            diffs.append({'num': num, 'field': 'name_id_translation', 'exp': exp['name_id_translation'], 'act': act_trans})
    
    sys.stdout.write(" Done.\n\n")
    sys.stdout.flush()
    
    # Build output
    output_lines = []
    output_lines.append("Membandingkan name_id dan name_id_translation...\n")
    output_lines.append(f"{'No':<4} {'Field':<25} {'Expected':<50} {'Actual':<50}")
    output_lines.append("=" * 135)
    
    for diff in diffs:
        output_lines.append(f"{diff['num']:<4} {diff['field']:<25} {diff['exp']:<50} {diff['act']:<50}")
    
    output_lines.append(f"\n\nTotal perbedaan: {len(diffs)}")
    if len(diffs) == 0:
        output_lines.append("✅ Semua data sudah sesuai!")
    else:
        output_lines.append(f"\nRincian perbedaan:")
        output_lines.append(f"- name_id: {sum(1 for d in diffs if d['field'] == 'name_id')}")
        output_lines.append(f"- name_id_translation: {sum(1 for d in diffs if d['field'] == 'name_id_translation')}")
    
    # Write to file
    output_file = os.path.join(script_dir, 'surah_differences.txt')
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(output_lines))
    
    # Print to console (lebih cepat dengan join)
    print('\n'.join(output_lines))
    print(f"\n✅ Hasil juga ditulis ke {output_file}")
    
except FileNotFoundError:
    print(f"❌ Error: File tidak ditemukan: {json_path}")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"❌ Error: JSON tidak valid: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)

