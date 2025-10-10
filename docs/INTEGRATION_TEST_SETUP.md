# Integration Test Setup

This document describes the E2E testing infrastructure for Movie Star using Flutter's integration_test package.

## Overview

Movie Star uses **integration_test** for cross-platform E2E testing on Windows, Linux, macOS, web, Android, and iOS.

## Installation

### Dependencies

The `integration_test` package is included in `pubspec.yaml`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  puppeteer: ^3.19.0  # Browser automation for POD OAuth testing
```

Run `flutter pub get` to install dependencies.

## Running Tests

### Running All Integration Tests

```bash
# Run all tests
flutter test integration_test/

# Run specific test
flutter test integration_test/app_test.dart

# Run on specific device (Windows)
flutter test integration_test/ -d windows

# Run workflow tests
flutter test integration_test/workflows/pod_favorites_real_test.dart
```

## Test Organization

```
integration_test/
├── fixtures/               # Test data and auth tokens
│   ├── test_credentials.json
│   └── auth_tokens.json
├── helpers/                # Test utilities
│   ├── credential_injector.dart
│   └── pod_auth_automator.dart
├── tools/                  # Development tools
│   ├── extract_tokens.dart
│   └── discover_oauth_params.dart
├── workflows/              # E2E workflow tests
│   └── pod_favorites_real_test.dart
└── app_test.dart          # Basic integration test
```

## Credential Injection for POD Testing

### Overview

To test real POD operations without manual login, we use credential injection. This allows E2E tests to run authenticated automatically.

### Setup

1. **Create test credentials file** at `integration_test/fixtures/test_credentials.json`:

```json
{
  "email": "test@anu.edu.au",
  "password": "YOUR_TEST_PASSWORD",
  "securityKey": "1234",
  "webId": "https://pods.dev.solidcommunity.au/healthpod-test/profile/card#me",
  "podUrl": "https://pods.dev.solidcommunity.au/healthpod-test/",
  "issuer": "https://pods.dev.solidcommunity.au/"
}
```

2. **Update the password** in the credentials file with the actual test account password.

3. **Add to .gitignore** to prevent committing real credentials:

```
# Test credentials
integration_test/fixtures/test_credentials.json
```

### Usage in Tests

```dart
import '../helpers/credential_injector.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load and inject credentials
    final credentials = await CredentialInjector.loadCredentials();
    await CredentialInjector.injectCredentials(credentials);

    // Verify injection
    final injected = await CredentialInjector.verifyInjection();
    expect(injected, isTrue);
  });

  tearDownAll(() async {
    // Clean up
    await CredentialInjector.clearCredentials();
  });

  testWidgets('test with authentication', (tester) async {
    // Your test code here
  });
}
```

### How It Works

1. **Load credentials** from `test_credentials.json`
2. **Inject into FlutterSecureStorage** - stores WebID and POD info
3. **App starts authenticated** - `isLoggedIn()` returns true
4. **Tests can use POD operations** - favorites, lists, etc.

### Limitations

- **Internal solidpod storage**: The `solidpod` package uses internal `AuthDataManager` class with private keys for storing authentication data, which makes direct credential injection challenging
- **OAuth tokens**: Solid POD uses OAuth with short-lived tokens obtained through browser authentication. The solidpod package manages these tokens internally.
- **Current implementation**: The credential injector attempts to inject WebID, POD URL, and issuer, but this may not be sufficient for the solidpod package to consider the user authenticated
- **Test POD required**: Credentials must be for a real test POD account
- **Security**: Never commit real passwords to version control

### Browser Automation Solution (Recommended)

We've implemented **Puppeteer-based browser automation** with full OAuth support to extract real POD tokens automatically! **Zero manual input required.**

#### How It Works

1. **Dynamic Client Registration**: Automatically registers an OAuth client with the Solid POD server
2. **PKCE Support**: Implements Proof Key for Code Exchange (PKCE) for secure public client authentication
3. **Automated OAuth Flow**:
   - Navigates to OAuth authorization endpoint
   - Enters email and password automatically
   - Handles consent screen ("Yes" button)
   - Intercepts OAuth callback to localhost:44007
4. **Token Exchange**: Exchanges authorization code for OAuth tokens (access_token, id_token, refresh_token)
5. **WebID Extraction**: Decodes JWT ID token to extract user's WebID
6. **Token Injection**: Injects all tokens into FlutterSecureStorage for E2E tests

#### What You Get

After running the token extraction tool, you'll have a complete OAuth token set:

```json
{
  "access_token": "eyJhbGc...",      // Bearer token for POD API requests
  "id_token": "eyJhbGc...",          // JWT with user identity
  "refresh_token": null,             // For token renewal (if provided)
  "webid": "https://pods.dev.solidcommunity.au/healthpod-test/profile/card#me",
  "token_type": "Bearer",
  "expires_in": 3600,
  "issuer": "https://pods.dev.solidcommunity.au",
  "client_id": "...",
  ...
}
```

#### Setup

1. **Install dependencies** (already in `pubspec.yaml`):
   ```yaml
   dev_dependencies:
     puppeteer: ^3.19.0
     crypto: ^3.0.6  # For PKCE
   ```

   Run: `flutter pub get`

2. **Extract OAuth tokens** (one-time or when tokens expire):
   ```bash
   # Headless mode (default)
   dart run integration_test/tools/extract_tokens.dart

   # With visible browser (for debugging)
   dart run integration_test/tools/extract_tokens.dart --no-headless
   ```

   This will:
   - Register OAuth client dynamically
   - Generate PKCE challenge
   - Navigate to OAuth authorization endpoint
   - Enter test credentials automatically (email, password)
   - Click "Yes" on consent screen
   - Intercept OAuth callback
   - Exchange authorization code for tokens
   - Extract WebID from ID token JWT
   - Save complete token set to `auth_tokens.json`

   Duration: ~15-20 seconds

#### Usage in Tests

```dart
import '../helpers/credential_injector.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inject real OAuth tokens (extracted via browser automation)
    await CredentialInjector.injectFullAuth();

    // Verify injection
    final injected = await CredentialInjector.verifyInjection();
    expect(injected, isTrue);
  });

  tearDownAll(() async {
    await CredentialInjector.clearCredentials();
  });

  testWidgets('test with real POD authentication', (tester) async {
    // Your test code here - fully authenticated!
  });
}
```

#### Files Created

- `integration_test/helpers/pod_auth_automator.dart` - Browser automation logic
- `integration_test/tools/extract_tokens.dart` - Standalone token extraction tool
- `integration_test/fixtures/auth_tokens.json` - Extracted OAuth tokens (gitignored)
- `integration_test/fixtures/auth_tokens.json.template` - Template file

#### Token Refresh

Tokens may expire after some time. If tests start failing with auth errors:

```bash
# Re-extract fresh tokens
dart run integration_test/tools/extract_tokens.dart

# Run tests again
flutter test integration_test/
```

#### CI/CD Integration

For continuous integration:

1. **Option A**: Store encrypted tokens as CI secrets
2. **Option B**: Run token extraction in CI before tests
3. **Option C**: Use mock POD service for CI

### Alternative Approaches

If browser automation doesn't work for your use case:

1. **Manual token extraction**: Login manually once, extract tokens from FlutterSecureStorage
2. **Mock POD service**: Create a mock POD for testing (fastest for CI/CD)
3. **Test without auth**: Test features that don't require POD authentication

## Test Types

### Basic App Tests

Tests that verify app loads and basic functionality without authentication:

```dart
// integration_test/app_test.dart
testWidgets('app loads and initializes', (WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MovieStar()));
  await tester.pumpAndSettle();
  expect(find.text('Movie Star'), findsWidgets);
});
```

### POD Operation Tests

Tests that verify POD operations with injected credentials:

```dart
// integration_test/workflows/pod_favorites_real_test.dart
testWidgets('can add movie to favorites on POD', (tester) async {
  final credentials = await CredentialInjector.loadCredentials();
  await CredentialInjector.injectCredentials(credentials);

  // Test POD operations
});
```

## Troubleshooting

### Windows .exe Lock

If tests fail with "cannot open moviestar.exe for writing":

```bash
# Kill the process
taskkill /F /IM moviestar.exe

# Clean build
flutter clean
flutter pub get
```

### Credential Injection Not Working

1. Verify `test_credentials.json` exists and has correct format
2. Check that password is filled in (not placeholder)
3. Verify test POD account is valid
4. Check FlutterSecureStorage platform configuration

## Security Notes

**IMPORTANT:**

- ✅ Use dedicated test POD accounts only
- ✅ Add `test_credentials.json` to `.gitignore`
- ✅ Never commit real passwords to version control
- ✅ Use different credentials for production vs testing
- ❌ Never use personal POD credentials in tests
- ❌ Never commit test credentials file with real passwords

## References

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Solid POD Authentication](https://solidproject.org/TR/protocol#authentication)
- [OAuth 2.0 with PKCE](https://datatracker.ietf.org/doc/html/rfc7636)
