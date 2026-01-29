# Continuous Integration and Testing

This document describes the CI/CD workflows and testing practices for the GuestConfigurationHelper module.

## Workflows

### Pull Request CI (`pr-ci.yml`)

This workflow runs automatically on all pull requests targeting the `main` or `develop` branches.

**Triggers:**
- Pull requests to `main` or `develop` branches
- Excludes changes to markdown files and GitHub workflow files (except workflow definitions)

**Jobs:**
1. **Test and Code Coverage**
   - Runs PSScriptAnalyzer for code quality checks
   - Executes all Pester tests with code coverage
   - Enforces minimum 80% code coverage threshold
   - Uploads test results and coverage reports as artifacts
   - Posts coverage summary to GitHub Actions summary

**Requirements:**
- Minimum 80% code coverage
- All tests must pass
- No PSScriptAnalyzer errors

### CI and Release (`ci-and-release.yml`)

This workflow runs on pushes to the `main` branch and handles both CI and release creation.

**Triggers:**
- Pushes to `main` branch
- Manual workflow dispatch

**Jobs:**
1. **Check Changes** - Verifies if module files changed and validates version bump
2. **Test and Analyze** - Runs tests and analysis (reuses test-and-analyze.yml)
3. **Create Release** - Creates GitHub release if tests pass and module files changed

### Test and Analyze (Reusable - `test-and-analyze.yml`)

This is a reusable workflow template that handles testing and code analysis.

**Inputs:**
- `upload-coverage` (boolean, default: false) - Whether to upload coverage artifacts
- `coverage-threshold` (number, default: 80) - Minimum required code coverage percentage

**Steps:**
1. Install required PowerShell modules (Pester, PSScriptAnalyzer, PSDscResources, etc.)
2. Run PSScriptAnalyzer with PSGallery settings
3. Run Pester tests with code coverage enabled
4. Generate coverage reports in JaCoCo format
5. Validate coverage meets threshold
6. Upload test results and coverage artifacts
7. Generate coverage summary for GitHub Actions

## Testing

### Test Framework

The project uses **Pester 5.x** for unit testing. Tests are located in the `/Tests` directory.

### Test Files

- `Publish-GuestConfigurationPackage.Tests.ps1` - Tests for the main public function
- `Test-ConfigurationFileSizeOnDisk.Tests.ps1` - Tests for package size validation
- `Compress-ConfigurationFileSizeOnDisk.Tests.ps1` - Tests for configuration compression
- `ConvertTo-Json-Depth.Tests.ps1` - Tests for JSON serialization depth
- `EdgeCases.Tests.ps1` - Additional edge case and coverage tests

### Running Tests Locally

**Run all tests:**
```powershell
Invoke-Pester -Path .\Tests\
```

**Run tests with code coverage:**
```powershell
$config = New-PesterConfiguration
$config.Run.Path = './Tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('./Public/*.ps1', './Private/*.ps1')
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = 'coverage.xml'
Invoke-Pester -Configuration $config
```

**Run a specific test file:**
```powershell
Invoke-Pester -Path .\Tests\Publish-GuestConfigurationPackage.Tests.ps1
```

### Code Coverage

- **Target:** 80% minimum code coverage
- **Format:** JaCoCo XML for compatibility with various coverage tools
- **Scope:** All files in `/Public` and `/Private` directories
- **Reports:** Generated automatically in CI/CD workflows

### Code Quality

**PSScriptAnalyzer:**
- Runs with PSGallery settings profile
- Fails build on any errors
- Warnings are reported but don't fail the build

**Settings:**
- Located in PSGallery's recommended ruleset
- Enforces PowerShell best practices
- Checks for common coding mistakes

## Local Development

### Prerequisites

```powershell
# Install required modules
Install-Module -Name Pester -Force -Scope CurrentUser
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Install-Module -Name PSDscResources -Force -Scope CurrentUser
Install-Module -Name PSDesiredStateConfiguration -Force -Scope CurrentUser
Install-Module -Name GuestConfiguration -Force -Scope CurrentUser
```

### Pre-commit Checklist

Before submitting a pull request:

1. ✅ Run PSScriptAnalyzer and fix any errors:
   ```powershell
   Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery
   ```

2. ✅ Run all tests and ensure they pass:
   ```powershell
   Invoke-Pester -Path .\Tests\
   ```

3. ✅ Check code coverage meets 80% threshold:
   ```powershell
   $config = New-PesterConfiguration
   $config.Run.Path = './Tests'
   $config.CodeCoverage.Enabled = $true
   $config.CodeCoverage.Path = @('./Public/*.ps1', './Private/*.ps1')
   $result = Invoke-Pester -Configuration $config
   # Check $result.CodeCoverage for coverage percentage
   ```

4. ✅ Ensure module version is bumped if module files changed

## Troubleshooting

### Tests Fail Locally but Pass in CI

- Ensure you're using the same PowerShell version (PowerShell 7.x)
- Verify all required modules are installed
- Check if you're running on Windows (some tests require Windows-specific DSC features)

### Code Coverage Below Threshold

- Add tests for new code paths
- Review uncovered lines in the coverage report
- Focus on edge cases and error handling

### PSScriptAnalyzer Errors

- Run `Invoke-ScriptAnalyzer` locally to see detailed errors
- Refer to PSScriptAnalyzer documentation for specific rules
- Some rules can be suppressed with `[Diagnostics.CodeAnalysis.SuppressMessageAttribute()]` if justified

## Contributing

When adding new features:

1. Write tests first (TDD approach recommended)
2. Ensure tests cover typical use cases, edge cases, and error scenarios
3. Maintain or improve code coverage percentage
4. Add parameter validation tests
5. Test verbose output and error messages
6. Update documentation as needed

## References

- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
