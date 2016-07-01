if ($env:APPVEYOR_REPO_BRANCH -eq 'master'-and $env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null) 
{
	Copy-Item (Join-Path $PSScriptRoot 'nuget.exe') 'C:\Program Files\PackageManagement\ProviderAssemblies\nuget.exe'
	Install-PackageProvider -Name NuGet -Force
	Publish-Module -NuGetApiKey $env:ApiKey -Path C:\VSTS -Confirm:$False -Verbose 
} 