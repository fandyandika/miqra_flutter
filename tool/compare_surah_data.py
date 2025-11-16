import json
import unicodedata

def normalize_text(text):
    """Normalize text by removing diacritics for comparison"""
    nfd = unicodedata.normalize('NFD', text)
    return ''.join(c for c in nfd if unicodedata.category(c) != 'Mn')

# Data yang diharapkan dari user
expected = {
    1: ("Al-Fatihah", "Pembuka"),
    2: ("Al-Baqarah", "Sapi"),
    3: ("Ali 'Imran", "Keluarga Imran"),
    4: ("An-Nisa'", "Perempuan"),
    5: ("Al-Ma'idah", "Hidangan"),
    6: ("Al-An'am", "Binatang Ternak"),
    7: ("Al-A'raf", "Tempat Tertinggi"),
    8: ("Al-Anfal", "Rampasan Perang"),
    9: ("At-Tawbah", "Pengampunan"),
    10: ("Yunus", "Yunus"),
    11: ("Hud", "Hud"),
    12: ("Yusuf", "Yusuf"),
    13: ("Ar-Ra'd", "Guruh"),
    14: ("Ibrahim", "Ibrahim"),
    15: ("Al-Hijr", "Hijr"),
    16: ("An-Nahl", "Lebah"),
    17: ("Al-Isra'", "Memperjalankan di Malam Hari"),
    18: ("Al-Kahf", "Gua"),
    19: ("Maryam", "Maryam"),
    20: ("Taha", "Taha"),
    21: ("Al-Anbiya'", "Para Nabi"),
    22: ("Al-Hajj", "Haji"),
    23: ("Al-Mu'minun", "Orang-Orang Mukmin"),
    24: ("An-Nur", "Cahaya"),
    25: ("Al-Furqan", "Pembeda"),
    26: ("Asy-Syu'ara'", "Para Penyair"),
    27: ("An-Naml", "Semut"),
    28: ("Al-Qasas", "Kisah-Kisah"),
    29: ("Al-Ankabut", "Laba-Laba"),
    30: ("Ar-Rum", "Romawi"),
    31: ("Luqman", "Luqman"),
    32: ("As-Sajdah", "Sajdah"),
    33: ("Al-Ahzab", "Golongan Yang Berserikat"),
    34: ("Saba'", "Saba'"),
    35: ("Fatir", "Pencipta"),
    36: ("Yasin", "Yasin"),
    37: ("As-Saffat", "Barisan-Barisan"),
    38: ("Sad", "Sad"),
    39: ("Az-Zumar", "Rombongan"),
    40: ("Ghafir", "Maha Pengampun"),
    41: ("Fussilat", "Dijelaskan"),
    42: ("Asy-Syura", "Musyawarah"),
    43: ("Az-Zukhruf", "Perhiasan dari Emas"),
    44: ("Ad-Dukhan", "Kabut Asap"),
    45: ("Al-Jasiyah", "Berlutut"),
    46: ("Al-Ahqaf", "Ahqaf"),
    47: ("Muhammad", "Nabi Muhammad"),
    48: ("Al-Fath", "Kemenangan"),
    49: ("Al-Hujurat", "Kamar-Kamar"),
    50: ("Qaf", "Qaf"),
    51: ("Az-Zariyat", "Yang Menerbangkan"),
    52: ("At-Tur", "Gunung"),
    53: ("An-Najm", "Bintang"),
    54: ("Al-Qamar", "Bulan"),
    55: ("Ar-Rahman", "Yang Maha Pengasih"),
    56: ("Al-Waqi'ah", "Hari Kiamat Yang Pasti Terjadi"),
    57: ("Al-Hadid", "Besi"),
    58: ("Al-Mujadalah", "Gugatan"),
    59: ("Al-Hasyr", "Pengusiran"),
    60: ("Al-Mumtahanah", "Wanita Yang Diuji"),
    61: ("As-Saff", "Barisan"),
    62: ("Al-Jumu'ah", "Jumat"),
    63: ("Al-Munafiqun", "Orang-Orang Munafik"),
    64: ("At-Tagabun", "Pengungkapan Kesalahan"),
    65: ("At-Talaq", "Talak"),
    66: ("At-Tahrim", "Pengharaman"),
    67: ("Al-Mulk", "Kerajaan"),
    68: ("Al-Qalam", "Pena"),
    69: ("Al-Haqqah", "Hari Kiamat Yang Pasti Terjadi"),
    70: ("Al-Ma'arij", "Tempat-Tempat Naik"),
    71: ("Nuh", "Nuh"),
    72: ("Al-Jinn", "Jin"),
    73: ("Al-Muzzammil", "Orang Berkelumun"),
    74: ("Al-Muddassir", "Orang Berselimut"),
    75: ("Al-Qiyamah", "Hari Kiamat"),
    76: ("Al-Insan", "Manusia"),
    77: ("Al-Mursalat", "Malaikat Yang Diutus"),
    78: ("An-Naba'", "Berita"),
    79: ("An-Nazi'at", "Yang Mencabut Dengan Keras"),
    80: ("Abasa", "Berwajah Masam"),
    81: ("At-Takwir", "Penggulungan"),
    82: ("Al-Infitar", "Terbelah"),
    83: ("Al-Mutaffifin", "Orang-Orang Yang Curang"),
    84: ("Al-Insyiqaq", "Terbelah"),
    85: ("Al-Buruj", "Gugusan Bintang"),
    86: ("At-Tariq", "Yang Datang Pada Malam Hari"),
    87: ("Al-A'la", "Yang Maha Tinggi"),
    88: ("Al-Ghasiyah", "Hari Kiamat Yang Menutupi"),
    89: ("Al-Fajr", "Fajar"),
    90: ("Al-Balad", "Negeri"),
    91: ("Asy-Syams", "Matahari"),
    92: ("Al-Lail", "Malam"),
    93: ("Ad-Duha", "Duha"),
    94: ("Asy-Syarh", "Pelapangan"),
    95: ("At-Tin", "Buah Tin"),
    96: ("Al-'Alaq", "Segumpal Darah"),
    97: ("Al-Qadr", "Al-Qadar"),
    98: ("Al-Bayyinah", "Bukti Nyata"),
    99: ("Az-Zalzalah", "Guncangan"),
    100: ("Al-'Adiyat", "Kuda Perang Yang Berlari Kencang"),
    101: ("Al-Qari'ah", "Al-Qari'ah"),
    102: ("At-Takasur", "Berbangga-Bangga"),
    103: ("Al-'Asr", "Masa"),
    104: ("Al-Humazah", "Pengumpat"),
    105: ("Al-Fil", "Gajah"),
    106: ("Quraisy", "Orang-Orang Quraisy"),
    107: ("Al-Ma'un", "Bantuan"),
    108: ("Al-Kausar", "Nikmat Yang Banyak"),
    109: ("Al-Kafirun", "Orang-Orang Kafir"),
    110: ("An-Nasr", "Pertolongan"),
    111: ("Al-Lahab", "Gejolak Api"),
    112: ("Al-Ikhlas", "Ikhlas"),
    113: ("Al-Falaq", "Fajar"),
    114: ("An-Nas", "Manusia"),
}

# Load data dari file
with open('assets/data/derived/surah_meta_merge.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

surahs = data['surahs']
differences = []

print("Membandingkan name_id dan name_id_translation...\n")
print(f"{'No':<4} {'Field':<20} {'Expected':<50} {'Actual':<50}")
print("=" * 130)

for surah in surahs:
    num = surah['surah']
    if num in expected:
        exp_name, exp_trans = expected[num]
        act_name = surah.get('name_id', '')
        act_trans = surah.get('name_id_translation', '')
        
        # Check name_id
        if exp_name != act_name:
            differences.append({
                'num': num,
                'field': 'name_id',
                'expected': exp_name,
                'actual': act_name
            })
            print(f"{num:<4} {'name_id':<20} {exp_name:<50} {act_name:<50}")
        
        # Check name_id_translation
        if exp_trans != act_trans:
            differences.append({
                'num': num,
                'field': 'name_id_translation',
                'expected': exp_trans,
                'actual': act_trans
            })
            print(f"{num:<4} {'name_id_translation':<20} {exp_trans:<50} {act_trans:<50}")

print(f"\n\nTotal perbedaan: {len(differences)}")
if len(differences) == 0:
    print("✅ Semua data sudah sesuai!")
else:
    print(f"\nRincian perbedaan:")
    print(f"- name_id: {sum(1 for d in differences if d['field'] == 'name_id')}")
    print(f"- name_id_translation: {sum(1 for d in differences if d['field'] == 'name_id_translation')}")

# Write to file
with open('tool/surah_differences.txt', 'w', encoding='utf-8') as f:
    f.write(f"Total perbedaan: {len(differences)}\n\n")
    f.write(f"{'No':<4} {'Field':<20} {'Expected':<50} {'Actual':<50}\n")
    f.write("=" * 130 + "\n")
    for diff in differences:
        f.write(f"{diff['num']:<4} {diff['field']:<20} {diff['expected']:<50} {diff['actual']:<50}\n")
print("\n✅ Hasil juga ditulis ke tool/surah_differences.txt")

