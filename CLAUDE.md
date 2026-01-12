# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GuestConfigurationHelper is a PowerShell module that creates and publishes Azure Guest Configuration packages from DSC configuration files. It outputs Azure DevOps pipeline variables for CI/CD integration.

## Requirements

- PowerShell 7.0+ (Core)
- Required modules: `PSDesiredStateConfiguration`, `PSDscResources`, `GuestConfiguration`

## Common Commands

### Run Tests
```powershell
Invoke-Pester -Path .\Tests\
```

### Run a Single Test File
```powershell
Invoke-Pester -Path .\Tests\Publish-GuestConfigurationPackage.Tests.ps1
```

### Import Module for Development
```powershell
Import-Module .\GuestConfigurationHelper.psd1 -Force
```

### Test the Main Function
```powershell
Publish-GuestConfigurationPackage -Configuration .\Tests\SampleConfigs\SimpleDscConfiguration.ps1 -Verbose
```

## Architecture

### Module Structure
- `GuestConfigurationHelper.psm1` - Entry point that dot-sources all Public and Private functions
- `GuestConfigurationHelper.psd1` - Module manifest defining metadata and dependencies
- `Public/` - Exported functions (user-facing API)
- `Private/` - Internal helper functions
- `Tests/` - Pester tests with sample configurations in `Tests/SampleConfigs/`

### Key Functions
- `Publish-GuestConfigurationPackage` (Public) - Main entry point that orchestrates:
  1. Extracts configuration name from .ps1 file using regex
  2. Dot-sources and invokes the DSC configuration to generate MOF
  3. Creates guest configuration package using `New-GuestConfigurationPackage`
  4. Optionally compresses package to reduce size
  5. Outputs Azure DevOps variables (`##vso[task.setvariable...]`)

- `Test-ConfigurationFileSizeOnDisk` (Private) - Validates package stays under Azure's 100MB limit
- `Compress-ConfigurationFileSizeOnDisk` (Private) - Removes versioned module folders to reduce package size
