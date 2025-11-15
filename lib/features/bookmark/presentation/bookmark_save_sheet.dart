import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../quran/data/models/surah_model.dart';
import '../providers/bookmark_providers.dart';
import '../data/bookmark_service.dart';

class BookmarkSaveSheet extends ConsumerStatefulWidget {
  final Verse verse;
  final int surahNumber;

  const BookmarkSaveSheet({
    super.key,
    required this.verse,
    required this.surahNumber,
  });

  @override
  ConsumerState<BookmarkSaveSheet> createState() => _BookmarkSaveSheetState();
}

class _BookmarkSaveSheetState extends ConsumerState<BookmarkSaveSheet> {
  String? _selectedFolderId;
  final _folderNameController = TextEditingController();

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final name = _folderNameController.text.trim();
    if (name.isEmpty) return;

    await BookmarkService.createFolder(name);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder berhasil dibuat')),
      );
    }
  }

  Future<void> _showCreateFolderDialog() async {
    _folderNameController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Folder Baru'),
        content: TextField(
          controller: _folderNameController,
          decoration: const InputDecoration(
            labelText: 'Nama folder',
            hintText: 'Contoh: Doa & Dzikir',
          ),
          autofocus: true,
          onSubmitted: (_) => _createFolder(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createFolder();
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBookmark() async {
    if (_selectedFolderId == null) return;

    final snippet = widget.verse.textId.length > 50
        ? '${widget.verse.textId.substring(0, 50)}...'
        : widget.verse.textId;

    await BookmarkService.addBookmark(
      folderId: _selectedFolderId!,
      surah: widget.surahNumber,
      ayah: widget.verse.ayah,
      snippet: snippet,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark berhasil disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.verse.textAr,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'IndopakNastaleeq',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.verse.textId,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Folder list
          foldersAsync.when(
            data: (folders) {
              if (folders.isEmpty) {
                return Column(
                  children: [
                    const Text('Belum ada folder'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showCreateFolderDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('+ Folder baru'),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pilih folder:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...folders.map((folder) => RadioListTile<String>(
                    title: Text(folder.name),
                    value: folder.id,
                    groupValue: _selectedFolderId,
                    onChanged: (value) {
                      setState(() {
                        _selectedFolderId = value;
                      });
                    },
                  )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showCreateFolderDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('+ Folder baru'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error memuat folder'),
          ),
          const SizedBox(height: 16),
          // Save button
          ElevatedButton(
            onPressed: _selectedFolderId == null ? null : _saveBookmark,
            child: const Text('Simpan Bookmark'),
          ),
        ],
      ),
    );
  }
}

