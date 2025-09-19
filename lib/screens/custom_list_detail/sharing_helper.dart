/// Sharing logic helper for custom list detail screen.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/serializer.dart';

/// Handles sharing functionality for custom lists.
class CustomListSharingHelper {
  /// Show the sharing dialog for a custom list.
  static void showSharingDialog(
    BuildContext context,
    CustomList customList,
    List<Movie> movies,
    StatefulWidget widget,
  ) {
    // This method should be implemented with the actual sharing UI
    // For now, just show a simple dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share List'),
          content:
              Text('Sharing "${customList.name}" with ${movies.length} movies'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Share a custom list to POD.
  static Future<void> shareCustomList(
    BuildContext context,
    CustomList customList,
    List<Movie> movies,
    StatefulWidget widget,
    Function(Movie) createMovieFileIfNotExists,
  ) async {
    // Capture all context-dependent references before any async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final userProfileService = UserProfileService(context, widget);

    try {
      // Show loading indicator (this is synchronous)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Prepare movie data for the list file (before async operations)
      final listFileName = 'MovieList-${DateTime.now().millisecondsSinceEpoch}';
      final listFilePath = 'user_lists/$listFileName.ttl';

      final movieDataList = movies.map((movie) {
        final movieContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
            movie, null, null);
        final base64Content = base64Encode(utf8.encode(movieContent));
        return {
          'id': movie.id,
          'title': movie.title,
          'ttl_content': base64Content,
        };
      }).toList();

      final listContent = '''
@prefix schema: <https://schema.org/> .
@prefix ex: <http://example.org/> .

<$listFileName> a ex:MovieList ;
    schema:name "${customList.name}" ;
    schema:description "${customList.description}" ;
    ex:movieCount ${customList.movieIds.length} ;
    ex:movies ${jsonEncode(movieDataList)} .
''';

      // Now perform async operations
      for (final movie in movies) {
        await createMovieFileIfNotExists(movie);
      }

      if (!context.mounted) return;
      final writeResult = await writePod(
        listFilePath,
        listContent,
        context,
        widget,
      );

      // Close loading dialog
      navigator.pop();

      if (writeResult == SolidFunctionCallStatus.success) {
        final userProfile = await userProfileService.getUserProfile();
        final podUrl = userProfile?['podUrl'] ?? 'your POD';

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'List "${customList.name}" shared to $podUrl',
            ),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share list: ${writeResult.toString()}',
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error sharing list: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }
}
