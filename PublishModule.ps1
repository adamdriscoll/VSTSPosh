Install-PackageProvider -Name NuGet -Force 
if ($env:APPVEYOR_REPO_BRANCH -eq 'master'-and $env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null) 
{
	Publish-Module -NuGetApiKey $env:ApiKey -Path C:\VSTS -Confirm:$False -ProjectUri https://github.com/adamdriscoll/vstsposh -Tags @('VSTS')
} 