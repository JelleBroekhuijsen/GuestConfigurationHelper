# Mock-friendly configuration for unit tests where cmdlets are mocked
# This version does nothing when invoked, allowing mocks to control test flow

# The line below allows regex detection (pattern: ^\s*Configuration\s+(\w+)) to work
$null = @'
Configuration SimpleDscConfiguration
'@

# This function does nothing - it's just a placeholder that allows the
# Publish-GuestConfigurationPackage function to call it without errors
# when file system operations are mocked
function SimpleDscConfiguration {
    param()
    # Intentionally empty - all operations are mocked in tests
}
