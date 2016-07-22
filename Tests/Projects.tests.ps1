$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe "Projects" -Tags Integration {
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

		It "Create new project with specified template name" {
			$ProjectName = New-ProjectName
			$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
			New-VSTSProject -Session $Session -Name $ProjectName -Wait -TemplateTypeName 'Scrum'
			Get-VSTSProject -Session $Session -Name $ProjectName | Should not be $null
			Remove-VSTSProject -Session $Session -Name $ProjectName
		}
	}

	Context "Process" {
		It "Returns default process template" {
			$Session = New-VstsSession -AccountName $account -User $userName -Token $token

			$Process = Get-VstsProcess -Session $Session | Where Name -EQ 'Agile'
			$Process | Should not be $null
			
			$Process = Get-VstsProcess -Session $Session | Where Name -EQ 'CMMI'
			$Process | Should not be $null

			$Process = Get-VstsProcess -Session $Session | Where Name -EQ 'SCRUM'
			$Process | Should not be $null
		}
	}
}