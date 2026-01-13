#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs PSScriptAnalyzer on the repository.

.DESCRIPTION
    Analyzes PowerShell code using PSScriptAnalyzer with PSGallery settings.
    Fails the build if any errors are found.
#>

Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan
$results = Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery

if ($results) {
  Write-Host "PSScriptAnalyzer found $($results.Count) issue(s):" -ForegroundColor Yellow
  $results | Format-Table -AutoSize

  $errors = $results | Where-Object { $_.Severity -eq 'Error' }
  $warnings = $results | Where-Object { $_.Severity -eq 'Warning' }

  Write-Host "`nSummary:" -ForegroundColor Cyan
  Write-Host "  Errors: $($errors.Count)" -ForegroundColor Red
  Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor Yellow

  if ($errors.Count -gt 0) {
    Write-Error "PSScriptAnalyzer found $($errors.Count) error(s). Please fix them before merging."
    exit 1
  }
} else {
  Write-Host "✓ No issues found by PSScriptAnalyzer" -ForegroundColor Green
}
