import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reader_settings_service.dart';
import '../data/reader_settings_hive.dart';

final readerSettingsProvider = StreamProvider<ReaderSettings>((ref) {
  return ReaderSettingsService.watchSettings();
});

final readerSettingsOnceProvider = Provider<ReaderSettings>((ref) {
  final asyncSettings = ref.watch(readerSettingsProvider);
  return asyncSettings.when(
    data: (settings) => settings,
    loading: () => ReaderSettings.defaultValue,
    error: (_, __) => ReaderSettings.defaultValue,
  );
});

