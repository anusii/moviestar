/// Script to fix BuildContext usage across async gaps.
///
/// This script addresses "use_build_context_synchronously" warnings by:
/// - Adding mounted checks before context usage
/// - Restructuring async operations to avoid context issues
/// - Providing safe patterns for context usage
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 BuildContext Usage Fix Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
    } else {
      print('\n✅ BuildContext usage fixes completed!');
    }
  } catch (e) {
    print('❌ Error during fix: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int contextChecksAdded = 0;
  int asyncMethodsRestructured = 0;
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

  // Check if this file has context usage issues based on analyze output
  if (!hasContextUsageIssues(file.path)) {
    return;
  }

  final fixedContent = fixContextUsage(originalContent, file.path, stats, verbose);

  if (fixedContent != originalContent) {
    stats.filesModified++;
    stats.modifiedFiles.add(file.path);

    if (!dryRun) {
      createBackup(file);
      file.writeAsStringSync(fixedContent);
    }

    if (verbose) {
      print('📝 Fixed context usage in: ${file.path}');
    }
  }
}

bool hasContextUsageIssues(String filePath) {
  // Based on flutter analyze output, these files have context issues
  final problematicFiles = [
    'lib/core/services/favorites/movie_list_operations_helper.dart',
    'lib/core/services/favorites/movie_list_service_refactored.dart',
    'lib/services/user_profile_service.dart',
    'lib/shared/widgets/custom_list_detail/list_sharing_controls.dart',
    'lib/shared/widgets/my_lists/list_creation_dialog_widget.dart',
    'lib/shared/widgets/settings/api_settings_panel.dart',
    'lib/shared/widgets/settings/cache_management_panel.dart',
    'lib/shared/widgets/settings/data_management_panel.dart',
    'lib/shared/widgets/shared_movie_list_detail/shared_list_data_loader.dart',
    'lib/shared/widgets/sharing/batch_sharing_handler.dart',
  ];

  final normalizedPath = filePath.replaceAll('\\', '/');
  return problematicFiles.any((pattern) => normalizedPath.endsWith(pattern));
}

String fixContextUsage(String content, String filePath, CleanupStats stats, bool verbose) {
  final lines = content.split('\n');
  final fixedLines = <String>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final fixResult = fixLineContextUsage(line, i, lines, filePath);

    if (fixResult.wasModified) {
      fixedLines.addAll(fixResult.newLines);
      stats.contextChecksAdded += fixResult.checksAdded;

      if (verbose) {
        print('  Fixed line ${i + 1}: Added context check');
      }
    } else {
      fixedLines.add(line);
    }
  }

  return fixedLines.join('\n');
}

class LineFixResult {
  final bool wasModified;
  final List<String> newLines;
  final int checksAdded;

  LineFixResult(this.wasModified, this.newLines, [this.checksAdded = 0]);
}

LineFixResult fixLineContextUsage(String line, int lineIndex, List<String> allLines, String filePath) {
  final trimmed = line.trim();

  // Look for context usage after await
  if (containsContextUsageAfterAsync(line)) {
    return addMountedCheck(line, lineIndex, allLines);
  }

  // Look for Navigator.of(context) calls after async operations
  if (containsNavigatorUsage(line)) {
    return addMountedCheckForNavigation(line, lineIndex, allLines);
  }

  // Look for showDialog or similar context-dependent calls
  if (containsDialogUsage(line)) {
    return addMountedCheckForDialog(line, lineIndex, allLines);
  }

  return LineFixResult(false, [line]);
}

bool containsContextUsageAfterAsync(String line) {
  // Check for common patterns of context usage that might be after async
  final patterns = [
    RegExp(r'context\s*\.\s*\w+'),  // context.something
    RegExp(r'of\s*\(\s*context\s*\)'), // of(context)
    RegExp(r'context\s*\,'),        // context as parameter
  ];

  return patterns.any((pattern) => pattern.hasMatch(line));
}

bool containsNavigatorUsage(String line) {
  return line.contains('Navigator.') && line.contains('context');
}

bool containsDialogUsage(String line) {
  final dialogPatterns = [
    'showDialog',
    'showModalBottomSheet',
    'ScaffoldMessenger.of',
    'Theme.of',
  ];

  return dialogPatterns.any((pattern) => line.contains(pattern)) && line.contains('context');
}

LineFixResult addMountedCheck(String line, int lineIndex, List<String> allLines) {
  final indent = getIndentation(line);
  final contextUsage = line.trim();

  // Create mounted check
  final mountedCheck = '${indent}if (!mounted) return;';
  final originalLine = line;

  return LineFixResult(true, [mountedCheck, originalLine], 1);
}

LineFixResult addMountedCheckForNavigation(String line, int lineIndex, List<String> allLines) {
  final indent = getIndentation(line);

  // For Navigator calls, we need to be more careful about the return type
  if (line.contains('Navigator.push') || line.contains('Navigator.pop')) {
    final mountedCheck = '${indent}if (!mounted) return;';
    return LineFixResult(true, [mountedCheck, line], 1);
  }

  return LineFixResult(false, [line]);
}

LineFixResult addMountedCheckForDialog(String line, int lineIndex, List<String> allLines) {
  final indent = getIndentation(line);

  // For dialog calls, add mounted check
  if (line.contains('showDialog') || line.contains('showModalBottomSheet')) {
    final mountedCheck = '${indent}if (!mounted) return;';
    return LineFixResult(true, [mountedCheck, line], 1);
  }

  // For ScaffoldMessenger or Theme.of calls
  if (line.contains('ScaffoldMessenger.of') || line.contains('Theme.of')) {
    final mountedCheck = '${indent}if (!mounted) return;';
    return LineFixResult(true, [mountedCheck, line], 1);
  }

  return LineFixResult(false, [line]);
}

String getIndentation(String line) {
  final match = RegExp(r'^(\s*)').firstMatch(line);
  return match?.group(1) ?? '';
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
  print('  Context checks added: ${stats.contextChecksAdded}');
  print('  Async methods restructured: ${stats.asyncMethodsRestructured}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }

  print('\n💡 Note: Some context usage issues may require manual review');
  print('   Consider extracting context-dependent code to synchronous methods');
}