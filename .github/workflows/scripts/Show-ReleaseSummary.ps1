#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Displays release summary.

.DESCRIPTION
    Shows information about the successfully created release.

.PARAMETER Tag
    Release tag (e.g., 'v1.0.0').

.PARAMETER Repository
    GitHub repository (owner/name format).

.PARAMETER ServerUrl
    GitHub server URL.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,
    
    [Parameter(Mandatory = $true)]
    [string]$Repository,
    
    [Parameter(Mandatory = $true)]
    [string]$ServerUrl
)

Write-Host "================================================" -ForegroundColor Green
Write-Host "Release Created Successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Tag: $Tag" -ForegroundColor Cyan
Write-Host "Release URL: $ServerUrl/$Repository/releases/tag/$Tag" -ForegroundColor Cyan
Write-Host ""
Write-Host "The publish workflow will now automatically publish to PowerShell Gallery" -ForegroundColor Yellow
