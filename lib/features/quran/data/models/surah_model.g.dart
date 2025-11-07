// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Verse _$VerseFromJson(Map<String, dynamic> json) => Verse(
      ayah: (json['ayah'] as num).toInt(),
      textAr: json['text_ar'] as String,
      textId: json['text_id'] as String,
      textTranslit: json['text_translit'] as String?,
    );

Map<String, dynamic> _$VerseToJson(Verse instance) => <String, dynamic>{
      'ayah': instance.ayah,
      'text_ar': instance.textAr,
      'text_id': instance.textId,
      'text_translit': instance.textTranslit,
    };

SurahData _$SurahDataFromJson(Map<String, dynamic> json) => SurahData(
      surahNumber: (json['surah_number'] as num).toInt(),
      nameArabic: json['name_arabic'] as String,
      nameLatin: json['name_latin'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((e) => Verse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SurahDataToJson(SurahData instance) => <String, dynamic>{
      'surah_number': instance.surahNumber,
      'name_arabic': instance.nameArabic,
      'name_latin': instance.nameLatin,
      'verses': instance.verses,
    };
