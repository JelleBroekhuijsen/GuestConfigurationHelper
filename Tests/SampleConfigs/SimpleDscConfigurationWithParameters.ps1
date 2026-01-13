param (
    [Parameter(Mandatory)]
    [psobject]
    $ConfigurationData
)

Configuration SimpleDscConfigurationWithParameters {
  param()
  Import-DscResource -ModuleName 'PSDscResources'
  Script SampleFile {
    GetScript  = {
      $path = 'C:\temp\sample.txt'
      $content = if (Test-Path -Path $path) {
        Get-Content -Path $path -Raw
      }
      return @{
        Result  = $content
        Path    = $path
      }
    }
    TestScript = {
      $path = 'C:\temp\sample.txt'
      if (-not (Test-Path -Path $path)) {
        return $false
      }
      $current = Get-Content -Path $path -Raw
      return $current -eq 'test'
    }
    SetScript  = {
      $path = 'C:\temp\sample.txt'
      'test' | Set-Content -Path $path -Encoding UTF8
    }
  }
}

SimpleDscConfigurationWithParameters -ConfigurationData $ConfigurationData