# POD Provider Compatibility Guide

> This guide explains how to adapt the MovieStar integration testing
> approach for different POD providers. For general adaptation, see
> [Adapting for Your App](adapting.md).
>
> **Documentation index:** See [README.md](../README.md) for complete
> documentation navigation.

## Solid POD Providers

All Solid POD providers must implement the **Solid-OIDC
specification**, which uses:

+ OAuth 2.0 Authorization Code Flow
+ PKCE (Proof Key for Code Exchange)
+ DPoP (Demonstration of Proof-of-Possession) tokens

The core OAuth + DPoP + Puppeteer approach works with any compliant
Solid POD provider. Only provider-specific UI selectors and
configuration details need adjustment.

## Tested Providers

| Provider | Status | Notes |
|----------|--------|-------|
| **Community Solid Server (CSS)** | Tested | Used in MovieStar |
| **Node Solid Server (NSS)** | Compatible | Solid-OIDC support |
| **Enterprise Solid Server (ESS)** | Compatible | Commercial offering |
| **Custom implementations** | Unknown | Must implement Solid-OIDC |

## Provider-Specific Configuration

### Community Solid Server (CSS)

**Used by:** MovieStar integration tests

**Login flow:**

+ Email + Password
+ Optional security key (2FA)
+ Consent screen with "Yes" button

**Token expiry:** 3600 seconds (1 hour)

**Refresh tokens:** Supported but not always returned

**Configuration:**

```json
{
  "email": "test@example.com",
  "password": "your-password",
  "securityKey": "1234",
  "issuer": "https://pods.dev.solidcommunity.au/"
}
```

**Puppeteer selectors (current):**

```dart
// Email field
await page.waitForSelector('input[name="email"]');

// Password field
await page.waitForSelector('input[name="password"]');

// Security key field
await page.waitForSelector('input[id="securityKey"]');

// Consent button
await page.$('button:has-text("Yes")');
```

### Node Solid Server (NSS)

**Login flow:**

+ Username + Password (not email)
+ May have different consent screen UI
+ Older OAuth implementation

**Key differences from CSS:**

+ Uses `username` field instead of `email`
+ Consent button may be named `approve` instead of `yes`
+ May not support security key field

**Modify for NSS:**

```dart
// In pod_auth_automator.dart
final usernameInput = await page.waitForSelector(
  'input[name="username"]'  // Changed from 'email'
);

final consentButton = await page.waitForSelector(
  'button[name="approve"]'  // Changed from 'yes'
);
```

**Configuration:**

```json
{
  "username": "testuser",
  "password": "your-password",
  "issuer": "https://your-nss-server.example.com/"
}
```

### Enterprise Solid Server (ESS)

**Login flow:**

+ May use enterprise SSO (SAML, LDAP)
+ Custom branded consent screens
+ May require additional authentication factors

**Key considerations:**

+ Custom Puppeteer selectors for your ESS instance
+ May need to handle SSO redirect flows
+ Token expiry policies may differ

**Requires:**

+ Inspection of your ESS HTML structure
+ Custom selector configuration
+ Possible SSO flow automation

**Example adaptation:**

```dart
// Navigate to SSO login page
await page.goto(authUrl);

// Wait for SSO provider redirect
await page.waitForNavigation();

// Fill SSO credentials
await page.type('#sso-username', credentials['username']);
await page.type('#sso-password', credentials['password']);

// Submit SSO form
await page.click('button[type="submit"]');

// Handle consent screen (if separate)
await page.waitForSelector('.consent-form');
await page.click('button[name="consent"]');
```

## Adapting Puppeteer Selectors

### Finding Correct Selectors

Run browser automation in non-headless mode to inspect elements:

```bash
dart run integration_test/tools/generate_auth_data.dart --no-headless
```

Use Chrome DevTools to find selectors:

+ Right-click element → Inspect
+ Note the `id`, `name`, or `class` attributes
+ Use selector syntax: `#id`, `[name="value"]`, `.class`

### Common Selector Patterns

**By ID:**

```dart
await page.waitForSelector('#username');
```

**By name attribute:**

```dart
await page.waitForSelector('input[name="email"]');
```

**By class:**

```dart
await page.waitForSelector('.login-button');
```

**By text content:**

```dart
await page.$('button:has-text("Login")');
```

**By type and attribute:**

```dart
await page.waitForSelector('input[type="password"]');
```

### Updating Selectors in Code

**File:** `integration_test/helpers/pod_auth_automator.dart`

**Section:** `_fillLoginForm()` method

```dart
Future<void> _fillLoginForm(pw.Page page) async {
  // Update these selectors for your POD provider
  final emailInput = await page.waitForSelector(
    'input[name="email"]'  // ← Change this
  );
  await emailInput.type(credentials['email']);

  final passwordInput = await page.waitForSelector(
    'input[name="password"]'  // ← Change this
  );
  await passwordInput.type(credentials['password']);

  // Security key may not exist for all providers
  if (credentials.containsKey('securityKey')) {
    final securityKeyInput = await page.$(
      'input[id="securityKey"]'  // ← Change this
    );
    if (securityKeyInput != null) {
      await securityKeyInput.type(credentials['securityKey']);
    }
  }

  // Submit button selector
  final submitButton = await page.waitForSelector(
    'button[type="submit"]'  // ← Change this
  );
  await submitButton.click();
}
```

## Troubleshooting Provider Issues

### Timeout Waiting for Selector

**Symptom:** Puppeteer timeout waiting for login form elements

**Cause:** Selector doesn't match your provider's HTML

**Solution:**

+ Run with `--no-headless` to see browser
+ Inspect elements using Chrome DevTools
+ Update selectors in `pod_auth_automator.dart`

### Consent Screen Not Found

**Symptom:** Puppeteer can't find consent button

**Cause:** Different consent screen implementation

**Solution:**

Try alternative button selectors:

```dart
// Option 1: By text
await page.$('button:has-text("Consent")');

// Option 2: By value
await page.$('button[value="consent"]');

// Option 3: By name
await page.$('input[name="authorize"]');

// Option 4: By class
await page.$('.consent-button');
```

### OAuth Client Registration Fails

**Symptom:** 400/401 error during client registration

**Cause:** Provider requires additional metadata fields

**Solution:**

Update client metadata in `oauth_helpers.dart`:

```dart
final clientMetadata = {
  'client_name': 'YourApp E2E Test Client',
  'redirect_uris': [redirectUri],
  'grant_types': ['authorization_code', 'refresh_token'],
  'response_types': ['code'],
  'token_endpoint_auth_method': 'none',
  'scope': 'openid profile offline_access',  // May be required
  'application_type': 'native',  // Or 'web'
};
```

### Token Format Differences

**Symptom:** solidpod package can't parse tokens

**Cause:** Provider returns non-standard token structure

**Solution:**

Log token response for debugging:

```dart
print('Token response: ${jsonEncode(tokenResponse)}');
```

Verify it contains required fields:

+ `access_token` (string)
+ `id_token` (string)
+ `token_type` (must be "DPoP")
+ `expires_in` or `expires_at` (integer)

## Provider Comparison

| Feature | CSS | NSS | ESS |
|---------|-----|-----|-----|
| **Login field** | email | username | Varies |
| **2FA support** | Security key | No | Varies |
| **Consent screen** | "Yes" button | "Approve" | Custom |
| **Token expiry** | 3600s | Varies | Configurable |
| **Refresh tokens** | Sometimes | Yes | Yes |
| **DPoP required** | Yes | Yes | Yes |

## Testing Your Adaptation

### Step 1: Verify Selectors

Run manual extraction to test selectors:

```bash
flutter run integration_test/tools/generate_auth_data.dart -d linux
```

If login succeeds, selectors are correct.

### Step 2: Test Automation

Run automated extraction:

```bash
dart run integration_test/tools/generate_auth_data.dart
```

Should complete in 15-20 seconds without errors.

### Step 3: Verify Auth Data

Check generated file structure:

```bash
cat integration_test/fixtures/complete_auth_data.json | jq .
```

Should contain `web_id`, `rsa_info`, `auth_response`.

### Step 4: Run Integration Tests

Test with your app:

```bash
flutter test integration_test/workflows/your_test.dart \
  -d linux --dart-define=INTERACT=0
```

## See Also

+ [Adapting for Your App](adapting.md) - General adaptation guide
+ [Authentication Guide](../concepts/authentication.md) - OAuth/DPoP concepts
+ [Architecture](../concepts/architecture.md) - Component interactions
+ [Testing Guide](testing-guide.md) - Running adapted tests
