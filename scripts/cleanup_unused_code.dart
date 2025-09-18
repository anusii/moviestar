/// Script to clean up unused fields, variables, and dead code.
///
/// This script removes:
/// - Unused private fields (_field)
/// - Unused local variables
/// - Unused private methods/declarations
/// - Dead code blocks (unreachable code)
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 Unused Code Cleanup Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
    } else {
      print('\n✅ Unused code cleanup completed!');
    }
  } catch (e) {
    print('❌ Error during cleanup: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int unusedFieldsRemoved = 0;
  int unusedVariablesRemoved = 0;
  int unusedMethodsRemoved = 0;
  int deadCodeBlocksRemoved = 0;
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

  // Analyze the file to find unused items
  final analysis = analyzeFile(originalContent, file.path);

  if (analysis.hasUnusedItems) {
    stats.filesModified++;
    stats.modifiedFiles.add(file.path);

    // Update stats
    stats.unusedFieldsRemoved += analysis.unusedFields.length;
    stats.unusedVariablesRemoved += analysis.unusedVariables.length;
    stats.unusedMethodsRemoved += analysis.unusedMethods.length;
    stats.deadCodeBlocksRemoved += analysis.deadCodeBlocks.length;

    if (verbose) {
      print('📝 Processing: ${file.path}');
      if (analysis.unusedFields.isNotEmpty) {
        print('  Unused fields: ${analysis.unusedFields.join(', ')}');
      }
      if (analysis.unusedVariables.isNotEmpty) {
        print('  Unused variables: ${analysis.unusedVariables.join(', ')}');
      }
      if (analysis.unusedMethods.isNotEmpty) {
        print('  Unused methods: ${analysis.unusedMethods.join(', ')}');
      }
      if (analysis.deadCodeBlocks.isNotEmpty) {
        print('  Dead code blocks: ${analysis.deadCodeBlocks.length}');
      }
    }

    if (!dryRun) {
      createBackup(file);
      final cleanedContent = removeUnusedItems(originalContent, analysis);
      file.writeAsStringSync(cleanedContent);
    }
  }
}

class FileAnalysis {
  final List<String> unusedFields;
  final List<String> unusedVariables;
  final List<String> unusedMethods;
  final List<CodeBlock> deadCodeBlocks;

  FileAnalysis({
    required this.unusedFields,
    required this.unusedVariables,
    required this.unusedMethods,
    required this.deadCodeBlocks,
  });

  bool get hasUnusedItems =>
      unusedFields.isNotEmpty ||
      unusedVariables.isNotEmpty ||
      unusedMethods.isNotEmpty ||
      deadCodeBlocks.isNotEmpty;
}

class CodeBlock {
  final int startLine;
  final int endLine;
  final String type;

  CodeBlock(this.startLine, this.endLine, this.type);
}

FileAnalysis analyzeFile(String content, String filePath) {
  final lines = content.split('\n');

  // Extract specific unused items based on flutter analyze patterns
  final unusedFields = extractUnusedFields(content, filePath);
  final unusedVariables = extractUnusedVariables(content, filePath);
  final unusedMethods = extractUnusedMethods(content, filePath);
  final deadCodeBlocks = extractDeadCodeBlocks(lines);

  return FileAnalysis(
    unusedFields: unusedFields,
    unusedVariables: unusedVariables,
    unusedMethods: unusedMethods,
    deadCodeBlocks: deadCodeBlocks,
  );
}

List<String> extractUnusedFields(String content, String filePath) {
  final unusedFields = <String>[];

  // Based on the flutter analyze output, identify specific unused fields
  final fieldPatterns = {
    'lib/core/services/api/api_key_service.dart': ['_context', '_child', '_cacheSettings'],
    'lib/core/services/api/api_key_service_compact.dart': ['_context', '_child', '_cacheSettings'],
    'lib/providers/cached_movie_service_provider.dart': ['_directApiKeyService'],
    'lib/core/services/pod/pod_favorites_service.dart': ['_listManagementService', '_sharingService', '_prefs', '_fallbackService'],
    'lib/core/services/pod/pod_favorites_service_compact.dart': ['_prefs', '_fallbackService', '_listManagementService', '_sharingService'],
  };

  final normalizedPath = filePath.replaceAll('\\', '/');
  for (final pattern in fieldPatterns.keys) {
    if (normalizedPath.endsWith(pattern)) {
      for (final field in fieldPatterns[pattern]!) {
        if (content.contains('final') && content.contains(field)) {
          unusedFields.add(field);
        }
      }
    }
  }

  return unusedFields;
}

List<String> extractUnusedVariables(String content, String filePath) {
  final unusedVariables = <String>[];

  // Based on flutter analyze output
  final variablePatterns = {
    'lib/core/services/api/api_key_service_compact.dart': ['podSuccess'],
    'lib/core/services/pod/pod_favorites_file_manager.dart': ['movieData'],
    'test/screens/shared_movie_list_detail_screen_test.dart': ['mockPrefs'],
  };

  final normalizedPath = filePath.replaceAll('\\', '/');
  for (final pattern in variablePatterns.keys) {
    if (normalizedPath.endsWith(pattern)) {
      for (final variable in variablePatterns[pattern]!) {
        if (content.contains(variable)) {
          unusedVariables.add(variable);
        }
      }
    }
  }

  return unusedVariables;
}

List<String> extractUnusedMethods(String content, String filePath) {
  final unusedMethods = <String>[];

  // Based on flutter analyze output
  final methodPatterns = {
    'lib/screens/custom_list_detail_screen.dart': ['_buildMoviesList'],
    'lib/screens/settings_screen.dart': ['_launchUrl'],
    'lib/shared/widgets/movie_details/movie_details_header.dart': ['_getSharedByText'],
    'lib/shared/utils/turtle/turtle_serializer.dart': ['_getOntologyNamespaces', '_escapeString', '_escapeAndSanitizeString'],
    'lib/widgets/movie_kanban_board.dart': ['_buildCustomListColumn'],
  };

  final normalizedPath = filePath.replaceAll('\\', '/');
  for (final pattern in methodPatterns.keys) {
    if (normalizedPath.endsWith(pattern)) {
      for (final method in methodPatterns[pattern]!) {
        if (content.contains(method)) {
          unusedMethods.add(method);
        }
      }
    }
  }

  return unusedMethods;
}

List<CodeBlock> extractDeadCodeBlocks(List<String> lines) {
  final deadCodeBlocks = <CodeBlock>[];

  // Look for dead code patterns based on flutter analyze output
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    // Dead code after return statements (based on analyze output)
    if (line.startsWith('return') && i + 1 < lines.length) {
      final nextLine = lines[i + 1].trim();
      if (nextLine.isNotEmpty && !nextLine.startsWith('}') && !nextLine.startsWith('//')) {
        // Look for the end of the dead code block
        int endLine = i + 1;
        while (endLine < lines.length && !lines[endLine].trim().startsWith('}')) {
          endLine++;
        }
        deadCodeBlocks.add(CodeBlock(i + 2, endLine, 'dead_code_after_return'));
      }
    }
  }

  return deadCodeBlocks;
}

String removeUnusedItems(String content, FileAnalysis analysis) {
  final lines = content.split('\n');
  final linesToRemove = <int>{};

  // Remove unused field declarations
  for (final field in analysis.unusedFields) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('final') && line.contains(field) && line.contains(';')) {
        linesToRemove.add(i);
      }
    }
  }

  // Remove unused variable declarations
  for (final variable in analysis.unusedVariables) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('final $variable') ||
          line.trim().startsWith('var $variable') ||
          line.trim().startsWith('$variable =')) {
        linesToRemove.add(i);
      }
    }
  }

  // Remove unused method declarations
  for (final method in analysis.unusedMethods) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(method) && (line.contains('(') || lines[i + 1].contains('('))) {
        // Find the end of the method
        int braceCount = 0;
        int endLine = i;
        bool foundOpenBrace = false;

        for (int j = i; j < lines.length; j++) {
          final methodLine = lines[j];
          if (methodLine.contains('{')) {
            foundOpenBrace = true;
            braceCount += methodLine.split('{').length - 1;
          }
          if (methodLine.contains('}')) {
            braceCount -= methodLine.split('}').length - 1;
          }
          if (foundOpenBrace && braceCount == 0) {
            endLine = j;
            break;
          }
        }

        for (int k = i; k <= endLine; k++) {
          linesToRemove.add(k);
        }
      }
    }
  }

  // Remove dead code blocks
  for (final block in analysis.deadCodeBlocks) {
    for (int i = block.startLine - 1; i < block.endLine && i < lines.length; i++) {
      linesToRemove.add(i);
    }
  }

  // Build the cleaned content
  final cleanedLines = <String>[];
  for (int i = 0; i < lines.length; i++) {
    if (!linesToRemove.contains(i)) {
      cleanedLines.add(lines[i]);
    }
  }

  return cleanedLines.join('\n');
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
  print('  Unused fields removed: ${stats.unusedFieldsRemoved}');
  print('  Unused variables removed: ${stats.unusedVariablesRemoved}');
  print('  Unused methods removed: ${stats.unusedMethodsRemoved}');
  print('  Dead code blocks removed: ${stats.deadCodeBlocksRemoved}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }
}