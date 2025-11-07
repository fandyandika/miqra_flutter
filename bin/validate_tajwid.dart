import 'dart:io';

/// Runner script for tajwid validation.
/// 
/// Validates tajwid spans for surah 001 and optionally 002:282.
void main(List<String> args) async {
  final projectRoot = Directory.current;
  final toolPath = '${projectRoot.path}/tool/tajwid_validator.dart';
  final sqlPath = '${projectRoot.path}/assets/data/quran/quran-indonesia.sql';

  // Validate 001
  print('Validating surah 001...');
  final tajwid001 = '${projectRoot.path}/assets/data/tajwid/001.json';
  
  final result001 = await Process.run(
    'dart',
    [toolPath, tajwid001, sqlPath],
    runInShell: true,
  );

  print(result001.stdout);
  if (result001.stderr.isNotEmpty) {
    print('Errors: ${result001.stderr}');
  }

  if (result001.exitCode != 0) {
    exit(result001.exitCode);
  }

  // Check for 002_282.json if present
  final tajwid002282 = '${projectRoot.path}/assets/data/tajwid/002_282.json';
  if (await File(tajwid002282).exists()) {
    print('\nValidating surah 002:282...');
    final result002 = await Process.run(
      'dart',
      [toolPath, tajwid002282, sqlPath],
      runInShell: true,
    );

    print(result002.stdout);
    if (result002.stderr.isNotEmpty) {
      print('Errors: ${result002.stderr}');
    }

    if (result002.exitCode != 0) {
      exit(result002.exitCode);
    }
  } else {
    print('\n002_282.json not found, skipping...');
  }

  print('\n✓ All validations passed');
}

