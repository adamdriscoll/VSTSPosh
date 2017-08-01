$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module -Name (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe 'Code' -Tags 'Integration' {
	$testRepoName = 'TestRepo'

	BeforeAll {
		$projectName = New-ProjectName
		$session = New-VSTSSession -AccountName $account -User $userName -Token $token
		Write-Verbose -Verbose -Message ('Creating VSTS test project {0}' -f $projectName)
		New-VSTSProject -Session $session -Name $projectName -Wait
	}

	Context 'Create a repository, get the repository and remove the repository' {
		It 'Should create repository' {
			{ $script:newRepo = New-VSTSGitRepository `
				-Session $session `
				-Project $projectName `
				-RepositoryName $testRepoName `
				-Verbose } | Should Not Throw
			$script:newRepo.Name | Should Be $testRepoName
		}

		It 'Should get the repository' {
			{ $script:existingRepo = Get-VSTSGitRepository `
				-Session $session `
				-Project $projectName `
				-Repository $testRepoName `
				-Verbose } | Should Not Throw
			$script:existingRepo.Name | Should Be $testRepoName
		}

		It 'Should delete the repository' {
			{ Remove-VSTSGitRepository `
				-Session $session `
				-Project $projectName `
				-Repository $testRepoName `
				-Verbose } | Should Not Throw
			{ $script:existingRepo = Get-VSTSGitRepository `
				-Session $session `
				-Project $projectName `
				-Repository $testRepoName `
				-Verbose } | Should Throw
		}
	}

	AfterAll {
		Write-Verbose -Verbose -Message ('Deleting VSTS test project {0}' -f $projectName)
		Remove-VSTSProject -Session $session -Name $projectName
	}
}
