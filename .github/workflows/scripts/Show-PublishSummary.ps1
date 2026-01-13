#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Displays publish summary.

.DESCRIPTION
    Shows information about the successfully published module.

.PARAMETER ModuleName
    Name of the published module.

.PARAMETER Version
    Version of the published module.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $true)]
    [string]$Version
)

Write-Host "================================================" -ForegroundColor Green
Write-Host "Module Successfully Published!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Module Name: $ModuleName" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host "Gallery URL: https://www.powershellgallery.com/packages/$ModuleName/$Version" -ForegroundColor Cyan
Write-Host ""
Write-Host "Users can now install with:" -ForegroundColor Yellow
Write-Host "  Install-Module -Name $ModuleName -RequiredVersion $Version" -ForegroundColor White
