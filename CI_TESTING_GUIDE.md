# CI/Release Pipeline Enhancement Testing Plan

This document outlines test scenarios for the new CI/Release pipeline enhancements.

## Overview

The CI pipeline now:
1. Detects if module-relevant files have changed
2. Validates that the module version was bumped when module files are modified
3. Only runs the release stage when module-relevant files are changed

## Test Scenarios

### Scenario 1: Module Files Changed Without Version Bump (Should Fail)

**Setup:**
- Modify a file in `/Public/` or `/Private/`
- OR modify `GuestConfigurationHelper.psm1` or `GuestConfigurationHelper.psd1`
- OR modify `README.md`
- Do NOT update the `ModuleVersion` in `GuestConfigurationHelper.psd1`

**Expected Result:**
- `Test-ModuleFilesChanged.ps1` detects module files changed: `module_files_changed=true`
- `Test-ModuleVersionBump.ps1` runs and fails with error message
- CI job fails with clear instructions to bump version
- Release stage is skipped (due to CI failure)

**Error Message Should Include:**
```
MODULE VERSION BUMP REQUIRED
==========================================
You have made changes to module-relevant files, but the module version
was not incremented. This is required to maintain version discipline.
```

### Scenario 2: Module Files Changed With Version Bump (Should Pass)

**Setup:**
- Modify a file in `/Public/` or `/Private/`
- OR modify `GuestConfigurationHelper.psm1` or `GuestConfigurationHelper.psd1`
- OR modify `README.md`
- Update the `ModuleVersion` in `GuestConfigurationHelper.psd1` (increment patch, minor, or major)

**Expected Result:**
- `Test-ModuleFilesChanged.ps1` detects module files changed: `module_files_changed=true`
- `Test-ModuleVersionBump.ps1` runs and passes
- All tests run successfully
- Release stage executes and creates a new release

**Success Message Should Include:**
```
✓ Version was incremented correctly

Details:
  Old version: X.Y.Z
  New version: X.Y.Z+1
  Change type: [Major/Minor/Patch] version bump
```

### Scenario 3: Only Non-Module Files Changed (Should Skip Release)

**Setup:**
- Modify files only in `/Tests/`
- OR modify workflow files in `.github/workflows/`
- OR modify documentation files (except README.md)
- Do NOT modify any module-relevant files

**Expected Result:**
- `Test-ModuleFilesChanged.ps1` detects no module files changed: `module_files_changed=false`
- `Test-ModuleVersionBump.ps1` skips validation (not required)
- All tests run successfully
- Release stage is **skipped** (conditional check fails)

**Output Should Include:**
```
✓ No module-relevant files changed
✓ Module files unchanged - version bump not required
```

### Scenario 4: Mixed Changes (Module + Non-Module Files) (Requires Version Bump)

**Setup:**
- Modify files in `/Tests/` AND `/Public/`
- Update the `ModuleVersion` in `GuestConfigurationHelper.psd1`

**Expected Result:**
- `Test-ModuleFilesChanged.ps1` detects module files changed: `module_files_changed=true`
- `Test-ModuleVersionBump.ps1` runs and passes
- All tests run successfully
- Release stage executes

### Scenario 5: README.md Only Changed (Requires Version Bump)

**Setup:**
- Modify only `README.md` (case-insensitive match)
- Update the `ModuleVersion` in `GuestConfigurationHelper.psd1`

**Expected Result:**
- `Test-ModuleFilesChanged.ps1` detects README.md as module file: `module_files_changed=true`
- `Test-ModuleVersionBump.ps1` runs and passes
- Release stage executes

## Module-Relevant Files (Reference)

The following files are considered module-relevant and trigger version bump requirement:
- `*.psm1` - PowerShell module files
- `*.psd1` - PowerShell manifest files
- `README.md` - Module documentation (case-insensitive)
- `Private/*` - All files in Private directory
- `Public/*` - All files in Public directory

## Non-Module Files (Reference)

Examples of files that do NOT require version bump:
- `Tests/*` - Test files
- `.github/workflows/*` - Workflow files
- `CONTRIBUTING.md` - Contributor documentation
- `LICENSE.md` - License file
- `.gitignore` - Git configuration
- `CLAUDE.md` - AI assistant documentation

## Manual Testing Commands

### Test Module File Detection
```powershell
cd /path/to/repo
$env:GITHUB_OUTPUT = "output.txt"
$env:GITHUB_WORKSPACE = (Get-Location).Path
./.github/workflows/scripts/Test-ModuleFilesChanged.ps1
Get-Content output.txt
```

### Test Version Bump Validation (No Changes)
```powershell
./.github/workflows/scripts/Test-ModuleVersionBump.ps1 -ModuleFilesChanged "false"
```

### Test Version Bump Validation (With Changes)
```powershell
./.github/workflows/scripts/Test-ModuleVersionBump.ps1 -ModuleFilesChanged "true"
```

## CI Integration

The workflow now includes these steps in the `test-and-analyze` job:

```yaml
- name: Check for module file changes
  id: check-module-files
  shell: pwsh
  run: ./.github/workflows/scripts/Test-ModuleFilesChanged.ps1

- name: Validate module version bump
  if: steps.check-module-files.outputs.module_files_changed == 'true'
  shell: pwsh
  run: |
    ./.github/workflows/scripts/Test-ModuleVersionBump.ps1 `
      -ModuleFilesChanged "${{ steps.check-module-files.outputs.module_files_changed }}"
```

The release job includes conditional execution:

```yaml
create-release:
  needs: test-and-analyze
  if: github.event_name == 'push' && github.ref == 'refs/heads/main' && needs.test-and-analyze.outputs.module_files_changed == 'true'
```
