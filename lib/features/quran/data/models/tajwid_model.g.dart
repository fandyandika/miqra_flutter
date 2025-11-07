// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tajwid_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TajwidRule _$TajwidRuleFromJson(Map<String, dynamic> json) => TajwidRule(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      rule: json['rule'] as String,
    );

Map<String, dynamic> _$TajwidRuleToJson(TajwidRule instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'rule': instance.rule,
    };

TajwidData _$TajwidDataFromJson(Map<String, dynamic> json) => TajwidData(
      index: json['index'] as String,
      verses: (json['verse'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => TajwidRule.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$TajwidDataToJson(TajwidData instance) =>
    <String, dynamic>{
      'index': instance.index,
      'verse': instance.verses,
      'count': instance.count,
    };
