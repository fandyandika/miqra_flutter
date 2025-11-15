// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_read_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LastReadPositionAdapter extends TypeAdapter<LastReadPosition> {
  @override
  final int typeId = 0;

  @override
  LastReadPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LastReadPosition(
      surah: fields[0] as int,
      ayah: fields[1] as int,
      mode: fields[2] as String,
      updatedAt: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LastReadPosition obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.surah)
      ..writeByte(1)
      ..write(obj.ayah)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastReadPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
