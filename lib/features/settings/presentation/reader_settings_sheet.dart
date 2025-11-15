import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reader_settings_hive.dart';
import '../data/reader_settings_service.dart';
import '../providers/reader_settings_providers.dart';

class ReaderSettingsSheet extends ConsumerStatefulWidget {
  const ReaderSettingsSheet({super.key});

  @override
  ConsumerState<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends ConsumerState<ReaderSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(readerSettingsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pengaturan Bacaan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          settingsAsync.when(
            data: (settings) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Font Size Section
                const Text(
                  'Ukuran Font',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Kecil'),
                        selected: settings.fontSizeLevel == 0,
                        onSelected: (selected) {
                          if (selected) {
                            ReaderSettingsService.saveSettings(
                              settings.copyWith(fontSizeLevel: 0),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Sedang'),
                        selected: settings.fontSizeLevel == 1,
                        onSelected: (selected) {
                          if (selected) {
                            ReaderSettingsService.saveSettings(
                              settings.copyWith(fontSizeLevel: 1),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Besar'),
                        selected: settings.fontSizeLevel == 2,
                        onSelected: (selected) {
                          if (selected) {
                            ReaderSettingsService.saveSettings(
                              settings.copyWith(fontSizeLevel: 2),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Display Section
                const Text(
                  'Tampilan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Tampilkan Terjemah'),
                  value: settings.showTranslation,
                  onChanged: (value) {
                    ReaderSettingsService.saveSettings(
                      settings.copyWith(showTranslation: value),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Tampilkan Transliterasi'),
                  value: settings.showTransliteration,
                  onChanged: (value) {
                    ReaderSettingsService.saveSettings(
                      settings.copyWith(showTransliteration: value),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Daily Target Section
                const Text(
                  'Target Harian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: settings.dailyTargetAyat > 1
                          ? () {
                              ReaderSettingsService.saveSettings(
                                settings.copyWith(
                                  dailyTargetAyat: settings.dailyTargetAyat - 1,
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '${settings.dailyTargetAyat}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: settings.dailyTargetAyat < 50
                          ? () {
                              ReaderSettingsService.saveSettings(
                                settings.copyWith(
                                  dailyTargetAyat: settings.dailyTargetAyat + 1,
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 8),
                    const Text('ayat'),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}

