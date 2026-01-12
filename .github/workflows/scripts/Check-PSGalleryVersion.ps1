#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Checks if module version exists in PowerShell Gallery.

.DESCRIPTION
    Queries PowerShell Gallery to verify the module version doesn't already exist.

.PARAMETER ModuleName
    Name of the module to check.

.PARAMETER ModuleVersion
    Version of the module to check.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleVersion
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Checking PowerShell Gallery" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Module: $ModuleName" -ForegroundColor Gray
Write-Host "Version to publish: $ModuleVersion" -ForegroundColor Gray
Write-Host ""
Write-Host "Querying PowerShell Gallery..." -ForegroundColor Cyan

try {
  $existingModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue
  
  if ($existingModule) {
    Write-Host "✓ Found existing module in gallery" -ForegroundColor Yellow
    Write-Host "  Current gallery version: $($existingModule.Version)" -ForegroundColor Gray
    Write-Host "  Published: $($existingModule.PublishedDate)" -ForegroundColor Gray
    Write-Host ""
    
    $currentVersion = [version]$existingModule.Version
    $newVersion = [version]$ModuleVersion
    
    Write-Host "Version comparison:" -ForegroundColor Cyan
    Write-Host "  Gallery version: $currentVersion" -ForegroundColor Gray
    Write-Host "  New version:     $newVersion" -ForegroundColor Gray
    Write-Host ""
    
    if ($currentVersion -eq $newVersion) {
      Write-Host "##[error]Version conflict!" -ForegroundColor Red
      Write-Host "##[error]Version $ModuleVersion already exists in PowerShell Gallery." -ForegroundColor Red
      Write-Host "##[error]You must update the version number in the module manifest before publishing." -ForegroundColor Red
      Write-Host "##[error]Current gallery version: $currentVersion" -ForegroundColor Red
      Write-Host "##[error]Attempted version: $newVersion" -ForegroundColor Red
      exit 1
    }
    elseif ($currentVersion -gt $newVersion) {
      Write-Host "##[error]Version rollback detected!" -ForegroundColor Red
      Write-Host "##[error]Attempting to publish version $newVersion which is older than gallery version $currentVersion." -ForegroundColor Red
      Write-Host "##[error]PowerShell Gallery does not allow publishing older versions." -ForegroundColor Red
      Write-Host "##[error]Please update the version in the manifest to be newer than $currentVersion." -ForegroundColor Red
      exit 1
    }
    else {
      Write-Host "✓ Version check passed" -ForegroundColor Green
      Write-Host "  New version $newVersion is newer than gallery version $currentVersion" -ForegroundColor Green
    }
  }
  else {
    Write-Host "✓ Module not found in gallery" -ForegroundColor Green
    Write-Host "  This will be the first publish of this module" -ForegroundColor Gray
  }
}
catch {
  Write-Host "##[error]Failed to query PowerShell Gallery!" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  Write-Host "##[error]This may be a network issue or PowerShell Gallery may be unavailable." -ForegroundColor Red
  Write-Host "##[error]Check PowerShell Gallery status at: https://www.powershellgallery.com/" -ForegroundColor Red
  exit 1
}
