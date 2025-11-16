import json

# Data yang diharapkan dari user
expected = {
    1: ("Al-Fātiḥah", "Pembuka"),
    2: ("Al-Baqarah", "Sapi"),
    3: ("Āli 'Imrān", "Keluarga Imran"),
    4: ("An-Nisā'", "Perempuan"),
    5: ("Al-Mā'idah", "Hidangan"),
    6: ("Al-An'ām", "Binatang Ternak"),
    7: ("Al-A'rāf", "Tempat Tertinggi"),
    8: ("Al-Anfāl", "Rampasan Perang"),
    9: ("At-Taubah", "Pengampunan"),
    10: ("Yūnus", "Yunus"),
    11: ("Hūd", "Hud"),
    12: ("Yūsuf", "Yusuf"),
    13: ("Ar-Ra'd", "Guruh"),
    14: ("Ibrāhīm", "Ibrahim"),
    15: ("Al-Ḥijr", "Hijr"),
    16: ("An-Naḥl", "Lebah"),
    17: ("Al-Isrā'", "Memperjalankan di Malam Hari"),
    18: ("Al-Kahf", "Gua"),
    19: ("Maryam", "Maryam"),
    20: ("Ṭāhā", "Taha"),
    21: ("Al-Anbiyā'", "Para Nabi"),
    22: ("Al-Ḥajj", "Haji"),
    23: ("Al-Mu'minūn", "Orang-Orang Mukmin"),
    24: ("An-Nūr", "Cahaya"),
    25: ("Al-Furqān", "Pembeda"),
    26: ("Asy-Syu'arā'", "Para Penyair"),
    27: ("An-Naml", "Semut"),
    28: ("Al-Qaṣaṣ", "Kisah-Kisah"),
    29: ("Al-'Ankabūt", "Laba-Laba"),
    30: ("Ar-Rūm", "Romawi"),
    31: ("Luqmān", "Luqman"),
    32: ("As-Sajdah", "Sajdah"),
    33: ("Al-Aḥzāb", "Golongan Yang Bersekutu"),
    34: ("Saba'", "Saba'"),
    35: ("Fāṭir", "Pencipta"),
    36: ("Yāsīn", "Yasin"),
    37: ("Aṣ-Ṣāffāt", "Barisan-Barisan"),
    38: ("Ṣād", "Ṣād "),
    39: ("Az-Zumar", "Rombongan"),
    40: ("Gāfir", "Maha Pengampun"),
    41: ("Fuṣṣilat", "Dijelaskan"),
    42: ("Asy-Syūrā", "Musyawarah"),
    43: ("Az-Zukhruf", "Perhiasan dari Emas"),
    44: ("Ad-Dukhān", "Kabut Asap"),
    45: ("Al-Jāṡiyah", "Berlutut"),
    46: ("Al-Aḥqāf", "Ahqaf"),
    47: ("Muḥammad", "Nabi Muhammad"),
    48: ("Al-Fatḥ", "Kemenangan"),
    49: ("Al-Ḥujurāt", "Kamar-Kamar"),
    50: ("Qāf", "Qaf"),
    51: ("Aż-Żāriyāt", "Yang Menerbangkan"),
    52: ("Aṭ-Ṭūr", "Gunung"),
    53: ("An-Najm", "Bintang"),
    54: ("Al-Qamar", "Bulan"),
    55: ("Ar-Raḥmān", "Yang Maha Pengasih"),
    56: ("Al-Wāqi'ah", "Hari Kiamat Yang Pasti Terjadi"),
    57: ("Al-Ḥadīd", "Besi"),
    58: ("Al-Mujādalah", "Gugatan"),
    59: ("Al-Ḥasyr", "Pengusiran"),
    60: ("Al-Mumtaḥanah", "Wanita Yang Diuji"),
    61: ("Aṣ-Ṣaff", "Barisan"),
    62: ("Al-Jumu'ah", "Jumat"),
    63: ("Al-Munāfiqūn", "Orang-Orang Munafik"),
    64: ("At-Tagābun", "Pengungkapan Kesalahan"),
    65: ("Aṭ-Ṭalāq", "Talak"),
    66: ("At-taḥrīm", "Pengharaman"),
    67: ("Al-Mulk", "Kerajaan"),
    68: ("Al-Qalam", "Pena"),
    69: ("Al-Ḥāqqah", "Hari Kiamat Yang Pasti Terjadi"),
    70: ("Al-Ma'ārij", "Tempat-Tempat Naik"),
    71: ("Nūḥ", "Nuh"),
    72: ("Al-Jinn", "Jin"),
    73: ("Al-Muzzammil", "Orang Berkelumun"),
    74: ("Al-Muddaṡṡir", "Orang Berselimut"),
    75: ("Al-Qiyāmah", "Hari Kiamat"),
    76: ("Al-Insān", "Manusia"),
    77: ("Al-Mursalāt", "Malaikat Yang Diutus"),
    78: ("An-Naba'", "Berita"),
    79: ("An-Nāzi'āt", "Yang Mencabut Dengan Keras"),
    80: ("'Abasa", "Berwajah Masam"),
    81: ("At-Takwīr", "Penggulungan"),
    82: ("Al-Infiṭār", "Terbelah"),
    83: ("Al-Muṭaffifīn", "Orang-Orang Yang Curang"),
    84: ("Al-Insyiqāq", "Terbelah"),
    85: ("Al-Burūj", "Gugusan Bintang"),
    86: ("Aṭ-Ṭāriq", "Yang Datang Pada Malam Hari"),
    87: ("Al-A'lā", "Yang Maha Tinggi"),
    88: ("Al-Gāsyiyah", "Hari Kiamat Yang Menghilangkan Kesadaran"),
    89: ("Al-Fajr", "Fajar"),
    90: ("Al-Balad", "Negeri"),
    91: ("Asy-Syams", "Matahari"),
    92: ("Al-Lail", "Malam"),
    93: ("Aḍ-Ḍuḥā", "Duha"),
    94: ("Asy-Syarḥ", "Pelapangan"),
    95: ("At-Tīn", "Buah Tin"),
    96: ("Al-'Alaq", "Segumpal Darah"),
    97: ("Al-Qadr", "Al-Qadar"),
    98: ("Al-Bayyinah", "Bukti Nyata"),
    99: ("Az-Zalzalah", "Guncangan"),
    100: ("Al-'Ādiyāt", "Kuda Perang Yang Berlari Kencang"),
    101: ("Al-Qāri'ah", "Al-Qāri'ah"),
    102: ("At-Takāṡur", "Berbangga-Bangga Dalam Memperbanyak Dunia"),
    103: ("Al-'Aṣr", "Masa"),
    104: ("Al-Humazah", "Pengumpat"),
    105: ("Al-Fīl", "Gajah"),
    106: ("Quraisy", "Orang Quraisy"),
    107: ("Al-Mā'un", "Bantuan"),
    108: ("Al-Kauṡar", "Nikmat Yang Banyak"),
    109: ("Al-Kāfirūn", "Orang-Orang kafir"),
    110: ("An-Naṣr", "Pertolongan"),
    111: ("Al-Lahab", "Gejolak Api"),
    112: ("Al-Ikhlāṣ", "Ikhlas"),
    113: ("Al-Falaq", "Fajar"),
    114: ("An-Nās", "Manusia"),
}

# Load data dari file
with open('assets/data/derived/surah_meta_merge.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

surahs = data['surahs']
differences = []

print("Membandingkan data...\n")
print(f"{'No':<4} {'Expected Name':<30} {'Actual Name':<30} {'Expected Trans':<40} {'Actual Trans':<40}")
print("=" * 150)

for surah in surahs:
    num = surah['surah']
    if num in expected:
        exp_name, exp_trans = expected[num]
        act_name = surah.get('name_id', '')
        act_trans = surah.get('name_id_translation', '')
        
        name_match = exp_name == act_name
        trans_match = exp_trans == act_trans
        
        if not name_match or not trans_match:
            status = "❌"
            differences.append({
                'num': num,
                'exp_name': exp_name,
                'act_name': act_name,
                'exp_trans': exp_trans,
                'act_trans': act_trans
            })
        else:
            status = "✅"
        
        if not name_match or not trans_match:
            print(f"{num:<4} {exp_name:<30} {act_name:<30} {exp_trans:<40} {act_trans:<40} {status}")

print(f"\n\nTotal perbedaan: {len(differences)}")
if len(differences) == 0:
    print("✅ Semua data sudah sesuai!")
if differences:
    print("\nDetail perbedaan:")
    for diff in differences:
        print(f"\nSurah {diff['num']}:")
        if diff['exp_name'] != diff['act_name']:
            print(f"  Name: '{diff['exp_name']}' vs '{diff['act_name']}'")
        if diff['exp_trans'] != diff['act_trans']:
            print(f"  Translation: '{diff['exp_trans']}' vs '{diff['act_trans']}'")

