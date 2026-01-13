# GuestConfigurationHelper

[![CI and Release](https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/actions/workflows/ci-and-release.yml/badge.svg)](https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/actions/workflows/ci-and-release.yml)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/GuestConfigurationHelper?label=PS%20Gallery)](https://www.powershellgallery.com/packages/GuestConfigurationHelper)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/GuestConfigurationHelper)](https://www.powershellgallery.com/packages/GuestConfigurationHelper)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)

GuestConfigurationHelper is a PowerShell module that simplifies the creation and publication of Azure Guest Configuration packages from DSC configuration files. It streamlines the process of packaging DSC configurations for use with Azure Policy Guest Configuration on Azure VMs and Arc-enabled machines.

## 🎯 Features

- **Create Guest Configuration Packages** - Convert DSC configuration files (.ps1) into Guest Configuration packages (.zip)
- **Automatic MOF Generation** - Extracts configuration names and generates MOF files from DSC configurations
- **Configuration Parameter Support** - Pass parameters to DSC configurations during package creation
- **Size Validation** - Warns about packages exceeding Azure's 100MB size limit
- **Dependency Optimization** - [EXPERIMENTAL] Reduces package size by removing versioned module folders
- **Azure DevOps Integration** - Outputs pipeline variables for CI/CD workflows:
  - `ConfigurationName` - The name of the configuration
  - `ConfigurationPackage` - Path to the created package
  - `ConfigurationFileHash` - SHA256 hash of the package
- **Custom Configuration Names** - Override default configuration names with the `-OverrideDefaultConfigurationName` parameter

## 📋 Requirements

- **PowerShell**: 7.0 or higher (PowerShell Core)
- **Required Modules**:
  - `PSDesiredStateConfiguration`
  - `PSDscResources`
  - `GuestConfiguration`

## 📦 Installation

Install from the PowerShell Gallery:

```powershell
Install-Module -Name GuestConfigurationHelper -Scope CurrentUser
```

Import the module:

```powershell
Import-Module GuestConfigurationHelper
```

## 🚀 Usage

### Basic Usage

Create a Guest Configuration package from a DSC configuration file:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\path\to\your\configuration.ps1"
```

### With Configuration Parameters

Pass parameters to your DSC configuration:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\configs\WebServerConfig.ps1" -ConfigurationParameters @{
    ServerName = 'web-server-01'
    Port = 8080
}
```

### Custom Output Location

Specify where to create the package:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\configs\config.ps1" -OutputFolder "C:\packages"
```

### Override Configuration Name

Use a custom name for the configuration package:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\configs\config.ps1" -OverrideDefaultConfigurationName "CustomConfigName"
```

### [EXPERIMENTAL] Reduce Package Size

When packages include large dependencies, you can compress them by removing versioned module folders:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\configs\config.ps1" -CompressConfiguration
```

**Note**: This feature removes versioned folders of modules (e.g., if both `Az.Accounts\2.0.0` and `Az.Accounts\2.1.0` exist, only the main module folder is kept). Use with caution and test thoroughly.

### Debug Mode (No Cleanup)

Keep temporary files for debugging:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\configs\config.ps1" -NoCleanup -Verbose
```

## 📖 Parameters Reference

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Configuration` | String | Yes | Path to the DSC configuration file (.ps1) |
| `-ConfigurationParameters` | Hashtable | No | Parameters to pass to the DSC configuration |
| `-OutputFolder` | String | No | Output directory for the package (default: current directory) |
| `-CompressConfiguration` | Switch | No | Enable experimental package size reduction |
| `-NoCleanup` | Switch | No | Keep temporary files after package creation |
| `-OverrideDefaultConfigurationName` | String | No | Use a custom name instead of the configuration name from the file |

## 🔍 Example DSC Configuration

```powershell
Configuration SimpleDscConfiguration {
    param()
    
    Import-DscResource -ModuleName 'PSDscResources'
    
    Script EnsureFile {
        GetScript = {
            $path = 'C:\temp\sample.txt'
            $content = if (Test-Path -Path $path) {
                Get-Content -Path $path -Raw
            }
            return @{
                Result = $content
                Path   = $path
            }
        }
        TestScript = {
            $path = 'C:\temp\sample.txt'
            if (-not (Test-Path -Path $path)) {
                return $false
            }
            $current = Get-Content -Path $path -Raw
            return $current -eq 'Configuration applied successfully'
        }
        SetScript = {
            $path = 'C:\temp\sample.txt'
            'Configuration applied successfully' | Set-Content -Path $path -Encoding UTF8
        }
    }
}
```

## 🐛 Troubleshooting

### Package Size Exceeds 100MB

**Issue**: Azure Guest Configuration has a 100MB package size limit.

**Solutions**:
1. Try using the `-CompressConfiguration` parameter (experimental)
2. Minimize the number of dependencies in your DSC configuration
3. Use smaller, more focused configurations instead of large monolithic ones

### Configuration Name Not Detected

**Issue**: Error message "Failed to detect any configurations in configuration file"

**Solution**: Ensure your DSC configuration follows the standard format:
```powershell
Configuration YourConfigurationName {
    # Configuration content
}
```

### Module Import Errors

**Issue**: Required modules not found

**Solution**: Install all required modules:
```powershell
Install-Module PSDesiredStateConfiguration, PSDscResources, GuestConfiguration -Scope CurrentUser
```

## 📊 Status Badges

The badges at the top of this README provide quick status information:

- **CI and Release** - Shows the status of automated tests and build processes. Click to view detailed workflow runs.
- **PS Gallery Version** - Displays the latest version available on PowerShell Gallery.
- **PS Gallery Downloads** - Shows total download count from PowerShell Gallery.
- **License** - Indicates the project license (MIT).

For detailed test results and build logs, visit the [Actions tab](https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/actions).

## 📝 Release History

- **1.5.2** - Bug fixes and stability improvements
- **1.5.0** - Improved large configuration object handling and enhanced testing
- **1.4.0** - Added Azure DevOps output variables and configuration name override support
- **1.3.0** - Added support for compressing Guest Configuration packages
- **1.2.0** - Added support for reducing dependency size of Guest Configuration packages
- **1.1.0** - Added detection and warnings for oversized Guest Configuration packages
- **1.0.0** - Initial release

## 🗺️ Roadmap

- [ ] Add support for uploading Guest Configuration packages to Azure Storage Accounts
- [ ] Add support for directly assigning configurations to VMs or Arc-enabled machines for faster testing
- [x] Add support for detecting and warning about oversized Guest Configuration packages
- [x] Add support for reducing dependency size of Guest Configuration packages

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Version bump requirements for module changes
- Pull request process
- Code standards and testing
- How the CI/Release pipeline works

## 📚 Additional Resources

- [Azure Guest Configuration Documentation](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview)
- [PowerShell Gallery Package](https://www.powershellgallery.com/packages/GuestConfigurationHelper)
- [GitHub Actions Workflows](https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/actions)
- [Release Notes](https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/releases)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

