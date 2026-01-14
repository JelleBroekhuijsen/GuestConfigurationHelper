#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Checks if module-relevant files have changed.

.DESCRIPTION
    Compares current commit with base ref to determine if any module-relevant files were modified.
    Module-relevant files include:
    - *.psm1 files
    - *.psd1 files  
    - README.md (case-insensitive)
    - Files in /Private/ directory
    - Files in /Public/ directory

.PARAMETER BaseRef
    The base reference to compare against (e.g., 'origin/main' or commit SHA).
    Defaults to the merge base with origin/main.

.PARAMETER HeadRef
    The head reference to compare (defaults to HEAD).

.OUTPUTS
    Sets GitHub Actions outputs:
    - module_files_changed: 'true' or 'false'
    - changed_files: JSON array of changed module files
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$BaseRef,
    
    [Parameter(Mandatory = $false)]
    [string]$HeadRef = "HEAD"
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Checking for Module File Changes" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Determine base ref if not provided
# Note: This logic is duplicated in Test-ModuleVersionBump.ps1
# If more scripts need this, consider extracting to a shared function
if ([string]::IsNullOrEmpty($BaseRef)) {
    Write-Host "No base ref provided, detecting base ref..." -ForegroundColor Gray
    try {
        # Check if HEAD is a merge commit (has multiple parents)
        # This happens when a PR is merged to main
        $parentCount = (git rev-list --parents -n 1 HEAD 2>&1 | ForEach-Object { $_.Split(' ').Count - 1 })
        
        if ($parentCount -gt 1) {
            # HEAD is a merge commit - compare with first parent to get merged changes
            # This ensures we capture all files from the merged PR
            $BaseRef = "HEAD^1"
            Write-Host "Detected merge commit, comparing with first parent: $BaseRef" -ForegroundColor Gray
        }
        else {
            # HEAD is not a merge commit - use standard merge-base logic
            # Try to fetch origin/main
            $fetchResult = git fetch origin main 2>&1
            $fetchExitCode = $LASTEXITCODE
            if ($fetchExitCode -ne 0) {
                Write-Host "##[warning]git fetch origin main failed with exit code $fetchExitCode" -ForegroundColor Yellow
                if ($null -ne $fetchResult -and $fetchResult -ne "") {
                    Write-Host $fetchResult -ForegroundColor DarkYellow
                }
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
    }
    catch {
        Write-Host "##[error]Failed to determine base ref: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Comparison parameters:" -ForegroundColor Cyan
Write-Host "  Base: $BaseRef" -ForegroundColor Gray
Write-Host "  Head: $HeadRef" -ForegroundColor Gray
Write-Host ""

# Get list of changed files
Write-Host "Fetching changed files..." -ForegroundColor Cyan
try {
    $changedFiles = git diff --name-only $BaseRef $HeadRef 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "##[error]Failed to get changed files: $changedFiles" -ForegroundColor Red
        exit 1
    }
    
    $changedFilesArray = $changedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    Write-Host "Total files changed: $($changedFilesArray.Count)" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "##[error]Error getting changed files: $_" -ForegroundColor Red
    exit 1
}

# Define module-relevant file patterns
$modulePatterns = @(
    '*.psm1',
    '*.psd1',
    'Private/*',
    'Public/*'
)

# Check for README.md (case-insensitive)
# Note: -match is case-insensitive by default in PowerShell
$readmePattern = '^readme\.md$'

# Filter for module-relevant files
$moduleFiles = @()
foreach ($file in $changedFilesArray) {
    $isModuleFile = $false
    
    # Check README.md (case-insensitive match)
    if ($file -imatch $readmePattern) {
        $isModuleFile = $true
    }
    
    # Check other patterns
    foreach ($pattern in $modulePatterns) {
        $wildcardPattern = $pattern.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        if ($file -like $wildcardPattern) {
            $isModuleFile = $true
            break
        }
    }
    
    if ($isModuleFile) {
        $moduleFiles += $file
    }
}

# Report results
Write-Host "Module-relevant files changed: $($moduleFiles.Count)" -ForegroundColor Cyan
if ($moduleFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Changed module files:" -ForegroundColor Yellow
    foreach ($file in $moduleFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
    $moduleFilesChanged = 'true'
}
else {
    Write-Host "✓ No module-relevant files changed" -ForegroundColor Green
    $moduleFilesChanged = 'false'
}

Write-Host ""
Write-Host "Setting outputs:" -ForegroundColor Cyan
Write-Host "  module_files_changed: $moduleFilesChanged" -ForegroundColor Gray

# Convert to JSON for output
$changedFilesJson = $moduleFiles | ConvertTo-Json -Compress -Depth 5
if ([string]::IsNullOrEmpty($changedFilesJson)) {
    $changedFilesJson = '[]'
}
Write-Host "  changed_files: $changedFilesJson" -ForegroundColor Gray

"module_files_changed=$moduleFilesChanged" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
"changed_files=$changedFilesJson" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append

Write-Host ""
Write-Host "✓ Module file change check complete" -ForegroundColor Green
