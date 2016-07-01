$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 
Import-Module (Join-Path $PSScriptRoot 'VSTS.psm1') -Force

Describe "New-VSTSProject" -Tags Integration {
	Context "Project doesn't exist" {
		It "Creates new project" {
			New-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'

			$Retries = 0
			do {
				#Takes a few seconds for the project to be created
				Start-Sleep -Seconds 10

				$TeamProject = Get-VSTSProject -AccountName $Account -User $userName -Token $token | Where name -EQ 'IntegrationTestProject' 

				$Retries++
			} while ($TeamProject -eq $null -and $Retries -le 10)

			if ($TeamProject -eq $null)
			{
				throw "Failed to create team project!" 
			}
		}
	}

	Remove-VSTSProject -AccountName $Account -User $userName -Token $token -Name 'IntegrationTestProject'
}

Describe "Get-VstsBuildQueue" -Tags Integration {
	Context "Default queues exist" {
		It "returns default queues" {
			$DefaultQueue = Get-VstsBuildQueue -AccountName $Account -User $userName -Token $token | Where name -EQ 'Default' 
			$HostedQueue = Get-VstsBuildQueue -AccountName $Account -User $userName -Token $token | Where name -EQ 'Hosted' 

			$DefaultQueue | Should not be $null
			$HostedQueue | Should not be $null
		}
	}
}