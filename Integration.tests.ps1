$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 
$ProjectName = [Guid]::NewGuid().ToString().Replace('-','')

Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

Describe "New-VSTSProject" -Tags Integration {
	Context "Project doesn't exist" {
		It "Creates new project" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
			Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
		}

		It "Creates new project with session" {
			$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
			New-VSTSProject -Session $Session -Name $ProjectName -Wait
			Remove-VSTSProject -Session $Session -Name $ProjectName -Wait
		}
	}
}

Describe "Get-VSTSProject" -Tags "Integration" {
	Context "Project exists" {
		It "Gets project by name" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
			Get-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName | Should not be $null
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
}

Describe "New-VSTSGitRepository" -Tags "Integration" {
	$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
	New-VSTSProject -Session $Session -Name $ProjectName -Wait

	Context "Repository doesn't exist" {
		It "Creates repository" {
			
			$Project = Get-VSTSProject -Session $Session -Name $ProjectName
			New-VSTSGitRepository -Session $Session -ProjectId $Project.ID -RepositoryName 'TestRepo'
			$Repo = Get-VSTSGitRepository -Session $Session -Project $ProjectName | Where Name -EQ 'TestRepo' 
			$Repo | Should not be $null
		}
	}

	Remove-VSTSProject -Session $Session -Name $ProjectName -Wait
}