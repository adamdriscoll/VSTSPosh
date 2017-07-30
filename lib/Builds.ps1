<#
	.SYNOPSIS
	Gets team project builds.

	.DESCRIPTION
	This cmdlet will return a list of builds
	or a single build if Id is specified.

	It can also be provided with additional query parmeters
	to allow additional filters to be applied.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the builds from.
#>
function Get-VstsBuild
{
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory = $True)]
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
		-Path $path `
		-Project $Project `
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
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param(
		[Parameter(Mandatory = $true)]
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
		-Path $path `
		-Project $Project `
		-ApiVersion '2.0' `
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Gets build definitions for the specified project.
#>
function New-VstsBuildDefinition
{
	param(
		[Parameter(Mandatory)]
		$Session,
		[Parameter(Mandatory = $true)]
		$Project,
		[Parameter(Mandatory = $true)]
		$Name,
		[Parameter()]
		$DisplayName = $Name,
		[Parameter()]
		$Comment,
		[Parameter(Mandatory = $true)]
		$Queue,
		[Parameter(Mandatory = $true)]
		[PSCustomObject]$Repository
	)

	if (-not (Test-Guid -Input $Queue))
	{
		$Queue = (Get-VstsBuildQueue -Session $Session | Where-Object -Property Name -EQ $Queue).Id
	}

	$Body = @{
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

	Invoke-VstsEndpoint -Session $Session -Path 'build/definitions' -ApiVersion 2.0 -Method POST -Body $Body -Project $Project
}

<#
	.SYNOPSIS
	Gets build queues for the collection.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Id
	The Id of the Build Queue to retrieve.

	.PARAMETER Name
	The Name of the Build Queue to retrieve.
#>
function Get-VstsBuildQueue
{
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(ParameterSetName = 'Id')]
		[Int32] $Id,

		[Parameter(ParameterSetName = 'Query')]
		[String] $Name
	)

	$Path = 'build/queues'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'name'
		}
	}
	else
	{
		if ($PSBoundParameters.ContainsKey('Id'))
		{
			$Path = ('{0}/{1}' -f $Path, $Id)
		}
	}

	$Result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $Path `
		-ApiVersion '2.0' `
		@additionalInvokeParameters

	return $Result.Value
}

<#
	.SYNOPSIS
	Gets team project build artifacts.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the build artifacts from.

	.PARAMETER BuildId
	The BuildId of the artifacts to return.
#>
function Get-VstsBuildArtifact
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[Parameter(Mandatory = $true)]
		$Project,

		[Parameter(Mandatory = $true)]
		[Int32] $BuildId
	)

	$Path = ('build/builds/{0}/artifacts' -f $BuildId)

	$Result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $Path `
		-Project $Project `
		-ApiVersion '2.0'

	return $Result.Value
}
