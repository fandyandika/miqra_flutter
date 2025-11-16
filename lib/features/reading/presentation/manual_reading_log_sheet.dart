import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/reading_providers.dart';
import '../../quran/providers/surah_providers.dart';

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
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dari ayat',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _fromAyah,
                    items: List.generate(
                      maxAyat,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _fromAyah = value;
                                if (_toAyah < _fromAyah) {
                                  _toAyah = _fromAyah;
                                }
                              });
                            }
                          },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sampai ayat',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _toAyah,
                    items: List.generate(
                      maxAyat,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _toAyah = value;
                                if (_fromAyah > _toAyah) {
                                  _fromAyah = _toAyah;
                                }
                              });
                            }
                          },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Ayat yang dicatat: ${_getAyatCount()} ayat',
            style: const TextStyle(fontWeight: FontWeight.w500),
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
        // Surah list
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: surahListAsync.when(
            data: (_) => filteredSurahs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada surah ditemukan'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final surah = filteredSurahs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${surah.number}'),
                        ),
                        title: Text(surah.nameLatin),
                        subtitle: Text(
                          '${surah.ayahCount} ayat • ${surah.place}',
                        ),
                        trailing: Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'QuranCommon',
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedSurah = surah.number;
                            _fromAyah = 1;
                            _toAyah = surah.ayahCount;
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

  Widget _buildSurahSelector() {
    final surahMeta = _selectedSurah != null
        ? ref.watch(surahMetaProvider(_selectedSurah!))
        : null;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSurah = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Surah',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    surahMeta?.nameLatin ?? 'Pilih surah',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 20),
          ],
        ),
      ),
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

