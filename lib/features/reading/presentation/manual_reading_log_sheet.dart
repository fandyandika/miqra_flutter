import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/reading_providers.dart';
import '../../quran/providers/surah_providers.dart';
import '../../quran/providers/last_read_providers.dart';
import '../../quran/data/last_read_hive.dart';
import '../../streak/providers/streak_providers.dart';

/// Bottom sheet for manually logging a reading session.
class ManualReadingLogSheet extends ConsumerStatefulWidget {
  final int? surahNumber;
  final int? maxAyat;
  final String readingMode;

  const ManualReadingLogSheet({
    super.key,
    this.surahNumber,
    this.maxAyat,
    this.readingMode = 'surah',
  });

  @override
  ConsumerState<ManualReadingLogSheet> createState() =>
      _ManualReadingLogSheetState();
}

class _ManualReadingLogSheetState
    extends ConsumerState<ManualReadingLogSheet> {
  int? _selectedSurah;
  int _fromAyah = 1;
  int _toAyah = 1;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  bool _isLoading = false;
  bool _isSuccess = false;
  int? _loggedLettersCount;
  int? _loggedHasanat;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.surahNumber;
    if (widget.maxAyat != null) {
      _toAyah = widget.maxAyat!;
    }
    _fromController = TextEditingController(text: '$_fromAyah');
    _toController = TextEditingController(text: '$_toAyah');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(surahSearchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _logReading() async {
    if (_isLoading) return;

    if (_selectedSurah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih surah terlebih dahulu'),
        ),
      );
      return;
    }

    if (_fromAyah > _toAyah) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayat awal harus lebih kecil atau sama dengan ayat akhir'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      final service = ref.read(readingSessionServiceProvider);
      final session = await service.logSession(
        surahNumber: _selectedSurah!,
        ayahStart: _fromAyah,
        ayahEnd: _toAyah,
        readingMode: widget.readingMode,
      );

      // Haptic feedback on success
      HapticFeedback.mediumImpact();

      // Invalidate stats to refresh
      ref.invalidate(todayReadingStatsProvider);
      ref.invalidate(streakSummaryProvider);

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _loggedLettersCount = session.lettersCount;
        _loggedHasanat = session.hasanat;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat bacaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getAyatCount() {
    return _toAyah - _fromAyah + 1;
  }

  @override
  Widget build(BuildContext context) {
    final lastReadAsync = ref.watch(lastReadProvider);
    final surahMeta = _selectedSurah != null
        ? ref.watch(surahMetaProvider(_selectedSurah!))
        : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Catat Bacaan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildLastReadShortcut(lastReadAsync),
            if (surahMeta != null) ...[
              const SizedBox(height: 8),
              Text(
                surahMeta.nameLatin,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isSuccess) ...[
              _buildSuccessState(),
            ] else ...[
              _buildFormState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadShortcut(AsyncValue<LastReadPosition?> lastReadAsync) {
    return lastReadAsync.when(
      data: (lastRead) {
        if (lastRead == null) {
          return const SizedBox.shrink();
        }
        final surahMeta = ref.read(surahMetaProvider(lastRead.surah));
        final surahName = surahMeta?.nameLatin ?? 'Surah ${lastRead.surah}';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terakhir dibaca',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'QS. $surahName • Ayat ${lastRead.ayah}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => _applyLastRead(lastRead, surahMeta?.ayahCount ?? widget.maxAyat ?? 1),
                child: const Text('Gunakan'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _applyLastRead(LastReadPosition lastRead, int maxAyat) {
    setState(() {
      _selectedSurah = lastRead.surah;
      _fromAyah = lastRead.ayah.clamp(1, maxAyat);
      _toAyah = _fromAyah;
      _syncControllers();
    });
  }

  Widget _buildFormState() {
    // If surah not selected, show surah picker
    if (_selectedSurah == null) {
      return _buildSurahPicker();
    }

    // Get max ayat from surah meta
    final surahMeta = ref.watch(surahMetaProvider(_selectedSurah!));
    final maxAyat = surahMeta?.ayahCount ?? widget.maxAyat ?? 1;

    // Update _toAyah if needed
    if (_toAyah > maxAyat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _toAyah = maxAyat;
            if (_fromAyah > _toAyah) {
              _fromAyah = _toAyah;
            }
            _syncControllers();
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah selector (editable)
        _buildSurahSelector(),
        const SizedBox(height: 16),
        _buildAyahInputs(maxAyat),
        const SizedBox(height: 16),
        _buildQuickRangeChips(maxAyat),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Ayat yang dicatat: ${_getAyatCount()} ayat',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _logReading,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hitung & Catat'),
        ),
      ],
    );
  }

  Widget _buildSurahPicker() {
    final surahListAsync = ref.watch(surahMetaListProvider);
    final filteredSurahs = ref.watch(filteredSurahListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari surah...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            ref.read(surahSearchQueryProvider.notifier).state = value;
          },
        ),
        const SizedBox(height: 16),
        _buildQuickSurahShortcuts(),
        const SizedBox(height: 12),
        // Surah list
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: surahListAsync.when(
            data: (_) => filteredSurahs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada surah ditemukan'),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredSurahs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final surah = filteredSurahs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            '${surah.number}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text(
                          surah.nameLatin,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${surah.ayahCount} ayat'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          setState(() {
                            _selectedSurah = surah.number;
                            _fromAyah = 1;
                            _toAyah = surah.ayahCount;
                            _syncControllers();
                          });
                        },
                      );
                    },
                  ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error memuat daftar surah'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSurahShortcuts() {
    final popularSurahs = [
      {'number': 1, 'label': 'Al-Fatihah'},
      {'number': 2, 'label': 'Al-Baqarah'},
      {'number': 18, 'label': 'Al-Kahf'},
      {'number': 36, 'label': 'Yasin'},
      {'number': 55, 'label': 'Ar-Rahman'},
      {'number': 56, 'label': 'Al-Waqi\'ah'},
      {'number': 67, 'label': 'Al-Mulk'},
      {'number': 78, 'label': 'An-Naba\''},
      {'number': 114, 'label': 'An-Nas'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: popularSurahs.map((surah) {
          final number = surah['number'] as int;
          final label = surah['label'] as String;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(label),
              onPressed: () {
                final meta = ref.read(surahMetaProvider(number));
                setState(() {
                  _selectedSurah = number;
                  _fromAyah = 1;
                  _toAyah = meta?.ayahCount ?? 1;
                  _syncControllers();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSurahSelector() {
    final surahMeta = _selectedSurah != null
        ? ref.watch(surahMetaProvider(_selectedSurah!))
        : null;

    final totalAyat = surahMeta?.ayahCount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSurah = null;
            _fromAyah = 1;
            _toAyah = 1;
            _syncControllers();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahMeta?.nameLatin ?? 'Pilih surah',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (totalAyat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$totalAyat ayat tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.swap_horiz, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyahInputs(int maxAyat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _AyahNumberField(
                label: 'Dari ayat',
                controller: _fromController,
                enabled: !_isLoading,
                maxAyat: maxAyat,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed == null) return;
                  final newFrom = parsed.clamp(1, maxAyat);
                  if (newFrom != _fromAyah) {
                    setState(() {
                      _fromAyah = newFrom;
                      if (_toAyah < _fromAyah) {
                        _toAyah = _fromAyah;
                        _toController.text = '$_toAyah';
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AyahNumberField(
                label: 'Sampai ayat',
                controller: _toController,
                enabled: !_isLoading,
                maxAyat: maxAyat,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed == null) return;
                  final newTo = parsed.clamp(1, maxAyat);
                  if (newTo != _toAyah) {
                    setState(() {
                      _toAyah = newTo;
                      if (_fromAyah > _toAyah) {
                        _fromAyah = _toAyah;
                        _fromController.text = '$_fromAyah';
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(
            _fromAyah.toDouble(),
            _toAyah.toDouble(),
          ),
          min: 1,
          max: maxAyat.toDouble(),
          divisions: maxAyat > 1 ? maxAyat - 1 : null,
          labels: RangeLabels('$_fromAyah', '$_toAyah'),
          onChanged: _isLoading
              ? null
              : (values) {
                  setState(() {
                    _fromAyah = values.start.round();
                    _toAyah = values.end.round();
                    _syncControllers();
                  });
                },
        ),
      ],
    );
  }

  Widget _buildQuickRangeChips(int maxAyat) {
    final remaining = maxAyat - _fromAyah + 1;
    final options = [
      {'label': '1 ayat', 'length': 1},
      {'label': '+5 ayat', 'length': 5},
      {'label': '+10 ayat', 'length': 10},
      {'label': 'Setengah surah', 'length': (maxAyat / 2).round()},
      {'label': 'Sampai akhir', 'length': remaining},
    ];
    final currentLength = _toAyah - _fromAyah + 1;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final label = option['label'] as String;
        final length = option['length'] as int;
        final targetLength = length.clamp(1, remaining);
        final targetTo = (_fromAyah + targetLength - 1).clamp(_fromAyah, maxAyat);
        return ChoiceChip(
          label: Text(label),
          selected: currentLength == targetLength && _toAyah == targetTo,
          onSelected: _isLoading
              ? null
              : (_) {
                  setState(() {
                    _toAyah = targetTo;
                    _syncControllers();
                  });
                },
        );
      }).toList(),
    );
  }

  void _syncControllers() {
    _fromController.value = TextEditingValue(
      text: '$_fromAyah',
      selection: TextSelection.collapsed(offset: '$_fromAyah'.length),
    );
    _toController.value = TextEditingValue(
      text: '$_toAyah',
      selection: TextSelection.collapsed(offset: '$_toAyah'.length),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Berhasil dicatat',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (_loggedLettersCount != null && _loggedHasanat != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildStatRow('Total huruf', '$_loggedLettersCount'),
                const SizedBox(height: 8),
                _buildStatRow('Estimasi hasanat', '$_loggedHasanat'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _AyahNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int maxAyat;
  final ValueChanged<String> onChanged;

  const _AyahNumberField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.maxAyat,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Maks $maxAyat',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}

