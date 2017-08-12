# PowerShell Module for Accessing the Visual Studio Team Services (VSTS) REST API

[Overview of integrating with Visual Studio Team Services](https://www.visualstudio.com/en-us/integrate/api/overview)

## Branches

Branch | Build Status | Code Coverage | Protected
--- | --- | --- | ---
master | [![Master](https://ci.appveyor.com/api/projects/status/2fc84qwbsidtgvfq/branch/master?svg=true)](https://ci.appveyor.com/project/adamdriscoll/vstsposh/branch/master) | [![codecov](https://codecov.io/gh/PlagueHO/VSTSPosh/branch/master/graph/badge.svg)](https://codecov.io/gh/PlagueHO/VSTSPosh/branch/master) | Yes
dev | [![Development](https://ci.appveyor.com/api/projects/status/2fc84qwbsidtgvfq/branch/develop?svg=true)](https://ci.appveyor.com/project/adamdriscoll/vstsposh/branch/develop) | [![codecov](https://codecov.io/gh/PlagueHO/VSTSPosh/branch/dev/graph/badge.svg)](https://codecov.io/gh/PlagueHO/VSTSPosh/branch/dev) | No

## Cmdlets

- Session
  - New-VstsSession
- Projects
  - Get-VstsProject
  - Wait-VstsProject
  - New-VstsProject
  - Remove-VstsProject
  - Get-VstsProcess
- Work
  - Get-VstsWorkItem
  - New-VstsWorkItem
  - Get-VstsWorkItemQuery
- Build
  - Get-VstsBuild
  - Get-VstsBuildDefinition
  - New-vstsBuild
  - Get-VstsBuildArtifacts
- Code
  - Policy
    - Get-VstsCodePolicyConfiguration
    - New-VstsCodePolicyConfiguration
  - Git
    - New-VstsGitRepository
    - Get-VstsGitRepository
    - Remove-VstsGitRepository
    - ConvertTo-VstsGitRepository
- Release
  - Get-VstsRelease
  - Get-VstsReleaseDefinition
  - New-VstsRelease
