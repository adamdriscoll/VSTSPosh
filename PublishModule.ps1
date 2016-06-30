if ($env:APPVEYOR_REPO_BRANCH -eq 'master'-and $env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null) 
{
	Start-FileDownload 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -FileName 'C:\Program Files\PackageManagement\ProviderAssemblies\nuget.exe'
	Install-PackageProvider -Name NuGet -Force
	Start-Sleep 2
	Publish-Module -NuGetApiKey $env:ApiKey -Path C:\VSTS -Confirm:$False -Verbose 
} 