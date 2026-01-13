#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Checks if a GitHub release already exists.

.DESCRIPTION
    Uses gh CLI to check if a release exists for the specified version tag.

.PARAMETER Version
    Version number (without 'v' prefix).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Checking Release Status" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$tag = "v$Version"

Write-Host "Target tag: $tag" -ForegroundColor Gray
Write-Host "Repository: $env:GITHUB_REPOSITORY" -ForegroundColor Gray
Write-Host ""

# Capture both stdout and stderr, and the exit code
$ErrorActionPreference = 'Continue'
$output = gh release view $tag 2>&1
$exitCode = $LASTEXITCODE

Write-Host "gh CLI exit code: $exitCode" -ForegroundColor Gray

# Analyze the result
if ($exitCode -eq 0) {
  # Release exists
  $exists = $true
  Write-Host "✓ Release $tag already exists" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Diagnostic output:" -ForegroundColor Gray
  Write-Host $output -ForegroundColor Gray
} else {
  # Release check failed - determine why
  $outputStr = $output | Out-String
  Write-Host "Release check returned non-zero exit code" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Diagnostic output:" -ForegroundColor Gray
  Write-Host $outputStr -ForegroundColor Gray
  Write-Host ""
  
  # Analyze the error to determine the type
  if ($outputStr -match "release not found|404|Not Found|could not find release") {
    # Expected: Release doesn't exist (404)
    $exists = $false
    Write-Host "✓ Release $tag does not exist (will be created)" -ForegroundColor Green
  } elseif ($outputStr -match "authentication|401|Unauthorized|403|Forbidden|Bad credentials") {
    # Authentication/authorization error
    Write-Host "##[error]Authentication or authorization error detected!" -ForegroundColor Red
    Write-Host "##[error]The GitHub token may be invalid or lack required permissions." -ForegroundColor Red
    Write-Host "##[error]Required permissions: contents: write" -ForegroundColor Red
    Write-Host "##[error]Full error output: $outputStr" -ForegroundColor Red
    exit 1
  } elseif ($outputStr -match "rate limit|429|API rate limit") {
    # Rate limiting error
    Write-Host "##[error]GitHub API rate limit exceeded!" -ForegroundColor Red
    Write-Host "##[error]Please wait and retry later, or check your API usage." -ForegroundColor Red
    Write-Host "##[error]Full error output: $outputStr" -ForegroundColor Red
    exit 1
  } elseif ($outputStr -match "timeout|timed out|connection") {
    # Network/connectivity error
    Write-Host "##[error]Network connectivity or timeout error!" -ForegroundColor Red
    Write-Host "##[error]There may be network issues or GitHub API is unavailable." -ForegroundColor Red
    Write-Host "##[error]Full error output: $outputStr" -ForegroundColor Red
    exit 1
  } else {
    # Unknown error - fail with diagnostic info
    Write-Host "##[error]Unexpected error checking release status!" -ForegroundColor Red
    Write-Host "##[error]Exit code: $exitCode" -ForegroundColor Red
    Write-Host "##[error]This might indicate a GitHub API issue, network problem, or gh CLI error." -ForegroundColor Red
    Write-Host "##[error]Full error output: $outputStr" -ForegroundColor Red
    Write-Host "##[error]Please check GitHub status at https://www.githubstatus.com/" -ForegroundColor Red
    exit 1
  }
}

Write-Host ""
Write-Host "Setting outputs:" -ForegroundColor Cyan
Write-Host "  exists: $($exists.ToString().ToLower())" -ForegroundColor Gray
Write-Host "  tag: $tag" -ForegroundColor Gray

echo "exists=$($exists.ToString().ToLower())" >> $env:GITHUB_OUTPUT
echo "tag=$tag" >> $env:GITHUB_OUTPUT

# Ensure script exits with success code
exit 0
