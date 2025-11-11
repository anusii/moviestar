# Adapting for Your Solid POD Application

This guide helps you adapt MovieStar's POD authentication testing approach for your own Solid POD application.

## Quick Start Checklist

- [ ] Copy reusable helper files to your project
- [ ] Update POD provider configuration
- [ ] Modify OAuth client settings
- [ ] Create test credentials file
- [ ] Write application-specific test assertions
- [ ] Update CI/CD configuration

## Reusable Components

These files can be copied directly to your project with minimal changes:

### Core Helpers (Copy As-Is)

```
integration_test/helpers/
├── credential_injector.dart       # ✓ Reusable
├── pod_auth_automator.dart        # ✓ Reusable
└── test_credentials.dart          # ✗ Deleted (legacy)

integration_test/tools/
└── generate_auth_data.dart        # ✓ Reusable

integration_test/utils/
└── delays.dart                    # ✓ Reusable
```

**What these provide:**
- OAuth 2.0 + PKCE flow implementation
- DPoP token generation with RSA keys
- Puppeteer browser automation
- Secure storage injection
- Token expiry checking and auto-regeneration

### Application-Specific Files (Customize)

```
integration_test/workflows/
└── pod_favorites_real_test.dart   # ✗ MovieStar-specific

integration_test/fixtures/
├── test_credentials.json          # ✗ Your POD credentials
└── complete_auth_data.json        # ✗ Auto-generated
```

## Configuration Changes

### 1. POD Provider URL

**Location:** Multiple files reference the POD provider

**MovieStar default:**
```dart
'https://pods.dev.solidcommunity.au'
```

**Change to:**
- Your POD provider URL
- Or make it configurable via environment variable

**Files to update:**

```dart
// integration_test/fixtures/test_credentials.json
{
  "issuer": "https://your-pod-provider.com",  // ← Change this
  "podUrl": "https://your-pod-provider.com/your-username/",
  "webId": "https://your-pod-provider.com/your-username/profile/card#me"
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
- Match your app's registered redirect URI
- Must be `http://localhost:<port>/` for desktop apps
- Different ports for different apps to avoid conflicts

**Example:**
```dart
// Your app uses port 45000
final redirectUri = 'http://localhost:45000/';
```

**Note:** Update in both:
1. `pod_auth_automator.dart` - Puppeteer automation
2. Your app's OAuth configuration

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
  "webId": "https://your-pod-provider.com/your-test-account/profile/card#me",
  "podUrl": "https://your-pod-provider.com/your-test-account/",
  "issuer": "https://your-pod-provider.com"
}
EOF
```

**Security:** Use a dedicated test POD account, not your personal POD.

## Writing Application-Specific Tests

### Template Structure

```dart
/// E2E test for [YourApp] POD operations.
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

    testWidgets('can access POD data', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test your app's POD operations
      await tester.tap(find.byIcon(Icons.cloud));
      await tester.pumpAndSettle();

      expect(find.text('POD Connected'), findsOneWidget);
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
  expect(find.text('Email: test@example.com'), findsOneWidget);
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
  // Inject credentials for POD A
  await CredentialInjector.injectFullAuth();

  app.main();
  await tester.pumpAndSettle();

  // Share data with POD B
  await tester.tap(find.text('Share'));
  await tester.enterText(find.byKey(const Key('recipient_webid')),
      'https://pod-b.example.com/user/profile/card#me');
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();

  expect(find.text('Shared successfully'), findsOneWidget);
});
```

## POD Provider Compatibility

### Supported POD Servers

This testing approach works with any Solid POD server implementing:

- **Solid-OIDC specification** - OAuth 2.0 with DPoP
- **OAuth 2.0 + PKCE** - Authorization Code Flow
- **DPoP (RFC 9449)** - Proof-of-Possession tokens

### Tested Providers

| Provider | Status | Notes |
|----------|--------|-------|
| **Community Solid Server (CSS)** | ✓ Tested | Used in MovieStar tests |
| **Node Solid Server (NSS)** | ✓ Compatible | Implements Solid-OIDC |
| **Enterprise Solid Server (ESS)** | ✓ Compatible | Commercial offering |
| **Custom implementations** | ? Unknown | Must implement Solid-OIDC |

### Provider-Specific Considerations

#### Community Solid Server (CSS)

**Login flow:**
- Email + Password
- Optional security key (2FA)
- Consent screen with "Yes" button

**Token expiry:** 3600 seconds (1 hour)

**Refresh tokens:** Supported but not always returned

#### Node Solid Server (NSS)

**Login flow:**
- Username + Password
- May have different consent screen UI

**Modify for NSS:**
```dart
// In pod_auth_automator.dart, update button selector
final consentButton = await page.waitForSelector(
  'button[name="approve"]',  // NSS uses 'approve' instead of 'yes'
);
```

#### Enterprise Solid Server (ESS)

**Login flow:**
- May use enterprise SSO
- Different consent screen branding

**Requires:** Custom Puppeteer selectors for your ESS instance

## Troubleshooting Adaptation

### Different Login Form Selectors

**Symptom:** Puppeteer timeout waiting for login form

**Solution:** Update selectors in `pod_auth_automator.dart`:

```dart
// Find your POD's selectors using Chrome DevTools
final emailInput = await page.waitForSelector('#your-email-field-id');
final passwordInput = await page.waitForSelector('#your-password-field-id');
```

**Debugging technique:**
1. Run with `headless: false` to see browser
2. Inspect elements in Chrome DevTools
3. Update selectors to match your POD's HTML

### Different Consent Screen

**Symptom:** Puppeteer can't find consent button

**Solution:** Update button selector:

```dart
// Original (CSS)
final consentButton = await page.$('button:has-text("Yes")');

// Try alternative selectors
final consentButton = await page.$('button[value="consent"]');
// OR
final consentButton = await page.$('input[type="submit"][name="authorize"]');
```

### OAuth Client Registration Differences

**Symptom:** Client registration fails with 400/401 error

**Solution:** Check your POD's client registration requirements:

```dart
// Some providers require additional fields
final clientMetadata = {
  'client_name': 'YourApp E2E Test Client',
  'redirect_uris': [redirectUri],
  'grant_types': ['authorization_code', 'refresh_token'],  // ← May be required
  'response_types': ['code'],  // ← May be required
  'token_endpoint_auth_method': 'none',  // ← For public clients
};
```

### Token Format Differences

**Symptom:** solidpod package can't parse tokens

**Solution:** Verify token structure matches expectations:

```dart
// Log the token response for debugging
print('Token response: ${jsonEncode(tokenResponse)}');

// Ensure it contains required fields:
// - access_token
// - id_token
// - token_type: "DPoP"
// - expires_in or expires_at
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Install Chrome
        run: |
          wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
          sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
          sudo apt-get update
          sudo apt-get install google-chrome-stable

      - name: Setup test credentials
        run: |
          mkdir -p integration_test/fixtures
          echo '${{ secrets.TEST_CREDENTIALS }}' > integration_test/fixtures/test_credentials.json

      - name: Generate auth data
        run: dart run integration_test/tools/generate_auth_data.dart

      - name: Run integration tests
        run: flutter test integration_test/ -d linux --dart-define=INTERACT=0
```

### Storing Credentials Securely

**GitHub Secrets:**
1. Go to repository Settings → Secrets → Actions
2. Add `TEST_CREDENTIALS` secret with your JSON content
3. Reference in workflow: `${{ secrets.TEST_CREDENTIALS }}`

**Encrypt auth data:**
```bash
# Generate encrypted auth data for CI
gpg --symmetric --cipher-algo AES256 integration_test/fixtures/complete_auth_data.json

# Commit encrypted version
git add integration_test/fixtures/complete_auth_data.json.gpg
```

## Migration Checklist

When adapting for your app:

**Phase 1: Setup**
- [ ] Copy `integration_test/helpers/` to your project
- [ ] Copy `integration_test/tools/` to your project
- [ ] Copy `integration_test/utils/` to your project
- [ ] Copy `integration_test/docs/` for reference
- [ ] Add dependencies: `puppeteer`, `pointycastle`, `flutter_secure_storage`

**Phase 2: Configuration**
- [ ] Update POD provider URL in test_credentials.json
- [ ] Change OAuth redirect URI in pod_auth_automator.dart
- [ ] Update OAuth client name
- [ ] Test browser automation with `dart run integration_test/tools/generate_auth_data.dart`

**Phase 3: Testing**
- [ ] Write app-specific test file in `integration_test/workflows/`
- [ ] Test auth injection works with your app
- [ ] Verify POD operations in tests
- [ ] Run with `flutter test integration_test/ -d <platform>`

**Phase 4: CI/CD**
- [ ] Set up encrypted credentials in CI
- [ ] Install Chrome in CI environment
- [ ] Configure test execution in workflow
- [ ] Verify tests pass in CI

## Example Projects

Looking for complete examples?

**MovieStar** - This project
- POD favorites storage
- Read and write operations
- Auto-regeneration enabled

**Future examples:**
- Solid Community contributions welcome
- Share your adapted implementation

## Getting Help

**Questions about adaptation:**
1. Check [Authentication Guide](authentication.md) for concepts
2. Review [Architecture Overview](architecture.md) for component details
3. See [Testing Guide](testing-guide.md) for troubleshooting
4. Open an issue on GitHub with `adaptation-question` label

**Contributing improvements:**
- Submit PRs to make helpers more reusable
- Share your adapted selectors for different POD providers
- Contribute example projects

## Summary

To adapt for your app:

1. **Copy reusable helpers** - OAuth, DPoP, Puppeteer automation
2. **Update configuration** - POD provider, redirect URI, client name
3. **Create test credentials** - Use dedicated test POD account
4. **Write app-specific tests** - Focus on your POD operations
5. **Set up CI/CD** - Encrypt credentials, install Chrome
6. **Debug selectors** - Adjust for your POD provider's UI

The core OAuth + DPoP + Puppeteer approach is fully reusable. Only application-specific test assertions and POD provider configuration need customization.

## Next Steps

- [Testing Guide](testing-guide.md) - Run your adapted tests
- [Architecture Overview](architecture.md) - Understand component interactions
- [JSON Files Reference](json-files.md) - Credential file structure
