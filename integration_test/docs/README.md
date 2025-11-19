# Integration Test Documentation

This directory contains comprehensive documentation for MovieStar's
integration testing framework with Solid POD authentication.

## Quick Navigation

### 📚 Concepts - Understanding the System

Start here if you're new to POD authentication:

+ [Authentication Guide](concepts/authentication.md) - OAuth, DPoP, and
  why browser automation
+ [Architecture Overview](concepts/architecture.md) - Component
  diagrams and responsibilities
+ [Test Execution Flows](concepts/architecture-flows.md) - Detailed
  execution scenarios

### 📖 Guides - Step-by-Step Instructions

Practical how-to guides:

+ [Setup Guide](guides/setup-guide.md) - Initial platform setup and
  credential extraction
+ [Testing Guide](guides/testing-guide.md) - How to run and write
  tests
+ [Troubleshooting](guides/troubleshooting.md) - Common issues and
  solutions
+ [Adapting for Your App](guides/adapting.md) - Reusability guide
+ [Provider Compatibility](guides/adapting-providers.md) - POD
  provider configuration
+ [CI/CD Integration](guides/adapting-cicd.md) - Continuous
  integration setup

### 📋 Reference - Quick Lookup

+ [JSON Files Reference](reference/json-files.md) - Credential file
  structures and token lifecycle

## Documentation Structure

```text
integration_test/docs/
├── README.md              # This file - main navigation
│
├── concepts/              # Understanding the system
│   ├── authentication.md
│   ├── architecture.md
│   └── architecture-flows.md
│
├── guides/                # How-to documentation
│   ├── setup-guide.md
│   ├── testing-guide.md
│   ├── troubleshooting.md
│   ├── adapting.md
│   ├── adapting-providers.md
│   └── adapting-cicd.md
│
└── reference/             # Quick lookup
    └── json-files.md
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

For troubleshooting, see [Troubleshooting](guides/troubleshooting.md).

## Why This Documentation Exists

Solid POD authentication differs significantly from traditional app
authentication. The integration test framework uses:

+ **OAuth 2.0 Authorization Code Flow with PKCE** - Secure
  authentication for public clients
+ **DPoP (Demonstration of Proof-of-Possession)** - Cryptographic
  proof of token ownership
+ **Browser Automation (Puppeteer)** - To handle OAuth redirects that
  Flutter tests can't intercept
+ **RSA Keypairs** - For signing DPoP tokens

This documentation explains **why** these components are necessary,
**how** they work together, and **how** to adapt them for other
applications.

## Learning Paths

### Path 1: I just want to run tests

+ [Setup Guide](guides/setup-guide.md)
+ [Testing Guide](guides/testing-guide.md)
+ [Troubleshooting](guides/troubleshooting.md)

### Path 2: I want to understand the system

+ [Authentication Guide](concepts/authentication.md)
+ [Architecture Overview](concepts/architecture.md)
+ [Test Execution Flows](concepts/architecture-flows.md)

### Path 3: I want to adapt this for my app

+ [Adapting for Your App](guides/adapting.md)
+ [Provider Compatibility](guides/adapting-providers.md)
+ [CI/CD Integration](guides/adapting-cicd.md)

## External Resources

+ [Solid Project](https://solidproject.org/) - Decentralized data
  storage specification
+ [Solid-OIDC
  Primer](https://solid.github.io/solid-oidc/) - Authentication
  specification for Solid
+ [OAuth 2.0 (RFC
  6749)](https://datatracker.ietf.org/doc/html/rfc6749) -
  Authorization framework
+ [DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) -
  Proof-of-possession specification
+ [PKCE (RFC 7636)](https://datatracker.ietf.org/doc/html/rfc7636) -
  Security extension for public clients
+ [Flutter Integration
  Testing](https://docs.flutter.dev/testing/integration-tests) -
  Flutter's E2E testing framework

## Contributing

When updating this documentation:

+ Keep each file focused on a single topic
+ Use Mermaid diagrams for complex flows (max 2 per file)
+ Link to external resources instead of duplicating content
+ Include concrete code examples where helpful
+ Update cross-references when adding new files
+ Follow the organizational structure (concepts, guides, reference)

## Questions or Issues?

If this documentation doesn't answer your question, please:

+ Check the [Troubleshooting](guides/troubleshooting.md) guide
+ Search existing [GitHub
  issues](https://github.com/anusii/moviestar/issues)
+ Create a new issue with the `documentation` label
