# Integration Test Setup

> **New to POD authentication?** Read [Understanding POD Authentication](authentication.md) first to learn why OAuth, DPoP, and browser automation are necessary.
>
> **Documentation index:** See [README.md](README.md) for complete documentation navigation.

This document describes the initial setup for E2E testing infrastructure for Movie Star using Flutter's integration_test package.

**For day-to-day testing usage, see [Testing Guide](testing-guide.md).**

## Overview

Movie Star uses **integration_test** for cross-platform E2E testing on Windows, Linux, macOS, web, Android, and iOS.

## Installation

### Dependencies

Add the following to `pubspec.yaml`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  puppeteer: ^3.19.0  # Browser automation for POD OAuth testing
  pointycastle: ^3.9.1  # RSA key generation for DPoP
```

Run `flutter pub get` to install dependencies.

### Platform-Specific Setup

#### Linux
```bash
flutter config --enable-linux-desktop
flutter create --platforms=linux .
```

#### Windows
```bash
flutter config --enable-windows-desktop
flutter create --platforms=windows .
```

#### macOS
```bash
flutter config --enable-macos-desktop
flutter create --platforms=macos .
```

## Test Organization

```text
integration_test/
├── fixtures/               # Test data and auth tokens (gitignored)
│   ├── test_credentials.json
│   └── complete_auth_data.json
├── helpers/                # Test utilities
│   ├── credential_injector.dart
│   ├── pod_auth_automator.dart
│   ├── oauth_helpers.dart
│   └── test_constants.dart
├── utils/                  # Development tools
│   ├── delays.dart
│   ├── generate_auth_data.dart
│   ├── generate_auth_data.dart
│   └── discover_oauth_params.dart
├── workflows/              # E2E workflow tests
│   ├── pod_favorites_real_test.dart
│   └── visual_login_test.dart
├── app_test.dart          # Basic integration test
└── app_hive_test.dart     # Hive initialization test
```

## Initial Credential Setup

### 1. Create Test Credentials File

Create `integration_test/fixtures/test_credentials.json`:

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

### 2. Update Credentials

- Replace `YOUR_TEST_PASSWORD` with your actual test account password
- Update `email`, `webId`, and `podUrl` if using a different test account

### 3. Verify .gitignore

Ensure these files are **NOT** committed:

```gitignore
# Integration test auth data (contains sensitive tokens)
integration_test/fixtures/complete_auth_data.json
integration_test/fixtures/test_credentials.json
```

## Extract Authentication Data

### First-Time Setup

Before running POD-authenticated tests, extract complete auth data:

```bash
# Automated extraction (recommended)
dart run integration_test/tools/generate_auth_data.dart

# Manual extraction (if automation fails)
flutter run integration_test/tools/generate_auth_data.dart -d linux
```

This generates:
- `integration_test/fixtures/complete_auth_data.json` - Complete auth data with RSA keys

**Token Expiration**: OAuth tokens expire after 1 hour. Re-run extraction if tests fail with `invalid_grant` errors.

## Complete Auth Data vs Legacy Tokens

### Why Complete Auth Data?

The solidpod package requires **complete authentication data** including:
- **RSA keypair** for DPoP (Demonstration of Proof-of-Possession)
- **Full OAuth2 Credential object**
- **Client metadata** and logout URL

**Legacy token injection** (basic access_token/id_token only) will fail with:
```
OpenIdException(invalid_grant): grant request is invalid
```

### What Gets Generated

The extraction tools generate RSA keypairs and build the complete auth structure:

```json
{
  "web_id": "https://pods.dev.solidcommunity.au/healthpod-test/profile/card#me",
  "logout_url": "https://pods.dev.solidcommunity.au/logout",
  "rsa_info": "{...RSA keypair in PEM format...}",
  "auth_response": {
    "access_token": "eyJhbGc...",
    "id_token": "eyJhbGc...",
    "token_type": "DPoP",
    ...
  }
}
```

## Browser Automation Details

### OAuth Flow Automation

The automated extraction performs:

1. **Dynamic Client Registration** - Registers OAuth client with POD server
2. **PKCE Generation** - Creates Proof Key for Code Exchange challenge
3. **Browser Navigation** - Opens Chrome/Chromium in headless mode
4. **Form Automation** - Fills email, password, security key
5. **Consent Handling** - Clicks "Yes" on consent screen
6. **Callback Interception** - Captures OAuth callback on localhost:44007
7. **Token Exchange** - Exchanges authorization code for tokens
8. **RSA Key Generation** - Generates 2048-bit RSA keypair using pointycastle
9. **Auth Data Assembly** - Builds complete auth data structure
10. **File Storage** - Saves to `complete_auth_data.json`

**Duration**: ~15-20 seconds

### Requirements

- **Chrome/Chromium** installed on system
- **Network access** to POD server
- **Valid test credentials** in `test_credentials.json`

## CI/CD Integration

For continuous integration environments:

### Option A: Pre-Generated Tokens
1. Generate tokens locally
2. Encrypt `complete_auth_data.json`
3. Store as CI secret
4. Decrypt before running tests

### Option B: On-Demand Extraction
1. Install Chrome in CI environment
2. Store test credentials as CI secrets
3. Run `dart run integration_test/tools/generate_auth_data.dart` before tests

### Option C: Mock POD Service
1. Create mock POD service for CI
2. Bypass real authentication
3. Fastest option but doesn't test real POD integration

## Security Best Practices

**IMPORTANT:**

✅ **DO:**
- Use dedicated test POD accounts only
- Add credential files to `.gitignore`
- Rotate test account passwords regularly
- Use different credentials for staging vs production testing
- Store CI credentials encrypted

❌ **DON'T:**
- Commit `test_credentials.json` with real passwords
- Use personal POD credentials in tests
- Share test credentials in public repositories
- Reuse production credentials for testing

## Troubleshooting Setup Issues

### Chrome/Chromium Not Found

**Problem**: `generate_auth_data.dart` fails to find browser

**Solution**:
```bash
# Linux
sudo apt install chromium-browser

# macOS
brew install chromium

# Windows
# Download Chrome from https://www.google.com/chrome/
```

### Token Extraction Timeout

**Problem**: Browser automation times out

**Solution**:
```bash
# Run with visible browser to debug
dart run integration_test/tools/generate_auth_data.dart --no-headless
```

### Invalid Credentials

**Problem**: Login fails during extraction

**Solution**:
1. Verify credentials in `test_credentials.json`
2. Test manual login at https://pods.dev.solidcommunity.au/
3. Check if security key is correct
4. Ensure test account is active

### Platform Not Enabled

**Problem**: `flutter test` fails with "No device found"

**Solution**:
```bash
# Check enabled platforms
flutter config

# Enable desktop platform
flutter config --enable-linux-desktop  # or --enable-windows-desktop

# Verify devices available
flutter devices
```

## Next Steps

After completing setup:

1. **Read [TESTING_GUIDE.md](TESTING_GUIDE.md)** for comprehensive testing documentation
2. **Run basic test**: `flutter test integration_test/app_test.dart -d linux`
3. **Run POD test**: `flutter test integration_test/workflows/pod_favorites_real_test.dart -d linux`
4. **Use qtest mode**: `make qtest.all` for quick automated testing

## References

- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Comprehensive testing guide
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Solid POD Authentication](https://solidproject.org/TR/protocol#authentication)
- [OAuth 2.0 with PKCE](https://datatracker.ietf.org/doc/html/rfc7636)
- [DPoP RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449)
