function Publish-GuestConfigurationPackage {
    <#
    .SYNOPSIS 
        Creates a GuestConfigurationPackage from a DSC configuration file.

    .DESCRIPTION
        This function creates a GuestConfigurationPackage from a DSC configuration file. The function extracts the configuration name from the configuration file and generates a MOF file from the configuration file. The function then creates a GuestConfigurationPackage using the New-GuestConfigurationPackage cmdlet.

    .PARAMETER Configuration
        The path to the DSC configuration file.

    .PARAMETER ConfigurationParameters
        A hashtable containing the configuration parameters to be used when generating the MOF file.

    .PARAMETER OutputFolder
        The path to the folder where the GuestConfigurationPackage will be created. The default value is the current directory.

    .PARAMETER CompressConfiguration
        Indicates whether to compress the configuration files before creating the package.

    .PARAMETER NoCleanup
        Indicates whether to clean up the temporary files created during the process. Default behavior is to clean up the temporary files.

    .EXAMPLE
        Publish-GuestConfigurationPackage -Configuration .\SimpleDscConfiguration.ps1

    .EXAMPLE
        Publish-GuestConfigurationPackage -Configuration .\SimpleDscConfiguration.ps1 -ConfigurationParameters @{ComputerName = 'localhost'}

    .EXAMPLE
        Publish-GuestConfigurationPackage -Configuration .\SimpleDscConfiguration.ps1 -OutputFolder .\Output

    .EXAMPLE
        Publish-GuestConfigurationPackage -Configuration .\SimpleDscConfiguration.ps1 -NoCleanup

    .EXAMPLE
        Publish-GuestConfigurationPackage -Configuration .\SimpleDscConfiguration.ps1 -CompressConfiguration
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        $Configuration,

        [Parameter()]
        [hashtable]
        $ConfigurationParameters,

        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $OutputFolder = $pwd.Path,

        [Parameter(ParameterSetName = 'Debug')]
        [switch]
        $NoCleanup,

        [Parameter()]
        [switch]
        $CompressConfiguration
    )
    
    begin {
        Write-Verbose 'Publish-GuestConfigurationPackage started'
        Write-Verbose "Running with parameter set: $($PSCmdlet.ParameterSetName)"
        Write-Verbose "Received parameters: $($PSBoundParameters| ConvertTo-Json)"

        $ErrorActionPreference = 'Stop'
        $configurationFile = Get-Item -Path $Configuration
        $configurations = Get-Content -Path $configurationFile.FullName -ErrorAction Stop | Select-String -Pattern '^Configuration\s+(\w+)' -AllMatches
        if ($configurations.Matches.Count -gt 1) {
            throw "Found multiple configurations in configuration file: $($configurationFile.FullName)"
        }
        if ($configurations.Matches.Groups.Count -lt 1) {
            throw "Failed to detect any configurations in configuration file: $($configurationFile.FullName)"
        }

        $configurationName = $configurations.Matches.Groups[1].Value
        Write-Verbose "Extracted configuration name: $($configurationName)"

        $ConfigurationMofFile = Join-Path -Path $pwd -ChildPath "$configurationName" -AdditionalChildPath "$configurationName.mof"
        Write-Verbose "Configuration MOF file: $($ConfigurationMofFile)"
    }
    
    process {
        if($ConfigurationParameters) {
            $mofFile = . $configurationFile.FullName @ConfigurationParameters -ErrorAction Stop
        }
        else{
            $mofFile = . $configurationFile.FullName -ErrorAction Stop
        }
        
        if (-not (Test-Path -Path $mofFile.FullName -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Failed to generate MOF file from configuration file: $($configurationFile.FullName)"
        }   
        else {
            Write-Verbose "Generated MOF file: $($mofFile.FullName)"
        }

        Write-Verbose "Renaming localhost.mof file to '$($configurationName).mof'..."
        Rename-Item -Path $mofFile.FullName -NewName "$($configurationName).mof" -ErrorAction Stop

        Write-Verbose "Creating package for configuration '$configurationName'..."
        $configurationPackage = New-GuestConfigurationPackage -Name $configurationName -Configuration $ConfigurationMofFile -Path $OutputFolder -Type AuditAndSet -Force
        if (-not (Test-Path -Path $configurationPackage.Path -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Failed to create package for configuration: $($configurationFile.BaseName)"
        }
        else {
            Write-Verbose "Created package for configuration: $($configurationPackage.Path)"
        }

        $stagingFolder = New-Item -Path "$pwd\staging" -ItemType Directory -ErrorAction Stop
        if($CompressConfiguration) {
            Test-ConfigurationFileSizeOnDisk -ConfigurationPackage $configurationPackage.Path -StagingFolder $stagingFolder.FullName -CompressConfiguration
            Compress-Archive -Path "$($stagingFolder.FullName)\*" -DestinationPath $configurationPackage.Path -Force
        }
        else{
            Test-ConfigurationFileSizeOnDisk -ConfigurationPackage $configurationPackage.Path -StagingFolder $stagingFolder.FullName
        }


        @{
            ConfigurationName     = $configurationName
            ConfigurationPackage  = $configurationPackage.Path
            ConfigurationFileHash = (Get-FileHash -Path $configurationPackage.Path -Algorithm SHA256).Hash
        }
    }
    
    end {
        if ($PSCmdlet.ParameterSetName -ne 'Debug') {
            Write-Verbose 'Cleaning up...'
            Remove-Item -Path "$pwd\$configurationName" -ErrorAction SilentlyContinue -Force -Recurse
            Remove-Item -Path "$pwd\staging" -ErrorAction SilentlyContinue -Force -Recurse
        }
    }
}