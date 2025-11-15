import 'package:hive/hive.dart';

part 'reader_settings_hive.g.dart';

@HiveType(typeId: 4)
class ReaderSettings extends HiveObject {
  @HiveField(0)
  final int fontSizeLevel; // 0=small, 1=medium, 2=large

  @HiveField(1)
  final bool showTranslation;

  @HiveField(2)
  final bool showTransliteration;

  @HiveField(3)
  final int dailyTargetAyat;

  ReaderSettings({
    required this.fontSizeLevel,
    required this.showTranslation,
    required this.showTransliteration,
    required this.dailyTargetAyat,
  });

  ReaderSettings copyWith({
    int? fontSizeLevel,
    bool? showTranslation,
    bool? showTransliteration,
    int? dailyTargetAyat,
  }) {
    return ReaderSettings(
      fontSizeLevel: fontSizeLevel ?? this.fontSizeLevel,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      dailyTargetAyat: dailyTargetAyat ?? this.dailyTargetAyat,
    );
  }

  static ReaderSettings get defaultValue => ReaderSettings(
    fontSizeLevel: 1,
    showTranslation: true,
    showTransliteration: true,
    dailyTargetAyat: 5,
  );
}

