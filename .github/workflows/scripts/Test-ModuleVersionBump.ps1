#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates that module version was bumped when module files changed.

.DESCRIPTION
    Compares the current module version against the version in the base branch.
    Fails if module-relevant files changed but the version wasn't incremented.

.PARAMETER BaseRef
    The base reference to compare against (e.g., 'origin/main' or commit SHA).
    Defaults to the merge base with origin/main.

.PARAMETER ManifestPath
    Path to the module manifest file (defaults to GuestConfigurationHelper.psd1).

.PARAMETER ModuleFilesChanged
    Whether module files were changed ('true' or 'false'). If 'false', this script succeeds immediately.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$BaseRef,
    
    [Parameter(Mandatory = $false)]
    [string]$ManifestPath = "GuestConfigurationHelper.psd1",
    
    [Parameter(Mandatory = $false)]
    [string]$ModuleFilesChanged = 'false'
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Validating Module Version Bump" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# If module files didn't change, skip validation
if ($ModuleFilesChanged -eq 'false') {
    Write-Host "✓ Module files unchanged - version bump not required" -ForegroundColor Green
    Write-Host ""
    Write-Host "This validation only applies when module-relevant files are modified." -ForegroundColor Gray
    exit 0
}

Write-Host "Module files changed - validating version bump..." -ForegroundColor Yellow
Write-Host ""

# Determine base ref if not provided
# Note: This logic is duplicated in Test-ModuleFilesChanged.ps1
# If more scripts need this, consider extracting to a shared function
if ([string]::IsNullOrEmpty($BaseRef)) {
    Write-Host "No base ref provided, detecting base ref..." -ForegroundColor Gray
    try {
        # Try to fetch origin/main
        $fetchResult = git fetch origin main 2>&1
        $fetchExitCode = $LASTEXITCODE
        if ($fetchExitCode -ne 0) {
            Write-Host "##[warning]Failed to fetch origin/main (exit code $fetchExitCode): $fetchResult" -ForegroundColor Yellow
        }
        
        # Check if origin/main exists
        git rev-parse --verify origin/main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            # Try merge-base first
            $BaseRef = git merge-base HEAD origin/main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Using merge-base with origin/main: $BaseRef" -ForegroundColor Gray
            }
            else {
                Write-Host "Could not determine merge-base, using origin/main directly" -ForegroundColor Yellow
                $BaseRef = "origin/main"
            }
        }
        else {
            # Fallback: try main branch directly
            $mainExists = git rev-parse --verify main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Using local main branch as base" -ForegroundColor Yellow
                $BaseRef = "main"
            }
            else {
                # Last resort: use HEAD~1 
                Write-Host "##[warning]Could not find main or origin/main, using HEAD~1" -ForegroundColor Yellow
                $BaseRef = "HEAD~1"
            }
        }
        Write-Host "Base ref: $BaseRef" -ForegroundColor Gray
    }
    catch {
        Write-Host "##[error]Failed to determine base ref: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Comparison parameters:" -ForegroundColor Cyan
Write-Host "  Base: $BaseRef" -ForegroundColor Gray
Write-Host "  Manifest: $ManifestPath" -ForegroundColor Gray
Write-Host ""

# Get current version
$currentManifestPath = Join-Path $env:GITHUB_WORKSPACE $ManifestPath
Write-Host "Reading current version from: $currentManifestPath" -ForegroundColor Cyan

if (-not (Test-Path $currentManifestPath)) {
    Write-Host "##[error]Current module manifest not found: $currentManifestPath" -ForegroundColor Red
    exit 1
}

try {
    $currentManifest = Import-PowerShellDataFile -Path $currentManifestPath
    $currentVersion = $currentManifest.ModuleVersion
    Write-Host "  Current version: $currentVersion" -ForegroundColor Gray
}
catch {
    Write-Host "##[error]Failed to read current module version: $_" -ForegroundColor Red
    exit 1
}

# Get base version
Write-Host ""
Write-Host "Reading base version from: $BaseRef" -ForegroundColor Cyan

try {
    # Get the manifest content from base ref
    $baseManifestContent = git show "${BaseRef}:${ManifestPath}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "##[error]Failed to read manifest from base ref: $baseManifestContent" -ForegroundColor Red
        exit 1
    }
    
    # Write to temp file and parse
    $tempFile = [System.IO.Path]::GetTempFileName()
    $tempFile = [System.IO.Path]::ChangeExtension($tempFile, '.psd1')
    $baseManifestContent | Out-File -FilePath $tempFile -Encoding UTF8
    
    $baseManifest = Import-PowerShellDataFile -Path $tempFile
    $baseVersion = $baseManifest.ModuleVersion
    Write-Host "  Base version: $baseVersion" -ForegroundColor Gray
    
    # Cleanup temp file
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "##[error]Failed to read base module version: $_" -ForegroundColor Red
    exit 1
}

# Compare versions
Write-Host ""
Write-Host "Comparing versions..." -ForegroundColor Cyan
Write-Host "  Base:    $baseVersion" -ForegroundColor Gray
Write-Host "  Current: $currentVersion" -ForegroundColor Gray
Write-Host ""

try {
    $currentVersionObj = [version]$currentVersion
    $baseVersionObj = [version]$baseVersion
    
    if ($currentVersionObj -gt $baseVersionObj) {
        Write-Host "✓ Version was incremented correctly" -ForegroundColor Green
        Write-Host ""
        Write-Host "Details:" -ForegroundColor Cyan
        Write-Host "  Old version: $baseVersion" -ForegroundColor Gray
        Write-Host "  New version: $currentVersion" -ForegroundColor Gray
        
        # Calculate the difference
        $majorDiff = $currentVersionObj.Major - $baseVersionObj.Major
        $minorDiff = $currentVersionObj.Minor - $baseVersionObj.Minor
        $patchDiff = $currentVersionObj.Build - $baseVersionObj.Build
        
        Write-Host ""
        Write-Host "  Change type: " -NoNewline -ForegroundColor Gray
        if ($majorDiff -gt 0) {
            Write-Host "Major version bump" -ForegroundColor Yellow
        }
        elseif ($minorDiff -gt 0) {
            Write-Host "Minor version bump" -ForegroundColor Yellow
        }
        else {
            Write-Host "Patch version bump" -ForegroundColor Yellow
        }
        
        exit 0
    }
    elseif ($currentVersionObj -eq $baseVersionObj) {
        Write-Host "##[error]❌ Module version was not incremented!" -ForegroundColor Red
        Write-Host "" 
        Write-Host "MODULE VERSION BUMP REQUIRED" -ForegroundColor Red
        Write-Host "==========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "You have made changes to module-relevant files, but the module version" -ForegroundColor Yellow
        Write-Host "was not incremented. This is required to maintain version discipline." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Current version: $currentVersion" -ForegroundColor Gray
        Write-Host "Base version:    $baseVersion" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Module-relevant files include:" -ForegroundColor Cyan
        Write-Host "  - *.psm1 files" -ForegroundColor Gray
        Write-Host "  - *.psd1 files" -ForegroundColor Gray
        Write-Host "  - README.md" -ForegroundColor Gray
        Write-Host "  - Files in /Private/ directory" -ForegroundColor Gray
        Write-Host "  - Files in /Public/ directory" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To fix this:" -ForegroundColor Cyan
        Write-Host "  1. Update the ModuleVersion in $ManifestPath" -ForegroundColor Gray
        Write-Host "  2. Increment the version appropriately:" -ForegroundColor Gray
        Write-Host "     - Major (X.0.0): Breaking changes" -ForegroundColor Gray
        Write-Host "     - Minor (0.X.0): New features, backwards compatible" -ForegroundColor Gray
        Write-Host "     - Patch (0.0.X): Bug fixes, backwards compatible" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
    else {
        Write-Host "##[warning]Current version ($currentVersion) is lower than base version ($baseVersion)" -ForegroundColor Yellow
        Write-Host "This is unusual but not blocking. Please verify this is intentional." -ForegroundColor Yellow
        exit 0
    }
}
catch {
    Write-Host "##[error]Failed to compare versions: $_" -ForegroundColor Red
    Write-Host "##[error]Current version: $currentVersion" -ForegroundColor Red
    Write-Host "##[error]Base version: $baseVersion" -ForegroundColor Red
    exit 1
}
