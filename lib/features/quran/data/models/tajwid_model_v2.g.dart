// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tajwid_model_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TajwidSpan _$TajwidSpanFromJson(Map<String, dynamic> json) => TajwidSpan(
      rule: json['rule'] as String,
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$TajwidSpanToJson(TajwidSpan instance) =>
    <String, dynamic>{
      'rule': instance.rule,
      'start': instance.start,
      'end': instance.end,
    };

TajwidAyah _$TajwidAyahFromJson(Map<String, dynamic> json) => TajwidAyah(
      ayah: (json['ayah'] as num).toInt(),
      spans: (json['spans'] as List<dynamic>)
          .map((e) => TajwidSpan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TajwidAyahToJson(TajwidAyah instance) =>
    <String, dynamic>{
      'ayah': instance.ayah,
      'spans': instance.spans,
    };

TajwidSurah _$TajwidSurahFromJson(Map<String, dynamic> json) => TajwidSurah(
      surahNumber: (json['surah_number'] as num).toInt(),
      verses: (json['verses'] as List<dynamic>)
          .map((e) => TajwidAyah.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TajwidSurahToJson(TajwidSurah instance) =>
    <String, dynamic>{
      'surah_number': instance.surahNumber,
      'verses': instance.verses,
    };
