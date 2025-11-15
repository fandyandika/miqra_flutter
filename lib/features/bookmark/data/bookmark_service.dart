import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'bookmark_hive.dart';

class BookmarkService {
  static const String _foldersBoxName = 'bookmark_folders_v1';
  static const String _itemsBoxName = 'bookmark_items_v1';
  static const String _progressBoxName = 'surah_progress_v1';
  static const _uuid = Uuid();

  static Box<BookmarkFolder>? _foldersBox;
  static Box<BookmarkItem>? _itemsBox;
  static Box<SurahProgress>? _progressBox;

  static Future<void> init() async {
    _foldersBox ??= await Hive.openBox<BookmarkFolder>(_foldersBoxName);
    _itemsBox ??= await Hive.openBox<BookmarkItem>(_itemsBoxName);
    _progressBox ??= await Hive.openBox<SurahProgress>(_progressBoxName);
  }

  static Future<List<BookmarkFolder>> getFolders() async {
    if (_foldersBox == null) await init();
    return _foldersBox!.values.toList();
  }

  static Future<void> createFolder(String name) async {
    if (_foldersBox == null) await init();
    final folder = BookmarkFolder(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _foldersBox!.put(folder.id, folder);
  }

  static Future<void> deleteFolder(String folderId) async {
    if (_foldersBox == null) await init();
    if (_itemsBox == null) await init();
    
    // Delete all items in this folder
    final itemsToDelete = _itemsBox!.values
        .where((item) => item.folderId == folderId)
        .map((item) => item.id)
        .toList();
    
    for (final itemId in itemsToDelete) {
      await _itemsBox!.delete(itemId);
    }
    
    // Delete folder
    await _foldersBox!.delete(folderId);
  }

  static Future<void> addBookmark({
    required String folderId,
    required int surah,
    required int ayah,
    required String snippet,
  }) async {
    if (_itemsBox == null) await init();
    final item = BookmarkItem(
      id: _uuid.v4(),
      folderId: folderId,
      surahNumber: surah,
      ayahNumber: ayah,
      snippet: snippet,
      createdAt: DateTime.now(),
    );
    await _itemsBox!.put(item.id, item);
  }

  static Stream<List<BookmarkItem>> watchBookmarksByFolder(String folderId) async* {
    if (_itemsBox == null) await init();
    
    final items = _itemsBox!.values
        .where((item) => item.folderId == folderId)
        .toList();
    yield items;
    
    yield* _itemsBox!.watch().map((event) {
      return _itemsBox!.values
          .where((item) => item.folderId == folderId)
          .toList();
    });
  }

  static Stream<List<SurahProgress>> watchSurahProgress() async* {
    if (_progressBox == null) await init();
    
    final progress = _progressBox!.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    yield progress;
    
    yield* _progressBox!.watch().map((event) {
      final progress = _progressBox!.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return progress;
    });
  }

  static Future<void> updateSurahProgress(int surah, int ayah) async {
    if (_progressBox == null) await init();
    
    final key = 'surah_$surah';
    final progress = SurahProgress(
      surahNumber: surah,
      lastAyah: ayah,
      updatedAt: DateTime.now(),
    );
    await _progressBox!.put(key, progress);
  }
}

