function New-GuestConfigurationPackage {
    <#
    .SYNOPSIS
        Wrapper function for the external New-GuestConfigurationPackage command.
    
    .DESCRIPTION
        This function wraps the external New-GuestConfigurationPackage command from the GuestConfiguration module.
        It exists to allow proper mocking in tests and to provide a consistent interface.
    
    .PARAMETER Name
        The name of the configuration package.
    
    .PARAMETER Configuration
        The path to the MOF configuration file.
    
    .PARAMETER Path
        The output path for the package.
    
    .PARAMETER Type
        The type of the package (e.g., AuditAndSet).
    
    .PARAMETER Force
        Force overwrite of existing package.
    
    .EXAMPLE
        New-GuestConfigurationPackage -Name 'MyConfig' -Configuration 'C:\MyConfig\MyConfig.mof' -Path 'C:\Output' -Type 'AuditAndSet' -Force
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Configuration,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [string]$Type = 'AuditAndSet',
        
        [Parameter()]
        [switch]$Force
    )
    
    # Try to call the external New-GuestConfigurationPackage command
    # This requires the GuestConfiguration module to be installed
    try {
        # Get the external command, excluding commands from the current module to avoid calling this wrapper recursively
        $externalCommand = Get-Command -Name 'New-GuestConfigurationPackage' -CommandType Cmdlet, Function -ErrorAction Stop | 
            Where-Object { $_.Module.Name -ne 'GuestConfigurationHelper' } |
            Select-Object -First 1
        
        if (-not $externalCommand) {
            throw "External New-GuestConfigurationPackage command not found in GuestConfiguration module"
        }
        
        & $externalCommand -Name $Name -Configuration $Configuration -Path $Path -Type $Type -Force:$Force
    }
    catch {
        # Provide helpful error message while preserving original exception details
        if ($_.Exception.Message -match "parameter|GuestConfiguration") {
            throw
        }
        throw "Failed to call New-GuestConfigurationPackage. The GuestConfiguration module may not be installed. Install it using: Install-Module -Name GuestConfiguration. Original error: $($_.Exception.Message)"
    }
}
