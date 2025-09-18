/// Script to fix compilation errors.
///
/// This script addresses specific compilation errors identified by flutter analyze:
/// - Missing method implementations (escapeString, retryOperation, etc.)
/// - Constructor parameter mismatches
/// - Missing required parameters
/// - Type argument issues
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run') || args.contains('-d');
  final verbose = args.contains('--verbose') || args.contains('-v');

  print('🧹 Compilation Error Fix Tool');
  print('Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}');
  print('');

  final stats = CleanupStats();

  try {
    processDirectory(Directory('lib'), stats, dryRun, verbose);
    printStats(stats);

    if (dryRun) {
      print('\n💡 Run without --dry-run to apply changes');
      print('⚠️  Some fixes may require manual review');
    } else {
      print('\n✅ Compilation error fixes completed!');
      print('⚠️  Please run flutter analyze to verify all errors are resolved');
    }
  } catch (e) {
    print('❌ Error during fix: $e');
    exit(1);
  }
}

class CleanupStats {
  int filesProcessed = 0;
  int filesModified = 0;
  int missingMethodsFixed = 0;
  int constructorIssuesFixed = 0;
  int parameterIssuesFixed = 0;
  int typeIssuesFixed = 0;
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

  // Check if this file has compilation errors based on analyze output
  if (!hasCompilationErrors(file.path)) {
    return;
  }

  final fixedContent = fixCompilationErrors(originalContent, file.path, stats, verbose);

  if (fixedContent != originalContent) {
    stats.filesModified++;
    stats.modifiedFiles.add(file.path);

    if (!dryRun) {
      createBackup(file);
      file.writeAsStringSync(fixedContent);
    }

    if (verbose) {
      print('📝 Fixed compilation errors in: ${file.path}');
    }
  }
}

bool hasCompilationErrors(String filePath) {
  // Based on flutter analyze output, these files have compilation errors
  final problematicFiles = [
    'lib/core/services/favorites/movie_list_service_compact.dart',
    'lib/core/services/pod/pod_favorites_service_compact.dart',
    'lib/shared/utils/turtle/movie_serializers.dart',
    'lib/shared/utils/turtle/rating_comment_serializers.dart',
    'lib/shared/utils/turtle/user_profile_serializers.dart',
    'lib/shared/widgets/sharing/batch_sharing_handler.dart',
  ];

  final normalizedPath = filePath.replaceAll('\\', '/');
  return problematicFiles.any((pattern) => normalizedPath.endsWith(pattern));
}

String fixCompilationErrors(String content, String filePath, CleanupStats stats, bool verbose) {
  String fixedContent = content;
  final normalizedPath = filePath.replaceAll('\\', '/');

  // Fix specific files based on flutter analyze errors
  if (normalizedPath.endsWith('lib/core/services/favorites/movie_list_service_compact.dart')) {
    fixedContent = fixMovieListServiceCompactErrors(fixedContent, stats, verbose);
  }

  if (normalizedPath.endsWith('lib/core/services/pod/pod_favorites_service_compact.dart')) {
    fixedContent = fixPodFavoritesServiceCompactErrors(fixedContent, stats, verbose);
  }

  if (normalizedPath.endsWith('lib/shared/utils/turtle/movie_serializers.dart') ||
      normalizedPath.endsWith('lib/shared/utils/turtle/rating_comment_serializers.dart') ||
      normalizedPath.endsWith('lib/shared/utils/turtle/user_profile_serializers.dart')) {
    fixedContent = fixTurtleSerializerErrors(fixedContent, stats, verbose);
  }

  if (normalizedPath.endsWith('lib/shared/widgets/sharing/batch_sharing_handler.dart')) {
    fixedContent = fixBatchSharingHandlerErrors(fixedContent, stats, verbose);
  }

  return fixedContent;
}

String fixMovieListServiceCompactErrors(String content, CleanupStats stats, bool verbose) {
  String fixed = content;

  // Fix retryOperation method issue
  if (fixed.contains('retryOperation(')) {
    // Add the mixin if not present
    if (!fixed.contains('with PodOperationsMixin')) {
      fixed = fixed.replaceFirst(
        'class MovieListService',
        'class MovieListService with PodOperationsMixin'
      );

      // Add import if not present
      if (!fixed.contains('import \'package:moviestar/core/services/pod/pod_operations_mixin.dart\'')) {
        final importIndex = fixed.indexOf('import \'package:flutter/material.dart\';');
        if (importIndex != -1) {
          final afterImport = importIndex + 'import \'package:flutter/material.dart\';'.length;
          fixed = fixed.substring(0, afterImport) +
                  '\n\nimport \'package:moviestar/core/services/pod/pod_operations_mixin.dart\';' +
                  fixed.substring(afterImport);
        }
      }

      stats.missingMethodsFixed++;
      if (verbose) {
        print('  Added PodOperationsMixin to MovieListService');
      }
    }
  }

  return fixed;
}

String fixPodFavoritesServiceCompactErrors(String content, CleanupStats stats, bool verbose) {
  String fixed = content;

  // Fix constructor parameter issues
  // Error: 3 positional arguments expected by 'PodListManagementService.new', but 2 found
  fixed = fixed.replaceAll(
    'PodListManagementService(context, child)',
    'PodListManagementService(context, child, _userProfileService)'
  );

  // Error: Too many positional arguments: 0 expected, but 2 found
  fixed = fixed.replaceAll(
    'PodSharingService(context, child)',
    'PodSharingService()'
  );

  // Fix CustomList constructor issues
  // Add missing required parameters
  fixed = fixed.replaceFirst(
    RegExp(r'CustomList\s*\(\s*id:\s*id,\s*name:\s*name,\s*\)'),
    'CustomList(\n          id: id,\n          name: name,\n          createdAt: DateTime.now(),\n          updatedAt: DateTime.now(),\n          movieIds: movies.map((m) => m.id).toList(),\n        )'
  );

  // Fix movies parameter issue
  fixed = fixed.replaceAll(
    'movies: movies,',
    '// movies: movies, // Remove this line as movies is not a valid parameter'
  );

  // Fix createOrUpdateMovieFile call
  fixed = fixed.replaceAll(
    'createOrUpdateMovieFile(movie, null, null)',
    'createOrUpdateMovieFile(movie)'
  );

  stats.constructorIssuesFixed++;
  stats.parameterIssuesFixed++;

  if (verbose) {
    print('  Fixed constructor and parameter issues in PodFavoritesServiceCompact');
  }

  return fixed;
}

String fixTurtleSerializerErrors(String content, CleanupStats stats, bool verbose) {
  String fixed = content;

  // Fix missing method calls by using static methods from TurtleSerializer
  final methodReplacements = {
    'escapeString(': 'TurtleSerializer.escapeString(',
    'escapeAndSanitizeString(': 'TurtleSerializer.escapeAndSanitizeString(',
    'getOntologyNamespaces()': 'TurtleSerializer.getOntologyNamespaces()',
  };

  methodReplacements.forEach((oldMethod, newMethod) => {
    if (fixed.contains(oldMethod)) {
      fixed = fixed.replaceAll(oldMethod, newMethod);
      stats.missingMethodsFixed++;
      if (verbose) {
        print('  Replaced $oldMethod with $newMethod');
      }
    }
  });

  return fixed;
}

String fixBatchSharingHandlerErrors(String content, CleanupStats stats, bool verbose) {
  String fixed = content;

  // Fix ShareableFile type issue
  // Error: The name 'ShareableFile' isn't a type, so it can't be used as a type argument
  fixed = fixed.replaceAll(
    'List<ShareableFile>',
    'List<Map<String, dynamic>>' // Use a more generic type
  );

  stats.typeIssuesFixed++;

  if (verbose) {
    print('  Fixed ShareableFile type issue');
  }

  return fixed;
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
  print('  Missing methods fixed: ${stats.missingMethodsFixed}');
  print('  Constructor issues fixed: ${stats.constructorIssuesFixed}');
  print('  Parameter issues fixed: ${stats.parameterIssuesFixed}');
  print('  Type issues fixed: ${stats.typeIssuesFixed}');

  if (stats.modifiedFiles.isNotEmpty) {
    print('\n📁 Modified files:');
    for (final file in stats.modifiedFiles) {
      print('  - $file');
    }
  }

  print('\n⚠️  Important Notes:');
  print('   - Some fixes may require manual verification');
  print('   - Run flutter analyze again to check for remaining issues');
  print('   - Test the application to ensure functionality is preserved');
}