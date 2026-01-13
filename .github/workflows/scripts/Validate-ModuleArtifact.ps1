#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates module artifact.

.DESCRIPTION
    Validates the extracted module manifest and structure.

.PARAMETER ModuleName
    Name of the module to validate.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Validating Module Artifact" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$moduleDir = Join-Path $env:GITHUB_WORKSPACE $ModuleName
$manifestPath = Join-Path $moduleDir "$ModuleName.psd1"

Write-Host "Module name: $ModuleName" -ForegroundColor Gray
Write-Host "Module directory: $moduleDir" -ForegroundColor Gray
Write-Host "Manifest path: $manifestPath" -ForegroundColor Gray
Write-Host ""

# Check if module directory exists
if (-not (Test-Path $moduleDir)) {
  Write-Host "##[error]Module directory not found!" -ForegroundColor Red
  Write-Host "##[error]Expected path: $moduleDir" -ForegroundColor Red
  Write-Host "##[error]The extraction step may have failed or produced unexpected structure." -ForegroundColor Red
  Write-Host "##[error]Current directory contents:" -ForegroundColor Red
  Get-ChildItem -Force | Format-Table Name
  exit 1
}

Write-Host "✓ Module directory found" -ForegroundColor Green
Write-Host ""
Write-Host "Module directory contents:" -ForegroundColor Cyan
Get-ChildItem $moduleDir -Recurse | 
  Select-Object FullName, Length | 
  ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Gray }
Write-Host ""

# Check if manifest exists
if (-not (Test-Path $manifestPath)) {
  Write-Host "##[error]Module manifest not found!" -ForegroundColor Red
  Write-Host "##[error]Expected path: $manifestPath" -ForegroundColor Red
  exit 1
}

Write-Host "✓ Manifest file found" -ForegroundColor Green
Write-Host ""
Write-Host "Validating manifest..." -ForegroundColor Cyan

try {
  $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
  
  Write-Host "✓ Module manifest is valid" -ForegroundColor Green
  Write-Host ""
  Write-Host "Module Details:" -ForegroundColor Cyan
  Write-Host "  Name: $($manifest.Name)" -ForegroundColor Gray
  Write-Host "  Version: $($manifest.Version)" -ForegroundColor Gray
  Write-Host "  Author: $($manifest.Author)" -ForegroundColor Gray
  Write-Host "  Description: $($manifest.Description)" -ForegroundColor Gray
  Write-Host "  PowerShell Version: $($manifest.PowerShellVersion)" -ForegroundColor Gray
  if ($manifest.RequiredModules) {
    Write-Host "  Required Modules:" -ForegroundColor Gray
    $manifest.RequiredModules | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
  }
  Write-Host ""

  # Set outputs for later steps
  Write-Host "Setting outputs..." -ForegroundColor Cyan
  echo "module_name=$($manifest.Name)" >> $env:GITHUB_OUTPUT
  echo "module_version=$($manifest.Version)" >> $env:GITHUB_OUTPUT
  echo "module_path=$moduleDir" >> $env:GITHUB_OUTPUT
  Write-Host "✓ Outputs set successfully" -ForegroundColor Green
}
catch {
  Write-Host "##[error]Module manifest validation failed!" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  Write-Host "##[error]The manifest may be malformed or have invalid metadata." -ForegroundColor Red
  Write-Host "##[error]Manifest path: $manifestPath" -ForegroundColor Red
  exit 1
}
