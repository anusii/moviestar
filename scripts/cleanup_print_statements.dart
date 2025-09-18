/// Script to clean up print statements and non-error debug prints.
///
/// This script removes:
/// - All print() statements (flagged by avoid_print linter)
/// - Non-error debugPrint() statements (✅, 🎬, ⚠️ prefixed)
/// - General info debugPrint() calls
///
/// Preserves:
/// - Error debugPrint() statements (❌ prefixed)
/// - Critical warning debugPrint() statements
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 Print Statement Cleanup Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
    } else {
      print('\n✅ Print statement cleanup completed!');
    }
  } catch (e) {
    print('❌ Error during cleanup: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int printStatementsRemoved = 0;
  int debugPrintsRemoved = 0;
  int debugPrintsPreserved = 0;
  List<String> modifiedFiles = [];
}

void processDirectory(Directory dir, CleanupStats stats, bool dryRun, bool verbose) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip generated files and test files
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
  final lines = originalContent.split('\n');
  final modifiedLines = <String>[];
  bool fileModified = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final result = processLine(line, i + 1, file.path, stats, verbose);

    if (result.shouldRemove) {
      fileModified = true;
      if (verbose) {
        print('  Removing line ${i + 1}: ${line.trim()}');
      }
    } else {
      modifiedLines.add(line);
    }
  }

  if (fileModified) {
    stats.filesModified++;
    stats.modifiedFiles.add(file.path);

    if (!dryRun) {
      createBackup(file);
      file.writeAsStringSync(modifiedLines.join('\n'));
    }

    if (verbose) {
      print('📝 Modified: ${file.path}');
    }
  }
}

class LineProcessResult {
  final bool shouldRemove;
  final String? reason;

  LineProcessResult(this.shouldRemove, [this.reason]);
}

LineProcessResult processLine(String line, int lineNumber, String filePath, CleanupStats stats, bool verbose) {
  final trimmed = line.trim();

  // Remove print() statements
  if (isPrintStatement(trimmed)) {
    stats.printStatementsRemoved++;
    return LineProcessResult(true, 'print statement');
  }

  // Handle debugPrint statements
  if (isDebugPrintStatement(trimmed)) {
    if (shouldPreserveDebugPrint(trimmed)) {
      stats.debugPrintsPreserved++;
      return LineProcessResult(false, 'preserved error/critical debug print');
    } else {
      stats.debugPrintsRemoved++;
      return LineProcessResult(true, 'non-error debug print');
    }
  }

  return LineProcessResult(false);
}

bool isPrintStatement(String line) {
  // Match print() calls
  final printRegex = RegExp(r'^\s*print\s*\(');
  return printRegex.hasMatch(line);
}

bool isDebugPrintStatement(String line) {
  // Match debugPrint() calls
  final debugPrintRegex = RegExp(r'^\s*debugPrint\s*\(');
  return debugPrintRegex.hasMatch(line);
}

bool shouldPreserveDebugPrint(String line) {
  // Preserve error messages (❌) and critical warnings
  final preservePatterns = [
    r'❌',           // Error messages
    r'Error\b',      // Contains "Error"
    r'Exception\b',  // Contains "Exception"
    r'Failed\b',     // Contains "Failed"
    r'Critical\b',   // Contains "Critical"
  ];

  return preservePatterns.any((pattern) => RegExp(pattern).hasMatch(line));
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
  print('📊 Cleanup Statistics:');
  print('  Files processed: ${stats.filesProcessed}');
  print('  Files modified: ${stats.filesModified}');
  print('  Print statements removed: ${stats.printStatementsRemoved}');
  print('  Debug prints removed: ${stats.debugPrintsRemoved}');
  print('  Debug prints preserved: ${stats.debugPrintsPreserved}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }
}