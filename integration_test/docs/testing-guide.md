# MovieStar E2E Testing Guide

> This guide explains how to write, run, and debug end-to-end (E2E)
> integration tests for the MovieStar application. The testing
> framework supports both quick automated testing and interactive
> visual testing.
>
> **New to POD authentication?** Read [Understanding POD
> Authentication](authentication.md) first to learn why OAuth, DPoP,
> and browser automation are necessary.
>
> **Documentation index:** See [README.md](README.md) for complete
> documentation navigation.

## Quick Start

```bash
# Extract auth data (first time only)
dart run integration_test/tools/generate_auth_data.dart

# Run all tests quickly
make qtest

# Run specific test
make workflows/pod_favorites_real_test.qtest
```

## Table of Contents

+ [Test Types](#test-types)
+ [Running Tests](#running-tests)
+ [Writing Tests](#writing-tests)
+ [POD Authentication](#pod-authentication)
+ [Best Practices](#best-practices)

## Test Types

### Integration Tests

End-to-end tests that run the complete application and verify
functionality:

**Basic Tests:**

+ `app_test.dart` - Smoke test for app initialization
+ `app_hive_test.dart` - Hive storage initialization test

**Workflow Tests:**

+ `workflows/pod_favorites_real_test.dart` - Full user workflows with
  POD authentication
+ `workflows/visual_login_test.dart` - Manual visual inspection of UI

### Visual Rendering Pattern

All integration tests follow a consistent pattern to ensure UI is
fully rendered before testing:

**Steps:**

+ **Initial Render:** `await tester.pumpAndSettle()` - Wait for
  animations and microtasks
+ **Styling Delay:** `await Future.delayed(delay)` - Allow
  styling/theming to load (2s)
+ **Visual Inspection:** `await tester.pump(interact)` - Interactive
  delay for manual review

**Example from app_hive_test.dart:**

```dart
await tester.pumpWidget(...);
await tester.pumpAndSettle(const Duration(seconds: 5));
await tester.pump(interact);  // 0s in qtest, 5s in itest
```

**Example from pod_favorites_real_test.dart:**

```dart
await tester.pumpWidget(...);
await tester.pumpAndSettle(const Duration(seconds: 5));
await Future.delayed(delay);  // Allow styling to load
await tester.pump();
await tester.pump(interact);
```

This ensures tests work reliably in both quick (`INTERACT=0`) and
interactive (`INTERACT>0`) modes.

### Unit Tests

Component-level tests for individual widgets, services, and state
management in `test/` directory.

## Running Tests

**IMPORTANT:** Do not use `flutter test integration_test/` (batch
mode) on desktop platforms - it fails due to a Flutter framework
limitation. Use `make qtest` instead, which runs tests individually.

### Quick Test Mode (qtest)

Run all tests quickly without visual interaction:

```bash
# Run all integration tests (recommended)
make qtest

# Run specific test
make workflows/pod_favorites_real_test.qtest
```

**Features:**

+ `INTERACT=0` - No delays, runs as fast as possible
+ `--reporter failures-only` - Only shows failures
+ Retries failed tests once automatically
+ Generates timestamped log file: `qtest_YYYYMMDDHHMMSS.txt`

### Interactive Test Mode (itest)

Run tests with visual interaction delays:

```bash
# Run specific test interactively
make workflows/pod_favorites_real_test.itest

# Or use flutter test with INTERACT parameter
flutter test integration_test/workflows/pod_favorites_real_test.dart \
  -d linux --dart-define=INTERACT=5
```

**Features:**

+ `INTERACT=5` - 5 second delay between major steps
+ Allows visual inspection of UI during test execution
+ Useful for debugging and development

### Individual Test Modes

```bash
# Quick (0s interact)
flutter test integration_test/app_test.dart \
  -d linux --dart-define=INTERACT=0

# Visual review (2s interact)
flutter test integration_test/app_test.dart \
  -d linux --dart-define=INTERACT=2

# Slow/development (5-10s interact)
flutter test integration_test/app_test.dart \
  -d linux --dart-define=INTERACT=10
```

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

    // Interactive delay
    await tester.pump(interact);

    // Continue with test assertions
    expect(find.text('Movie Star'), findsWidgets);
  });
}
```

**Key Points:**

+ Use `interact` for visual review during development/debugging
+ Use `delay` (2s) for required timing (animations, async operations)
+ Use `hack` (10s) for workarounds that need fixing (mark with TODO)
+ Tests MUST pass with `INTERACT=0` - never rely on interact for
  functionality

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

  testWidgets('descriptive test name', (tester) async {
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

## POD Authentication

### Complete Auth Data vs Legacy Tokens

The solidpod package requires **complete authentication data**
including:

+ RSA keypair for DPoP (Demonstration of Proof-of-Possession)
+ Full OAuth2 Credential object
+ Client metadata and logout URL

**Legacy token injection** (basic access_token/id_token only) will
fail with:

```text
OpenIdException(invalid_grant): grant request is invalid
```

### Extracting Complete Auth Data

#### Method 1: Automated Extraction (Recommended)

Uses browser automation with Puppeteer:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

**What it does:**

+ Launches headless Chrome browser
+ Navigates to POD login
+ Fills in credentials from `test_credentials.json`
+ Generates RSA keypair for DPoP
+ Saves complete auth data to `complete_auth_data.json`

**Requirements:**

+ Chrome/Chromium installed
+ Test credentials file exists
+ Network access to POD server

#### Method 2: Manual Extraction

For visual login or when automation fails:

```bash
flutter run integration_test/tools/generate_auth_data.dart -d linux
```

**Steps:**

+ App launches showing login screen with overlay
+ Manually log in with your POD credentials
+ Click "EXTRACT AUTH DATA" button in overlay
+ Auth data saved to `complete_auth_data.json`

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

**Security Note:** This file is git-ignored. Never commit credentials
to version control.

### Auto-Regeneration

Tests can automatically regenerate expired tokens:

```dart
await CredentialInjector.injectFullAuth(
  autoRegenerateOnFailure: true
);
```

This will:

+ Try to load existing `complete_auth_data.json`
+ If missing/expired, automatically run browser automation
+ Generate fresh auth data
+ Inject into test environment

## Best Practices

+ **Always use `interact` delays** for visual inspection, never
  hardcode delays for functionality
+ **Tests must pass with `INTERACT=0`** - qtest mode is the standard
+ **Use descriptive test names** that explain what is being verified
+ **Clean up after tests** - clear credentials, reset state
+ **Keep tests focused** - one concept per test
+ **Use complete auth data** - never rely on legacy token injection
+ **Document workarounds** - mark `hack` delays with TODO comments
+ **Test on target platform** - Linux tests should run on Linux

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
flutter test integration_test/app_test.dart \
  -d linux --dart-define=INTERACT=5

# Check test discovery
flutter test --list
```

## See Also

+ [Troubleshooting](testing-troubleshooting.md) - Common issues and
  solutions
+ [Setup Guide](setup-guide.md) - Initial setup instructions for POD
  authentication
+ [Authentication Guide](authentication.md) - OAuth/DPoP concepts
+ [Architecture](architecture.md) - Component overview and execution
  flows
+ [JSON Files Reference](json-files.md) - Credential file structures
+ [Adapting for Your App](adapting.md) - Reusability guide for other
  POD applications

## Additional Resources

### Documentation

+ [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
  - Official Flutter E2E testing guide
+ [Solid POD Documentation](https://solidproject.org/) - Solid
  Project overview and specifications
+ [Solid OIDC Primer](https://solid.github.io/solid-oidc/) -
  Solid-OIDC authentication specification

### Packages and Tools

+ [puppeteer](https://pub.dev/packages/puppeteer) - Headless
  Chrome/Chromium automation for Dart
+ [pointycastle](https://pub.dev/packages/pointycastle) - Pure Dart
  cryptography library for RSA key generation
+ [fast_rsa](https://pub.dev/packages/fast_rsa) - Flutter RSA
  encryption library (used by solidpod)
+ [solidpod](https://pub.dev/packages/solidpod) - Solid POD client
  library for Flutter
+ [integration_test](https://pub.dev/packages/integration_test) -
  Flutter's official E2E testing package
+ [flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
  - Flutter's widget testing framework

### Cryptography and Security

+ [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) -
  OAuth 2.0 Demonstrating Proof of Possession
+ [OAuth 2.0 (RFC 6749)](https://datatracker.ietf.org/doc/html/rfc6749)
  - OAuth 2.0 Authorization Framework
+ [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html)
  - OpenID Connect Core specification
+ [PKCE (RFC 7636)](https://datatracker.ietf.org/doc/html/rfc7636) -
  Proof Key for Code Exchange
+ [JWK (RFC 7517)](https://datatracker.ietf.org/doc/html/rfc7517) -
  JSON Web Key specification
+ [ASN.1](https://en.wikipedia.org/wiki/ASN.1) - Abstract Syntax
  Notation for PEM encoding

### Browser Automation

+ [Puppeteer API Documentation](https://pptr.dev/) - Official
  Puppeteer documentation
+ [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)
  - Protocol used by Puppeteer
+ [Chromium Download](https://www.chromium.org/getting-involved/download-chromium/)
  - Download Chromium for testing
