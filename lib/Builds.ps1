<#
	.SYNOPSIS
	Gets team project builds.

	.DESCRIPTION
	This cmdlet will return a list of builds
	or a single build if Id is specified.

	It can also be provided with additional query parmeters
	to allow additional filters to be applied.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the builds from.
#>
function Get-VstsBuild
{
	[CmdletBinding(DefaultParameterSetName = 'Account')]
	param
	(
		[Parameter(Mandatory = $True, ParameterSetName = 'Account')]
		[String] $AccountName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $User,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $Token,

		[Parameter(Mandatory = $True, ParameterSetName = 'Session')]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Project,

		[Parameter(ParameterSetName = 'Id')]
		[Int32] $Id,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Definitions,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Queues,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = 'build/builds'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters    = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'definitions', 'queues'
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'top'
		}
	}
	else
	{
		if ($PSBoundParameters.ContainsKey('Id'))
		{
			$path = ('{0}/{1}' -f $path, $Id)
		}
	}

	$Result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path `
		-ApiVersion '2.0' `
		@additionalInvokeParameters

	return $Result.Value
}

<#
	.SYNOPSIS
	Gets a team project build definitions.

	.DESCRIPTION
	This cmdlet will return a list of build definitions
	or a single build definition if Id or Name is specified.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to create the new release in.

	.PARAMETER Id
	The id of the Build Definition to return.

	.PARAMETER Name
	The Name of the Build Definition to return.

	.PARAMETER Top
	The maximum number of Build Definitions to return.

	.EXAMPLE
	Get-VstsBuildDefinition `
		-Session $vstsSession `
		-Project 'FabrikamFiber'

	Return all build definitions in the project FabrikamFiber.

	.EXAMPLE
	Get-VstsBuildDefinition `
		-Session $vstsSession `
		-Project 'FabrikamFiber' `
		-Name 'Main-CI'

	Returns the build definition with the name 'Main-CI'

	.EXAMPLE
	Get-VstsBuildDefinition `
		-Session $vstsSession `
		-Project 'FabrikamFiber' `
		-Id 203

	Returns the build definition with the Id 203.
#>
function Get-VstsBuildDefinition
{
	[CmdletBinding(DefaultParameterSetName = 'Account')]
	param
	(
		[Parameter(Mandatory = $True, ParameterSetName = 'Account')]
		[String] $AccountName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $User,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $Token,

		[Parameter(Mandatory = $True, ParameterSetName = 'Session')]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter(ParameterSetName = 'Id')]
		[Int32] $Id,

		[Parameter(ParameterSetName = 'Query')]
		[String] $Name,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = 'build/definitions'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters    = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'name'
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Top'
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
		-ApiVersion '2.0' `
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Gets build definitions for the specified project.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.
#>
function New-VstsBuildDefinition
{
	[CmdletBinding(DefaultParameterSetName = 'Account')]
	param
	(
		[Parameter(Mandatory = $True, ParameterSetName = 'Account')]
		[String] $AccountName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $User,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $Token,

		[Parameter(Mandatory = $True, ParameterSetName = 'Session')]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter(Mandatory = $true)]
		[String] $Name,

		[Parameter()]
		[String] $DisplayName = $Name,

		[Parameter()]
		[String] $Comment,

		[Parameter(Mandatory = $true)]
		[String] $Queue,

		[Parameter(Mandatory = $true)]
		[PSCustomObject] $Repository
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = 'build/definitions'

	if (-not (Test-Guid -Input $Queue))
	{
		$Queue = (Get-VstsBuildQueue -Session $Session | Where-Object -Property Name -EQ $Queue).Id
	}

	$body = @{
		name         = $Name
		type         = "build"
		quality      = "definition"
		queue        = @{
			id = $Queue
		}
		build        = @(
			@{
				enabled         = $true
				continueOnError = $false
				alwaysRun       = $false
				displayName     = $DisplayName
				task            = @{
					id          = "71a9a2d3-a98a-4caa-96ab-affca411ecda"
					versionSpec = "*"
				}
				inputs          = @{
					"solution"              = "**\\*.sln"
					"msbuildArgs"           = ""
					"platform"              = '$(platform)'
					"configuration"         = '$(config)'
					"clean"                 = "false"
					"restoreNugetPackages"  = "true"
					"vsLocationMethod"      = "version"
					"vsVersion"             = "latest"
					"vsLocation"            = ""
					"msbuildLocationMethod" = "version"
					"msbuildVersion"        = "latest"
					"msbuildArchitecture"   = "x86"
					"msbuildLocation"       = ""
					"logProjectEvents"      = "true"
				}
			},
			@{
				"enabled"         = $true
				"continueOnError" = $false
				"alwaysRun"       = $false
				"displayName"     = "Test Assemblies **\\*test*.dll;-:**\\obj\\**"
				"task"            = @{
					"id"          = "ef087383-ee5e-42c7-9a53-ab56c98420f9"
					"versionSpec" = "*"
				}
				"inputs"          = @{
					"testAssembly"             = "**\\*test*.dll;-:**\\obj\\**"
					"testFiltercriteria"       = ""
					"runSettingsFile"          = ""
					"codeCoverageEnabled"      = "true"
					"otherConsoleOptions"      = ""
					"vsTestVersion"            = "14.0"
					"pathtoCustomTestAdapters" = ""
				}
			}
		)
		"repository" = @{
			"id"            = $Repository.Id
			"type"          = "tfsgit"
			"name"          = $Repository.Name
			"localPath"     = "`$(sys.sourceFolder)/$($Repository.Name)"
			"defaultBranch" = "refs/heads/master"
			"url"           = $Repository.Url
			"clean"         = "false"
		}
		"options"    = @(
			@{
				"enabled"    = $true
				"definition" = @{
					"id" = "7c555368-ca64-4199-add6-9ebaf0b0137d"
				}
				"inputs"     = @{
					"parallel"    = "false"
					"multipliers" = @("config", "platform")
				}
			}
		)
		"variables"  = @{
			"forceClean" = @{
				"value"         = "false"
				"allowOverride" = $true
			}
			"config"     = @{
				"value"         = "debug, release"
				"allowOverride" = $true
			}
			"platform"   = @{
				"value"         = "any cpu"
				"allowOverride" = $true
			}
		}
		"triggers"   = @()
		"comment"    = $Comment
	} | ConvertTo-Json -Depth 20

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path `
		-ApiVersion 2.0 `
		-Method 'POST' `
		-Body $body

	return $result.Value
}

<#
	.SYNOPSIS
	Gets team project build artifacts.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the build artifacts from.

	.PARAMETER BuildId
	The BuildId of the artifacts to return.
#>
function Get-VstsBuildArtifact
{
	[CmdletBinding(DefaultParameterSetName = 'Account')]
	param
	(
		[Parameter(Mandatory = $True, ParameterSetName = 'Account')]
		[String] $AccountName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $User,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $Token,

		[Parameter(Mandatory = $True, ParameterSetName = 'Session')]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter(Mandatory = $true)]
		[Int32] $BuildId
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = ('build/builds/{0}/artifacts' -f $BuildId)

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path `
		-ApiVersion '2.0'

	return $result.Value
}

<#
	.SYNOPSIS
	Gets build queues for the collection.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Id
	The Id of the Build Queue to retrieve.

	.PARAMETER Name
	The Name of the Build Queue to retrieve.
#>
function Get-VstsBuildQueue
{
	[CmdletBinding(DefaultParameterSetName = 'Account')]
	param
	(
		[Parameter(Mandatory = $True, ParameterSetName = 'Account')]
		[String] $AccountName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $User,

		[Parameter(Mandatory = $true, ParameterSetName = 'Account')]
		[String] $Token,

		[Parameter(Mandatory = $True, ParameterSetName = 'Session')]
		$Session,

		[Parameter()]
		[Int32] $Id,

		[Parameter()]
		[String] $Name
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$Path = 'build/queues'
	$additionalInvokeParameters = @{}

	if ($PSBoundParameters.ContainsKey('Id'))
	{
		$Path = ('{0}/{1}' -f $Path, $Id)
	}
	else
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'name'
		}
	}

	$Result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $Path `
		-ApiVersion '2.0' `
		@additionalInvokeParameters

	return $Result.Value
}
