import 'package:hive/hive.dart';

part 'last_read_hive.g.dart';

@HiveType(typeId: 0)
class LastReadPosition extends HiveObject {
  @HiveField(0)
  final int surah;

  @HiveField(1)
  final int ayah;

  @HiveField(2)
  final String mode;

  @HiveField(3)
  final String updatedAt;

  LastReadPosition({
    required this.surah,
    required this.ayah,
    required this.mode,
    required this.updatedAt,
  });
}

