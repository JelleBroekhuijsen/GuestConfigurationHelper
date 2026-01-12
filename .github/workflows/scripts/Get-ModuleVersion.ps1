#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Extracts module version and name from manifest.

.DESCRIPTION
    Reads the module manifest file and outputs version and name to GitHub Actions outputs.
#>

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Extracting Module Information" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$manifestPath = Join-Path $env:GITHUB_WORKSPACE "GuestConfigurationHelper.psd1"
Write-Host "Manifest path: $manifestPath" -ForegroundColor Gray

if (-not (Test-Path $manifestPath)) {
  Write-Host "##[error]Module manifest not found!" -ForegroundColor Red
  Write-Host "##[error]Expected path: $manifestPath" -ForegroundColor Red
  Write-Host "##[error]Current directory: $env:GITHUB_WORKSPACE" -ForegroundColor Red
  Write-Host "##[error]Directory contents:" -ForegroundColor Red
  Get-ChildItem $env:GITHUB_WORKSPACE | Format-Table Name
  exit 1
}

Write-Host "✓ Manifest found" -ForegroundColor Green
Write-Host ""

try {
  $manifest = Import-PowerShellDataFile -Path $manifestPath
  $version = $manifest.ModuleVersion
  
  # Get module name from the manifest file name itself
  $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($manifestPath)
  
  Write-Host "Module Information:" -ForegroundColor Cyan
  Write-Host "  Name: $moduleName" -ForegroundColor Gray
  Write-Host "  Version: $version" -ForegroundColor Gray
  Write-Host "  Author: $($manifest.Author)" -ForegroundColor Gray
  Write-Host "  Description: $($manifest.Description)" -ForegroundColor Gray
  Write-Host ""
  
  Write-Host "Setting outputs..." -ForegroundColor Cyan
  echo "version=$version" >> $env:GITHUB_OUTPUT
  echo "module_name=$moduleName" >> $env:GITHUB_OUTPUT
  Write-Host "✓ Outputs set successfully" -ForegroundColor Green
}
catch {
  Write-Host "##[error]Failed to parse module manifest!" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  Write-Host "##[error]Manifest path: $manifestPath" -ForegroundColor Red
  exit 1
}
