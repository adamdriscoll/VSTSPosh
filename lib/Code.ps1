<#
	.SYNOPSIS
	Gets Git repositories in the specified team project.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the repositories from.

	.PARAMETER Repository
	The id or name of the repository.

	.EXAMPLE
	>
	$vstsSession = New-VSTSSession `
		-AccountName 'myvstsaccount' `
		-User 'joe.bloggs@fabrikam.com' `
		-Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

	Get-VstsGitRepository `
		-Session $session `
		-Project 'FabrikamFiber'

	Get a list of Git repositories in the FabrikamFiber project.

	.EXAMPLE
	>
	$vstsSession = New-VSTSSession `
		-AccountName 'myvstsaccount' `
		-User 'joe.bloggs@fabrikam.com' `
		-Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

	Get-VstsGitRepository `
		-Session $session `
		-Project 'FabrikamFiber' `
		-Repository 'PortalApp'

	Get a the PortalApp repository in the FabrikamFiber project.
#>
function Get-VstsGitRepository
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter()]
		[String] $Repository
	)

	$path = 'git/repositories'

	if ($PSBoundParameters.ContainsKey('Repository'))
	{
		$path = ('{0}/{1}' -f $path, $Repository)
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path

	return $result.Value
}

<#
	.SYNOPSIS
	Creates a new Git repository in the specified team project.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the repositories from.

	.PARAMETER RepositoryName
	The name of the repository to create.

	.EXAMPLE
	>
	$vstsSession = New-VSTSSession `
		-AccountName 'myvstsaccount' `
		-User 'joe.bloggs@fabrikam.com' `
		-Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

	New-VstsGitRepository `
		-Session $session `
		-Project 'FabrikamFiber' `
		-RepositoryName 'PortalApp'

	Create a repository in the FabrikamFiber project called PortalApp.
#>
function New-VstsGitRepository
{
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		$Project,

		[Parameter(Mandatory = $True)]
		$RepositoryName
	)

	$path = 'git/repositories'

	if (-not (Test-Guid -Input $Project))
	{
		$projectId = (Get-VstsProject -Session $Session -Name $Project).Id
	}

	$body = @{
		Name    = $RepositoryName
		Project = @{
			Id = $projectId
		}
	} | ConvertTo-Json

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		-Method 'POST' `
		-Body $body `
		-ErrorAction Stop

	return $result.Value
}

<#
	.SYNOPSIS
	Get code policy configurations for the specified project.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the policy configuration from.

	.PARAMETER Id
	The Id of the policy configuration to return.

	.PARAMETER Top
	Restrict the number of policy configurations to be returned.

	.PARAMETER Skip
	Do not return the first 'skip' number of policy configurations.
#>
function Get-VstsCodePolicyConfiguration
{
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter(ParameterSetName = 'Id')]
		[String] $Id,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Skip

	)

	$path = 'policy/configurations'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Top', 'Skip'
		}
	}
	else
	{
		if ($PSBoundParameters.ContainsKey('Id'))
		{
			$path = ('{0}/{1}' -f $path, $Id)
		}
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path `
		-ApiVersion '2.0-preview.1' `
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Creates a new Code Policy Configuration for the specified project.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to create the Code Policy Configuration in.

	.PARAMETER RepositoryId
	The repository Id to create the new Code Policy Configuration on.

	.PARAMETER MinimumReviewers
	The minimum number of reviewers.

	.PARAMETER Branches
	The branches to apply the Code Policy Configuration to.
#>
function New-VstsCodePolicyConfiguration
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Project,

		[Parameter()]
		[Guid] $RepositoryId = [Guid]::Empty,

		[Parameter()]
		[Int] $MinimumReviewers = 1,

		[Parameter(Mandatory = $True)]
		[String[]] $Branches
	)

	$path = 'policy/configurations'

	$repoId = $null
	if ($RepositoryId -ne [Guid]::Empty)
	{
		$repoId = $RepositoryId.ToString()
	}

	$scopes = foreach ($branch in $Branches)
	{
		@{
			repositoryId = $RepoId
			refName      = "refs/heads/$branch"
			matchKind    = "exact"
		}
	}

	$policy = @{
		isEnabled  = $true
		isBlocking = $false
		type       = @{
			id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
		}
		settings   = @{
			minimumApproverCount = $MinimumReviewers
			creatorVoteCounts    = $false
			scope                = @($scopes)
		}
	} | ConvertTo-Json -Depth 10

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path `
		-ApiVersion '2.0-preview.1' `
		-Body $policy `
		-Method 'POST' `
		-ErrorAction Stop

	return $result.Value
}

<#
	.SYNOPSIS
	Converts a TFVC repository to a VSTS Git repository.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The session object created by New-VstsSession.

	.PARAMETER TargetName
	The name of the VSTS Re

	.PARAMETER SourceFolder
	The session object created by New-VstsSession.
#>
function ConvertTo-VstsGitRepository
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		$Project,

		[Parameter(Mandatory = $True)]
		$TargetName,

		[Parameter(Mandatory = $True)]
		$SourceFolder
	)

	$gitCommand = Get-Command git
	if ($null -eq $gitCommand -or $gitCommand.CommandType -ne 'Application' -or $gitCommand.Name -ne 'git.exe')
	{
		throw "Git-tfs needs to be installed to use this command. See https://github.com/git-tfs/git-tfs. You can install with Chocolatey: cinst gittfs"
	}

	$gitTfsCommand = Get-Command git-tfs
	if ($null -eq $gitTfsCommand -or $gitTfsCommand.CommandType -ne 'Application' -or $gitTfsCommand.Name -ne 'git-tfs.exe')
	{
		throw "Git-tfs needs to be installed to use this command. See https://github.com/git-tfs/git-tfs. You can install with Chocolatey: cinst gittfs"
	}

	git tfs clone "https://$($Session.AccountName).visualstudio.com/defaultcollection" "$/$Project/$SourceFolder" --branches=none

	Push-Location -Path (Split-Path -Path $SourceFolder -Leaf)

	$null = New-VstsGitRepository -Session $Session -RepositoryName $TargetName -Project $Project

	git checkout -b develop
	git remote add origin https://$($Session.AccountName).visualstudio.com/DefaultCollection/$Project/_git/$TargetName
	git push --all origin
	git tfs cleanup

	Pop-Location
	Remove-Item -Path (Split-Path -Path $SourceFolder -Leaf) -Force
}
