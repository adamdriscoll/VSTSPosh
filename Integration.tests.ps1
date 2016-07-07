$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 

Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

Describe "New-VSTSProject" -Tags Integration {
	Context "Project doesn't exist" {
		It "Creates new project" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
}

Describe "Get-VSTSProject" -Tags "Integration" {
	Context "Project exists" {
		It "Gets project by name" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
			Get-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' | Should not be $null
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
}

Describe "New-VSTSGitRepository" -Tags "Integration" {
	Context "Repository doesn't exist" {
		It "Creates repository" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
			$Project = Get-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'
			New-VSTSGitRepository -AccountName $Account -User $userName -Token $token -ProjectId $Project.ID -RepositoryName 'TestRepo'
			$Repo = Get-VSTSGitRepository -AccountName $Account -User $userName -Token $token -Project 'IntegrationTestProject' | Where Name -EQ 'TestRepo' 
			$Repo | Should not be $null
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' -Wait
}