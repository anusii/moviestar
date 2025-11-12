# Integration Test Documentation

This directory contains comprehensive documentation for MovieStar's integration testing framework with Solid POD authentication.

## Quick Navigation

**New to POD authentication?** Start here:

+ [Authentication Guide](authentication.md) - Understanding OAuth,
  DPoP, and why browser automation is needed
+ [Architecture Overview](architecture.md) - Component diagrams and
  responsibilities
+ [Test Execution Flows](architecture-flows.md) - Detailed test
  execution scenarios
+ [JSON Files Reference](json-files.md) - Structure and purpose of
  credential files

**Running tests:**

+ [Testing Guide](testing-guide.md) - How to run and write tests with
  INTERACT pattern
+ [Troubleshooting](testing-troubleshooting.md) - Common issues and
  solutions

**Setting up from scratch:**

+ [Setup Guide](setup-guide.md) - Initial platform setup and
  credential extraction

**Adapting for your app:**

+ [Reusability Guide](adapting.md) - How to use this testing approach
  in other apps
+ [Provider Compatibility](adapting-providers.md) - POD provider
  configuration
+ [CI/CD Integration](adapting-cicd.md) - Setting up continuous
  integration

## Documentation Structure

```text
integration_test/docs/
├── README.md                      # This file - navigation
├── authentication.md              # OAuth/DPoP concepts
├── architecture.md                # Component diagrams
├── architecture-flows.md          # Test execution flows
├── json-files.md                  # JSON file structures
├── adapting.md                    # Reusability guide
├── adapting-providers.md          # POD provider compatibility
├── adapting-cicd.md               # CI/CD integration
├── testing-guide.md               # How to run and write tests
├── testing-troubleshooting.md     # Common issues
└── setup-guide.md                 # Initial setup
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

For troubleshooting, see
[Troubleshooting](testing-troubleshooting.md).

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

+ Check the [Troubleshooting](testing-troubleshooting.md) guide
+ Search existing [GitHub
  issues](https://github.com/anusii/moviestar/issues)
+ Create a new issue with the `documentation` label
