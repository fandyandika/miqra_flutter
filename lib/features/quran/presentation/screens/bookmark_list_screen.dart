import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../bookmark/providers/bookmark_providers.dart';
import '../../../bookmark/presentation/bookmark_folder_detail_screen.dart';
import '../../providers/surah_providers.dart';

class BookmarkListScreen extends ConsumerStatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  ConsumerState<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends ConsumerState<BookmarkListScreen> {
  int _selectedIndex = 0;

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'hari ini';
    } else if (difference.inDays == 1) {
      return 'kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Segmented control
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Bookmark')),
              ButtonSegment(value: 1, label: Text('Riwayat')),
            ],
            selected: {_selectedIndex},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedIndex = newSelection.first;
              });
            },
          ),
        ),
        // Content
        Expanded(
          child: _selectedIndex == 0
              ? _BookmarkView(formatRelativeDate: _formatRelativeDate)
              : _RiwayatView(formatRelativeDate: _formatRelativeDate),
        ),
      ],
    );
  }
}

class _BookmarkView extends ConsumerWidget {
  final String Function(DateTime) formatRelativeDate;

  const _BookmarkView({required this.formatRelativeDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada folder bookmark',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: folders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return ref.watch(bookmarksByFolderProvider(folder.id)).when(
              data: (items) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: miqraPrimary.withValues(alpha: 0.1),
                    child: Icon(Icons.folder, color: miqraPrimary),
                  ),
                  title: Text(folder.name),
                  subtitle: Text('${items.length} ayat'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookmarkFolderDetailScreen(
                          folderId: folder.id,
                          folderName: folder.name,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListTile(
                leading: CircleAvatar(
                  backgroundColor: miqraPrimary.withOpacity(0.1),
                  child: Icon(Icons.folder, color: miqraPrimary),
                ),
                title: Text(folder.name),
                subtitle: const Text('Memuat...'),
              ),
              error: (error, _) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: miqraPrimary.withOpacity(0.1),
                  child: Icon(Icons.folder, color: miqraPrimary),
                ),
                title: Text(folder.name),
                subtitle: const Text('Error'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

class _RiwayatView extends ConsumerWidget {
  final String Function(DateTime) formatRelativeDate;

  const _RiwayatView({required this.formatRelativeDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(surahProgressListProvider);

    return progressAsync.when(
      data: (progressList) {
        if (progressList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: progressList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final progress = progressList[index];
            final surahMeta = ref.watch(surahMetaProvider(progress.surahNumber));

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: miqraCoral.withValues(alpha: 0.1),
                child: Text(
                  '${progress.surahNumber}',
                  style: TextStyle(color: miqraCoral, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                surahMeta?.nameLatin ?? 'Surah ${progress.surahNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Terakhir di ayat ${progress.lastAyah} – ${formatRelativeDate(progress.updatedAt)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.go('/read/surah/${progress.surahNumber}?ayat=${progress.lastAyah}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
