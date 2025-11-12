# Adapting for Your Solid POD Application

> This guide helps you adapt MovieStar's POD authentication testing
> approach for your own Solid POD application.
>
> **For provider-specific details:** See [Provider
> Compatibility](adapting-providers.md)
>
> **For CI/CD setup:** See [CI/CD Integration](adapting-cicd.md)
>
> **Documentation index:** See [README.md](../README.md) for complete
> documentation navigation.

## Quick Start Checklist

**Setup Phase:**

+ [ ] Copy reusable helper files to your project
+ [ ] Add required dependencies to pubspec.yaml
+ [ ] Update POD provider configuration
+ [ ] Modify OAuth client settings
+ [ ] Create test credentials file

**Testing Phase:**

+ [ ] Write application-specific test assertions
+ [ ] Test auth injection with your app
+ [ ] Verify POD operations in tests
+ [ ] Run tests with INTERACT=0 to ensure they pass

**CI/CD Phase:**

+ [ ] Update CI/CD configuration (see
  [CI/CD Integration](adapting-cicd.md))
+ [ ] Set up encrypted credentials in CI
+ [ ] Verify tests pass in CI environment

## Reusable Components

These files can be copied directly to your project with minimal
changes:

### Core Helpers (Copy As-Is)

```text
integration_test/helpers/
├── credential_injector.dart       # Reusable
└── pod_auth_automator.dart        # Reusable

integration_test/tools/
└── generate_auth_data.dart        # Reusable

integration_test/utils/
└── delays.dart                    # Reusable
```

**What these provide:**

+ OAuth 2.0 + PKCE flow implementation
+ DPoP token generation with RSA keys
+ Puppeteer browser automation
+ Secure storage injection
+ Token expiry checking and auto-regeneration

### Application-Specific Files (Customize)

```text
integration_test/workflows/
└── your_app_test.dart             # Write your own tests

integration_test/fixtures/
├── test_credentials.json          # Your POD credentials
└── complete_auth_data.json        # Auto-generated
```

### Required Dependencies

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  puppeteer: ^3.19.0  # Browser automation for OAuth
  pointycastle: ^3.9.1  # RSA key generation for DPoP
  flutter_secure_storage: ^9.0.0  # Secure credential storage
```

## Configuration Changes

### 1. POD Provider URL

**Location:** Multiple files reference the POD provider

**MovieStar default:**

```dart
'https://pods.dev.solidcommunity.au'
```

**Change to:**

+ Your POD provider URL
+ Or make it configurable via environment variable

**Files to update:**

```json
// integration_test/fixtures/test_credentials.json
{
  "issuer": "https://your-pod-provider.com",
  "podUrl": "https://your-pod-provider.com/username/",
  "webId": "https://your-pod-provider.com/username/profile/card#me"
}
```

**Making it configurable:**

```dart
// Add to pod_auth_automator.dart
static String getPodProvider() {
  return const String.fromEnvironment(
    'POD_PROVIDER',
    defaultValue: 'https://pods.dev.solidcommunity.au',
  );
}
```

### 2. OAuth Redirect URI

**Location:** `integration_test/helpers/pod_auth_automator.dart`

**MovieStar default:**

```dart
final redirectUri = 'http://localhost:44007/';
```

**Change to:**

+ Match your app's registered redirect URI
+ Must be `http://localhost:<port>/` for desktop apps
+ Different ports for different apps to avoid conflicts

**Example:**

```dart
// Your app uses port 45000
final redirectUri = 'http://localhost:45000/';
```

**Note:** Update in both:

+ `pod_auth_automator.dart` - Puppeteer automation
+ Your app's OAuth configuration

### 3. OAuth Client Name

**Location:** `integration_test/helpers/pod_auth_automator.dart`

**MovieStar default:**

```dart
'client_name': 'MovieStar E2E Test Client',
```

**Change to:**

```dart
'client_name': 'YourApp E2E Test Client',
```

This name appears in POD server logs and consent screens.

### 4. Test Credentials

**Location:** `integration_test/fixtures/test_credentials.json`

Create with your POD account:

```bash
cat > integration_test/fixtures/test_credentials.json <<'EOF'
{
  "email": "your-test-account",
  "password": "your-test-password",
  "securityKey": "your-2fa-key",
  "webId": "https://your-pod-provider.com/test/profile/card#me",
  "podUrl": "https://your-pod-provider.com/test/",
  "issuer": "https://your-pod-provider.com"
}
EOF
```

**Security:** Use a dedicated test POD account, not your personal POD.

## Writing Application-Specific Tests

### Test Template

```dart
/// E2E test for YourApp POD operations.
///
/// Copyright (C) 2025, Your Organization.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:your_app/main.dart' as app;
import '../helpers/credential_injector.dart';
import '../utils/delays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('YourApp POD Tests', () {
    setUpAll() async {
      // Inject auth before app launch
      await CredentialInjector.injectFullAuth(
        autoRegenerateOnFailure: true,
      );
    });

    tearDownAll() async {
      // Clean up credentials
      await CredentialInjector.clearCredentials();
    });

    testWidgets('app recognizes authenticated state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await Future.delayed(delay);
      await tester.pump(interact);

      // Your app-specific assertions
      expect(find.text('Logged In'), findsOneWidget);
    });
  });
}
```

### Common Test Patterns

#### Pattern 1: Read-Only POD Access

For apps that only read public data:

```dart
testWidgets('loads public profile from POD', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Navigate to profile screen
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();

  // Verify data loaded from POD
  expect(find.text('Name: Test User'), findsOneWidget);
});
```

#### Pattern 2: Write Operations

For apps that modify POD data:

```dart
testWidgets('saves preferences to POD', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Modify a setting
  await tester.tap(find.byKey(const Key('dark_mode_toggle')));
  await tester.pumpAndSettle();

  // Save to POD
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify saved
  expect(find.text('Saved to POD'), findsOneWidget);
});
```

#### Pattern 3: Multi-POD Operations

For apps that work with multiple PODs:

```dart
testWidgets('shares data between PODs', (tester) async {
  await CredentialInjector.injectFullAuth();

  app.main();
  await tester.pumpAndSettle();

  // Share data with another POD
  await tester.tap(find.text('Share'));
  await tester.enterText(
    find.byKey(const Key('recipient_webid')),
    'https://pod-b.example.com/user/profile/card#me'
  );
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();

  expect(find.text('Shared successfully'), findsOneWidget);
});
```

## Migration Steps

### Step 1: Copy Files

Copy the reusable components to your project:

```bash
# Copy helpers
cp -r integration_test/helpers your-project/integration_test/

# Copy tools
cp -r integration_test/tools your-project/integration_test/

# Copy utils
cp -r integration_test/utils your-project/integration_test/

# Optional: Copy docs for reference
cp -r integration_test/docs your-project/integration_test/
```

### Step 2: Update Configuration

+ Update POD provider URL in `pod_auth_automator.dart`
+ Change OAuth redirect URI (use different port)
+ Update OAuth client name
+ Create `test_credentials.json` with your POD account

### Step 3: Test Authentication

Generate auth data to verify setup:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

Should complete in 15-20 seconds and create
`complete_auth_data.json`.

### Step 4: Write App Tests

Create your first test in `integration_test/workflows/`:

```bash
touch integration_test/workflows/your_app_test.dart
```

Use the template above and add your app-specific assertions.

### Step 5: Run Tests

```bash
# Quick test
flutter test integration_test/workflows/your_app_test.dart \
  -d linux --dart-define=INTERACT=0

# Interactive test (for debugging)
flutter test integration_test/workflows/your_app_test.dart \
  -d linux --dart-define=INTERACT=5
```

## Getting Help

**Questions about adaptation:**

+ Check [Authentication Guide](../concepts/authentication.md) for concepts
+ Review [Architecture](../concepts/architecture.md) for component details
+ See [Testing Guide](testing-guide.md) for troubleshooting
+ Open an issue with `adaptation-question` label

**Contributing improvements:**

+ Submit PRs to make helpers more reusable
+ Share your adapted selectors for different POD providers
+ Contribute example projects

## Summary

To adapt for your app:

+ **Copy reusable helpers** - OAuth, DPoP, Puppeteer automation
+ **Update configuration** - POD provider, redirect URI, client name
+ **Create test credentials** - Use dedicated test POD account
+ **Write app-specific tests** - Focus on your POD operations
+ **Set up CI/CD** - See [CI/CD Integration](adapting-cicd.md)
+ **Debug selectors** - See [Provider
  Compatibility](adapting-providers.md)

The core OAuth + DPoP + Puppeteer approach is fully reusable. Only
application-specific test assertions and POD provider configuration
need customization.

## See Also

+ [Provider Compatibility](adapting-providers.md) - POD provider
  configuration
+ [CI/CD Integration](adapting-cicd.md) - Setting up continuous
  integration
+ [Testing Guide](testing-guide.md) - Running your adapted tests
+ [Architecture](../concepts/architecture.md) - Understanding component
  interactions
+ [JSON Files Reference](../reference/json-files.md) - Credential file structure
