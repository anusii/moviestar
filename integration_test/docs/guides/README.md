# Guides - Step-by-Step Instructions

This section contains practical how-to guides for setting up, running,
and adapting the integration testing framework.

## Getting Started Guides

**[Setup Guide](setup-guide.md)**

Initial platform setup and credential extraction for first-time users.

**You'll learn:**
+ Platform-specific setup (Linux, Windows, macOS)
+ Installing dependencies
+ Creating test credentials
+ Extracting authentication data

**[Testing Guide](testing-guide.md)**

How to run and write integration tests for MovieStar.

**You'll learn:**
+ Running tests (qtest vs itest modes)
+ Writing tests with INTERACT pattern
+ POD authentication setup
+ Best practices

**[Troubleshooting](troubleshooting.md)**

Common issues and solutions when running integration tests.

**Covers:**
+ Test discovery issues
+ Invalid grant errors
+ Browser automation failures
+ Device not found errors
+ Batch test failures

## Adaptation Guides

**[Adapting for Your App](adapting.md)**

How to reuse this testing approach in other Solid POD applications.

**You'll learn:**
+ What components are reusable
+ Configuration changes needed
+ Writing app-specific tests
+ Migration steps

**[Provider Compatibility](adapting-providers.md)**

POD provider-specific configuration and selectors.

**Covers:**
+ Community Solid Server (CSS)
+ Node Solid Server (NSS)
+ Enterprise Solid Server (ESS)
+ Finding and updating Puppeteer selectors

**[CI/CD Integration](adapting-cicd.md)**

Setting up continuous integration with GitHub Actions.

**You'll learn:**
+ GitHub Actions workflow configuration
+ Storing credentials securely
+ Pre-generated vs on-demand tokens
+ Platform-specific CI setup

## Recommended Paths

**Path 1: First-time setup**

1. [Setup Guide](setup-guide.md)
2. [Testing Guide](testing-guide.md)
3. [Troubleshooting](troubleshooting.md) (as needed)

**Path 2: Adapting for your app**

1. [Adapting for Your App](adapting.md)
2. [Provider Compatibility](adapting-providers.md)
3. [CI/CD Integration](adapting-cicd.md)

## Need More Context?

+ [Understanding POD Authentication](../concepts/authentication.md)
+ [Architecture Overview](../concepts/architecture.md)
+ [JSON Files Reference](../reference/json-files.md)

## Back to Main

[← Documentation Home](../README.md)
