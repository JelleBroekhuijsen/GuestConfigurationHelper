# GuestConfigurationHelper

GuestConfigurationHelper is a PowerShell module that helps you to publish Guest Configuration packages to Azure.

## Features

- Create a Guest Configuration package (.zip) from a DSC configuration file (.ps1)
- Output the configuration parameters needed for assignment (SHA256 file hash, configuration name)

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

- 1.0.0 - Initial release

## Roadmap

- [ ] Add support for uploading Guest Configuration packages to Azure Storage Accounts
- [ ] Add support for detecting and warning about too large Guest Configuration packages
- [ ] Add support for reducing dependency size of Guest Configuration packages
- [ ] Add support for directly assigning a configuration to a VM or Arc Connected Machine to allow for quicker testing of configuration then what is supported when using Azure Policy for assignment
