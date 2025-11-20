import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../providers/bookmark_providers.dart';
import '../../quran/providers/surah_providers.dart';

class BookmarkFolderDetailScreen extends ConsumerWidget {
  final String folderId;
  final String folderName;

  const BookmarkFolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksByFolderProvider(folderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
      ),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada bookmark di folder ini',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              final surahMeta = ref.watch(surahMetaProvider(bookmark.surahNumber));

              return Card(
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: miqraPrimary.withValues(alpha: 0.1),
                    child: Text(
                      '${bookmark.surahNumber}:${bookmark.ayahNumber}',
                      style: TextStyle(
                        color: miqraPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${surahMeta?.nameLatin ?? 'Surah ${bookmark.surahNumber}'} - Ayat ${bookmark.ayahNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        bookmark.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeDate(bookmark.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.go('/read/surah/${bookmark.surahNumber}?ayat=${bookmark.ayahNumber}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

