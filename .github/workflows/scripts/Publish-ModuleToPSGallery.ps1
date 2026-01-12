#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publishes module to PowerShell Gallery.

.DESCRIPTION
    Uses Publish-Module to publish the module to PowerShell Gallery.

.PARAMETER ModulePath
    Path to the module directory.

.PARAMETER ModuleName
    Name of the module.

.PARAMETER ModuleVersion
    Version of the module.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleVersion
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Publishing to PowerShell Gallery" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Module: $ModuleName" -ForegroundColor Gray
Write-Host "Version: $ModuleVersion" -ForegroundColor Gray
Write-Host "Path: $ModulePath" -ForegroundColor Gray
Write-Host ""

# Verify API key is present
if ([string]::IsNullOrEmpty($env:PSGALLERY_API_KEY)) {
  Write-Host "##[error]PowerShell Gallery API key not found!" -ForegroundColor Red
  Write-Host "##[error]The PS_GALLERY_API_KEY secret must be set in repository secrets." -ForegroundColor Red
  Write-Host "##[error]To set it:" -ForegroundColor Red
  Write-Host "##[error]  1. Go to https://www.powershellgallery.com/ and sign in" -ForegroundColor Red
  Write-Host "##[error]  2. Get your API key from your account settings" -ForegroundColor Red
  Write-Host "##[error]  3. Add it as a secret named PS_GALLERY_API_KEY in this repository" -ForegroundColor Red
  exit 1
}

Write-Host "✓ API key found" -ForegroundColor Green
Write-Host ""
Write-Host "Publishing module..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Gray
Write-Host ""

try {
  $publishParams = @{
    Path        = $ModulePath
    NuGetApiKey = $env:PSGALLERY_API_KEY
    Repository  = 'PSGallery'
    Verbose     = $true
    ErrorAction = 'Stop'
  }

  Publish-Module @publishParams

  Write-Host ""
  Write-Host "✓ Module published successfully to PowerShell Gallery" -ForegroundColor Green
  Write-Host ""
  Write-Host "Note: It may take a few minutes for the module to appear in search results." -ForegroundColor Yellow
}
catch {
  Write-Host "##[error]Failed to publish module!" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  Write-Host ""
  
  $errorMessage = $_.Exception.Message
  
  if ($errorMessage -match "401|Unauthorized|API key") {
    Write-Host "##[error]Authentication error!" -ForegroundColor Red
    Write-Host "##[error]The API key may be invalid or expired." -ForegroundColor Red
    Write-Host "##[error]Please regenerate your PowerShell Gallery API key and update the secret." -ForegroundColor Red
  } elseif ($errorMessage -match "409|already exists|Conflict") {
    Write-Host "##[error]Version conflict!" -ForegroundColor Red
    Write-Host "##[error]Version $ModuleVersion may already exist in the gallery." -ForegroundColor Red
    Write-Host "##[error]The version check may have been outdated or there was a race condition." -ForegroundColor Red
  } elseif ($errorMessage -match "400|Bad Request|validation") {
    Write-Host "##[error]Validation error!" -ForegroundColor Red
    Write-Host "##[error]The module manifest or package structure may not meet PSGallery requirements." -ForegroundColor Red
    Write-Host "##[error]Check: https://docs.microsoft.com/en-us/powershell/scripting/gallery/concepts/publishing-guidelines" -ForegroundColor Red
  } elseif ($errorMessage -match "timeout|timed out") {
    Write-Host "##[error]Timeout error!" -ForegroundColor Red
    Write-Host "##[error]The publish operation took too long. Try again later." -ForegroundColor Red
  } elseif ($errorMessage -match "network|connection") {
    Write-Host "##[error]Network error!" -ForegroundColor Red
    Write-Host "##[error]Could not connect to PowerShell Gallery. Check https://www.powershellgallery.com/" -ForegroundColor Red
  } else {
    Write-Host "##[error]Unexpected error during publish!" -ForegroundColor Red
    Write-Host "##[error]Please check the error message above for details." -ForegroundColor Red
  }
  
  exit 1
}
