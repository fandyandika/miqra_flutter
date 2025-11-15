import 'package:hive/hive.dart';

part 'bookmark_hive.g.dart';

@HiveType(typeId: 1)
class BookmarkFolder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  BookmarkFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}

@HiveType(typeId: 2)
class BookmarkItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String folderId;

  @HiveField(2)
  final int surahNumber;

  @HiveField(3)
  final int ayahNumber;

  @HiveField(4)
  final String snippet;

  @HiveField(5)
  final DateTime createdAt;

  BookmarkItem({
    required this.id,
    required this.folderId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.snippet,
    required this.createdAt,
  });
}

@HiveType(typeId: 3)
class SurahProgress extends HiveObject {
  @HiveField(0)
  final int surahNumber;

  @HiveField(1)
  final int lastAyah;

  @HiveField(2)
  final DateTime updatedAt;

  SurahProgress({
    required this.surahNumber,
    required this.lastAyah,
    required this.updatedAt,
  });
}

