#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Prepares module artifact for release.

.DESCRIPTION
    Copies module files to a publish directory structure.

.PARAMETER ModuleName
    Name of the module to prepare.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName
)

Write-Host "Preparing module artifact..." -ForegroundColor Cyan
$publishDir = Join-Path $env:GITHUB_WORKSPACE "publish"
$moduleDir = Join-Path $publishDir $ModuleName

# Verify working directory
Write-Host "Working directory: $env:GITHUB_WORKSPACE" -ForegroundColor Gray

# Create publish directory structure
try {
  New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
  Write-Host "✓ Created directory: $moduleDir" -ForegroundColor Green
}
catch {
  Write-Host "##[error]Failed to create module directory!" -ForegroundColor Red
  Write-Host "##[error]Path: $moduleDir" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  exit 1
}
Write-Host ""

# Copy module files (excluding repository metadata, tests, etc.)
$filesToCopy = @(
  "$ModuleName.psd1",
  "$ModuleName.psm1",
  "Helpers.ps1",
  "README.md"
)

$requiredFiles = @("$ModuleName.psd1", "$ModuleName.psm1")
$copiedCount = 0

foreach ($file in $filesToCopy) {
  $sourcePath = Join-Path $env:GITHUB_WORKSPACE $file
  if (Test-Path $sourcePath) {
    try {
      Copy-Item -Path $sourcePath -Destination $moduleDir -Force -ErrorAction Stop
      Write-Host "  ✓ Copied: $file" -ForegroundColor Gray
      $copiedCount++
    }
    catch {
      Write-Host "##[error]Failed to copy file: $file" -ForegroundColor Red
      Write-Host "##[error]Error: $_" -ForegroundColor Red
      exit 1
    }
  } elseif ($requiredFiles -contains $file) {
    Write-Host "##[error]Required file not found: $file" -ForegroundColor Red
    Write-Host "##[error]Expected path: $sourcePath" -ForegroundColor Red
    exit 1
  } else {
    Write-Host "  ⚠ Optional file not found: $file" -ForegroundColor Yellow
  }
}

if ($copiedCount -eq 0) {
  Write-Host "##[error]No files were copied!" -ForegroundColor Red
  exit 1
}
Write-Host ""

# Copy directories
$dirsToPublish = @('Public', 'Private')
foreach ($dir in $dirsToPublish) {
  $sourcePath = Join-Path $env:GITHUB_WORKSPACE $dir
  if (Test-Path $sourcePath) {
    try {
      Copy-Item -Path $sourcePath -Destination $moduleDir -Recurse -Force -ErrorAction Stop
      $fileCount = (Get-ChildItem -Path (Join-Path $moduleDir $dir) -Recurse -File).Count
      Write-Host "  ✓ Copied directory: $dir ($fileCount files)" -ForegroundColor Gray
    }
    catch {
      Write-Host "##[error]Failed to copy directory: $dir" -ForegroundColor Red
      Write-Host "##[error]Error: $_" -ForegroundColor Red
      exit 1
    }
  } else {
    Write-Host "  ⚠ Directory not found: $dir" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "✓ Module prepared at: $moduleDir" -ForegroundColor Green
