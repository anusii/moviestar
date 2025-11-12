# JSON Files Reference

This guide explains the structure and purpose of JSON files used in the
integration test framework.

## Overview

The test framework uses two JSON files for authentication:

| File | Purpose | Lifespan | Git Tracked |
|------|---------|----------|-------------|
| `test_credentials.json` | User credentials for POD login | Permanent | No (git-ignored) |
| `complete_auth_data.json` | OAuth tokens + RSA keys | 1 hour | No (git-ignored) |

## test_credentials.json

### Purpose

Contains your POD account credentials that Puppeteer uses to automate the
login flow. This file is created manually and remains stable.

### Location

```text
integration_test/fixtures/test_credentials.json
```

### Structure

```json
{
  "email": "your-pod-username",
  "password": "your-pod-password",
  "securityKey": "your-2fa-security-key",
  "webId": "https://pods.dev.solidcommunity.au/your-pod/profile/card#me",
  "podUrl": "https://pods.dev.solidcommunity.au/your-pod/",
  "issuer": "https://pods.dev.solidcommunity.au"
}
```

### Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `email` | string | POD account email/username | `"healthpod-test"` |
| `password` | string | POD account password | `"SecurePassword123"` |
| `securityKey` | string | Two-factor authentication key | `"123456"` (if enabled) |
| `webId` | string | Your Solid WebID (unique identifier) | `"https://pods.dev.solidcommunity.au/healthpod-test/profile/card#me"` |
| `podUrl` | string | Root URL of your POD storage | `"https://pods.dev.solidcommunity.au/healthpod-test/"` |
| `issuer` | string | OpenID Connect issuer (POD provider) | `"https://pods.dev.solidcommunity.au"` |

### Setup

+ Create an account on a Solid POD provider (e.g.,
  https://pods.dev.solidcommunity.au)
+ Note your credentials and WebID
+ Create the file:

```bash
cat > integration_test/fixtures/test_credentials.json <<'EOF'
{
  "email": "your-username",
  "password": "your-password",
  "securityKey": "your-2fa-key",
  "webId": "https://pods.dev.solidcommunity.au/your-username/profile/card#me",
  "podUrl": "https://pods.dev.solidcommunity.au/your-username/",
  "issuer": "https://pods.dev.solidcommunity.au"
}
EOF
```

### Security

**CRITICAL:** This file contains sensitive credentials and is git-ignored.
Never commit it to version control.

```gitignore
# .gitignore already includes:
integration_test/fixtures/test_credentials.json
```

## complete_auth_data.json

### Purpose

Contains the **complete authentication data structure** extracted from a
real OAuth login session, including:

+ DPoP-bound OAuth tokens (access_token, id_token, refresh_token)
+ RSA keypair for DPoP proof signing
+ OAuth client metadata
+ Logout URL

This file is **automatically generated** by the Puppeteer automation and
expires after 1 hour.

### Location

```text
integration_test/fixtures/complete_auth_data.json
```

### Structure

```json
{
  "web_id": "https://pods.dev.solidcommunity.au/healthpod-test/profile/card#me",
  "logout_url": "https://pods.dev.solidcommunity.au/logout",
  "rsa_info": {
    "public_key_jwk": {
      "kty": "RSA",
      "n": "base64-encoded-modulus...",
      "e": "AQAB"
    },
    "private_key_jwk": {
      "kty": "RSA",
      "n": "base64-encoded-modulus...",
      "e": "AQAB",
      "d": "base64-encoded-private-exponent...",
      "p": "base64-encoded-prime1...",
      "q": "base64-encoded-prime2...",
      "dp": "base64-encoded-dmp1...",
      "dq": "base64-encoded-dmq1...",
      "qi": "base64-encoded-iqmp..."
    },
    "private_key_pem": "-----BEGIN RSA PRIVATE KEY-----\nMIIEow...\n-----END RSA PRIVATE KEY-----",
    "public_key_pem": "-----BEGIN PUBLIC KEY-----\nMIIBIj...\n-----END PUBLIC KEY-----"
  },
  "auth_response": {
    "token": {
      "access_token": "eyJhbGciOiJFUzI1NiIsInR5cCI6ImF0K2p3dCIsImtpZCI6IjEifQ...",
      "id_token": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjEifQ...",
      "refresh_token": "nrU_gKrpS9ZTbvLfSt6O3UCCLNdsFPUyuZ2dDzG0bUx",
      "token_type": "DPoP",
      "expires_at": 1762867910,
      "scope": "openid webid offline_access"
    },
    "client": {
      "client_id": "-I5uBOy6NBCfMJUTk2QnJ",
      "client_name": "MovieStar E2E Test Client",
      "redirect_uris": ["http://localhost:44007/"]
    },
    "credential": {
      "webId": "https://pods.dev.solidcommunity.au/healthpod-test/profile/card#me",
      "iss": "https://pods.dev.solidcommunity.au/",
      "accessToken": "eyJhbGciOiJFUzI1NiIsInR5cCI6ImF0K2p3dCIsImtpZCI6IjEifQ...",
      "idToken": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjEifQ...",
      "refreshToken": "nrU_gKrpS9ZTbvLfSt6O3UCCLNdsFPUyuZ2dDzG0bUx",
      "tokenType": "DPoP",
      "expiresAt": 1762867910
    }
  }
}
```

### Field Descriptions

#### Top-Level Fields

| Field | Description |
|-------|-------------|
| `web_id` | User's Solid WebID (copied from auth_response) |
| `logout_url` | URL to revoke OAuth session |
| `rsa_info` | RSA keypair in multiple formats for DPoP signing |
| `auth_response` | Complete OAuth token response and metadata |

#### RSA Info Fields

| Field | Description |
|-------|-------------|
| `public_key_jwk` | Public key in JSON Web Key format (shared with POD) |
| `private_key_jwk` | Private key in JWK format (for solidpod package) |
| `private_key_pem` | Private key in PEM format (standard encoding) |
| `public_key_pem` | Public key in PEM format |

#### Auth Response > Token Fields

| Field | Description | Expiry |
|-------|-------------|--------|
| `access_token` | DPoP-bound token for API requests | 1 hour |
| `id_token` | JWT containing user identity claims | 1 hour |
| `refresh_token` | Token to obtain new access tokens | Varies (not always supported) |
| `token_type` | Always "DPoP" for Solid | N/A |
| `expires_at` | Unix timestamp when token expires | N/A |
| `scope` | OAuth scopes granted | N/A |

### Generation

This file is generated by running:

```bash
# Automated (recommended)
dart run integration_test/tools/generate_auth_data.dart

# Or through test auto-regeneration
flutter test integration_test/workflows/pod_favorites_real_test.dart \
  -d linux --dart-define=AUTO_REGENERATE=true
```

The generation process:

+ Loads credentials from `test_credentials.json`
+ Launches Puppeteer browser automation
+ Performs OAuth login flow
+ Generates RSA keypair
+ Exchanges authorization code for DPoP-bound tokens
+ Saves complete structure to this file

### Token Expiration

OAuth access tokens expire after **3600 seconds (1 hour)**. When tokens
expire, you'll see:

```text
OpenIdException(invalid_grant): grant request is invalid
```

**Solutions:**

**Auto-regeneration** (recommended for local testing):

```dart
await CredentialInjector.injectFullAuth(autoRegenerateOnFailure: true);
```

**Manual regeneration**:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

**Pre-generate for CI** (see
[Testing Guide](testing-guide.md#ci-cd-integration))

### Token Lifecycle

```mermaid
stateDiagram-v2
    [*] --> NotGenerated: Initial state
    NotGenerated --> Fresh: Run generate_auth_data.dart
    Fresh --> Expired: Wait 1 hour
    Expired --> Fresh: Regenerate tokens
    Fresh --> InUse: Test loads complete_auth_data.json
    InUse --> TestPass: Token valid
    InUse --> TestFail: Token expired
    TestFail --> Fresh: Auto-regenerate (if enabled)
```

## File Comparison

### Why Two Files?

| Aspect | test_credentials.json | complete_auth_data.json |
|--------|----------------------|------------------------|
| **Contains** | User credentials | OAuth tokens + RSA keys |
| **Created by** | Developer (manual) | Puppeteer automation |
| **Lifespan** | Permanent | 1 hour |
| **Used by** | Puppeteer login script | Test credential injection |
| **Regeneration** | Never (unless password changes) | Every hour or on-demand |
| **Format** | Simple key-value pairs | Complex nested structure |

### Data Flow

```mermaid
flowchart LR
    A[test_credentials.json] --> B[Puppeteer Automation]
    B --> C[OAuth Login Flow]
    C --> D[Generate RSA Keys]
    D --> E[Exchange for Tokens]
    E --> F[complete_auth_data.json]
    F --> G[CredentialInjector]
    G --> H[FlutterSecureStorage]
    H --> I[Integration Tests]
```

## Troubleshooting

### File Not Found

**Error:**

```text
Exception: Test credentials file not found: integration_test/fixtures/test_credentials.json
```

**Solution:** Create `test_credentials.json` as described above.

### Invalid JSON Format

**Error:**

```text
FormatException: Unexpected character
```

**Solution:** Validate JSON syntax with:

```bash
cat integration_test/fixtures/test_credentials.json | jq .
```

### Token Expired

**Error:**

```text
OpenIdException(invalid_grant)
```

**Solution:** Regenerate `complete_auth_data.json`:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

### Missing RSA Keys

**Error:**

```text
NoSuchMethodError: The getter 'rsa_info' was called on null
```

**Cause:** File was manually edited or generated with old tool version.

**Solution:** Delete and regenerate:

```bash
rm integration_test/fixtures/complete_auth_data.json
dart run integration_test/tools/generate_auth_data.dart
```

## Security Best Practices

+ **Never commit credential files** - Both files are git-ignored by default
+ **Use test accounts** - Don't use production POD accounts for testing
+ **Rotate credentials regularly** - Change test account passwords
  periodically
+ **Limit POD data** - Test PODs should contain only non-sensitive test data
+ **Encrypt in CI/CD** - Use GitHub Secrets or similar for CI environments

## Next Steps

+ [Authentication Guide](authentication.md) - Understand OAuth and DPoP
  concepts
+ [Architecture Overview](architecture.md) - See how files are used in
  testing
+ [Testing Guide](testing-guide.md) - Run tests with these credentials
