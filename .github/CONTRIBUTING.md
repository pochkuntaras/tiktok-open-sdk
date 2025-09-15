# Contributing to TikTok Open SDK

Thank you for your interest in contributing to the TikTok Open SDK! This document provides guidelines for contributing to this Ruby gem.

## Getting Started

1. [Fork the repository][fork]
2. [Create a topic branch][branch] from `main`
3. Clone your fork locally and set up the development environment

## Development Setup

After cloning the repository:

```bash
# Install dependencies
bundle install

# Run the setup script
bin/setup

# Run tests to ensure everything works
bundle exec rspec
```

## Making Changes

### Code Style
- Follow Ruby style guidelines
- Run `rubocop` to check for style issues
- Run `rubocop -a` to automatically fix most issues
- Ensure all tests pass with `bundle exec rspec`

### Testing
- Write tests for new features and bug fixes
- Ensure all existing tests continue to pass
- Aim for good test coverage
- Use descriptive test names and contexts

### Documentation
- Update documentation for any new features
- Add examples in the README if applicable
- Update CHANGELOG.md for user-facing changes

### TikTok API Considerations
- Be mindful of TikTok API rate limits and best practices
- Test with different TikTok API endpoints when applicable
- Consider backward compatibility with existing API versions
- Document any breaking changes clearly

## Submitting Changes

1. Commit your changes with clear, descriptive commit messages
2. Push your branch to your fork
3. [Submit a pull request][pr] with:
   - Clear description of changes
   - Reference to any related issues
   - Screenshots or examples if applicable
   - Updated tests and documentation

## Pull Request Guidelines

- Keep PRs focused and reasonably sized
- Include tests for new functionality
- Update documentation as needed
- Ensure CI passes
- Request review from maintainers

## Reporting Issues

When reporting bugs or requesting features:
- Use the provided issue templates
- Include relevant environment details
- Provide clear reproduction steps for bugs
- Include examples and use cases for feature requests

## Code of Conduct

Please note that this project follows a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

[fork]: http://help.github.com/fork-a-repo/
[branch]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-branches
[pr]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests
