# Concepts - Understanding POD Authentication Testing

This section explains the fundamental concepts behind integration
testing with Solid POD authentication.

## What You'll Learn

+ Why traditional Flutter testing doesn't work with POD authentication
+ How OAuth 2.0 with PKCE and DPoP works
+ Component architecture and responsibilities
+ Test execution flow from start to finish

## Documents in This Section

**[Authentication Guide](authentication.md)**

Learn why OAuth, DPoP, RSA keypairs, and browser automation are
necessary for POD testing.

**Topics covered:**
+ OAuth 2.0 Authorization Code Flow with PKCE
+ DPoP (Demonstration of Proof-of-Possession)
+ RSA keypair generation and JWK format
+ Why Puppeteer browser automation is required

**[Architecture Overview](architecture.md)**

Understand the component structure and how pieces fit together.

**Topics covered:**
+ Component diagram with 4 main layers
+ Responsibilities of each component
+ Integration points and contracts
+ Directory structure

**[Test Execution Flows](architecture-flows.md)**

See detailed sequence diagrams for test execution scenarios.

**Topics covered:**
+ Fresh tokens (happy path) flow
+ Expired tokens with auto-regeneration flow
+ Timing and synchronization
+ Error handling strategies

## Recommended Reading Order

For newcomers:

1. **Authentication Guide** - Understand the "why"
2. **Architecture Overview** - See the "what"
3. **Test Execution Flows** - Follow the "how"

## Next Steps

After understanding the concepts:

+ [Setup Guide](../guides/setup-guide.md) - Set up your environment
+ [Testing Guide](../guides/testing-guide.md) - Run your first test
+ [Adapting Guide](../guides/adapting.md) - Use this for your app

## Back to Main

[← Documentation Home](../README.md)
