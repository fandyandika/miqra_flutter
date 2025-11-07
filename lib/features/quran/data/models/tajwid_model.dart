import 'package:json_annotation/json_annotation.dart';
part 'tajwid_model.g.dart';

@JsonSerializable()
class TajwidRule {
  final int start;
  final int end;
  final String rule;
  const TajwidRule({
    required this.start,
    required this.end,
    required this.rule,
  });
  factory TajwidRule.fromJson(Map<String, dynamic> json) => _$TajwidRuleFromJson(json);
  Map<String, dynamic> toJson() => _$TajwidRuleToJson(this);
}

@JsonSerializable()
class TajwidData {
  final String index;
  @JsonKey(name: 'verse')
  final Map<String, List<TajwidRule>> verses;
  final int count;
  const TajwidData({
    required this.index,
    required this.verses,
    required this.count,
  });
  factory TajwidData.fromJson(Map<String, dynamic> json) => _$TajwidDataFromJson(json);
  Map<String, dynamic> toJson() => _$TajwidDataToJson(this);
  
  List<TajwidRule> getRulesForVerse(int verseNumber, int surahNumber) {
    // Handle verse indexing inconsistency:
    // - Surah 1: verse_1, verse_2, ...
    // - Surah 2+: verse_0, verse_1, ...
    final verseKey = surahNumber == 1 
        ? 'verse_$verseNumber' 
        : 'verse_${verseNumber - 1}';
    return verses[verseKey] ?? [];
  }
}

