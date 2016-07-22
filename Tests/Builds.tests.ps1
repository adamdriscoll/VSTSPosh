$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe "Builds" -Tags "Integration" {
	$ProjectName = New-ProjectName
	$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
	New-VSTSProject -Session $Session -Name $ProjectName -Wait

	Context "Has default build queues" {
		It "It returns default build queues" {
			$Queue = Get-VstsBuildQueue -Session $Session | Where Name -EQ 'Hosted'
			$Queue | Should not be $null
			
			$Queue = Get-VstsBuildQueue -Session $Session | Where Name -EQ 'Default'
			$Queue | Should not be $null
		}
	}
	<#
	Context "Has no build definitions" {
		It "Creates new build definition" {
			$Repository = New-VstsGitRepository -Session $Session -RepositoryName 'TestRepo' -Project $ProjectName
			New-VstsBuildDefinition -Session $Session -Project $ProjectName -Name 'Definition' -Queue Hosted -Repository $Repository
			$Definition = Get-VstsBuildDefinition -Session $Session -Project $ProjectName | Where Name -EQ 'Definition'
			$Definition | Should not be $null
		}
	}
	#>

	Remove-VSTSProject -Session $Session -Name $ProjectName
}