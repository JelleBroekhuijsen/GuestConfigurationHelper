#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a GitHub release.

.DESCRIPTION
    Uses gh CLI to create a new GitHub release with the specified tag and notes.

.PARAMETER Tag
    Release tag (e.g., 'v1.0.0').

.PARAMETER ModuleName
    Name of the module.

.PARAMETER Version
    Version of the module.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $true)]
    [string]$Version
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Creating GitHub Release" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$notes = Get-Content -Path release-notes.txt -Raw
$zipName = "$ModuleName-$Version.zip"

Write-Host "Release details:" -ForegroundColor Gray
Write-Host "  Tag: $Tag" -ForegroundColor Gray
Write-Host "  Module: $ModuleName" -ForegroundColor Gray
Write-Host "  Version: $Version" -ForegroundColor Gray
Write-Host "  Asset: $zipName" -ForegroundColor Gray
Write-Host ""

# Verify asset exists before attempting release
if (-not (Test-Path $zipName)) {
  Write-Host "##[error]Module package file not found: $zipName" -ForegroundColor Red
  Write-Host "##[error]The package preparation step may have failed." -ForegroundColor Red
  Write-Host "##[error]Current directory contents:" -ForegroundColor Red
  Get-ChildItem -Force | Format-Table Name, Length, LastWriteTime
  exit 1
}

Write-Host "✓ Asset file verified: $zipName ($([math]::Round((Get-Item $zipName).Length / 1KB, 2)) KB)" -ForegroundColor Green
Write-Host ""
Write-Host "Creating release..." -ForegroundColor Cyan

# Create release with error handling
$ErrorActionPreference = 'Continue'
$output = gh release create $Tag `
  --title "Release $Tag" `
  --notes $notes `
  --verify-tag=false `
  $zipName 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
  Write-Host "✓ Release $Tag created successfully" -ForegroundColor Green
  Write-Host ""
  Write-Host "Release output:" -ForegroundColor Gray
  Write-Host $output -ForegroundColor Gray
} else {
  $outputStr = $output | Out-String
  Write-Host "##[error]Failed to create GitHub release!" -ForegroundColor Red
  Write-Host "##[error]Exit code: $exitCode" -ForegroundColor Red
  Write-Host ""
  Write-Host "Error output:" -ForegroundColor Red
  Write-Host $outputStr -ForegroundColor Red
  Write-Host ""
  
  # Provide specific guidance based on error type
  if ($outputStr -match "already exists|409|Conflict") {
    Write-Host "##[error]The release or tag already exists. This may be a race condition." -ForegroundColor Red
    Write-Host "##[error]Try re-running the workflow or manually delete the existing release/tag." -ForegroundColor Red
  } elseif ($outputStr -match "authentication|401|Unauthorized|403|Forbidden") {
    Write-Host "##[error]Authentication/authorization error!" -ForegroundColor Red
    Write-Host "##[error]Ensure the workflow has 'contents: write' permission." -ForegroundColor Red
  } elseif ($outputStr -match "validation|invalid") {
    Write-Host "##[error]Validation error in release data!" -ForegroundColor Red
    Write-Host "##[error]Check the release notes format or asset file." -ForegroundColor Red
  } elseif ($outputStr -match "asset.*not found|no such file") {
    Write-Host "##[error]Asset file error!" -ForegroundColor Red
    Write-Host "##[error]The module package file may have been deleted or moved." -ForegroundColor Red
  }
  
  Write-Host "##[error]For more information, see: https://cli.github.com/manual/gh_release_create" -ForegroundColor Red
  exit 1
}
