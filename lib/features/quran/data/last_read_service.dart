import 'package:hive_flutter/hive_flutter.dart';
import 'last_read_hive.dart';
import '../../bookmark/data/bookmark_service.dart';

class LastReadService {
  static const String _boxName = 'last_read_v1';
  static Box<LastReadPosition>? _box;

  static Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<LastReadPosition>(_boxName);
  }

  static Future<void> saveLastRead(int surah, int ayah, String mode) async {
    if (_box == null) await init();
    
    final now = DateTime.now().toIso8601String();
    final position = LastReadPosition(
      surah: surah,
      ayah: ayah,
      mode: mode,
      updatedAt: now,
    );
    
    await _box!.put('current', position);
    
    // Update surah progress tracking
    await BookmarkService.updateSurahProgress(surah, ayah);
  }

  static LastReadPosition? getLastRead() {
    if (_box == null) return null;
    return _box!.get('current');
  }

  static Stream<LastReadPosition?> watchLastRead() async* {
    if (_box == null) {
      await init();
    }

    yield _box!.get('current');
    yield* _box!
        .watch(key: 'current')
        .map((event) => event.value as LastReadPosition?);
  }
}

