function Wait-VSTSProject {
	param($AccountName, $UserName, $Token, $Name, $Attempts = 3)

	$Retries = 0
	do {
		#Takes a few seconds for the project to be created
		Start-Sleep -Seconds 10

		$TeamProject = Get-VSTSProject -AccountName $AccountName -User $userName -Token $token -Name $Name

		$Retries++
	} while ($TeamProject -eq $null -and $Retries -le 10)

	if ($TeamProject -eq $null)
	{
		throw "Failed to create team project!" 
	}
}

Describe "New-VSTSProject" -Tags Integration {
	$userName = $env:VSTSPoshUserName
	$token = $env:VSTSPoshToken
	$account = $env:VSTSPoshAccount 

	Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

	Context "Project doesn't exist" {
		It "Creates new project" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'
			Wait-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' 
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'
}

Describe "Get-VSTSProject" -Tags "Integration" {
	$userName = $env:VSTSPoshUserName
	$token = $env:VSTSPoshToken
	$account = $env:VSTSPoshAccount 

	Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

	Context "Project exists" {
		It "Gets project by name" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'
			Wait-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' 
			Get-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject' | Should not be $null
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'
}