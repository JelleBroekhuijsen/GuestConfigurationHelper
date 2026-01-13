#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Packages module for GitHub release.

.DESCRIPTION
    Creates a zip archive of the prepared module.

.PARAMETER ModuleName
    Name of the module to package.

.PARAMETER Version
    Version of the module.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $true)]
    [string]$Version
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Packaging Module for Release" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$zipName = "$ModuleName-$Version.zip"
$publishDir = Join-Path $env:GITHUB_WORKSPACE "publish"
$moduleDir = Join-Path $publishDir $ModuleName

Write-Host "Module: $ModuleName" -ForegroundColor Gray
Write-Host "Version: $Version" -ForegroundColor Gray
Write-Host "Package name: $zipName" -ForegroundColor Gray
Write-Host "Working directory: $env:GITHUB_WORKSPACE" -ForegroundColor Gray
Write-Host ""

# Verify publish directory exists and has content
if (-not (Test-Path $moduleDir)) {
  Write-Host "##[error]Module directory not found!" -ForegroundColor Red
  Write-Host "##[error]Expected path: $moduleDir" -ForegroundColor Red
  Write-Host "##[error]The module preparation step may have failed." -ForegroundColor Red
  Write-Host "##[error]Current directory contents:" -ForegroundColor Red
  Get-ChildItem $env:GITHUB_WORKSPACE -Force | Format-Table Name
  exit 1
}

# Verify critical files exist
$manifestPath = Join-Path $moduleDir "$ModuleName.psd1"
if (-not (Test-Path $manifestPath)) {
  Write-Host "##[error]Module manifest not found in prepared directory!" -ForegroundColor Red
  Write-Host "##[error]Expected path: $manifestPath" -ForegroundColor Red
  exit 1
}

Write-Host "Module directory contents:" -ForegroundColor Cyan
$fileList = Get-ChildItem -Path $moduleDir -Recurse -File
$totalSize = ($fileList | Measure-Object -Property Length -Sum).Sum
$fileList | Select-Object FullName, Length | 
  ForEach-Object { Write-Host "  $($_.FullName) ($($_.Length) bytes)" -ForegroundColor Gray }
Write-Host ""
Write-Host "Total files: $($fileList.Count)" -ForegroundColor Gray
Write-Host "Total size: $([math]::Round($totalSize / 1KB, 2)) KB" -ForegroundColor Gray
Write-Host ""

Write-Host "Creating zip archive..." -ForegroundColor Cyan

try {
  # Compress from within the publish directory to avoid nested structure
  $currentLocation = Get-Location
  try {
    Set-Location $publishDir
    Compress-Archive -Path "$ModuleName/*" -DestinationPath "$env:GITHUB_WORKSPACE/$zipName" -Force -ErrorAction Stop
  }
  finally {
    # Ensure we always restore the location, even if Compress-Archive fails
    Set-Location $currentLocation
  }
  
  $zipPath = Join-Path $env:GITHUB_WORKSPACE $zipName
  if (Test-Path $zipPath) {
    $zipSize = (Get-Item $zipPath).Length
    Write-Host "✓ Created $zipName ($([math]::Round($zipSize / 1KB, 2)) KB)" -ForegroundColor Green
    
    # Validate zip is not empty or corrupt
    if ($zipSize -lt 1KB) {
      Write-Host "##[error]Zip file is suspiciously small ($zipSize bytes)!" -ForegroundColor Red
      Write-Host "##[error]The archive may be empty or corrupt." -ForegroundColor Red
      exit 1
    }
  } else {
    Write-Host "##[error]Zip file was not created!" -ForegroundColor Red
    Write-Host "##[error]Expected path: $zipPath" -ForegroundColor Red
    exit 1
  }
}
catch {
  Write-Host "##[error]Failed to create zip archive!" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  Write-Host "##[error]Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
  exit 1
}
