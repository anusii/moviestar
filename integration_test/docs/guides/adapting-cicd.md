# CI/CD Integration Guide

> This guide explains how to integrate POD authentication testing into
> continuous integration and deployment pipelines. For general
> adaptation, see [Adapting for Your App](adapting.md).
>
> **Documentation index:** See [README.md](../README.md) for complete
> documentation navigation.

## Overview

Running integration tests with POD authentication in CI/CD requires:

+ Chrome/Chromium browser for automation
+ Encrypted test credentials stored as secrets
+ Auth data generation before test execution
+ Individual test execution (not batch mode)

## GitHub Actions Integration

### Complete Workflow Example

```yaml
name: Integration Tests

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  integration-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          flutter-version: '3.24.0'

      - name: Install Chrome
        run: |
          wget -q -O - \
            https://dl-ssl.google.com/linux/linux_signing_key.pub \
            | sudo apt-key add -
          sudo sh -c 'echo "deb [arch=amd64] \
            http://dl.google.com/linux/chrome/deb/ stable main" \
            >> /etc/apt/sources.list.d/google.list'
          sudo apt-get update
          sudo apt-get install -y google-chrome-stable

      - name: Install dependencies
        run: flutter pub get

      - name: Setup test credentials
        run: |
          mkdir -p integration_test/fixtures
          echo '${{ secrets.TEST_CREDENTIALS }}' \
            > integration_test/fixtures/test_credentials.json

      - name: Generate auth data
        run: |
          dart run integration_test/tools/generate_auth_data.dart

      - name: Run integration tests
        run: |
          flutter test integration_test/app_test.dart \
            -d linux --dart-define=INTERACT=0
          flutter test integration_test/workflows/your_test.dart \
            -d linux --dart-define=INTERACT=0
```

### Workflow Breakdown

**Chrome installation:**

+ Required for Puppeteer browser automation
+ Uses Google's official Chrome repository
+ Installs stable version

**Test credentials setup:**

+ Reads encrypted credentials from GitHub secrets
+ Creates `test_credentials.json` in fixtures directory
+ Only exists during CI run (not committed)

**Auth data generation:**

+ Runs automated browser flow
+ Generates complete auth data with RSA keys
+ Creates `complete_auth_data.json` for tests

**Individual test execution:**

+ Runs each test file separately (not batch mode)
+ Uses `INTERACT=0` for quick execution
+ Desktop platform required (linux in CI)

## Storing Credentials Securely

### GitHub Secrets Setup

Navigate to repository settings:

```text
Repository → Settings → Secrets and variables → Actions
```

Add secret named `TEST_CREDENTIALS` with JSON content:

```json
{
  "email": "test@example.com",
  "password": "your-test-password",
  "securityKey": "1234",
  "webId": "https://pods.example.com/test/profile/card#me",
  "podUrl": "https://pods.example.com/test/",
  "issuer": "https://pods.example.com/"
}
```

### Using Secrets in Workflow

```yaml
- name: Setup test credentials
  run: |
    mkdir -p integration_test/fixtures
    echo '${{ secrets.TEST_CREDENTIALS }}' \
      > integration_test/fixtures/test_credentials.json
```

### Multi-Environment Secrets

For different environments (staging, production):

```yaml
- name: Setup credentials (staging)
  if: github.ref == 'refs/heads/dev'
  run: |
    echo '${{ secrets.TEST_CREDENTIALS_STAGING }}' \
      > integration_test/fixtures/test_credentials.json

- name: Setup credentials (production)
  if: github.ref == 'refs/heads/main'
  run: |
    echo '${{ secrets.TEST_CREDENTIALS_PROD }}' \
      > integration_test/fixtures/test_credentials.json
```

## Alternative Approaches

### Option A: Pre-Generated Tokens (Faster)

Generate tokens locally, encrypt, store in CI:

```bash
# Generate auth data locally
dart run integration_test/tools/generate_auth_data.dart

# Encrypt the file
gpg --symmetric --cipher-algo AES256 \
  integration_test/fixtures/complete_auth_data.json

# Commit encrypted version
git add integration_test/fixtures/complete_auth_data.json.gpg
git commit -m "Add encrypted auth data for CI"
```

**CI workflow:**

```yaml
- name: Decrypt auth data
  run: |
    echo "${{ secrets.GPG_PASSPHRASE }}" | \
      gpg --quiet --batch --yes --decrypt \
      --passphrase-fd 0 \
      --output integration_test/fixtures/complete_auth_data.json \
      integration_test/fixtures/complete_auth_data.json.gpg
```

**Pros:**

+ Faster CI execution (no browser automation)
+ No Chrome installation needed
+ More reliable (no browser timeout issues)

**Cons:**

+ Tokens expire after 1 hour (requires rotation)
+ Must regenerate and commit when expired
+ Not suitable for long-running CI jobs

### Option B: On-Demand Generation (Current)

Generate fresh tokens in CI using browser automation:

```yaml
- name: Generate auth data
  run: dart run integration_test/tools/generate_auth_data.dart
```

**Pros:**

+ Always fresh tokens
+ No manual rotation needed
+ Tests real OAuth flow

**Cons:**

+ Requires Chrome installation
+ Slower (15-20 seconds for generation)
+ Can timeout if POD server slow

### Option C: Mock POD Service

Create mock POD service for CI that bypasses real authentication:

```dart
// In test setup
if (const bool.fromEnvironment('CI')) {
  // Use mock auth for CI
  await MockAuthService.injectMockCredentials();
} else {
  // Use real auth for local development
  await CredentialInjector.injectFullAuth();
}
```

**Pros:**

+ Fastest option
+ No external dependencies
+ No credential management

**Cons:**

+ Doesn't test real POD integration
+ Requires maintaining mock service
+ May miss real-world authentication issues

## Platform-Specific CI Configuration

### Linux (Ubuntu)

```yaml
runs-on: ubuntu-latest
steps:
  - name: Install Chrome
    run: |
      sudo apt-get update
      sudo apt-get install -y google-chrome-stable

  - name: Run tests
    run: flutter test integration_test/ -d linux
```

### macOS

```yaml
runs-on: macos-latest
steps:
  - name: Install Chrome
    run: brew install --cask google-chrome

  - name: Run tests
    run: flutter test integration_test/ -d macos
```

### Windows

```yaml
runs-on: windows-latest
steps:
  - name: Install Chrome
    run: |
      choco install googlechrome -y

  - name: Run tests
    run: flutter test integration_test/ -d windows
```

## Migration Checklist for CI/CD

When setting up CI/CD for your adapted app:

**Phase 1: Secrets Setup**

+ [ ] Create dedicated test POD account
+ [ ] Generate test credentials JSON
+ [ ] Add `TEST_CREDENTIALS` to GitHub secrets
+ [ ] Test credentials manually to verify they work

**Phase 2: Workflow Configuration**

+ [ ] Create `.github/workflows/integration-tests.yml`
+ [ ] Add Flutter setup action
+ [ ] Add Chrome installation steps
+ [ ] Add credential injection step
+ [ ] Add auth data generation step

**Phase 3: Test Execution**

+ [ ] Run each test file individually (not batch mode)
+ [ ] Use `INTERACT=0` for quick execution
+ [ ] Specify desktop platform (`-d linux/windows/macos`)
+ [ ] Add `AUTO_REGENERATE=false` for POD tests

**Phase 4: Verification**

+ [ ] Push to trigger workflow
+ [ ] Verify Chrome installs successfully
+ [ ] Verify auth data generation completes
+ [ ] Verify tests pass in CI
+ [ ] Check execution time (should be < 5 minutes)

## Troubleshooting CI Issues

### Chrome Not Found

**Symptom:** Puppeteer can't find Chrome executable

**Solution:** Verify Chrome installation in workflow:

```yaml
- name: Verify Chrome installation
  run: which google-chrome || which chromium-browser
```

### Auth Generation Timeout

**Symptom:** Browser automation times out in CI

**Solution:** Increase timeout or use pre-generated tokens:

```dart
// In generate_auth_data.dart
final browser = await puppeteer.launch(
  timeout: Duration(minutes: 5),  // Increased from default
);
```

### Tests Fail in CI but Pass Locally

**Symptom:** Integration tests fail only in CI environment

**Possible causes:**

+ Missing dependencies (check Flutter version)
+ Different platform behavior (Linux vs Windows/macOS)
+ Network issues (POD server unreachable from CI)
+ Timing issues (CI slower than local machine)

**Solution:** Add debug logging:

```yaml
- name: Run tests with verbose output
  run: |
    flutter test integration_test/ \
      -d linux --dart-define=INTERACT=0 --verbose
```

### Batch Mode Failures

**Symptom:** First test passes, subsequent tests fail

**Solution:** Run tests individually (see example workflow above)

```yaml
- name: Run tests individually
  run: |
    flutter test integration_test/app_test.dart -d linux
    flutter test integration_test/workflows/test1.dart -d linux
    flutter test integration_test/workflows/test2.dart -d linux
```

## See Also

+ [Adapting for Your App](adapting.md) - General adaptation guide
+ [Provider Compatibility](adapting-providers.md) - POD provider setup
+ [Testing Guide](testing-guide.md) - Running tests locally
+ [Troubleshooting](troubleshooting.md) - Common issues
