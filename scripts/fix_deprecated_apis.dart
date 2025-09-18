/// Script to fix deprecated API usage.
///
/// This script replaces deprecated API calls with their modern equivalents:
/// - Replace withOpacity() with withValues()
/// - Update other deprecated API calls as needed
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 Deprecated API Fix Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
    } else {
      print('\n✅ Deprecated API fixes completed!');
    }
  } catch (e) {
    print('❌ Error during fix: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int withOpacityFixed = 0;
  int otherDeprecatedFixed = 0;
  List<String> modifiedFiles = [];
}

void processDirectory(Directory dir, CleanupStats stats, bool dryRun, bool verbose) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (isExcludedFile(entity.path)) continue;
      processFile(entity, stats, dryRun, verbose);
    }
  }
}

bool isExcludedFile(String path) {
  final excludePatterns = [
    '.g.dart',
    '.gr.dart',
    '.freezed.dart',
    '.chopper.dart',
    '.part.dart',
    '.config.dart',
    'test/',
    'scripts/'
  ];

  return excludePatterns.any((pattern) => path.contains(pattern));
}

void processFile(File file, CleanupStats stats, bool dryRun, bool verbose) {
  stats.filesProcessed++;

  final originalContent = file.readAsStringSync();

  // Check if this file has deprecated API usage based on analyze output
  if (!hasDeprecatedApiUsage(file.path, originalContent)) {
    return;
  }

  final fixedContent = fixDeprecatedApis(originalContent, file.path, stats, verbose);

  if (fixedContent != originalContent) {
    stats.filesModified++;
    stats.modifiedFiles.add(file.path);

    if (!dryRun) {
      createBackup(file);
      file.writeAsStringSync(fixedContent);
    }

    if (verbose) {
      print('📝 Fixed deprecated APIs in: ${file.path}');
    }
  }
}

bool hasDeprecatedApiUsage(String filePath, String content) {
  // Based on flutter analyze output, these files have withOpacity issues
  final problematicFiles = [
    'lib/shared/widgets/kanban/kanban_search_filter.dart',
    'lib/shared/widgets/kanban/kanban_settings_panel.dart',
    'lib/shared/widgets/shared_movie_list_detail/shared_list_header_widget.dart',
    'lib/shared/widgets/shared_movie_list_detail/shared_list_movie_display.dart',
    'lib/shared/widgets/shared_movie_list_detail/shared_list_permissions_panel.dart',
  ];

  final normalizedPath = filePath.replaceAll('\\', '/');
  final isProblematicFile = problematicFiles.any((pattern) => normalizedPath.endsWith(pattern));

  // Also check if the content actually contains deprecated APIs
  final hasWithOpacity = content.contains('.withOpacity(');

  return isProblematicFile || hasWithOpacity;
}

String fixDeprecatedApis(String content, String filePath, CleanupStats stats, bool verbose) {
  String fixedContent = content;

  // Fix withOpacity() -> withValues()
  fixedContent = fixWithOpacityUsage(fixedContent, stats, verbose);

  // Add other deprecated API fixes here as needed

  return fixedContent;
}

String fixWithOpacityUsage(String content, CleanupStats stats, bool verbose) {
  // Pattern to match .withOpacity(value) calls
  final withOpacityPattern = RegExp(r'\.withOpacity\s*\(\s*([^)]+)\s*\)');

  return content.replaceAllMapped(withOpacityPattern, (match) {
    final opacityValue = match.group(1)!.trim();
    stats.withOpacityFixed++;

    if (verbose) {
      print('  Replacing .withOpacity($opacityValue) with .withValues(alpha: $opacityValue)');
    }

    // Convert to withValues format
    return '.withValues(alpha: $opacityValue)';
  });
}

void createBackup(File file) {
  final backupDir = Directory('scripts/backups');
  if (!backupDir.existsSync()) {
    backupDir.createSync(recursive: true);
  }

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = file.path.split('/').last;
  final backupPath = 'scripts/backups/${fileName}_$timestamp.backup';

  file.copySync(backupPath);
}

void printStats(CleanupStats stats) {
  print('📊 Fix Statistics:');
  print('  Files processed: ${stats.filesProcessed}');
  print('  Files modified: ${stats.filesModified}');
  print('  withOpacity() calls fixed: ${stats.withOpacityFixed}');
  print('  Other deprecated APIs fixed: ${stats.otherDeprecatedFixed}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }

  print('\n💡 withOpacity() has been replaced with withValues(alpha: value)');
  print('   This maintains the same visual behavior with the updated API');
}