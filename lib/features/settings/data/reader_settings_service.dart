import 'package:hive_flutter/hive_flutter.dart';
import 'reader_settings_hive.dart';

class ReaderSettingsService {
  static const String _boxName = 'reader_settings_v1';
  static Box<ReaderSettings>? _box;

  static Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<ReaderSettings>(_boxName);
  }

  static Future<ReaderSettings> loadSettings() async {
    if (_box == null) await init();
    return _box!.get('settings') ?? ReaderSettings.defaultValue;
  }

  static Future<void> saveSettings(ReaderSettings value) async {
    if (_box == null) await init();
    await _box!.put('settings', value);
  }

  static Stream<ReaderSettings> watchSettings() async* {
    if (_box == null) await init();
    
    yield _box!.get('settings') ?? ReaderSettings.defaultValue;
    yield* _box!.watch(key: 'settings').map((event) {
      return event.value as ReaderSettings? ?? ReaderSettings.defaultValue;
    });
  }
}

