/// Script to fix comment formatting issues.
///
/// This script ensures:
/// - All comment blocks end with full stops
/// - Proper spacing between comment blocks and code
/// - Consistent documentation comment formatting
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 Comment Formatting Fix Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    processDirectory(Directory('test'), stats, dryRun, verbose);
    processDirectory(Directory('scripts'), stats, dryRun, verbose);

    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
    } else {
      print('\n✅ Comment formatting fixes completed!');
    }
  } catch (e) {
    print('❌ Error during fix: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int periodsAdded = 0;
  int spacingFixed = 0;
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
  ];

  return excludePatterns.any((pattern) => path.contains(pattern));
}

void processFile(File file, CleanupStats stats, bool dryRun, bool verbose) {
  stats.filesProcessed++;

  final originalContent = file.readAsStringSync();
  final lines = originalContent.split('\n');
  final fixedLines = <String>[];
  bool fileModified = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final fixResult = fixCommentLine(line, i, lines, stats);

    if (fixResult.wasModified) {
      fixedLines.addAll(fixResult.newLines);
      fileModified = true;

      if (verbose) {
        print('  Line ${i + 1}: ${fixResult.changeDescription}');
      }
    } else {
      fixedLines.add(line);
    }
  }

  if (fileModified) {
    stats.filesModified++;
    stats.modifiedFiles.add(file.path);

    if (!dryRun) {
      createBackup(file);
      file.writeAsStringSync(fixedLines.join('\n'));
    }

    if (verbose) {
      print('📝 Fixed comments in: ${file.path}');
    }
  }
}

class CommentFixResult {
  final bool wasModified;
  final List<String> newLines;
  final String? changeDescription;

  CommentFixResult(this.wasModified, this.newLines, [this.changeDescription]);
}

CommentFixResult fixCommentLine(String line, int lineIndex, List<String> allLines, CleanupStats stats) {
  final trimmed = line.trim();

  // Handle documentation comments (///)
  if (trimmed.startsWith('///')) {
    return fixDocumentationComment(line, lineIndex, allLines, stats);
  }

  // Handle single-line comments (//)
  if (trimmed.startsWith('//') && !trimmed.startsWith('///')) {
    return fixSingleLineComment(line, lineIndex, allLines, stats);
  }

  return CommentFixResult(false, [line]);
}

CommentFixResult fixDocumentationComment(String line, int lineIndex, List<String> allLines, CleanupStats stats) {
  final trimmed = line.trim();

  // Skip empty comment lines, copyright lines, or lines that already end with punctuation
  if (trimmed == '///' ||
      trimmed.contains('Copyright') ||
      trimmed.contains('License') ||
      trimmed.contains('http') ||
      trimmed.contains('@') ||
      endsWithPunctuation(trimmed)) {

    // Check if we need to add spacing after this comment block
    return checkAndAddSpacing(line, lineIndex, allLines, stats);
  }

  // Add period to comment lines that need it
  if (needsPeriod(trimmed)) {
    final fixed = addPeriodToComment(line);
    stats.periodsAdded++;

    // Also check for spacing after fixing the period
    final spacingResult = checkAndAddSpacing(fixed, lineIndex, allLines, stats);
    if (spacingResult.wasModified) {
      return CommentFixResult(true, spacingResult.newLines, 'Added period and fixed spacing');
    }

    return CommentFixResult(true, [fixed], 'Added period');
  }

  // Just check spacing
  return checkAndAddSpacing(line, lineIndex, allLines, stats);
}

CommentFixResult fixSingleLineComment(String line, int lineIndex, List<String> allLines, CleanupStats stats) {
  // For now, just handle spacing for single-line comments
  return checkAndAddSpacing(line, lineIndex, allLines, stats);
}

CommentFixResult checkAndAddSpacing(String line, int lineIndex, List<String> allLines, CleanupStats stats) {
  // Check if this is the end of a comment block and needs spacing
  if (isEndOfCommentBlock(lineIndex, allLines)) {
    final nextLineIndex = lineIndex + 1;
    if (nextLineIndex < allLines.length) {
      final nextLine = allLines[nextLineIndex].trim();

      // If next line is not empty and not a comment, add spacing
      if (nextLine.isNotEmpty &&
          !nextLine.startsWith('//') &&
          !nextLine.startsWith('library') &&
          !nextLine.startsWith('import') &&
          !nextLine.startsWith('export')) {

        stats.spacingFixed++;
        return CommentFixResult(true, [line, ''], 'Added spacing after comment block');
      }
    }
  }

  return CommentFixResult(false, [line]);
}

bool endsWithPunctuation(String line) {
  final punctuation = ['.', '!', '?', ':', ';', ')', ']', '}'];
  return punctuation.any((p) => line.endsWith(p));
}

bool needsPeriod(String commentLine) {
  final content = commentLine.replaceFirst('///', '').trim();

  // Skip if empty or very short
  if (content.length < 3) return false;

  // Skip if it's a code example or contains special characters
  if (content.contains('(') ||
      content.contains('[') ||
      content.contains('{') ||
      content.contains('`') ||
      content.contains('=') ||
      content.contains('<') ||
      content.contains('>')) {
    return false;
  }

  // Skip if it's a list item or bullet point
  if (content.startsWith('- ') ||
      content.startsWith('* ') ||
      RegExp(r'^\d+\.').hasMatch(content)) {
    return false;
  }

  // Add period if it looks like a sentence and doesn't end with punctuation
  return content.length > 5 && !endsWithPunctuation(commentLine);
}

String addPeriodToComment(String line) {
  return line.trimRight() + '.';
}

bool isEndOfCommentBlock(int lineIndex, List<String> allLines) {
  // Check if current line is a comment
  final currentLine = allLines[lineIndex].trim();
  if (!currentLine.startsWith('//')) return false;

  // Check if next line is not a comment (or end of file)
  if (lineIndex + 1 >= allLines.length) return true;

  final nextLine = allLines[lineIndex + 1].trim();
  return !nextLine.startsWith('//');
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
  print('  Periods added: ${stats.periodsAdded}');
  print('  Spacing fixes: ${stats.spacingFixed}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }

  print('\n💡 Comments now have proper punctuation and spacing');
  print('   Documentation will be more consistent and readable');
}