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
		Write-Verbose -Verbose -Message ('Creating VSTS test project {0}' -f $projectName)
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
			$script:workItem.Fields.'System.Title' | Should Be 'This is a test work item'
			$script:workItem.Fields.'System.Description' | Should Be 'Test'
		}
	}

	AfterAll {
		Write-Verbose -Verbose -Message ('Deleting VSTS test project {0}' -f $projectName)
		Remove-VSTSProject -Session $session -Name $projectName
	}
}


