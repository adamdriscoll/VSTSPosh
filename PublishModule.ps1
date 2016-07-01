if ($env:APPVEYOR_REPO_BRANCH -eq 'master'-and $env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null) 
{
	Install-PackageProvider -Name NuGet -Force
	mkdir C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet -force
	Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkID=690216&clcid=0x409" -OutFile "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe"
	Copy-Item (Join-Path $PSScriptRoot 'nuget.exe') 'C:\Program Files\PackageManagement\ProviderAssemblies\nuget.exe'
	Publish-Module -NuGetApiKey $env:ApiKey -Path C:\VSTS -Confirm:$False -Verbose 
} 