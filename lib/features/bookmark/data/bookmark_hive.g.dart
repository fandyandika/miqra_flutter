// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookmarkFolderAdapter extends TypeAdapter<BookmarkFolder> {
  @override
  final int typeId = 1;

  @override
  BookmarkFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookmarkFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkFolder obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookmarkItemAdapter extends TypeAdapter<BookmarkItem> {
  @override
  final int typeId = 2;

  @override
  BookmarkItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookmarkItem(
      id: fields[0] as String,
      folderId: fields[1] as String,
      surahNumber: fields[2] as int,
      ayahNumber: fields[3] as int,
      snippet: fields[4] as String,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.surahNumber)
      ..writeByte(3)
      ..write(obj.ayahNumber)
      ..writeByte(4)
      ..write(obj.snippet)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SurahProgressAdapter extends TypeAdapter<SurahProgress> {
  @override
  final int typeId = 3;

  @override
  SurahProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SurahProgress(
      surahNumber: fields[0] as int,
      lastAyah: fields[1] as int,
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SurahProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.lastAyah)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurahProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
