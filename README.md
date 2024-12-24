# GuestConfigurationHelper

GuestConfigurationHelper is a PowerShell module that helps you to publish Guest Configuration packages to Azure.

## Installation

```powershell
Install-Module -Name GuestConfigurationHelper
```

## Usage

### Create a Guest Configuration package from a DSC configuration:

```powershell
Publish-GuestConfigurationPackage -Configuration "C:\path\to\your\configuration.ps1" 
```

### Release History

