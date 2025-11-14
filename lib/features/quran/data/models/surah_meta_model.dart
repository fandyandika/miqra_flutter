import 'package:json_annotation/json_annotation.dart';

part 'surah_meta_model.g.dart';

@JsonSerializable()
class JuzSegment {
  final int juz;
  @JsonKey(name: 'start_ayah')
  final int startAyah;
  @JsonKey(name: 'end_ayah')
  final int endAyah;

  const JuzSegment({
    required this.juz,
    required this.startAyah,
    required this.endAyah,
  });

  factory JuzSegment.fromJson(Map<String, dynamic> json) =>
      _$JuzSegmentFromJson(json);
  Map<String, dynamic> toJson() => _$JuzSegmentToJson(this);
}

@JsonSerializable()
class PageRange {
  final int page;
  @JsonKey(name: 'start_ayah')
  final int startAyah;
  @JsonKey(name: 'end_ayah')
  final int endAyah;

  const PageRange({
    required this.page,
    required this.startAyah,
    required this.endAyah,
  });

  factory PageRange.fromJson(Map<String, dynamic> json) =>
      _$PageRangeFromJson(json);
  Map<String, dynamic> toJson() => _$PageRangeToJson(this);
}

@JsonSerializable()
class JuzRange {
  final int start;
  final int end;

  const JuzRange({
    required this.start,
    required this.end,
  });

  factory JuzRange.fromJson(Map<String, dynamic> json) =>
      _$JuzRangeFromJson(json);
  Map<String, dynamic> toJson() => _$JuzRangeToJson(this);
}

@JsonSerializable()
class PageRangeSimple {
  final int start;
  final int end;

  const PageRangeSimple({
    required this.start,
    required this.end,
  });

  factory PageRangeSimple.fromJson(Map<String, dynamic> json) =>
      _$PageRangeSimpleFromJson(json);
  Map<String, dynamic> toJson() => _$PageRangeSimpleToJson(this);
}

@JsonSerializable()
class SurahMeta {
  @JsonKey(name: 'surah')
  final int number;
  @JsonKey(name: 'code_3')
  final String code3;
  @JsonKey(name: 'name_ar')
  final String nameArabic;
  @JsonKey(name: 'name_id')
  final String nameLatin;
  @JsonKey(name: 'name_id_translation')
  final String nameTranslationId;
  @JsonKey(name: 'name_en')
  final String nameEnglish;
  final String place;
  final String type;
  @JsonKey(name: 'ayah_count')
  final int ayahCount;
  final int rukus;
  final JuzRange juz;
  @JsonKey(name: 'juz_segments')
  final List<JuzSegment> juzSegments;
  final PageRangeSimple pages;
  @JsonKey(name: 'page_ranges')
  final List<PageRange> pageRanges;

  const SurahMeta({
    required this.number,
    required this.code3,
    required this.nameArabic,
    required this.nameLatin,
    required this.nameTranslationId,
    required this.nameEnglish,
    required this.place,
    required this.type,
    required this.ayahCount,
    required this.rukus,
    required this.juz,
    required this.juzSegments,
    required this.pages,
    required this.pageRanges,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json) =>
      _$SurahMetaFromJson(json);
  Map<String, dynamic> toJson() => _$SurahMetaToJson(this);
}

@JsonSerializable()
class SurahMetaEnvelope {
  final String version;
  final String source;
  @JsonKey(name: 'generated_at')
  final String generatedAt;
  final List<SurahMeta> surahs;

  const SurahMetaEnvelope({
    required this.version,
    required this.source,
    required this.generatedAt,
    required this.surahs,
  });

  factory SurahMetaEnvelope.fromJson(Map<String, dynamic> json) =>
      _$SurahMetaEnvelopeFromJson(json);
  Map<String, dynamic> toJson() => _$SurahMetaEnvelopeToJson(this);
}


