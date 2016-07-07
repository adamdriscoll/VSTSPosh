$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

Describe "New-VSTSProject" -Tags Integration {
	Context "Project doesn't exist" {
		It "Creates new project" {
			$ProjectName = New-ProjectName
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
			Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName
		}

		It "Creates new project with session" {
			$ProjectName = New-ProjectName
			$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
			New-VSTSProject -Session $Session -Name $ProjectName -Wait
			Remove-VSTSProject -Session $Session -Name $ProjectName
		}
	}
}

Describe "Get-VSTSProject" -Tags "Integration" {
	$ProjectName = New-ProjectName

	Context "Project exists" {
		It "Gets project by name" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
			Get-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName | Should not be $null
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName
}

Describe "New-VSTSGitRepository" -Tags "Integration" {
	$ProjectName = New-ProjectName
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

	Remove-VSTSProject -Session $Session -Name $ProjectName
}

Describe "Work items" -Tags "Integration" {
	$ProjectName = New-ProjectName
	$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
	New-VSTSProject -Session $Session -Name $ProjectName -Wait

	Context "Work item doesn't exist" {
		It "Creates new work item" {
			
			$WI = New-VstsWorkItem -Session $Session -WorkItemType 'Task' -Project $ProjectName -PropertyHashtable @{ 'System.Title' = 'This is a test work item'; 'System.Description' = 'Test'}
			$WI | Should not be $null
		}
	}

	Remove-VSTSProject -Session $Session -Name $ProjectName
}