# Contributing to GuestConfigurationHelper

Thank you for your interest in contributing to GuestConfigurationHelper! This document provides guidelines and requirements for contributing to this project.

## Version Bump Requirements

When making changes to the module, you **must** increment the module version in `GuestConfigurationHelper.psd1` if your changes affect any of the following module-relevant files:

- `*.psm1` files (PowerShell module files)
- `*.psd1` files (PowerShell manifest files)
- `README.md` (module documentation)
- Files in the `/Private/` directory
- Files in the `/Public/` directory

### Version Numbering

Follow [Semantic Versioning](https://semver.org/) principles:

- **Major version (X.0.0)**: Breaking changes or significant API modifications
- **Minor version (0.X.0)**: New features that are backwards compatible
- **Patch version (0.0.X)**: Bug fixes and minor changes that are backwards compatible

### Example

If you're fixing a bug in a function in the `/Public/` directory:
1. Make your code changes
2. Update the `ModuleVersion` in `GuestConfigurationHelper.psd1` (e.g., from `1.5.2` to `1.5.3`)
3. Commit both changes together

### CI Validation

The CI pipeline will automatically verify that:
1. You've incremented the version when module-relevant files are changed
2. The version number is valid and higher than the base branch

If you forget to bump the version, the CI will fail with a clear error message explaining what needs to be done.

## Release Process

Releases are automatically created when:
- Changes are pushed to the `main` branch
- Module-relevant files (listed above) were modified
- The module version was properly incremented

If only non-module files change (e.g., documentation in `/Tests/`, workflow files, etc.), the release stage will be skipped automatically.

## Pull Request Guidelines

1. **Fork and Branch**: Create a feature branch from `main`
2. **Make Changes**: Implement your changes following the coding standards
3. **Update Version**: If you modified module-relevant files, bump the version
4. **Test**: Run tests locally with `Invoke-Pester -Path .\Tests\`
5. **Commit**: Write clear commit messages describing your changes
6. **Push**: Push your branch and create a pull request

## Code Standards

- Follow PowerShell best practices and style guidelines
- Use PowerShell 7.0+ compatible syntax
- Add Pester tests for new functionality
- Run `PSScriptAnalyzer` before committing
- Document functions with comment-based help

## Testing

Run tests locally before submitting:

```powershell
# Run all tests
Invoke-Pester -Path .\Tests\

# Run a specific test file
Invoke-Pester -Path .\Tests\Publish-GuestConfigurationPackage.Tests.ps1

# Run with code coverage
Invoke-Pester -Path .\Tests\ -CodeCoverage .\*.ps1
```

## Questions or Issues?

If you have questions or encounter issues:
- Check existing [Issues](https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/issues)
- Create a new issue with detailed information
- Be respectful and constructive in all interactions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
