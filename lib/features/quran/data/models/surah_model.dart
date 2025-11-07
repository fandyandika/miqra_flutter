import 'package:json_annotation/json_annotation.dart';
part 'surah_model.g.dart';

@JsonSerializable()
class Verse {
  final int ayah;
  @JsonKey(name: 'text_ar') final String textAr;
  @JsonKey(name: 'text_id') final String textId;
  @JsonKey(name: 'text_translit') final String? textTranslit;
  const Verse({
    required this.ayah,
    required this.textAr,
    required this.textId,
    this.textTranslit,
  });
  factory Verse.fromJson(Map<String, dynamic> json) => _$VerseFromJson(json);
  Map<String, dynamic> toJson() => _$VerseToJson(this);
}

@JsonSerializable()
class SurahData {
  @JsonKey(name: 'surah_number') final int surahNumber;
  @JsonKey(name: 'name_arabic')  final String nameArabic;
  @JsonKey(name: 'name_latin')   final String nameLatin;
  final List<Verse> verses;
  const SurahData({required this.surahNumber, required this.nameArabic, required this.nameLatin, required this.verses});
  factory SurahData.fromJson(Map<String, dynamic> json) => _$SurahDataFromJson(json);
  Map<String, dynamic> toJson() => _$SurahDataToJson(this);
}

