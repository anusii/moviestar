/// API Settings Panel Component - API Key Configuration and Validation.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:moviestar/core/services/api/api_key_service.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';

class ApiSettingsPanel extends ConsumerStatefulWidget {
  final Function(String title, List<Widget> children) buildSection;
  final ApiKeyService apiKeyService;
  final bool fromApiKeyPrompt;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onTriggerAppReinitialization;

  const ApiSettingsPanel({
    super.key,
    required this.buildSection,
    required this.apiKeyService,
    this.fromApiKeyPrompt = false,
    this.onNavigateToHome,
    this.onTriggerAppReinitialization,
  });

  @override
  ConsumerState<ApiSettingsPanel> createState() => _ApiSettingsPanelState();
}

class _ApiSettingsPanelState extends ConsumerState<ApiSettingsPanel> {
  /// Whether the API key is visible.
  bool _isApiKeyVisible = false;

  /// Controller for the API key input field.
  late final TextEditingController _apiKeyController;

  /// Focus node for the API key input field.
  final FocusNode _apiKeyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await widget.apiKeyService.getApiKey();
    if (mounted) {
      _apiKeyController.text = apiKey ?? '';
    }
  }

  /// Launch a URL in the browser.
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Triggers app reinitialization after API key is set.
  void _triggerAppReinitialization() {
    widget.onTriggerAppReinitialization?.call();
  }

  void _navigateToHomeScreen() {
    widget.onNavigateToHome?.call();
  }

  Future<void> _saveApiKey() async {
    await widget.apiKeyService.setApiKey(_apiKeyController.text);

    if (!context.mounted) return;

    if (mounted) {
      // Invalidate all movie providers to force refresh with new API key.
      // IMPORTANT: Must invalidate apiKeyProvider first so dependent providers refresh
      ref.invalidate(apiKeyProvider);
      ref.invalidate(popularMoviesWithCacheInfoProvider);
      ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
      ref.invalidate(topRatedMoviesWithCacheInfoProvider);
      ref.invalidate(upcomingMoviesWithCacheInfoProvider);
      ref.invalidate(movieServiceProvider);
      ref.invalidate(contentServiceProvider);

      // Give providers time to refresh before showing success message
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Show success message.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // If we navigated here from the API key prompt, navigate back to home.
        if (widget.fromApiKeyPrompt) {
          _navigateToHomeScreen();
        }

        // Trigger app reinitialization after API key is set
        // This will properly initialize POD folders and data loading
        _triggerAppReinitialization();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildSection('API Configuration', [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MovieDB API Key',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Gap(4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Required to fetch movie data and images',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                ),
                if (widget.fromApiKeyPrompt)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const Gap(8),
            SizedBox(
              width: 420,
              child: TextField(
                controller: _apiKeyController,
                style: Theme.of(context).textTheme.bodyLarge,
                focusNode: _apiKeyFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter your MovieDB API key',
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder:
                      Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder:
                      Theme.of(context).inputDecorationTheme.focusedBorder,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isApiKeyVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      setState(() {
                        _isApiKeyVisible = !_isApiKeyVisible;
                      });
                    },
                    tooltip: _isApiKeyVisible ? 'Hide API key' : 'Show API key',
                  ),
                ),
                obscureText: !_isApiKeyVisible,
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: () {
                // Launch TMDB website to get API key.
                final Uri url = Uri.parse(
                  'https://www.themoviedb.org/?language=en-AU',
                );
                _launchUrl(url);
              },
              child: const Text(
                'Get your API key from The Movie Database (TMDB)',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: _saveApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Save API Key'),
            ),
          ],
        ),
      ),
    ]);
  }
}
