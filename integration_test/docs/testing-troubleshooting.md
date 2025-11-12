# Integration Test Troubleshooting

> This guide covers common issues when running MovieStar integration
> tests and their solutions. For general testing information, see
> [Testing Guide](testing-guide.md).
>
> **Documentation index:** See [README.md](README.md) for complete
> documentation navigation.

## Test Discovery Issues

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

## Invalid Grant Errors

**Problem:**

```text
AuthDataManager => _getTokenResponse() failed:
OpenIdException(invalid_grant)
```

**Causes:**

+ Using legacy token injection (missing RSA keys)
+ Tokens expired (> 1 hour old)
+ Incomplete auth data structure

**Solutions:**

```bash
# Re-extract complete auth data
dart run integration_test/tools/generate_auth_data.dart

# Or enable auto-regeneration in test
await CredentialInjector.injectFullAuth(
  autoRegenerateOnFailure: true
);
```

## Visual Delays Not Working

**Problem:** UI appears unstyled or test runs too fast

**Solution:** Use `interact` delay pattern, not hardcoded delays:

```dart
// Wrong - hardcoded delay
await Future.delayed(const Duration(seconds: 2));

// Correct - interact delay
import '../utils/delays.dart';
await tester.pump(interact);
```

Run with `INTERACT > 0` to see visual rendering:

```bash
flutter test integration_test/app_test.dart \
  -d linux --dart-define=INTERACT=5
```

## Tests Pass with INTERACT but Fail with INTERACT=0

**Problem:** Test works interactively but fails in qtest mode

**Root Cause:** Test is relying on `interact` delay for
functionality (timing issue)

**Solution:**

+ Identify the async operation causing timing issues
+ Use `await tester.pumpAndSettle()` to wait for animations/futures
+ If needed, use `delay` (2s) for required timing
+ Mark with TODO and use `hack` if it's a workaround

```dart
// For required async operations
await tester.pumpAndSettle();
await Future.delayed(delay);  // Required 2s for network/animation

// For workarounds that need fixing
await Future.delayed(hack);  // TODO: Fix async architecture
```

## Browser Automation Failures

**Problem:** `generate_auth_data.dart` fails with timeout or login
errors

**Debug Steps:**

Run in non-headless mode to see browser:

```bash
dart run integration_test/tools/generate_auth_data.dart --no-headless
```

Check credentials file exists and is correct:

```bash
cat integration_test/fixtures/test_credentials.json
```

Test POD server accessibility:

```bash
curl https://pods.dev.solidcommunity.au/.well-known/\
openid-configuration
```

Check Chrome/Chromium installation:

```bash
which google-chrome chromium-browser chromium
```

## Device Not Found Errors

**Problem:**

```text
No desktop device found. Please ensure you have the correct desktop
platform enabled.
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

## Batch Test Failures with Log Reader Errors

**Problem:**

When running `flutter test integration_test/`, the first test passes
but subsequent tests fail with:

```text
Error waiting for a debug connection: The log reader stopped
unexpectedly, or never started.
Failed to load "...": Unable to start the app on the device.
```

**Root Cause:**

This is a **known limitation of Flutter's integration testing
framework** on desktop platforms (Windows, Linux, macOS). The Flutter
test runner has issues properly cleaning up and restarting the app
between tests when running in batch mode. Only the first test
succeeds; subsequent tests fail because the test runner cannot
establish a debug connection to the app.

This is NOT related to the MovieStar codebase or POD authentication -
it's a fundamental Flutter framework issue tracked in the Flutter
repository.

**Solution: Run Tests Individually**

The recommended approach is to run each integration test individually:

```bash
# Run each test separately
flutter test integration_test/app_hive_test.dart -d <platform>
flutter test integration_test/app_test.dart -d <platform>
flutter test integration_test/workflows/pod_favorites_real_test.dart \
  -d <platform> --dart-define=INTERACT=0
flutter test integration_test/workflows/visual_login_test.dart \
  -d <platform> --dart-define=INTERACT=0

# Example for Windows
flutter test integration_test/app_hive_test.dart -d windows
flutter test integration_test/app_test.dart -d windows
flutter test integration_test/workflows/pod_favorites_real_test.dart \
  -d windows --dart-define=INTERACT=0
flutter test integration_test/workflows/visual_login_test.dart \
  -d windows --dart-define=INTERACT=0
```

**AUTO_REGENERATE Flag:**

The `pod_favorites_real_test.dart` supports automatic token
regeneration when run individually. To disable this feature (e.g., for
CI/CD where you want to ensure fresh tokens are pre-generated):

```bash
# Disable auto-regeneration for POD test
flutter test integration_test/workflows/pod_favorites_real_test.dart \
  -d <platform> \
  --dart-define=INTERACT=0 \
  --dart-define=AUTO_REGENERATE=false
```

By default, auto-regeneration is **enabled** for individual test runs,
providing a better developer experience.

**Note:** Batch testing (`flutter test integration_test/`) is
currently not reliable on desktop platforms due to Flutter framework
limitations. Individual test execution is the recommended approach
until Flutter addresses this issue.

## Quick Troubleshooting Checklist

When a test fails, check in order:

+ File name ends with `_test.dart`
+ Auth data is fresh (< 1 hour old)
+ Chrome/Chromium is installed
+ Test credentials file exists and is correct
+ Platform is enabled (`flutter devices` shows device)
+ Test passes with `INTERACT=5` (timing issue if yes)
+ Not using batch mode on desktop (run individually)

## Common Error Messages

**"No device found"**

Enable desktop platform:

```bash
flutter config --enable-linux-desktop  # or windows/macos
```

**"invalid_grant"**

Regenerate auth data:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

**"Browser automation timeout"**

Run with visible browser to debug:

```bash
dart run integration_test/tools/generate_auth_data.dart --no-headless
```

**"Test not discovered"**

Rename file to end with `_test.dart`:

```bash
mv integration_test/my_test.dart integration_test/my_test_test.dart
```

## Getting Help

If troubleshooting doesn't resolve your issue:

+ Check [Testing Guide](testing-guide.md) for usage patterns
+ Review [Authentication Guide](authentication.md) for OAuth concepts
+ Check [Setup Guide](setup-guide.md) for initial configuration
+ Review [Architecture](architecture.md) for component interactions
+ Check Flutter integration test logs for stack traces
+ Verify POD server is accessible
+ Try manual auth extraction to isolate automation issues

## See Also

+ [Testing Guide](testing-guide.md) - Running and writing tests
+ [Setup Guide](setup-guide.md) - Initial setup instructions
+ [Authentication Guide](authentication.md) - OAuth/DPoP concepts
+ [Architecture](architecture.md) - Component overview
