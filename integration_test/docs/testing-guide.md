# MovieStar E2E Testing Guide

> **New to POD authentication?** Read [Understanding POD Authentication](authentication.md) first to learn why OAuth, DPoP, and browser automation are necessary.
>
> **Documentation index:** See [README.md](README.md) for complete documentation navigation.

## Overview

This guide explains how to write, run, and debug end-to-end (E2E) integration tests for the MovieStar application. The testing framework supports both quick automated testing and interactive visual testing.

For conceptual background and architecture details, see:
- [Understanding POD Authentication](authentication.md) - OAuth, DPoP, and why browser automation
- [Architecture Overview](architecture.md) - Component diagrams and data flow
- [JSON Files Reference](json-files.md) - Credential file structures
- [Adapting for Your App](adapting.md) - Reusability guide for other POD applications

## Table of Contents

1. [Test Types](#test-types)
2. [Running Tests](#running-tests)
3. [Writing Tests](#writing-tests)
4. [POD Authentication](#pod-authentication)
5. [Troubleshooting](#troubleshooting)

---

## Test Types

### Integration Tests (`integration_test/`)

End-to-end tests that run the complete application and verify functionality:

- **Basic Tests**: `app_test.dart`, `app_hive_test.dart` - Smoke tests for app initialization
- **Workflow Tests**: `workflows/pod_favorites_real_test.dart` - Full user workflows with POD authentication
- **Visual Tests**: `workflows/visual_login_test.dart` - Manual visual inspection of UI

#### Visual Rendering Pattern

All integration tests follow a consistent pattern to ensure UI is fully rendered before testing:

1. **Initial Render**: `await tester.pumpAndSettle()` - Wait for animations and microtasks
2. **Styling Delay**: `await Future.delayed(delay)` - Allow styling/theming to load (2s)
3. **Visual Inspection**: `await tester.pump(interact)` - Interactive delay for manual review

**Example from `app_hive_test.dart` (lines 79-85):**
```dart
await tester.pumpWidget(...);
await tester.pumpAndSettle(const Duration(seconds: 5));  // Initial render
await tester.pump(interact);  // Visual inspection (0s in qtest, 5s in itest)
```

**Example from `pod_favorites_real_test.dart` (lines 94-101):**
```dart
await tester.pumpWidget(...);
await tester.pumpAndSettle(const Duration(seconds: 5));  // Initial render
await Future.delayed(delay);  // Allow styling to load (2s)
await tester.pump();  // Apply styling
await tester.pump(interact);  // Visual inspection
```

This ensures tests work reliably in both quick (`INTERACT=0`) and interactive (`INTERACT>0`) modes.

### Unit Tests (`test/`)

Component-level tests for individual widgets, services, and state management.

---

## Running Tests

⚠️ **IMPORTANT:** Do not use `flutter test integration_test/` (batch mode) on desktop platforms - it fails due to a Flutter framework limitation. Use `make qtest` instead, which runs tests individually.

### Quick Test Mode (qtest) - Recommended

Run all tests quickly without visual interaction:

```bash
# Run all integration tests (recommended)
make qtest

# Run specific test
make workflows/pod_favorites_real_test.qtest
```

**Features:**
- `INTERACT=0` - No delays, runs as fast as possible
- `--reporter failures-only` - Only shows failures
- Retries failed tests once automatically
- Generates timestamped log file: `qtest_YYYYMMDDHHMMSS.txt`

### Interactive Test Mode (itest)

Run tests with visual interaction delays:

```bash
# Run specific test interactively
make workflows/pod_favorites_real_test.itest

# Or use flutter test with INTERACT parameter
flutter test integration_test/workflows/pod_favorites_real_test.dart -d linux --dart-define=INTERACT=5
```

**Features:**
- `INTERACT=5` - 5 second delay between major steps
- Allows visual inspection of UI during test execution
- Useful for debugging and development

### Individual Test Modes

```bash
# Quick (0s interact)
flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=0

# Visual review (2s interact)
flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=2

# Slow/development (5-10s interact)
flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=10
```

---

## Writing Tests

### The INTERACT Pattern

All tests should use the `interact` delay from `utils/delays.dart`:

```dart
import '../utils/delays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('my test', (WidgetTester tester) async {
    // Initialize app
    app.main();
    await tester.pumpAndSettle();

    // Interactive delay - allows visual inspection when INTERACT > 0
    await tester.pump(interact);

    // Continue with test assertions
    expect(find.text('Movie Star'), findsWidgets);
  });
}
```

**Key Points:**
- Use `interact` for visual review during development/debugging
- Use `delay` (2s) for required timing (animations, async operations)
- Use `hack` (10s) for workarounds that need fixing (mark with TODO)
- Tests MUST pass with `INTERACT=0` - never rely on interact for functionality

### Test Structure Template

```dart
/// Brief description of what this test verifies.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:moviestar/main.dart' as app;
import '../utils/delays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('descriptive test name', (WidgetTester tester) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();
    await tester.pump(interact);

    // 2. Actions
    // ... perform user actions ...

    // 3. Assertions
    expect(/* condition */, /* matcher */);
  });
}
```

---

## POD Authentication

### Complete Auth Data vs Legacy Tokens

The solidpod package requires **complete authentication data** including:
- RSA keypair for DPoP (Demonstration of Proof-of-Possession)
- Full OAuth2 Credential object
- Client metadata and logout URL

**Legacy token injection** (basic access_token/id_token only) will fail with:
```
OpenIdException(invalid_grant): grant request is invalid
```

### Extracting Complete Auth Data

#### Method 1: Automated Extraction (Recommended)

Uses browser automation with Puppeteer:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

**What it does:**
1. Launches headless Chrome browser
2. Navigates to POD login
3. Fills in credentials from `integration_test/fixtures/test_credentials.json`
4. Generates RSA keypair for DPoP
5. Saves complete auth data to `integration_test/fixtures/complete_auth_data.json`

**Requirements:**
- Chrome/Chromium installed
- Test credentials file exists
- Network access to POD server

#### Method 2: Manual Extraction

For visual login or when automation fails:

```bash
flutter run integration_test/tools/generate_auth_data.dart -d linux
```

**Steps:**
1. App launches showing login screen with overlay
2. Manually log in with your POD credentials
3. Click "EXTRACT AUTH DATA" button in overlay
4. Auth data saved to `integration_test/fixtures/complete_auth_data.json`

### Test Credentials Setup

Create `integration_test/fixtures/test_credentials.json`:

```json
{
  "username": "your-pod-username",
  "password": "your-pod-password",
  "securityKey": "your-security-key",
  "podUrl": "https://pods.dev.solidcommunity.au/your-pod/",
  "issuer": "https://pods.dev.solidcommunity.au"
}
```

**Security Note:** This file is git-ignored. Never commit credentials to version control.

### Auto-Regeneration

Tests can automatically regenerate expired tokens:

```dart
await CredentialInjector.injectFullAuth(autoRegenerateOnFailure: true);
```

This will:
1. Try to load existing `complete_auth_data.json`
2. If missing/expired, automatically run browser automation
3. Generate fresh auth data
4. Inject into test environment

---

## Troubleshooting

### Test Discovery Issues

**Problem:** `flutter test` doesn't find any tests

**Solution:** Test files MUST end with `_test.dart` suffix:
```bash
# Correct
integration_test/app_test.dart
integration_test/workflows/pod_favorites_real_test.dart

# Wrong - will not be discovered
integration_test/app.dart
integration_test/workflows/pod_favorites_real.dart
```

### Invalid Grant Errors

**Problem:**
```
AuthDataManager => _getTokenResponse() failed: OpenIdException(invalid_grant)
```

**Causes:**
1. Using legacy token injection (missing RSA keys)
2. Tokens expired (> 1 hour old)
3. Incomplete auth data structure

**Solutions:**
```bash
# Re-extract complete auth data
dart run integration_test/tools/generate_auth_data.dart

# Or enable auto-regeneration in test
await CredentialInjector.injectFullAuth(autoRegenerateOnFailure: true);
```

### Visual Delays Not Working

**Problem:** UI appears unstyled or test runs too fast

**Solution:** Use `interact` delay pattern, not hardcoded delays:

```dart
// ❌ Wrong - hardcoded delay
await Future.delayed(const Duration(seconds: 2));

// ✅ Correct - interact delay
import '../utils/delays.dart';
await tester.pump(interact);
```

Run with `INTERACT > 0` to see visual rendering:
```bash
flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=5
```

### Tests Pass with INTERACT but Fail with INTERACT=0

**Problem:** Test works interactively but fails in qtest mode

**Root Cause:** Test is relying on `interact` delay for functionality (timing issue)

**Solution:**
1. Identify the async operation causing timing issues
2. Use `await tester.pumpAndSettle()` to wait for animations/futures
3. If needed, use `delay` (2s) for required timing
4. Mark with TODO and use `hack` if it's a workaround

```dart
// For required async operations
await tester.pumpAndSettle();
await Future.delayed(delay);  // Required 2s for network/animation

// For workarounds that need fixing
await Future.delayed(hack);  // TODO: Fix R script async architecture
```

### Browser Automation Failures

**Problem:** `generate_auth_data.dart` fails with timeout or login errors

**Debug Steps:**
1. Run in non-headless mode to see browser:
   ```bash
   dart run integration_test/tools/generate_auth_data.dart --no-headless
   ```

2. Check credentials file exists and is correct:
   ```bash
   cat integration_test/fixtures/test_credentials.json
   ```

3. Test POD server accessibility:
   ```bash
   curl https://pods.dev.solidcommunity.au/.well-known/openid-configuration
   ```

4. Check Chrome/Chromium installation:
   ```bash
   which google-chrome chromium-browser chromium
   ```

### Device Not Found Errors

**Problem:**
```
No desktop device found. Please ensure you have the correct desktop platform enabled.
```

**Solution:**
```bash
# Check available devices
flutter devices

# Enable Linux desktop (if on Linux)
flutter config --enable-linux-desktop

# Or use specific device ID
flutter test integration_test/app_test.dart --device-id linux
```

### Batch Test Failures with "Log Reader Stopped Unexpectedly"

**Problem:**
When running `flutter test integration_test/`, the first test passes but subsequent tests fail with:
```
Error waiting for a debug connection: The log reader stopped unexpectedly, or never started.
Failed to load "...": Unable to start the app on the device.
```

**Root Cause:**
This is a **known limitation of Flutter's integration testing framework** on desktop platforms (Windows, Linux, macOS). The Flutter test runner has issues properly cleaning up and restarting the app between tests when running in batch mode. Only the first test succeeds; subsequent tests fail because the test runner cannot establish a debug connection to the app.

This is NOT related to the MovieStar codebase or POD authentication - it's a fundamental Flutter framework issue tracked in the Flutter repository.

**Solution: Run Tests Individually**
The recommended approach is to run each integration test individually:

```bash
# Run each test separately
flutter test integration_test/app_hive_test.dart -d <platform>
flutter test integration_test/app_test.dart -d <platform>
flutter test integration_test/workflows/pod_favorites_real_test.dart -d <platform> --dart-define=INTERACT=0
flutter test integration_test/workflows/visual_login_test.dart -d <platform> --dart-define=INTERACT=0

# Example for Windows
flutter test integration_test/app_hive_test.dart -d windows
flutter test integration_test/app_test.dart -d windows
flutter test integration_test/workflows/pod_favorites_real_test.dart -d windows --dart-define=INTERACT=0
flutter test integration_test/workflows/visual_login_test.dart -d windows --dart-define=INTERACT=0
```

**AUTO_REGENERATE Flag:**
The `pod_favorites_real_test.dart` supports automatic token regeneration when run individually. To disable this feature (e.g., for CI/CD where you want to ensure fresh tokens are pre-generated):

```bash
# Disable auto-regeneration for POD test
flutter test integration_test/workflows/pod_favorites_real_test.dart -d <platform> --dart-define=INTERACT=0 --dart-define=AUTO_REGENERATE=false
```

By default, auto-regeneration is **enabled** for individual test runs, providing a better developer experience.

**Note:** Batch testing (`flutter test integration_test/`) is currently not reliable on desktop platforms due to Flutter framework limitations. Individual test execution is the recommended approach until Flutter addresses this issue.

---

## Best Practices

1. **Always use `interact` delays** for visual inspection, never hardcode delays for functionality
2. **Tests must pass with `INTERACT=0`** - qtest mode is the standard
3. **Use descriptive test names** that explain what is being verified
4. **Clean up after tests** - clear credentials, reset state
5. **Keep tests focused** - one concept per test
6. **Use complete auth data** - never rely on legacy token injection
7. **Document workarounds** - mark `hack` delays with TODO comments
8. **Test on target platform** - Linux tests should run on Linux

---

## Quick Reference

```bash
# Run all tests quickly
make qtest.all

# Run specific test quickly
make workflows/pod_favorites_real_test.qtest

# Run specific test interactively
make workflows/pod_favorites_real_test.itest

# Extract auth data (automated)
dart run integration_test/tools/generate_auth_data.dart

# Extract auth data (manual)
flutter run integration_test/tools/generate_auth_data.dart -d linux

# Run with custom INTERACT
flutter test integration_test/app_test.dart -d linux --dart-define=INTERACT=5

# Check test discovery
flutter test --list
```

---

## Additional Resources

### Documentation
- [Setup Guide](setup-guide.md) - Initial setup instructions for POD authentication
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests) - Official Flutter E2E testing guide
- [Solid POD Documentation](https://solidproject.org/) - Solid Project overview and specifications
- [Solid OIDC Primer](https://solid.github.io/solid-oidc/) - Solid-OIDC authentication specification

### Packages & Tools
- [puppeteer](https://pub.dev/packages/puppeteer) - Headless Chrome/Chromium automation for Dart
- [pointycastle](https://pub.dev/packages/pointycastle) - Pure Dart cryptography library for RSA key generation
- [fast_rsa](https://pub.dev/packages/fast_rsa) - Flutter RSA encryption library (used by solidpod)
- [solidpod](https://pub.dev/packages/solidpod) - Solid POD client library for Flutter
- [integration_test](https://pub.dev/packages/integration_test) - Flutter's official E2E testing package
- [flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) - Flutter's widget testing framework

### Cryptography & Security
- [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) - OAuth 2.0 Demonstrating Proof of Possession
- [OAuth 2.0 (RFC 6749)](https://datatracker.ietf.org/doc/html/rfc6749) - OAuth 2.0 Authorization Framework
- [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) - OpenID Connect Core specification
- [PKCE (RFC 7636)](https://datatracker.ietf.org/doc/html/rfc7636) - Proof Key for Code Exchange
- [JWK (RFC 7517)](https://datatracker.ietf.org/doc/html/rfc7517) - JSON Web Key specification
- [ASN.1](https://en.wikipedia.org/wiki/ASN.1) - Abstract Syntax Notation for PEM encoding

### Browser Automation
- [Puppeteer API Documentation](https://pptr.dev/) - Official Puppeteer documentation
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/) - Protocol used by Puppeteer
- [Chromium Download](https://www.chromium.org/getting-involved/download-chromium/) - Download Chromium for testing
