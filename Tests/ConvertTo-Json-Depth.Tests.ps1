BeforeAll {
    . $PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1
    . $PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1
    . $PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1
}

Describe 'ConvertTo-Json Depth parameter verification' {
    Context 'Verifying that ConvertTo-Json uses adequate depth' {
        It 'should use depth parameter in Publish-GuestConfigurationPackage' {
            $functionContent = Get-Content -Path "$PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1" -Raw
            $functionContent | Should -Match 'ConvertTo-Json.*-Depth\s+\d+'
        }
        
        It 'should use depth parameter in Test-ConfigurationFileSizeOnDisk' {
            $functionContent = Get-Content -Path "$PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1" -Raw
            $functionContent | Should -Match 'ConvertTo-Json.*-Depth\s+\d+'
        }
        
        It 'should use depth parameter in Compress-ConfigurationFileSizeOnDisk' {
            $functionContent = Get-Content -Path "$PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1" -Raw
            $functionContent | Should -Match 'ConvertTo-Json.*-Depth\s+\d+'
        }
        
        It 'should not produce truncation warnings for deeply nested objects' {
            # Create a deeply nested structure similar to the issue
            $deeplyNestedParams = @{
                ConfigurationData = @{
                    NonNodeData = @{
                        sentinelTenants = @(
                            @{
                                connectWiseCompanyId = 'TST001'
                                ensure = 'Present'
                                azureTenantId = 'infrastructure@newemail.co.za'
                                azureKeyVaultName = 'kvsenprdzanfilm01'
                                secretNamePrefix = 'tst-dev'
                            },
                            @{
                                connectWiseCompanyId = 'ACU004'
                                ensure = 'Present'
                                azureTenantId = 'acumentgroupsa.onmicrosoft.com'
                                azureKeyVaultName = 'kvsenprdzanfilm01'
                                secretNamePrefix = 'acu-prd'
                            }
                        )
                        AllNodes = @()
                    }
                }
            }
            
            # Capture warnings when converting with depth 10
            $warnings = @()
            $json = $deeplyNestedParams | ConvertTo-Json -Depth 10 -WarningVariable warnings -WarningAction SilentlyContinue
            
            # Verify no truncation warnings
            $warnings | Where-Object { $_ -match 'truncated as serialization has exceeded the set depth' } | Should -BeNullOrEmpty
            
            # Verify the structure is preserved (not converted to string representation)
            $json | Should -Not -Match '@\\{sentinelTenants=System\\.Object\\[\\]\\}'
            $json | Should -Match 'connectWiseCompanyId'
        }
        
        It 'should produce truncation warnings with default depth (demonstrating the problem)' {
            # Create the same deeply nested structure
            $deeplyNestedParams = @{
                ConfigurationData = @{
                    NonNodeData = @{
                        sentinelTenants = @(
                            @{
                                connectWiseCompanyId = 'TST001'
                                ensure = 'Present'
                                azureTenantId = 'infrastructure@newemail.co.za'
                                azureKeyVaultName = 'kvsenprdzanfilm01'
                                secretNamePrefix = 'tst-dev'
                            }
                        )
                    }
                }
            }
            
            # Capture warnings when converting with depth 2 (default)
            $warnings = @()
            $json = $deeplyNestedParams | ConvertTo-Json -Depth 2 -WarningVariable warnings -WarningAction SilentlyContinue
            
            # Verify truncation warnings appear with shallow depth
            $warnings | Where-Object { $_ -match 'truncated as serialization has exceeded the set depth' } | Should -Not -BeNullOrEmpty
        }
    }
}
