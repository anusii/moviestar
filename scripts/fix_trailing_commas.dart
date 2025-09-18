/// Script to fix missing trailing commas.
///
/// This script adds trailing commas where required by the Dart linter,
/// particularly focusing on test files where most violations occur.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 Trailing Comma Fix Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    // Process both lib and test directories since trailing comma issues appear in both
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    processDirectory(Directory('test'), stats, dryRun, verbose);

    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
    } else {
      print('\n✅ Trailing comma fixes completed!');
    }
  } catch (e) {
    print('❌ Error during fix: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int trailingCommasAdded = 0;
  List<String> modifiedFiles = [];
}

void processDirectory(Directory dir, CleanupStats stats, bool dryRun, bool verbose) {
  if (!dir.existsSync()) return;

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
  int commasAdded = 0;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final result = processLine(line, i, lines, file.path);

    if (result.modified) {
      modifiedLines.add(result.newLine);
      fileModified = true;
      commasAdded++;

      if (verbose) {
        print('  Line ${i + 1}: Added trailing comma');
        print('    Before: ${line.trim()}');
        print('    After:  ${result.newLine.trim()}');
      }
    } else {
      modifiedLines.add(line);
    }
  }

  if (fileModified) {
    stats.filesModified++;
    stats.trailingCommasAdded += commasAdded;
    stats.modifiedFiles.add(file.path);

    if (!dryRun) {
      createBackup(file);
      file.writeAsStringSync(modifiedLines.join('\n'));
    }

    if (verbose) {
      print('📝 Modified: ${file.path} (${commasAdded} commas added)');
    }
  }
}

class LineProcessResult {
  final bool modified;
  final String newLine;

  LineProcessResult(this.modified, this.newLine);
}

LineProcessResult processLine(String line, int lineIndex, List<String> allLines, String filePath) {
  final trimmed = line.trim();

  // Based on the specific flutter analyze errors, look for patterns that need trailing commas
  if (needsTrailingComma(trimmed, lineIndex, allLines, filePath)) {
    final newLine = addTrailingComma(line);
    return LineProcessResult(true, newLine);
  }

  return LineProcessResult(false, line);
}

bool needsTrailingComma(String line, int lineIndex, List<String> allLines, String filePath) {
  // Skip if line already has a trailing comma
  if (line.endsWith(',')) return false;

  // Skip if line ends with a semicolon (statement end)
  if (line.endsWith(';')) return false;

  // Skip if line ends with opening brace
  if (line.endsWith('{')) return false;

  // Based on the specific locations from flutter analyze output
  final normalizedPath = filePath.replaceAll('\\', '/');

  // Check specific patterns from the analyze output
  if (shouldAddTrailingCommaForSpecificCase(line, lineIndex, allLines, normalizedPath)) {
    return true;
  }

  // General patterns that typically need trailing commas
  if (isParameterOrArgumentLine(line, lineIndex, allLines)) {
    return true;
  }

  return false;
}

bool shouldAddTrailingCommaForSpecificCase(String line, int lineIndex, List<String> allLines, String filePath) {
  // Specific cases from flutter analyze output
  final specificCases = [
    // test/screens/movie_details_screen_test.dart:103:36
    'test/screens/movie_details_screen_test.dart',
    // test/screens/settings_screen_test.dart cases
    'test/screens/settings_screen_test.dart',
    // test/services/pod_favorites_service_test.dart:33:63
    'test/services/pod_favorites_service_test.dart',
    // test/services/pod_operations_mixin_test.dart cases
    'test/services/pod_operations_mixin_test.dart',
    // test/widgets/movie_kanban_board_test.dart cases
    'test/widgets/movie_kanban_board_test.dart',
  ];

  if (!specificCases.any((path) => filePath.endsWith(path))) {
    return false;
  }

  // Look for function call patterns that need trailing commas
  final patterns = [
    RegExp(r'\)\s*$'),  // Line ends with closing parenthesis
    RegExp(r'>\s*$'),   // Line ends with closing angle bracket (generics)
    RegExp(r']\s*$'),   // Line ends with closing square bracket
  ];

  // Check if this line needs a trailing comma based on the next line
  if (lineIndex + 1 < allLines.length) {
    final nextLine = allLines[lineIndex + 1].trim();

    // If next line starts with closing paren/bracket and current line doesn't end with comma
    if ((nextLine.startsWith(')') || nextLine.startsWith(']') || nextLine.startsWith('}'))) {
      return patterns.any((pattern) => pattern.hasMatch(line));
    }
  }

  return false;
}

bool isParameterOrArgumentLine(String line, int lineIndex, List<String> allLines) {
  // Check if this looks like a parameter or argument that should have a trailing comma

  // Look for widget properties or method arguments
  final argumentPatterns = [
    RegExp(r':\s*\w+\([^)]*\)\s*$'),        // Property with widget constructor
    RegExp(r':\s*\[.*\]\s*$'),              // Property with list
    RegExp(r':\s*\{.*\}\s*$'),              // Property with map
    RegExp(r':\s*[^,;]+\s*$'),              // Property with value
  ];

  if (argumentPatterns.any((pattern) => pattern.hasMatch(line))) {
    // Check if the next line suggests this is inside a parameter list
    if (lineIndex + 1 < allLines.length) {
      final nextLine = allLines[lineIndex + 1].trim();

      // If next line is a closing paren/bracket or another parameter
      if (nextLine.startsWith(')') ||
          nextLine.startsWith(']') ||
          nextLine.startsWith('}') ||
          nextLine.contains(':')) {
        return true;
      }
    }
  }

  return false;
}

String addTrailingComma(String line) {
  final trimmed = line.trimRight();
  final leadingSpaces = line.substring(0, line.length - line.trimLeft().length);

  return leadingSpaces + trimmed.trimRight() + ',';
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
  print('  Trailing commas added: ${stats.trailingCommasAdded}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }
}