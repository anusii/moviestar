/// Browser automation helper functions for POD authentication.
///
/// This module provides browser interaction utilities including:
/// - Handling OAuth consent screens
/// - Security key input handling
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'package:puppeteer/puppeteer.dart';

/// Handles OAuth consent screen if present.
///
/// Attempts to find and click the consent approval button.
/// Returns true if a consent button was found and clicked, false otherwise.
Future<bool> handleConsentScreen(Page page) async {
  try {
    // Wait a moment for the consent screen to render.
    await Future.delayed(const Duration(seconds: 2));

    print('Looking for consent buttons...');

    // Try to find and click the "Yes" button.
    try {
      // Look for button with text "Yes" (case-insensitive).
      final buttons = await page.$$('button');
      print('Found ${buttons.length} buttons on page');

      for (final button in buttons) {
        final text =
            await page.evaluate('el => el.textContent', args: [button]);
        final textStr = text.toString().trim().toLowerCase();

        print('Button text: "$textStr"');

        if (textStr == 'yes' ||
            textStr == 'allow' ||
            textStr == 'authorize' ||
            textStr == 'consent') {
          print('✓ Found consent button with text: "$text", clicking...');
          await button.click();
          return true;
        }
      }
    } catch (e) {
      print('Error finding consent button: $e');
    }

    // Alternative: try looking for input type=submit with "Yes" value.
    try {
      final submitInputs = await page.$$('input[type="submit"]');
      for (final input in submitInputs) {
        final value = await page.evaluate('el => el.value', args: [input]);
        final valueStr = value.toString().trim().toLowerCase();

        if (valueStr == 'yes' ||
            valueStr == 'allow' ||
            valueStr == 'authorize') {
          print('✓ Found consent input with value: "$value", clicking...');
          await input.click();
          return true;
        }
      }
    } catch (e) {
      print('Error checking submit inputs: $e');
    }

    // Last resort: try the first submit button.
    try {
      final submitButtons = await page.$$('button[type="submit"]');
      if (submitButtons.isNotEmpty) {
        print('Trying first submit button as fallback...');
        await submitButtons.first.click();
        return true;
      }
    } catch (e) {
      print('Error clicking submit button: $e');
    }

    print('No consent button found');
    return false;
  } catch (e) {
    print('Error handling consent screen: $e');
    return false;
  }
}

/// Handles security key input if present.
///
/// Looks for security key input fields and fills them with the provided key.
/// Returns true if a security key field was found and filled, false otherwise.
Future<bool> handleSecurityKey(Page page, String securityKey) async {
  try {
    // Look for security key input.
    final securityKeySelectors = [
      'input[type="text"][placeholder*="key"]',
      'input[type="text"][placeholder*="security"]',
      'input[name="securityKey"]',
      'input[id="securityKey"]',
    ];

    for (final selector in securityKeySelectors) {
      try {
        await page.waitForSelector(
          selector,
          timeout: const Duration(seconds: 2),
        );
        await page.type(selector, securityKey);

        // Click submit button.
        await page.click('button[type="submit"]');
        return true;
      } catch (_) {
        // Try next selector.
      }
    }

    return false;
  } catch (e) {
    print('No security key prompt found or error handling it: $e');
    return false;
  }
}
