# System.Web is not always loaded by default, so ensure it is loaded.
Add-Type -AssemblyName System.Web

<#
	.SYNOPSIS
	Create a new VSTS session object that needs to be passed
	to other VSTS module calls to provide connection
	information. It can be used to connect to VSTS or TFS
	APIs.

	.PARAMETER AccountName
	The name of the VSTS Account to. Not required for TFS
	sessions.

	.PARAMETER User
	This user name to authenticate to VSTS or TFS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS
	or TFS.

	.PARAMETER Collection
	This collection to use. This defaults to
	'DefaultCollection'.

	.PARAMETER Server
	The name of the VSTS or TFS Server to connect to.
	For VSTS this will be 'visualstudio.com'. The default value
	if this is not specified is 'visualstudio.com'.

	.PARAMETER HTTPS
	Use HTTP or HTTPS to connect to the server.
	Defaults to HTTPS.

	.OUTPUTS
	VSTS Session Object.
#>
function New-VstsSession
{
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param
	(
		[Parameter()]
		[String] $AccountName,

		[Parameter(Mandatory = $true)]
		[String] $User,

		[Parameter(Mandatory = $true)]
		[String] $Token,

		[Parameter()]
		[String] $Collection = 'DefaultCollection',

		[Parameter()]
		[String] $Server = 'visualstudio.com',

		[Parameter()]
		[ValidateSet('HTTP', 'HTTPS')]
		[String] $Scheme = 'HTTPS'
	)

	[PSCustomObject] @{
		AccountName = $AccountName
		User        = $User
		Token       = $Token
		Collection  = $Collection
		Server      = $Server
		Scheme      = $Scheme
	}
}

<#
	.SYNOPSIS
	Helper function that takes an array of bound
	parameters passed to the calling function
	and an array of parameter names and creates a hash
	table containing each parameter that appears in
	the Bound Parameters and in the Parameters
	List.

	.PARAMETER BoundParameters
	This is the content of the PSBoundParameters from
	the calling function.

	.PARAMETER ParameterList
	This is the list of parameters to extract from the
	bound parameters list.

	.OUTPUTS
	Hashtable containing all parameters from
	BoundParameters that also appear in ParameterList.
#>
function Get-VstsQueryStringParametersFromBound
{
	[CmdletBinding()]
	[OutputType([Hashtable])]
	param
	(
		[Parameter(Mandatory = $true)]
		$BoundParameters,

		[Parameter(Mandatory = $true)]
		[Array] $ParameterList
	)

	$result = @{}
	foreach ($parameter in $ParameterList)
	{
		if ($BoundParameters.ContainsKey($parameter))
		{
			$result += @{ $parameter = $BoundParameters[$parameter] }
		}
	}
	return $result
}

<#
	.SYNOPSIS
	Assembles a VSTS or TFS endpoint URI object
	to be used to connect to a VSTS or TFS endpoint.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER EndpointName
	Set an alternate VSTS endpoint to call.
	This is required by API calls for to preview APIs that are not
	yet available on the primary endpoint.
#>
function Get-VstsEndpointUri
{
	[CmdletBinding()]
	[OutputType([System.UriBuilder])]
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[String] $EndpointName
	)

	if ([String]::IsNullOrEmpty($Session.AccountName))
	{
		$argumentList = ('{0}://{1}' -f $Session.Scheme, $Session.Server)
	}
	else
	{
		if ([String]::IsNullOrEmpty($EndpointName))
		{
			$argumentList = ('{0}://{1}.visualstudio.com' -f $Session.Scheme, $Session.AccountName)
		}
		else
		{
			$argumentList = ('{0}://{1}.{2}.visualstudio.com' -f $Session.Scheme, $Session.AccountName, $EndpointName)
		}
	}

	$uriBuilder = New-Object `
		-TypeName System.UriBuilder `
		-ArgumentList $argumentList

	return $uriBuilder
}

<#
	.SYNOPSIS
	Invokes the VSTS REST API endpoint.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER QueryStringParameters
	A hash table containing any additional query string
	parameters to add to the URI.

	.PARAMETER Project
	The name of the project to invoke the REST API for.

	.PARAMETER Path
	The path to add to the URI.

	.PARAMETER ApiVersion
	The version of the REST API to use.

	.PARAMETER Method
	The method to use for the REST API. Deraults to 'GET'.

	.PARAMETER Body
	The body to pass in the REST call.

	.PARAMETER EndpointName
	Set an alternate VSTS endpoint to call.
	This is required by API calls for to preview APIs that are not
	yet available on the primary endpoint.

	.PARAMETER QueryStringExtParameters
	A hash table containing any additional query string
	parameters to add to the URI. These will be added with a '$'
	pre-pended to the query string name. E.g. '&$Top=10'.
#>
function Invoke-VstsEndpoint
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[Hashtable] $QueryStringParameters,

		[String] $Project,

		[Uri] $Path,

		[String] $ApiVersion = '1.0',

		[ValidateSet('GET', 'PUT', 'POST', 'DELETE', 'PATCH')]
		[String] $Method = 'GET',

		[String] $Body,

		[String] $EndpointName,

		[Hashtable] $QueryStringExtParameters
	)

	$queryString = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)

	if ($QueryStringParameters -ne $null)
	{
		foreach ($parameter in $QueryStringParameters.GetEnumerator())
		{
			$queryString[$parameter.Key] = $parameter.Value
		}
	}

	<#
		These are query parmaeters that will be added prepended with a $.
		They can't be passed in the QueryStringParameters.
	#>
	if ($QueryStringExtParameters -ne $null)
	{
		foreach ($parameter in $QueryStringExtParameters.GetEnumerator())
		{
			$queryString['$' + $parameter.Key] = $parameter.Value
		}
	}

	$queryString["api-version"] = $ApiVersion
	$queryString = $queryString.ToString()

	$authorization = Get-VstsAuthorization -User $Session.User -Token $Session.Token

	$collection = $Session.Collection

	$uriBuilder = Get-VstsEndpointUri -Session $Session -EndpointName $EndpointName
	$uriBuilder.Query = $queryString

	if ([String]::IsNullOrEmpty($Project))
	{
		$uriBuilder.Path = ('{0}/_apis/{1}' -f $collection, $Path)
	}
	else
	{
		$uriBuilder.Path = ('{0}/{1}/_apis/{2}' -f $collection, $Project, $Path)
	}

	$uri = $uriBuilder.Uri

	Write-Verbose -Message "Invoke URI [$uri]"

	$contentType = 'application/json'

	if ($Method -eq 'PUT' -or $Method -eq 'POST' -or $Method -eq 'PATCH')
	{
		if ($Method -eq 'PATCH')
		{
			$contentType = 'application/json-patch+json'
		}

		$restResult = Invoke-RestMethod $Uri -Method $Method -ContentType $ContentType -Headers @{ Authorization = $authorization } -Body $Body
	}
	else
	{
		$restResult = Invoke-RestMethod $Uri -Method $Method -ContentType $ContentType -Headers @{ Authorization = $authorization }
	}

	if ($restResult.Value)
	{
		return $restResult
	}
	else
	{
		<#
			A Value property wasn't returned which usually occurs
			if a specific record is requested from the API.
			So create a new object with the value property set
			to the returned object.
		#>
		return [psobject] @{
			Value = $restResult
		}
	}
}

<#
	.SYNOPSIS
	Generates a VSTS authorization header value from a username and Personal
	Access Token.

	.PARAMETER User
	The username of the account to generate the authentication header for.

	.PARAMETER Token
	The Personal Access Token to use in the authentication header.
#>
function Get-VstsAuthorization
{
	[CmdletBinding()]
	[OutputType([String])]
	param
	(
		[String] $User,

		[String] $Token
	)

	$value = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $Token)))
	return ("Basic {0}" -f $value)
}

<#
	.SYNOPSIS
	Get projects in a VSTS account.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to return.

	.PARAMETER StateFilter
	If specified will return all projects matching this state.

	.PARAMETER Top
	Restrict the number of projects to be returned.

	.PARAMETER Skip
	Do not return the first 'skip' number of projects.
#>
function Get-VstsProject
{
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(ParameterSetName = 'Name')]
		[String] $Name,

		[Parameter(ParameterSetName = 'Query')]
		[ValidateSet('WellFormed', 'CreatePending', 'Deleting', 'New', 'All')]
		[String] $StateFilter,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Skip
	)

	$path = 'projects'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters    = (Get-VstsQueryStringParametersFromBound `
					-BoundParameters $PSBoundParameters `
					-ParameterList 'stateFilter')
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Top', 'Skip'
		}
	}
	else
	{
		if ($PSBoundParameters.ContainsKey('Name'))
		{
			$path = ('{0}/{1}' -f $path, $Name)
		}
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Wait for a project to be created or deleted.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to wait for.

	.PARAMETER Attempts
	The number of attempts to make when waiting for the project.

	.PARAMETER Exists
	Specifies if the cmdlet will wait for the project to exist
	or be absent (e.g. if being deleted).

	.PARAMETER RetryIntervalSec
	The number of seconds to wait between each check for the
	project.
#>
function Wait-VSTSProject
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Name,

		[Int32] $Attempts = 30,

		[Switch] $Exists,

		[Int32] $RetryIntervalSec = 2
	)

	$retries = 0
	do
	{
		# Takes a few seconds for the project to be created
		Start-Sleep -Seconds $RetryIntervalSec

		Write-Verbose -Message ('Checking project {0} state' -f $Name)
		$teamProject = Get-VSTSProject -Session $Session -Name $Name -ErrorAction SilentlyContinue

		$retries++
	} while ((($null -eq $teamProject -and $Exists) -or ($null -ne $teamProject -and -not $Exists)) -and $retries -le $Attempts)

	if (($null -eq $TeamProject -and $Exists) -or ($null -ne $TeamProject -and -not $Exists) )
	{
		throw "Failed to create team project!"
	}
}

<#
	.SYNOPSIS
	Creates a new project in a VSTS account.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to create.

	.PARAMETER Description
	The description of the project to create.

	.PARAMETER SourceControlType
	The type of source control system to use.
	Defaults to 'Git'.

	.PARAMETER TemplateTypeId
	The template type Id for the type of work item management
	to use for the project.

	.PARAMETER TemplateTypeName
	The template type Name for the type of work item management
	to use for the project.

	.PARAMETER Wait
	Switch to cause the cmdlet to wait for the project to be
	created before returning.
#>
function New-VstsProject
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Name,

		[Parameter()]
		[String] $Description,

		[Parameter()]
		[ValidateSet('Git', 'Tfvc')]
		[String] $SourceControlType = 'Git',

		[Parameter(ParameterSetName = 'TemplateTypeId')]
		[String] $TemplateTypeId = '6b724908-ef14-45cf-84f8-768b5384da45',

		[Parameter(ParameterSetName = 'TemplateTypeName')]
		[String] $TemplateTypeName = 'Agile',

		[Parameter()]
		[Switch] $Wait
	)

	$path = 'projects'

	if ($PSCmdlet.ParameterSetName -eq 'TemplateTypeName')
	{
		$templateTypeId = Get-VstsProcess -Session $Session |
			Where-Object -Property Name -EQ $TemplateTypeName |
			Select-Object -ExpandProperty Id

		if ($null -eq $templateTypeId)
		{
			throw "Template $TemplateTypeName not found."
		}
	}

	$body = @{
		name         = $Name
		description  = $Description
		capabilities = @{
			versioncontrol  = @{
				sourceControlType = $SourceControlType
			}
			processTemplate = @{
				templateTypeId = $templateTypeId
			}
		}
	} | ConvertTo-Json

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		-Method 'POST' `
		-Body $body `
		-ErrorAction Stop

	if ($Wait)
	{
		Wait-VSTSProject -Session $Session -Name $Name -Exists
	}

	return $result.Value
}

<#
	.SYNOPSIS
	Deletes a project from the specified VSTS account.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to delete.

	.PARAMETER Wait
	Switch to cause the cmdlet to wait for the project to be
	deleted before returning.
#>
function Remove-VSTSProject
{
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Name,

		[Parameter()]
		[Switch] $Wait
	)

	$projectId = (Get-VstsProject -Session $Session -Name $Name).Id

	if ($null -eq $projectId)
	{
		throw "Project $Name not found in $AccountName."
	}

	Write-Verbose -Message ('Removing project Id {0}' -f $projectId)
	$null = Invoke-VstsEndpoint -Session $Session -Path "projects/$projectId" -Method 'DELETE'

	if ($Wait)
	{
		Wait-VSTSProject -Session $Session -Name $Name
	}
}

<#
	.SYNOPSIS
	Get work items from VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Id
	The Id of a single work item to lookup.

	.PARAMETER Ids
	The Ids to lookup for multiple work items.

	.PARAMETER AsOf
	Gets the work items as they existed at this time.

	The date format must be:
	2014-12-29T20:49:22.103Z

	.PARAMETER Expand
	Gets work item relationships (work item links, hyperlinks, file attachments, etc.).
#>
function Get-VstsWorkItem
{
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True, ParameterSetName = 'Id')]
		[String] $Id,

		[Parameter(Mandatory = $True, ParameterSetName = 'Query')]
		[String[]] $Ids,

		[Parameter(ParameterSetName = 'Query')]
		[String] $AsOf,

		[Parameter(ParameterSetName = 'Query')]
		[ValidateSet('All', 'Relations', 'None')]
		[String] $Expand
	)

	$path = 'wit/workitems'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		# Convert the Ids into a comma delimited string
		$PSBoundParameters['Ids'] = ($PSBoundParameters['Ids'] -join ',')

		$additionalInvokeParameters = @{
			QueryStringParameters    = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'ids', 'asOf'
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'expand'
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
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Create new work items in VSTS

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Project
	The name of the project to get the policy configuration from.

	.PARAMETER WorkItemType
	The work item type to create.

	.PARAMETER PropertyHashtable
	A hash table containing the properties to set for the new
	work item. Because hash tables to not support '.' in the key
	all '.' must be replaced with underscore. This will be replaced
	with a '.' when submitted to the API.

	.EXAMPLE
	$vstsSession = New-VSTSSession `
		-AccountName 'myvstsaccount' `
		-User 'joe.bloggs@fabrikam.com' `
		-Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

	New-VstsWorkItem `
		-Session $session `
		-Project 'FabrikamFiber' `
		-WorkItemType 'User Story' `
		-PropertyHashtable @{ System_Title = 'Add support for creating new work item' }

	Creates a new user story in FabrikamFiber project with the
	title 'Add support for creating new work item'
#>
function New-VstsWorkItem
{
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Project,

		[Parameter(Mandatory = $True)]
		[string] $WorkItemType,

		[Parameter(Mandatory = $True)]
		[Hashtable]	$PropertyHashtable
	)

	$path = ('wit/workitems/${0}' -f $WorkItemType)

	$fields = foreach ($kvp in $PropertyHashtable.GetEnumerator())
	{
		[PSCustomObject] @{
			op    = 'add'
			path  = '/fields/{0}' -f ($kvp.Key.Replace('_','.'))
			value = $kvp.value
		}
	}

	$body = $fields | ConvertTo-Json

	if ($fields.Count -lt 2)
	{
		$body = ('[{0}]' -f $body)
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Project $Project `
		-Path $path `
		-Method 'PATCH' `
		-Body $body

	return $result.Value
}

<#
	.SYNOPSIS
	Returns a list of work item queries from the specified folder.
#>
function Get-VstsWorkItemQuery
{
	param
	(
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$AccountName,
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$User,
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$Token,
		[Parameter(Mandatory, ParameterSetname = 'Session')]
		$Session,
		[Parameter(Mandatory = $true)]$Project,
		$FolderPath
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	$Result = Invoke-VstsEndpoint -Session $Session -Project $Project -Path 'wit/queries' -QueryStringParameters @{depth = 1}

	foreach ($value in $Result.Value)
	{
		if ($Value.isFolder -and $Value.hasChildren)
		{
			Write-Verbose "$Value.Name"
			foreach ($child in $value.Children)
			{
				if (-not $child.isFolder)
				{
					$child
				}
			}
		}
	}
}

<#
	.SYNOPSIS
	Gets Git repositories in the specified team project.
#>
function Get-VstsGitRepository
{
	param
	(
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$AccountName,
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$User,
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$Token,
		[Parameter(Mandatory, ParameterSetname = 'Session')]
		$Session,
		[Parameter(Mandatory = $true)]$Project
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	$Result = Invoke-VstsEndpoint -Session $Session -Project $Project -Path 'git/repositories' -QueryStringParameters @{depth = 1}
	$Result.Value
}

<#
	.SYNOPSIS
	Creates a new Git repository in the specified team project.
#>
function New-VstsGitRepository
{
	param
	(
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$AccountName,
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$User,
		[Parameter(Mandatory, ParameterSetname = 'Account')]
		$Token,
		[Parameter(Mandatory, ParameterSetname = 'Session')]
		$Session,
		[Parameter(Mandatory = $true)]
		$Project,
		[Parameter(Mandatory = $true)]
		$RepositoryName
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	if (-not (Test-Guid $Project))
	{
		$Project = (Get-VstsProject -Session $Session -Name $Project).Id
	}

	$Body = @{
		Name    = $RepositoryName
		Project = @{
			Id = $Project
		}
	} | ConvertTo-Json

	Invoke-VstsEndpoint -Session $Session -Method POST -Path 'git/repositories' -Body $Body
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
	Gets available team processes.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Id
	The process Id of the process to return. This is a Guid.
#>
function Get-VstsProcess
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter()]
		[String] $Id
	)

	$path = 'process/processes'

	if ($PSBoundParameters.ContainsKey('Id'))
	{
		$path = ('{0}/{1}' -f $path, $Id)
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path

	return $result.Value
}

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
		$Project,

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


function Test-Guid
{
	param([Parameter(Mandatory)]$Input)

	$Guid = [Guid]::Empty
	[Guid]::TryParse($Input, [ref]$Guid)
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
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(Mandatory = $True)]
		[String] $Project,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $DefinitionId
	)

	$path = 'release/definitions'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = (Get-VstsQueryStringParametersFromBound `
					-BoundParameters $PSBoundParameters `
					-ParameterList 'DefinitionId')
		}
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
		$Project,

		[Parameter(ParameterSetName = 'Id')]
		[Int32] $Id,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $DefinitionId,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top,

		[Parameter(ParameterSetName = 'Query')]
		[String] $CreatedBy,

		[Parameter(ParameterSetName = 'Query')]
		[ValidateSet('Draft', 'Active', 'Abandoned')]
		[String] $StatusFilter,

		[Parameter(ParameterSetName = 'Query')]
		[ValidateSet('ascending', 'descending')]
		[String] $QueryOrder
	)

	$path = 'release/releases'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
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
		$Project,

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
