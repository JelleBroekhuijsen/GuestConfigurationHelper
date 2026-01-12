#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs required PowerShell modules for CI/CD pipeline.

.DESCRIPTION
    Installs Pester, PSScriptAnalyzer, and PSDscResources modules required for testing and analysis.
#>

Write-Host "Installing Pester..." -ForegroundColor Cyan
Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Cyan
Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser
Write-Host "Installing PSDscResources..." -ForegroundColor Cyan
Install-Module -Name PSDscResources -Force -SkipPublisherCheck -Scope CurrentUser
Write-Host "✓ Modules installed" -ForegroundColor Green
