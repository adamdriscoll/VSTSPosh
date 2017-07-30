$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe "Projects" -Tags Integration {
	Context "Project doesn't exist" {
		It "Should create new project" {
			$ProjectName = New-ProjectName
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName -Wait
			Get-VSTSProject -Session $Session -Name $ProjectName | Should Not BeNullOrEmpty
			Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name $ProjectName
		}

		It "Should create new project with session" {
			$ProjectName = New-ProjectName
			$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
			New-VSTSProject -Session $Session -Name $ProjectName -Wait
			Get-VSTSProject -Session $Session -Name $ProjectName | Should Not BeNullOrEmpty
			Remove-VSTSProject -Session $Session -Name $ProjectName
		}

		It "Should create new project with specified template name" {
			$ProjectName = New-ProjectName
			$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
			New-VSTSProject -Session $Session -Name $ProjectName -Wait -TemplateTypeName 'Scrum'
			Get-VSTSProject -Session $Session -Name $ProjectName | Should Not BeNullOrEmpty
			Remove-VSTSProject -Session $Session -Name $ProjectName
		}
	}

	Context "Process" {
		It "Should returns default process template" {
			$Session = New-VstsSession -AccountName $account -User $userName -Token $token

			$Process = Get-VstsProcess -Session $Session | Where-Object -Property Name -EQ 'Agile'
			$Process | Should Not BeNullOrEmpty

			$Process = Get-VstsProcess -Session $Session | Where-Object -Property Name -EQ 'CMMI'
			$Process | Should Not BeNullOrEmpty

			$Process = Get-VstsProcess -Session $Session | Where-Object -Property Name -EQ 'SCRUM'
			$Process | Should Not BeNullOrEmpty
		}
	}
}
