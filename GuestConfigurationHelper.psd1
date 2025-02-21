@{

  # Script module or binary module file associated with this manifest.
  RootModule           = 'GuestConfigurationHelper.psm1'

  # Version number of this module.
  ModuleVersion        = '1.3.7'

  # Supported PSEditions
  CompatiblePSEditions = @('Core')

  # Minimum version of the PowerShell engine required by this module
  PowerShellVersion = '7.0'

  # ID used to uniquely identify this module
  GUID                 = 'f26b9f8d-cd7a-4453-a3a7-ff6758614663'

  # Author of this module
  Author               = 'Jelle Broekhuijsen (consultancy@jll.io)'

  # Company or vendor of this module
  CompanyName          = 'jll.io Consultancy'

  # Copyright statement for this module
  Copyright            = '(c) Jelle Broekhuijsen - MIT License'

  # Description of the functionality provided by this module
  Description          = 'A module to support development and publication of Azure Guest Configuration'

  # Modules that must be imported into the global environment prior to importing this module
  RequiredModules      = @(
    'PSDesiredStateConfiguration',
    'PSDscResources',
    'GuestConfiguration'
  )

  # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
  # FunctionsToExport    = @()

  # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
  CmdletsToExport      = @()

  # Variables to export from this module
  VariablesToExport    = @()

  # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
  AliasesToExport      = @()


  # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
  PrivateData          = @{

    PSData = @{

      # A URL to the license for this module.
      LicenseUri = 'https://github.com/JelleBroekhuijsen/GuestConfigurationHelper/LICENSE.md'

      # A URL to the main website for this project.
      ProjectUri = 'https://github.com/JelleBroekhuijsen/GuestConfigurationHelper'

    } # End of PSData hashtable

  } # End of PrivateData hashtable
}

