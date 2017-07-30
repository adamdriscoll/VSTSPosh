<#
	.SYNOPSIS
	Gets team project release definitions.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the release from.

	.PARAMETER DefinitionId
	The DefinitionId of the release to return.
#>
function Get-VstsReleaseDefinition
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Project,

		[Parameter()]
		[Int32] $DefinitionId
	)

	$path = 'release/definitions'

	$additionalInvokeParameters = @{
		QueryStringParameters = (Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'DefinitionId')
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		-Project $Project `
		-ApiVersion '3.0-preview.2' `
		-EndpointName 'vsrm' `
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Gets team project release definitions.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the release from.

	.PARAMETER Id
	The Id of the release to return.

	.PARAMETER Top
	The maximum number of releases to return.

	.PARAMETER CreatedBy
	The alias of the user that created the release.

	.PARAMETER StatusFilter
	The releases that have this status.

	.PARAMETER QueryOrder
	Gets the results in the defined order of created date
	for releases.
#>
function Get-VstsRelease
{
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter()]
		[Int32] $Id,

		[Parameter()]
		[Int32] $DefinitionId,

		[Parameter()]
		[Int32] $Top,

		[Parameter()]
		[String] $CreatedBy,

		[Parameter()]
		[ValidateSet('Draft', 'Active', 'Abandoned')]
		[String] $StatusFilter,

		[Parameter()]
		[ValidateSet('ascending', 'descending')]
		[String] $QueryOrder
	)

	$path = 'release/releases'
	$additionalInvokeParameters = @{}

	if ($PSBoundParameters.ContainsKey('Id'))
	{
		$path = ('{0}/{1}' -f $path, $Id)
	}
	else
	{
		$additionalInvokeParameters = @{
			QueryStringParameters    = (Get-VstsQueryStringParametersFromBound `
					-BoundParameters $PSBoundParameters `
					-ParameterList 'DefinitionId', 'CreatedBy', 'StatusFilter', 'QueryOrder')
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Expand'
		}
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		-Project $Project `
		-ApiVersion '3.0-preview.2' `
		-EndpointName 'vsrm' `
		@additionalInvokeParameters

	return $Result.Value
}

<#
	.SYNOPSIS
	Creates a new release for a project.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to create the new release in.

	.PARAMETER DefinitionId
	The release definition Id to create the new release for.

	.PARAMETER Description
	The description of the new release.

	.PARAMETER Artifacts
	The artifacts that will be provided into the release.

	These must be in the format:
	[
		alias: {string},
			 instanceReference: {
					name: {string},
					id: {string},
					sourceBranch: {string}
			 }
	]

	.EXAMPLE
	$vstsSession = New-VSTSSession `
		-AccountName 'myvstsaccount' `
		-User 'joe.bloggs@fabrikam.com' `
		-Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

	New-VstsRelease `
		-Session $vstsSession `
		-Project 'pipeline' `
		-DefinitionId 2 `
		-Description 'Test from API' `
		-Artifacts @( @{ Alias = 'FabrikamCI'; instanceReference = @{ id = 2217 } } )
	#>
function New-VstsRelease
{
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[Parameter(Mandatory = $true)]
		[String] $Project,

		[Parameter(Mandatory = $true)]
		[Int32] $DefinitionId,

		[Parameter(Mandatory = $true)]
		[String] $Description,

		[Parameter(Mandatory = $true)]
		[HashTable[]] $Artifacts
	)

	$Body = @{
		definitionId = $DefinitionId
		description  = $Description
		artifacts    = $Artifacts
	} | ConvertTo-Json -Depth 20

	Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path 'release/releases' `
		-ApiVersion '3.0-preview.2' `
		-EndpointName 'vsrm' `
		-Method POST `
		-Body $Body
}
