#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates release notes from git commits.

.DESCRIPTION
    Creates formatted release notes by extracting commit messages since the last tag.
    This script fixes the YAML syntax error by properly escaping markdown code fences.

.PARAMETER Version
    Version number for the release.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Generating Release Notes" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Version: $Version" -ForegroundColor Gray
Write-Host ""

# Get commits since last tag
Write-Host "Checking for previous releases..." -ForegroundColor Cyan
$ErrorActionPreference = 'Continue'
$lastTag = git describe --tags --abbrev=0 2>&1
$lastTagExitCode = $LASTEXITCODE

if ($lastTagExitCode -eq 0) {
  Write-Host "✓ Found previous tag: $lastTag" -ForegroundColor Green
  Write-Host "Getting commits since $lastTag..." -ForegroundColor Cyan
  $commits = git log "$lastTag..HEAD" --pretty=format:"- %s (%h)" 2>&1
  $commitCount = (git rev-list "$lastTag..HEAD" --count 2>&1)
  Write-Host "  Found $commitCount commits since last release" -ForegroundColor Gray
} else {
  Write-Host "No previous tags found - this appears to be the first release" -ForegroundColor Yellow
  Write-Host "Getting all commits..." -ForegroundColor Cyan
  $commits = git log --pretty=format:"- %s (%h)" 2>&1
  $commitCount = (git rev-list HEAD --count 2>&1)
  Write-Host "  Found $commitCount total commits" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Commit list preview (first 10):" -ForegroundColor Cyan
$commits | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
if ($commitCount -gt 10) {
  Write-Host "  ... and $($commitCount - 10) more" -ForegroundColor Gray
}
Write-Host ""

# Create release notes with properly escaped code fence
# Using backtick (`) to escape backticks in PowerShell string
$notes = @"
## GuestConfigurationHelper v$Version

### Changes
$commits

### Installation
```powershell
Install-Module -Name GuestConfigurationHelper -RequiredVersion $Version
```
"@

# Write to file to preserve multiline content
$notes | Out-File -FilePath release-notes.txt -Encoding utf8
Write-Host "✓ Release notes generated and saved to release-notes.txt" -ForegroundColor Green
