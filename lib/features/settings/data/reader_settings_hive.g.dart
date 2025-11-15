// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_settings_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReaderSettingsAdapter extends TypeAdapter<ReaderSettings> {
  @override
  final int typeId = 4;

  @override
  ReaderSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReaderSettings(
      fontSizeLevel: fields[0] as int,
      showTranslation: fields[1] as bool,
      showTransliteration: fields[2] as bool,
      dailyTargetAyat: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ReaderSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fontSizeLevel)
      ..writeByte(1)
      ..write(obj.showTranslation)
      ..writeByte(2)
      ..write(obj.showTransliteration)
      ..writeByte(3)
      ..write(obj.dailyTargetAyat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
