$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module -Name (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe 'Work items' -Tags 'Integration' {
	BeforeAll {
		$projectName = New-ProjectName
		$session = New-VSTSSession -AccountName $account -User $userName -Token $token
		New-VSTSProject -Session $session -Name $projectName -Wait
	}

	Context "Work item doesn't exist" {
		It 'Should create a new work item' {
			{ $script:workItem = New-VstsWorkItem `
				-Session $session `
				-WorkItemType 'Task' `
				-Project $projectName `
				-PropertyHashtable @{
					'System.Title' = 'This is a test work item'
					'System.Description' = 'Test'
				} `
				-Verbose } | Should Not Throw
			$script:workItem | Should Not BeNullOrEmpty
		}
	}

	AfterAll {
		Remove-VSTSProject -Session $session -Name $projectName -Verbose
	}
}


