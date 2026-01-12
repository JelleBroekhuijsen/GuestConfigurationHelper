#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs Pester tests for the module.

.DESCRIPTION
    Executes all Pester tests in the Tests directory with detailed output.
#>

Write-Host "Running Pester tests..." -ForegroundColor Cyan

$config = New-PesterConfiguration
$config.Run.Path = './Tests'
$config.Run.Exit = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = 'testResults.xml'
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config
