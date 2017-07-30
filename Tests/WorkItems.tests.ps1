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
		$session = New-VSTSSession -AccountName $Account -User $userName -Token $token
		New-VSTSProject -Session $Session -Name $ProjectName -Wait
	}

	Context "Work item doesn't exist" {
		It "Creates new work item" {
			$WI = New-VstsWorkItem -Session $Session -WorkItemType 'Task' -Project $ProjectName -PropertyHashtable @{
				'System.Title' = 'This is a test work item'
				'System.Description' = 'Test'
			}
			$WI | Should not be $null
		}
	}

	AfterAll {
		Remove-VSTSProject -Session $Session -Name $ProjectName
	}
}


