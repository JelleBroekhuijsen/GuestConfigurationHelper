#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gets release information from GitHub.

.DESCRIPTION
    Extracts release tag and version from GitHub release event or latest release.

.PARAMETER EventName
    GitHub event name (release or workflow_dispatch).

.PARAMETER ReleaseTagName
    Release tag name from GitHub event (optional, for release events).

.PARAMETER Repository
    GitHub repository (owner/name format).

.PARAMETER ModuleName
    Name of the module.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$EventName,
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseTagName,
    
    [Parameter(Mandatory = $true)]
    [string]$Repository,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleName
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Getting Release Information" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Module name: $ModuleName" -ForegroundColor Gray
Write-Host "Event type: $EventName" -ForegroundColor Gray
Write-Host "Repository: $Repository" -ForegroundColor Gray
Write-Host ""

if ($EventName -eq "release") {
  $tag = $ReleaseTagName
  $version = $tag -replace '^v', ''
  Write-Host "✓ Release event detected" -ForegroundColor Green
  Write-Host "  Tag: $tag" -ForegroundColor Gray
  Write-Host "  Version: $version" -ForegroundColor Gray
} else {
  Write-Host "Manual workflow dispatch - fetching latest release..." -ForegroundColor Cyan
  
  # For manual runs, we'll download from latest release
  $ErrorActionPreference = 'Continue'
  $output = gh release view --json tagName,name --repo $Repository 2>&1
  $exitCode = $LASTEXITCODE
  
  if ($exitCode -eq 0) {
    try {
      $latestRelease = $output | ConvertFrom-Json
      $tag = $latestRelease.tagName
      $version = $tag -replace '^v', ''
      Write-Host "✓ Latest release found" -ForegroundColor Green
      Write-Host "  Tag: $tag" -ForegroundColor Gray
      Write-Host "  Version: $version" -ForegroundColor Gray
    }
    catch {
      Write-Host "##[error]Failed to parse release information!" -ForegroundColor Red
      Write-Host "##[error]Parse error: $_" -ForegroundColor Red
      Write-Host "##[error]Raw output: $output" -ForegroundColor Red
      exit 1
    }
  } else {
    $outputStr = $output | Out-String
    Write-Host "##[error]Failed to fetch latest release!" -ForegroundColor Red
    Write-Host "##[error]Exit code: $exitCode" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error output:" -ForegroundColor Red
    Write-Host $outputStr -ForegroundColor Red
    Write-Host ""
    
    if ($outputStr -match "release not found|404|Not Found|no releases found") {
      Write-Host "##[error]No releases found in this repository." -ForegroundColor Red
      Write-Host "##[error]Please create a release first by:" -ForegroundColor Red
      Write-Host "##[error]  1. Pushing to main branch to trigger CI workflow" -ForegroundColor Red
      Write-Host "##[error]  2. Or manually creating a release with a module package asset" -ForegroundColor Red
    } elseif ($outputStr -match "authentication|401|Unauthorized|403|Forbidden") {
      Write-Host "##[error]Authentication or authorization error!" -ForegroundColor Red
      Write-Host "##[error]Ensure the workflow has 'contents: read' permission." -ForegroundColor Red
    } else {
      Write-Host "##[error]Unexpected error. This may be a GitHub API issue." -ForegroundColor Red
      Write-Host "##[error]Check GitHub status: https://www.githubstatus.com/" -ForegroundColor Red
    }
    
    exit 1
  }
}

Write-Host ""
Write-Host "Setting outputs:" -ForegroundColor Cyan
echo "tag=$tag" >> $env:GITHUB_OUTPUT
echo "version=$version" >> $env:GITHUB_OUTPUT
echo "asset_name=$ModuleName-$version.zip" >> $env:GITHUB_OUTPUT
Write-Host "  tag: $tag" -ForegroundColor Gray
Write-Host "  version: $version" -ForegroundColor Gray
Write-Host "  asset_name: $ModuleName-$version.zip" -ForegroundColor Gray
