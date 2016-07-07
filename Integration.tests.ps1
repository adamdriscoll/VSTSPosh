

Describe "New-VSTSProject" -Tags Integration {
	$userName = $env:VSTSPoshUserName
	$token = $env:VSTSPoshToken
	$account = $env:VSTSPoshAccount 

	Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

	Context "Project doesn't exist" {
		It "Creates new project" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
}

Describe "Get-VSTSProject" -Tags "Integration" {
	$userName = $env:VSTSPoshUserName
	$token = $env:VSTSPoshToken
	$account = $env:VSTSPoshAccount 

	Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

	Context "Project exists" {
		It "Gets project by name" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
			Get-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' | Should not be $null
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
}