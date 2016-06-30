$FunctionsToExport = @(
'Get-VstsProject',
'New-VstsProject',
'Remove-VstsProject',
'Get-VstsWorkItem',
'New-VstsWorkItem',
'Get-VstsWorkItemQuery',
'Get-VstsCodePolicy',
'New-VstsCodePolicy',
'New-VstsGitRepository',
'Get-VstsGitRepository')

$NewModuleManifestParams = @{
	ModuleVersion = '1.0.46' #$ENV:APPVEYOR_BUILD_VERSION
	Path = (Join-Path $PSScriptRoot '.\VSTS.psd1')
	Author = 'Adam Driscoll'
	Company = 'Concurrency, Inc'
	Description = 'Visual Studio Team Services PowerShell Integration'
	RootModule = (Join-Path $PSScriptRoot '.\VSTS.psm1')
	FunctionsToExport = $FunctionsToExport
	ProjectUri = 'https://github.com/adamdriscoll/vstsposh'
	Tags = @('VSTS')
}

New-ModuleManifest @NewModuleManifestParams