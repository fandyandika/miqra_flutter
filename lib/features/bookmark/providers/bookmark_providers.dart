import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/bookmark_service.dart';
import '../data/bookmark_hive.dart';

final foldersProvider = StreamProvider<List<BookmarkFolder>>((ref) async* {
  await BookmarkService.init();
  yield await BookmarkService.getFolders();
  
  final box = await Hive.openBox<BookmarkFolder>('bookmark_folders_v1');
  yield* box.watch().asyncMap((_) async => await BookmarkService.getFolders());
});

final bookmarksByFolderProvider = StreamProvider.family<List<BookmarkItem>, String>((ref, folderId) {
  return BookmarkService.watchBookmarksByFolder(folderId);
});

final surahProgressListProvider = StreamProvider<List<SurahProgress>>((ref) {
  return BookmarkService.watchSurahProgress();
});

