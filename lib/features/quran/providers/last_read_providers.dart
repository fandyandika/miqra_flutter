import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/last_read_service.dart';
import '../data/last_read_hive.dart';

final lastReadProvider = StreamProvider<LastReadPosition?>((ref) {
  return LastReadService.watchLastRead();
});

final lastReadOnceProvider = Provider<LastReadPosition?>((ref) {
  return LastReadService.getLastRead();
});

