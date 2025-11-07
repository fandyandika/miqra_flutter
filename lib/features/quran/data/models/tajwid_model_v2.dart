import 'package:json_annotation/json_annotation.dart';
part 'tajwid_model_v2.g.dart';

@JsonSerializable()
class TajwidSpan {
  final String rule;
  final int start;
  final int end;
  
  const TajwidSpan({
    required this.rule,
    required this.start,
    required this.end,
  });
  
  factory TajwidSpan.fromJson(Map<String, dynamic> json) => _$TajwidSpanFromJson(json);
  Map<String, dynamic> toJson() => _$TajwidSpanToJson(this);
}

@JsonSerializable()
class TajwidAyah {
  final int ayah;
  final List<TajwidSpan> spans;
  
  const TajwidAyah({
    required this.ayah,
    required this.spans,
  });
  
  factory TajwidAyah.fromJson(Map<String, dynamic> json) => _$TajwidAyahFromJson(json);
  Map<String, dynamic> toJson() => _$TajwidAyahToJson(this);
}

@JsonSerializable()
class TajwidSurah {
  @JsonKey(name: 'surah_number')
  final int surahNumber;
  final List<TajwidAyah> verses;
  
  const TajwidSurah({
    required this.surahNumber,
    required this.verses,
  });
  
  factory TajwidSurah.fromJson(Map<String, dynamic> json) => _$TajwidSurahFromJson(json);
  Map<String, dynamic> toJson() => _$TajwidSurahToJson(this);
  
  List<TajwidSpan> getSpansForAyah(int ayahNumber) {
    final ayah = verses.firstWhere(
      (v) => v.ayah == ayahNumber,
      orElse: () => const TajwidAyah(ayah: 0, spans: []),
    );
    return ayah.spans;
  }
}

