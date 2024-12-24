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

## Release History

## Roadmap

- [ ] Add support for uploading Guest Configuration packages to Azure Storage Accounts
- [ ] Add support for detecting and warning about too large Guest Configuration packages
- [ ] Add support for reducing dependency size of Guest Configuration packages
