function Compress-ConfigurationFileSizeOnDisk {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]
    $ExtractedConfigurationPackageFolder
  )
  
  begin {
    Write-Verbose 'Compress-ConfigurationFileSizeOnDisk started'
    Write-Verbose "Running with parameter set: $($PSCmdlet.ParameterSetName)"
    Write-Verbose "Received parameters: $($PSBoundParameters| ConvertTo-Json -Depth 10)"

    Write-Warning "Reducing the configuration file size works by removing duplicate files from the configuration's included PowerShell module dependencies. This will break support for having multiple versions of the same module in the configuration package. This is an experimental feature and may not work as expected."
    $versionRegex = '^\d+(\.\d+)*$'
    $modulesFolder = Join-Path -Path $ExtractedConfigurationPackageFolder -ChildPath 'Modules'
  }
  
  process {
    $folders = Get-ChildItem -Path $modulesFolder -Directory -Recurse -Depth 1 | Where-Object { $_.Name -match $versionRegex }
    foreach ($folder in $folders) {
      Write-Verbose "Removing folder: $($folder.FullName)"
      Remove-Item -Path $folder.FullName -Recurse -Force
    }
  }
  
  end {
    
  }
}