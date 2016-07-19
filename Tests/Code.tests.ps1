$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe "Code" -Tags "Integration" {
	$ProjectName = New-ProjectName
	$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
	New-VSTSProject -Session $Session -Name $ProjectName -Wait

	Context "Repository doesn't exist" {
		It "Creates repository" {
			New-VSTSGitRepository -Session $Session -Project $ProjectName -RepositoryName 'TestRepo'
			$Repo = Get-VSTSGitRepository -Session $Session -Project $ProjectName | Where Name -EQ 'TestRepo' 
			$Repo | Should not be $null
		}
	}

	Remove-VSTSProject -Session $Session -Name $ProjectName
}
