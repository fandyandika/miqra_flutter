import 'dart:convert';
import 'package:flutter/services.dart';

class QuranFontHelper {
  static Map<String, String>? _ligatures;
  static Map<String, String>? _surahNameLigatures;
  
  static Future<void> loadLigatures() async {
    if (_ligatures != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/fontjuz/ligatures.json');
      _ligatures = Map<String, String>.from(json.decode(jsonString));
    } catch (_) {
      // Fail-safe: don't block startup if ligatures fail to load
      _ligatures = const {};
    }
  }
  
  static Future<void> loadSurahNameLigatures() async {
    if (_surahNameLigatures != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/fontjuz/ligatures-surah-name.json');
      _surahNameLigatures = Map<String, String>.from(json.decode(jsonString));
    } catch (_) {
      // Fail-safe: don't block startup if ligatures fail to load
      _surahNameLigatures = const {};
    }
  }
  
  static String getBismillah() {
    // Karakter Unicode untuk bismillah: U+FDFD (﷽)
    // Jika ligatures sudah di-load, gunakan dari JSON, jika tidak gunakan karakter Unicode langsung
    if (_ligatures != null && _ligatures!.containsKey('bismillah')) {
      return _ligatures!['bismillah']!;
    }
    // Fallback ke karakter Unicode bismillah
    return '\uFDFD';
  }
  
  static bool shouldShowBismillah(int surahNumber) {
    // Tidak tampilkan di surah 1 (Al-Fatihah) dan surah 9 (At-Taubah)
    return surahNumber != 1 && surahNumber != 9;
  }
  
  static String getSurahHeader() {
    // Menggunakan ligature "header" untuk surah header
    if (_ligatures != null && _ligatures!.containsKey('surah_header')) {
      return _ligatures!['surah_header']!;
    }
    // Fallback ke string "header" yang akan dirender oleh font
    return 'header';
  }

  /// Ayah number wrappers (font: quran-common.ttf)
  static String getAyahOpen1() {
    if (_ligatures != null) {
      if (_ligatures!.containsKey('ayah_open1')) return _ligatures!['ayah_open1']!;
      if (_ligatures!.containsKey('s1open')) return _ligatures!['s1open']!;
    }
    return 's1open'; // fallback: directly use ligature trigger
  }

  static String getAyahClose1() {
    if (_ligatures != null) {
      if (_ligatures!.containsKey('ayah_close1')) return _ligatures!['ayah_close1']!;
      if (_ligatures!.containsKey('s1close')) return _ligatures!['s1close']!;
    }
    return 's1close'; // fallback: directly use ligature trigger
  }
  
  static String getMakkahSymbol() {
    if (_ligatures != null && _ligatures!.containsKey('makkah')) {
      return _ligatures!['makkah']!;
    }
    return 'makkah';
  }
  
  static String getMadinahSymbol() {
    if (_ligatures != null && _ligatures!.containsKey('madinah')) {
      return _ligatures!['madinah']!;
    }
    return 'madinah';
  }
  
  static String getSurahType(int surahNumber) {
    // Mapping surah makkiyah (1-86 sebagian, 87-114 sebagian)
    // Madaniyah: 2, 3, 4, 5, 8, 9, 24, 33, 47, 48, 49, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 98, 99, 110
    final madaniyahSurahs = [2, 3, 4, 5, 8, 9, 24, 33, 47, 48, 49, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 98, 99, 110];
    return madaniyahSurahs.contains(surahNumber) ? 'madinah' : 'makkah';
  }
  
  static String getSurahTranslation(int surahNumber) {
    // Mapping terjemahan surah (contoh beberapa surah utama)
    final translations = {
      1: 'Pembukaan',
      2: 'Sapi Betina',
      3: 'Keluarga Imran',
      4: 'Wanita',
      5: 'Hidangan',
      6: 'Binatang Ternak',
      7: 'Tempat Tertinggi',
      8: 'Rampasan Perang',
      9: 'Pengampunan',
      10: 'Yunus',
      11: 'Hud',
      12: 'Yusuf',
      13: 'Guruh',
      14: 'Ibrahim',
      15: 'Al-Hijr',
      16: 'Lebah',
      17: 'Perjalanan Malam',
      18: 'Goa',
      19: 'Maryam',
      20: 'Thaha',
      21: 'Para Nabi',
      22: 'Haji',
      23: 'Orang-Orang Mukmin',
      24: 'Cahaya',
      25: 'Pembeda',
      26: 'Para Penyair',
      27: 'Semut',
      28: 'Kisah-Kisah',
      29: 'Laba-Laba',
      30: 'Romawi',
      31: 'Luqman',
      32: 'Sajdah',
      33: 'Golongan yang Bersekutu',
      34: 'Saba',
      35: 'Maha Pencipta',
      36: 'Yasin',
      37: 'Barisan-Barisan',
      38: 'Shad',
      39: 'Rombongan',
      40: 'Yang Maha Pengampun',
      41: 'Yang Dijelaskan',
      42: 'Musyawarah',
      43: 'Perhiasan',
      44: 'Kabut',
      45: 'Berlutut',
      46: 'Bukit Pasir',
      47: 'Muhammad',
      48: 'Kemenangan',
      49: 'Kamar-Kamar',
      50: 'Qaf',
      51: 'Angin yang Menerbangkan',
      52: 'Bukit',
      53: 'Bintang',
      54: 'Bulan',
      55: 'Yang Maha Pemurah',
      56: 'Hari Kiamat',
      57: 'Besi',
      58: 'Wanita yang Mengajukan Gugatan',
      59: 'Pengusiran',
      60: 'Wanita yang Diuji',
      61: 'Barisan',
      62: 'Jumat',
      63: 'Orang-Orang Munafik',
      64: 'Pengungkapan Kesalahan',
      65: 'Talak',
      66: 'Mengharamkan',
      67: 'Kerajaan',
      68: 'Pena',
      69: 'Hari Kiamat',
      70: 'Tempat Naik',
      71: 'Nuh',
      72: 'Jin',
      73: 'Orang yang Berselimut',
      74: 'Orang yang Berkemul',
      75: 'Hari Kebangkitan',
      76: 'Manusia',
      77: 'Malaikat yang Diutus',
      78: 'Berita Besar',
      79: 'Malaikat yang Mencabut',
      80: 'Ia Bermuka Masam',
      81: 'Penggulungan',
      82: 'Terbelah',
      83: 'Orang-Orang yang Curang',
      84: 'Terbelah',
      85: 'Gugusan Bintang',
      86: 'Yang Datang di Malam Hari',
      87: 'Yang Paling Tinggi',
      88: 'Hari Pembalasan',
      89: 'Fajar',
      90: 'Negeri',
      91: 'Matahari',
      92: 'Malam',
      93: 'Waktu Dhuha',
      94: 'Lapang',
      95: 'Buah Tin',
      96: 'Segumpal Darah',
      97: 'Kemuliaan',
      98: 'Bukti Nyata',
      99: 'Kegoncangan',
      100: 'Kuda yang Berlari Kencang',
      101: 'Hari Kiamat',
      102: 'Bermegah-Megahan',
      103: 'Asar',
      104: 'Pengumpat',
      105: 'Gajah',
      106: 'Quraisy',
      107: 'Barang yang Berguna',
      108: 'Pemberian yang Banyak',
      109: 'Orang-Orang Kafir',
      110: 'Pertolongan',
      111: 'Gejolak Api',
      112: 'Ikhlas',
      113: 'Subuh',
      114: 'Manusia',
    };
    return translations[surahNumber] ?? '';
  }
  
  /// Get surah name ligature for a specific surah number
  static String getSurahNameLigature(int surahNumber) {
    if (_surahNameLigatures == null) {
      return ''; // Return empty if not loaded yet
    }
    final key = 'surah-$surahNumber';
    return _surahNameLigatures![key] ?? '';
  }
}

