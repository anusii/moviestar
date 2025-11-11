# Integration Test Documentation

This directory contains comprehensive documentation for MovieStar's integration testing framework with Solid POD authentication.

## Quick Navigation

**New to POD authentication?** Start here:
1. [Authentication Guide](authentication.md) - Understanding OAuth, DPoP, and why browser automation is needed
2. [Architecture Overview](architecture.md) - Component diagrams and testing flow
3. [JSON Files Reference](json-files.md) - Structure and purpose of credential files

**Running tests:**
- [Testing Guide](testing-guide.md) - How to run tests, INTERACT pattern, troubleshooting

**Setting up from scratch:**
- [Setup Guide](setup-guide.md) - Initial platform setup and credential extraction

**Adapting for your app:**
- [Reusability Guide](adapting.md) - How to use this testing approach in other Solid POD applications

## Documentation Structure

```
integration_test/docs/
├── README.md              # This file - documentation overview
├── authentication.md      # OAuth/DPoP concepts and why browser automation
├── architecture.md        # Component diagrams and testing flow
├── json-files.md          # JSON file structures and token lifecycle
├── adapting.md            # Guide for other Solid POD applications
├── testing-guide.md       # Operational guide (moved from docs/)
└── setup-guide.md         # Setup instructions (moved from docs/)
```

## Quick Start

If you just want to run tests without understanding the details:

```bash
# 1. Ensure test_credentials.json exists
cat integration_test/fixtures/test_credentials.json

# 2. Run all integration tests
make qtest

# 3. If POD tests fail with expired tokens, regenerate:
dart run integration_test/tools/generate_auth_data.dart
```

For troubleshooting, see [Testing Guide - Troubleshooting](testing-guide.md#troubleshooting).

## Why This Documentation Exists

Solid POD authentication differs significantly from traditional app authentication. The integration test framework uses:

- **OAuth 2.0 Authorization Code Flow with PKCE** - Secure authentication for public clients
- **DPoP (Demonstration of Proof-of-Possession)** - Cryptographic proof of token ownership
- **Browser Automation (Puppeteer)** - To handle OAuth redirects that Flutter tests can't intercept
- **RSA Keypairs** - For signing DPoP tokens

This documentation explains **why** these components are necessary, **how** they work together, and **how** to adapt them for other applications.

## External Resources

- [Solid Project](https://solidproject.org/) - Decentralized data storage specification
- [Solid-OIDC Primer](https://solid.github.io/solid-oidc/) - Authentication specification for Solid
- [OAuth 2.0 (RFC 6749)](https://datatracker.ietf.org/doc/html/rfc6749) - Authorization framework
- [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) - Proof-of-possession specification
- [PKCE (RFC 7636)](https://datatracker.ietf.org/doc/html/rfc7636) - Security extension for public clients
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests) - Flutter's E2E testing framework

## Contributing

When updating this documentation:

1. Keep each file focused on a single topic
2. Use Mermaid diagrams for complex flows (max 2 per file)
3. Link to external resources instead of duplicating content
4. Include concrete code examples where helpful
5. Update cross-references in README.md when adding new files

## Questions or Issues?

If this documentation doesn't answer your question, please:

1. Check the [Troubleshooting section](testing-guide.md#troubleshooting)
2. Search existing [GitHub issues](https://github.com/anusii/moviestar/issues)
3. Create a new issue with the `documentation` label
