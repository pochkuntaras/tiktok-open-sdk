# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2025-10-06
### Added
- **OmniAuth Strategy** - Ready-to-use OmniAuth strategy for TikTok Open Platform integration in Rails applications
  - Supports multiple TikTok OAuth scopes (user.info.basic, user.info.profile, user.info.stats)
  - Automatic token handling and user info retrieval
  - Rails/Devise integration examples and callbacks
- **Post API** - New module for interacting with TikTok's Post API endpoints
  - Creator info query functionality for video publishing workflows
  - Support for querying creator settings and capabilities

## [0.3.0] - 2025-09-20
### Added
- User information retrieval from TikTok API
- Improved request validation and error handling

## [0.2.0] - 2025-09-17
### Added
- Support for obtaining a client access token directly from the TikTok Open API, enabling secure server-to-server authentication for backend integrations and service authentication flows.

## [0.1.0] - 2025-09-15
### Added
- **OAuth 2.0 Authentication**
  - Authorization URI generation with customizable scopes and redirect URIs.
  - Access token exchange and refresh functionality.
  - Token revocation support.
  - Comprehensive error handling.

- **HTTP Client**
  - GET and POST request support.
  - SSL/TLS handling for HTTPS URLs.
  - Query parameter encoding and form data support.
  - Custom headers and timeout configuration.

- **Configuration**
  - Easy SDK setup with client credentials.
  - Customizable OAuth endpoints.
  - Flexible scope and redirect URI management.

- **Developer Experience**
  - Complete Ruby documentation with examples.
  - Rails integration examples.
  - Test coverage.
  - RuboCop code quality enforcement.
  - MIT license.

### Technical Details
- **Ruby Support**: 3.0.0+  
- **Dependencies**: Zero runtime dependencies.  
- **Testing**: RSpec with WebMock.  
- **Security**: Automated vulnerability scanning.  
