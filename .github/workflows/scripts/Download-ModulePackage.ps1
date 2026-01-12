#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Downloads module package from GitHub release.

.DESCRIPTION
    Uses gh CLI to download the module package asset from a GitHub release.

.PARAMETER Tag
    Release tag (e.g., 'v1.0.0').

.PARAMETER AssetName
    Name of the asset file to download.

.PARAMETER Repository
    GitHub repository (owner/name format).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    
    [Parameter(Mandatory = $true)]
    [string]$AssetName,
    
    [Parameter(Mandatory = $true)]
    [string]$Repository
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Downloading Module Package" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Release tag: $Tag" -ForegroundColor Gray
Write-Host "Asset name: $AssetName" -ForegroundColor Gray
Write-Host "Repository: $Repository" -ForegroundColor Gray
Write-Host ""
Write-Host "Downloading from release..." -ForegroundColor Cyan

# Download with error handling
$ErrorActionPreference = 'Continue'
$output = gh release download $Tag --pattern $AssetName --repo $Repository 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
  $outputStr = $output | Out-String
  Write-Host "##[error]Failed to download release asset!" -ForegroundColor Red
  Write-Host "##[error]Exit code: $exitCode" -ForegroundColor Red
  Write-Host ""
  Write-Host "Error output:" -ForegroundColor Red
  Write-Host $outputStr -ForegroundColor Red
  Write-Host ""
  
  if ($outputStr -match "not found|404|no asset") {
    Write-Host "##[error]Asset not found in release!" -ForegroundColor Red
    Write-Host "##[error]Expected asset: $AssetName" -ForegroundColor Red
    Write-Host "##[error]The release may not have been created properly or the asset is missing." -ForegroundColor Red
    Write-Host "##[error]Please check the release at: https://github.com/$Repository/releases/tag/$Tag" -ForegroundColor Red
  } elseif ($outputStr -match "authentication|401|Unauthorized|403|Forbidden") {
    Write-Host "##[error]Authentication or authorization error!" -ForegroundColor Red
    Write-Host "##[error]Ensure the workflow has 'contents: read' permission." -ForegroundColor Red
  } else {
    Write-Host "##[error]Unexpected download error." -ForegroundColor Red
    Write-Host "##[error]This may be a GitHub API issue or network problem." -ForegroundColor Red
  }
  
  exit 1
}

Write-Host "Download command completed" -ForegroundColor Gray
Write-Host ""

# Verify the file was actually downloaded
if (-not (Test-Path $AssetName)) {
  Write-Host "##[error]Asset file not found after download!" -ForegroundColor Red
  Write-Host "##[error]Expected file: $AssetName" -ForegroundColor Red
  Write-Host "##[error]Current directory contents:" -ForegroundColor Red
  Get-ChildItem -Force | Format-Table Name, Length, LastWriteTime
  exit 1
}

$fileSize = (Get-Item $AssetName).Length
Write-Host "✓ Successfully downloaded $AssetName ($([math]::Round($fileSize / 1KB, 2)) KB)" -ForegroundColor Green
