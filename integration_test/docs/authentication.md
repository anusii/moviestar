# Understanding POD Authentication

This guide explains why Solid POD authentication requires browser
automation and specialized token handling instead of traditional Flutter UI
testing.

## Table of Contents

+ [Why Can't We Use Normal Flutter Testing?](#why-cant-we-use-normal-flutter-testing)
+ [OAuth 2.0 Authorization Code Flow](#oauth-20-authorization-code-flow)
+ [DPoP: Proof-of-Possession Tokens](#dpop-proof-of-possession-tokens)
+ [RSA Keypairs for Token Signing](#rsa-keypairs-for-token-signing)
+ [Why Puppeteer Browser Automation?](#why-puppeteer-browser-automation)

## Why Can't We Use Normal Flutter Testing?

Flutter integration tests can tap through UI elements in your app, but
Solid POD authentication requires an **external OAuth flow** that leaves
your app's context:

```mermaid
sequenceDiagram
    participant Test as Integration Test
    participant App as MovieStar App
    participant Browser as External Browser
    participant POD as POD Server

    Test->>App: Launch app
    App->>POD: Request authorization URL
    POD-->>App: Return auth URL
    App->>Browser: Open external browser
    Note over App,Browser: App loses control here
    Browser->>POD: User logs in
    POD->>Browser: Redirect with auth code
    Browser->>App: Return to app (localhost callback)
    App->>POD: Exchange code for tokens
    POD-->>App: Return access + ID tokens
```

**The problem:** Flutter tests cannot control the external browser or
intercept the OAuth callback URL. This is why we need Puppeteer to automate
the browser separately.

## OAuth 2.0 Authorization Code Flow

Solid POD uses the **Authorization Code Flow with PKCE** (Proof Key for
Code Exchange), designed for public clients like mobile and desktop apps
that can't securely store client secrets.

### Why OAuth?

OAuth separates **authentication** (proving who you are) from
**authorization** (what you can access). This enables:

+ Users control their data on their own POD server
+ Apps request permission to access specific resources
+ No passwords stored in apps - tokens are used instead

### Key Components

| Component | Purpose | Example |
|-----------|---------|---------|
| **Authorization Code** | Temporary code exchanged for tokens | `xCOp_oCtHrOWgLQO4ShL...` |
| **Code Verifier** | Random string (PKCE security) | Generated per-session |
| **Code Challenge** | SHA-256 hash of verifier | Sent with auth request |
| **Access Token** | Bearer token for API requests | JWT, expires in 1 hour |
| **ID Token** | Contains user identity (WebID) | JWT with user claims |
| **Refresh Token** | Long-lived token to get new access tokens | Not consistently supported by all POD servers |

### PKCE Security

PKCE prevents authorization code interception attacks:

+ App generates random `code_verifier`
+ App hashes it to create `code_challenge`
+ POD server stores challenge during authorization
+ When exchanging code for tokens, app sends original verifier
+ Server verifies `SHA256(verifier) == challenge`

This proves the app that started the flow is completing it, even without a
client secret.

**Learn more:** [RFC 7636 - Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636)

## DPoP: Proof-of-Possession Tokens

Standard OAuth uses **Bearer tokens** - anyone who possesses the token can
use it. If stolen, the token can be used by attackers.

**DPoP (Demonstration of Proof-of-Possession)** adds cryptographic proof
that you own the private key associated with the token.

### Bearer vs DPoP Comparison

| Aspect | Bearer Token | DPoP Token |
|--------|--------------|------------|
| **Security** | Stolen token = full access | Stolen token useless without private key |
| **Header** | `Authorization: Bearer <token>` | `Authorization: DPoP <token>` + `DPoP: <proof>` |
| **Binding** | Not bound to client | Bound to client's public key |
| **Required for Solid** | No | Yes |

### How DPoP Works

```mermaid
sequenceDiagram
    participant App
    participant POD as POD Server

    Note over App: Generate RSA keypair
    App->>POD: Token request + public key (JWK)
    POD-->>App: DPoP-bound access token
    Note over App: Sign proof using private key
    App->>POD: API request + token + proof
    Note over POD: Verify signature with public key
    POD-->>App: Data (if proof valid)
```

Each API request includes:

+ **Access token** - DPoP-bound token from OAuth flow
+ **DPoP proof** - JWT signed with your private key containing:
  + HTTP method (GET, POST, etc.)
  + Target URL
  + Timestamp (prevents replay attacks)
  + Unique request ID (jti claim)

The POD server verifies the signature matches the public key bound to the
token.

**Learn more:** [RFC 9449 - OAuth 2.0 Demonstrating Proof of Possession](https://datatracker.ietf.org/doc/html/rfc9449)

## RSA Keypairs for Token Signing

DPoP requires an **RSA keypair** (public + private key) for cryptographic signing.

### Why RSA?

RSA is an **asymmetric encryption algorithm**:

+ **Private key** - Signs DPoP proofs, never leaves the app
+ **Public key** - POD server uses this to verify signatures

### Key Formats

The test framework generates and stores RSA keys in two formats:

**JWK (JSON Web Key)** - Used by solidpod package for token signing:

```json
{
  "kty": "RSA",
  "n": "base64-encoded-modulus",
  "e": "AQAB",
  "d": "base64-encoded-private-exponent",
  "p": "base64-encoded-prime1",
  "q": "base64-encoded-prime2",
  ...
}
```

**PEM (Privacy Enhanced Mail)** - Standard format for key storage:

```text
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA...
-----END RSA PRIVATE KEY-----
```

### Key Generation

The integration test framework generates 2048-bit RSA keys using the
`pointycastle` package:

```dart
// Generate keypair
final keyPair = generateRSAKeyPair();

// Convert to JWK for solidpod
final jwk = convertToJWK(keyPair);

// Convert to PEM for storage
final pem = convertToPEM(keyPair);
```

**Security note:** Test RSA keys are stored in `complete_auth_data.json`
(git-ignored). For production apps, keys should be stored in secure device
storage (iOS Keychain, Android Keystore, etc.).

**Learn more:** [RFC 7517 - JSON Web Key (JWK)](https://datatracker.ietf.org/doc/html/rfc7517)

## Why Puppeteer Browser Automation?

Puppeteer allows us to automate the OAuth browser flow that Flutter tests cannot control.

### What Puppeteer Does

+ **Launches headless Chrome** - Browser instance controlled
  programmatically
+ **Navigates to POD login** - Fills email, password, security key
+ **Intercepts OAuth callback** - Captures authorization code from redirect
  URL
+ **Generates RSA keypair** - Creates DPoP keys programmatically
+ **Exchanges code for tokens** - Completes OAuth flow
+ **Saves complete auth data** - Stores tokens + RSA keys for test
  injection

### The Complete Flow

```mermaid
sequenceDiagram
    participant Automator as Puppeteer Automator
    participant Browser as Headless Chrome
    participant POD as POD Server
    participant File as complete_auth_data.json

    Automator->>Browser: Launch browser
    Automator->>POD: Register OAuth client
    POD-->>Automator: client_id
    Note over Automator: Generate PKCE verifier
    Automator->>Browser: Navigate to auth URL
    Automator->>Browser: Fill email
    Automator->>Browser: Fill password
    Automator->>Browser: Fill security key
    Browser->>POD: Submit login
    POD->>Browser: Consent screen
    Automator->>Browser: Click "Yes" button
    Browser->>Automator: Redirect to localhost:44007?code=...
    Note over Automator: Intercept callback
    Note over Automator: Generate RSA keypair
    Automator->>POD: Exchange code + verifier + public key
    POD-->>Automator: DPoP-bound tokens
    Automator->>File: Save tokens + RSA keys
```

### Why Not Flutter WebView?

Flutter's `webview_flutter` package **cannot intercept OAuth callbacks**
reliably across platforms (Windows, Linux, macOS). Puppeteer provides
consistent cross-platform browser automation specifically designed for this
use case.

### Trade-offs

**Pros:**

+ Generates real, valid tokens with proper DPoP binding
+ Tests authenticate exactly like production
+ Consistent behavior across platforms

**Cons:**

+ Requires Chrome/Chromium installation
+ Takes 15-20 seconds to complete OAuth flow
+ Cannot run in environments without browser support

**Alternative:** For CI/CD, pre-generate tokens and inject them. See
[Testing Guide](testing-guide.md#ci-cd-integration) for details.

## Summary

Solid POD authentication requires:

+ **OAuth 2.0 with PKCE** - Secure authorization for public clients
+ **DPoP tokens** - Cryptographically bound to client keypair
+ **RSA keypairs** - For signing proof-of-possession tokens
+ **Browser automation** - To complete OAuth flow Flutter tests can't
  intercept

This complexity enables the Solid vision of **decentralized,
user-controlled data storage** where users authenticate with their own POD
server, not a centralized app backend.

## Next Steps

+ [Architecture Overview](architecture.md) - See how components fit together
+ [JSON Files Reference](json-files.md) - Understand credential file
  structure
+ [Testing Guide](testing-guide.md) - Run tests with POD authentication
