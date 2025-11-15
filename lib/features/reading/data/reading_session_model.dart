/// Model for reading session data from Supabase.
class ReadingSession {
  final String id;
  final int surahNumber;
  final int ayahStart;
  final int ayahEnd;
  final int lettersCount;
  final int hasanat;
  final String readingMode; // 'surah' or 'focus'
  final DateTime createdAt;
  final String? notes;

  const ReadingSession({
    required this.id,
    required this.surahNumber,
    required this.ayahStart,
    required this.ayahEnd,
    required this.lettersCount,
    required this.hasanat,
    required this.readingMode,
    required this.createdAt,
    this.notes,
  });

  /// Creates ReadingSession from Supabase response (Map).
  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    return ReadingSession(
      id: map['id'] as String,
      surahNumber: map['surah_number'] as int,
      ayahStart: map['ayah_start'] as int,
      ayahEnd: map['ayah_end'] as int,
      lettersCount: map['letters_count'] as int,
      hasanat: map['hasanat'] as int,
      readingMode: map['reading_mode'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  /// Converts ReadingSession to Map (for debugging/testing).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_number': surahNumber,
      'ayah_start': ayahStart,
      'ayah_end': ayahEnd,
      'letters_count': lettersCount,
      'hasanat': hasanat,
      'reading_mode': readingMode,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }
}

