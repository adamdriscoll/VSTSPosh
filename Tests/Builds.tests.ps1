$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName
{
	[Guid]::NewGuid().ToString().Replace('-', '').Substring(10)
}

Import-Module -Name (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe 'Builds' -Tags 'Integration' {
	BeforeAll {
		$Script:session = New-VSTSSession -AccountName $account -User $userName -Token $token
		$Script:projectName = New-ProjectName

		$parameterDetails = @{
			Session = $Script:session
			Name    = $Script:projectName
			Verbose = $True
		}

		New-VSTSProject @parameterDetails -Wait
	}

	Context 'Has default build queues' {
		It 'Should return default build queues' {
			{ $script:queue = Get-VstsBuildQueue -Session $Script:session } | Should Not Throw
			$script:queue | Where-Object -Property Name -EQ 'Default' | Should Not BeNullOrEmpty
			$script:queue | Where-Object -Property Name -EQ 'Hosted' | Should Not BeNullOrEmpty
			$script:queue | Where-Object -Property Name -EQ 'Hosted Linux Preview' | Should Not BeNullOrEmpty
			$script:queue | Where-Object -Property Name -EQ 'Hosted VS2017' | Should Not BeNullOrEmpty
		}
	}

	AfterAll {
		Remove-VSTSProject @parameterDetails
	}
}
