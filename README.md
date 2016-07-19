# PowerShell Module for Accessing the Visual Studio Team Services (VSTS) REST API

https://www.visualstudio.com/en-us/integrate/api/overview

## Build Status

- Master: [![Master](https://ci.appveyor.com/api/projects/status/2fc84qwbsidtgvfq/branch/master?svg=true)](https://ci.appveyor.com/project/adamdriscoll/vstsposh/branch/master)
- Development: [![Development](https://ci.appveyor.com/api/projects/status/2fc84qwbsidtgvfq/branch/develop?svg=true)](https://ci.appveyor.com/project/adamdriscoll/vstsposh/branch/develop)

## Cmdlets

- Projects
	- Get-VstsProject
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
- Code	
	- Policy
		- Get-VstsCodePolicy
		- New-VstsCodePolicy
	- Git
		- New-VstsGitRepository
		- Get-VstsGitRepository