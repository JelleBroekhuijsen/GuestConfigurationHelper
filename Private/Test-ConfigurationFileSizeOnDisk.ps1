function Test-ConfigurationFileSizeOnDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        $ConfigurationPackage,

        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $StagingFolder = $pwd.Path,

        [Parameter()]
        [Switch]
        $CompressConfiguration
    )

    begin {
        Write-Verbose 'Test-ConfigurationFileSizeOnDisk started'
        Write-Verbose "Running with parameter set: $($PSCmdlet.ParameterSetName)"
        Write-Verbose "Received parameters: $($PSBoundParameters| ConvertTo-Json)"
    }

    process {
        $configurationPackageFile = Get-Item -Path $ConfigurationPackage
        $unzipFolder = New-Item -Path $StagingFolder -Name $configurationPackageFile.BaseName -ItemType Directory -ErrorAction Stop
        
        Write-Verbose "Expanding configuration package: $($configurationPackageFile.FullName) to staging folder: $($stagingFolder.FullName)"
        Expand-Archive -Path $configurationPackageFile.FullName -DestinationPath $unzipFolder.FullName -Force

        if($CompressConfiguration) {
            Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder $unzipFolder.FullName
        }

        $fileSize = Get-ChildItem -Path $unzipFolder.FullName -Recurse | Measure-Object -Property Length -Sum

        if($fileSize.Sum -gt 100MB) {
            Write-Warning "The extracted configuration package is too large. The maximum supported size for Azure Guest Configuration is 100MB. The current size is $([Math]::Round(($fileSize.Sum / 1024 / 1024),2,[System.MidpointRounding]::AwayFromZero)) MB."
            return $false
        }
        $true   
    }

    end {
    }
}