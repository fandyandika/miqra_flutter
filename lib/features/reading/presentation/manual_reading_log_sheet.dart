import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reading_providers.dart';
import '../../quran/providers/surah_providers.dart';

/// Bottom sheet for manually logging a reading session.
class ManualReadingLogSheet extends ConsumerStatefulWidget {
  final int surahNumber;
  final int maxAyat;

  const ManualReadingLogSheet({
    super.key,
    required this.surahNumber,
    required this.maxAyat,
  });

  @override
  ConsumerState<ManualReadingLogSheet> createState() =>
      _ManualReadingLogSheetState();
}

class _ManualReadingLogSheetState
    extends ConsumerState<ManualReadingLogSheet> {
  int _fromAyah = 1;
  int _toAyah = 1;
  bool _isLoading = false;
  bool _isSuccess = false;
  int? _loggedLettersCount;
  int? _loggedHasanat;

  @override
  void initState() {
    super.initState();
    _toAyah = widget.maxAyat;
  }

  Future<void> _logReading() async {
    if (_isLoading) return;

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
        surahNumber: widget.surahNumber,
        ayahStart: _fromAyah,
        ayahEnd: _toAyah,
        readingMode: 'surah',
      );

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
    final surahMeta = ref.watch(surahMetaProvider(widget.surahNumber));

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dari ayat'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _fromAyah,
                    items: List.generate(
                      widget.maxAyat,
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
                  const Text('Sampai ayat'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _toAyah,
                    items: List.generate(
                      widget.maxAyat,
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

