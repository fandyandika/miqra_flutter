// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah_meta_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JuzSegment _$JuzSegmentFromJson(Map<String, dynamic> json) => JuzSegment(
      juz: (json['juz'] as num).toInt(),
      startAyah: (json['start_ayah'] as num).toInt(),
      endAyah: (json['end_ayah'] as num).toInt(),
    );

Map<String, dynamic> _$JuzSegmentToJson(JuzSegment instance) =>
    <String, dynamic>{
      'juz': instance.juz,
      'start_ayah': instance.startAyah,
      'end_ayah': instance.endAyah,
    };

PageRange _$PageRangeFromJson(Map<String, dynamic> json) => PageRange(
      page: (json['page'] as num).toInt(),
      startAyah: (json['start_ayah'] as num).toInt(),
      endAyah: (json['end_ayah'] as num).toInt(),
    );

Map<String, dynamic> _$PageRangeToJson(PageRange instance) => <String, dynamic>{
      'page': instance.page,
      'start_ayah': instance.startAyah,
      'end_ayah': instance.endAyah,
    };

JuzRange _$JuzRangeFromJson(Map<String, dynamic> json) => JuzRange(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$JuzRangeToJson(JuzRange instance) => <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
    };

PageRangeSimple _$PageRangeSimpleFromJson(Map<String, dynamic> json) =>
    PageRangeSimple(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$PageRangeSimpleToJson(PageRangeSimple instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
    };

SurahMeta _$SurahMetaFromJson(Map<String, dynamic> json) => SurahMeta(
      number: (json['surah'] as num).toInt(),
      code3: json['code_3'] as String,
      nameArabic: json['name_ar'] as String,
      nameLatin: json['name_id'] as String,
      nameTranslationId: json['name_id_translation'] as String,
      nameEnglish: json['name_en'] as String,
      place: json['place'] as String,
      type: json['type'] as String,
      ayahCount: (json['ayah_count'] as num).toInt(),
      rukus: (json['rukus'] as num).toInt(),
      juz: JuzRange.fromJson(json['juz'] as Map<String, dynamic>),
      juzSegments: (json['juz_segments'] as List<dynamic>)
          .map((e) => JuzSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      pages: PageRangeSimple.fromJson(json['pages'] as Map<String, dynamic>),
      pageRanges: (json['page_ranges'] as List<dynamic>)
          .map((e) => PageRange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SurahMetaToJson(SurahMeta instance) => <String, dynamic>{
      'surah': instance.number,
      'code_3': instance.code3,
      'name_ar': instance.nameArabic,
      'name_id': instance.nameLatin,
      'name_id_translation': instance.nameTranslationId,
      'name_en': instance.nameEnglish,
      'place': instance.place,
      'type': instance.type,
      'ayah_count': instance.ayahCount,
      'rukus': instance.rukus,
      'juz': instance.juz,
      'juz_segments': instance.juzSegments,
      'pages': instance.pages,
      'page_ranges': instance.pageRanges,
    };

SurahMetaEnvelope _$SurahMetaEnvelopeFromJson(Map<String, dynamic> json) =>
    SurahMetaEnvelope(
      version: json['version'] as String,
      source: json['source'] as String,
      generatedAt: json['generated_at'] as String,
      surahs: (json['surahs'] as List<dynamic>)
          .map((e) => SurahMeta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SurahMetaEnvelopeToJson(SurahMetaEnvelope instance) =>
    <String, dynamic>{
      'version': instance.version,
      'source': instance.source,
      'generated_at': instance.generatedAt,
      'surahs': instance.surahs,
    };
