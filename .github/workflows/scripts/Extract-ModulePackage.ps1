#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Extracts module package archive.

.DESCRIPTION
    Extracts the downloaded zip archive containing the module.

.PARAMETER AssetName
    Name of the archive file to extract.

.PARAMETER ModuleName
    Name of the module being extracted.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AssetName,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleName
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Extracting Module Package" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "Archive file: $AssetName" -ForegroundColor Gray
Write-Host "Module name: $ModuleName" -ForegroundColor Gray
Write-Host "Working directory: $env:GITHUB_WORKSPACE" -ForegroundColor Gray

# Verify archive exists
if (-not (Test-Path $AssetName)) {
  Write-Host "##[error]Archive file not found: $AssetName" -ForegroundColor Red
  Write-Host "##[error]The download step may have failed." -ForegroundColor Red
  exit 1
}

$archiveSize = (Get-Item $AssetName).Length
Write-Host "Archive size: $([math]::Round($archiveSize / 1KB, 2)) KB" -ForegroundColor Gray
Write-Host ""

$extractionPath = Join-Path $env:GITHUB_WORKSPACE $ModuleName
Write-Host "Extracting archive to: $extractionPath" -ForegroundColor Cyan

try {
  Expand-Archive -Path $AssetName -DestinationPath $extractionPath -Force
  Write-Host "✓ Archive extracted successfully" -ForegroundColor Green
  Write-Host ""
  
  Write-Host "Extracted contents:" -ForegroundColor Cyan
  Get-ChildItem $extractionPath -Force -Recurse | Format-Table Name, Length, LastWriteTime
}
catch {
  Write-Host "##[error]Failed to extract archive!" -ForegroundColor Red
  Write-Host "##[error]Error: $_" -ForegroundColor Red
  Write-Host "##[error]The archive file may be corrupted." -ForegroundColor Red
  exit 1
}
