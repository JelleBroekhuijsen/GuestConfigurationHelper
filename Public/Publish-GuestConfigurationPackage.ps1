function Publish-GuestConfigurationPackage {
    <#
    .SYNOPSIS 
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$ConfigurationFilePath,

        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        $OutputFolder = $pwd.Path,

        [Parameter(ParameterSetName = 'Debug')]
        [switch]$NoCleanup
    )
    
    begin {
        Write-Verbose "Publish-GuestConfigurationPackage started"
        Write-Verbose "Running with parameter set: $($PSCmdlet.ParameterSetName)"
        Write-Verbose "Received parameters: $($PSBoundParameters| ConvertTo-Json)"

        $ErrorActionPreference = 'Stop'
        $configuration = Get-Item -Path $ConfigurationFilePath
        $configurationName = Get-Content -Path $configuration.FullName -ErrorAction Stop | Select-String -Pattern 'Configuration\s+(\w+)' | ForEach-Object { $_.Matches.Groups[1].Value }
        if(-not $configurationName) {
            throw "Failed to extract configuration name from configuration file: $($configuration.FullName)"
        }
        
        if($configurationName.Count -gt 1){
            throw "Found multiple configurations in configuration file: $($configuration.FullName)"
        }

        $ConfigurationMofFile = Join-Path -Path $pwd -ChildPath "$configurationName" -AdditionalChildPath "$configurationName.mof"
    }
    
    process {
        $mofFile = . $configuration.FullName -ErrorAction Stop
        if (-not (Test-Path -Path $mofFile.FullName -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Failed to generate MOF file from configuration file: $($configuration.FullName)"
        }
        else {
            Write-Verbose "Generated MOF file: $($mofFile.FullName)"
        }

        Write-Verbose "Renaming localhost.mof file to '$($configurationName).mof'..."
        Rename-Item $mofFile.FullName -NewName "$($configurationName).mof" -ErrorAction Stop

        Write-Verbose "Creating package for configuration '$configurationName'..."
        $config = New-GuestConfigurationPackage -Name $configurationName -Configuration $ConfigurationMofFile -Path $OutputFolder. -Type AuditAndSet -Force
        if(-not (Test-Path -Path $config.Path -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Failed to create package for configuration: $($configuration.BaseName)"
        }
        else {
            Write-Verbose "Created package for configuration: $($config.Path)"
        }
    }
    
    end {
        
    }
}