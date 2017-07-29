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
function New-VstsSession {
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param
	(
		[Parameter()]
		[String] $AccountName,
		
		[Parameter(Mandatory=$true)]
		[String] $User,
		
		[Parameter(Mandatory=$true)]
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
		User = $User
		Token = $Token
		Collection = $Collection
		Server = $Server
		Scheme = $Scheme
	}
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
function Get-VstsEndpointUri {
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
function Invoke-VstsEndpoint {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		$Session,

		[Hashtable] $QueryStringParameters,

		[String] $Project,

		[Uri] $Path,

		[String] $ApiVersion='1.0',

		[ValidateSet('GET', 'PUT', 'POST', 'DELETE', 'PATCH')]
		[String] $Method = 'GET',

		[String] $Body,

		[String] $EndpointName,

		[Hashtable] $QueryStringExtParameters
	)

	$queryString = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)

	if ($QueryStringParameters -ne $null)
	{
		foreach($parameter in $QueryStringParameters.GetEnumerator())
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
		foreach($parameter in $QueryStringExtParameters.GetEnumerator())
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
function Get-VstsAuthorization {
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
#>
function Get-VstsProject {
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param
	(
		[Parameter(Mandatory = $True)]
		$Session,

		[Parameter(ParameterSetName = 'Name')]
		[String] $Name,

		[Parameter(ParameterSetName = 'Query')]
		[ValidateSet('WellFormed','CreatePending','Deleting','New','All')]
		[String] $StateFilter,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Skip
	)

	$Path = 'projects'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = (Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'stateFilter')
			QueryStringExtParameters = Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Top','Skip'
		}
	}
	else
	{
		if ($PSBoundParameters.ContainsKey('Name'))
		{
			$Path = ('{0}/{1}' -f $Path, $Name)
		}
	}

	$Result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $Path `
		@additionalInvokeParameters

	return $Result.Value
}

function Wait-VSTSProject {
	param
	(
		[Parameter(Mandatory)]$Session,
		[Parameter(Mandatory)]$Name,
		$Attempts = 30,
		[Switch]$Exists
	)

	$Retries = 0
	do {
		#Takes a few seconds for the project to be created
		Start-Sleep -Seconds 2

		$TeamProject = Get-VSTSProject -Session $Session -Name $Name

		$Retries++
	} while ((($TeamProject -eq $null -and $Exists) -or ($TeamProject -ne $null -and -not $Exists)) -and $Retries -le $Attempts)

	if (($TeamProject -eq $null -and $Exists) -or ($TeamProject -ne $null -and -not $Exists) )
	{
		throw "Failed to create team project!"
	}
}

function New-VstsProject
{
	<#
		.SYNOPSIS
			Creates a new project in a VSTS account
	#>
	param(
	[Parameter(Mandatory, ParameterSetname='Account')]$AccountName,
	[Parameter(Mandatory, ParameterSetname='Account')]$User,
	[Parameter(Mandatory, ParameterSetname='Account')]$Token,
	[Parameter(Mandatory, ParameterSetname='Session')]$Session,
	[Parameter(Mandatory)]$Name,
	[Parameter()]$Description,
	[Parameter()][ValidateSet('Git')]$SourceControlType = 'Git',
	[Parameter()]$TemplateTypeId = '6b724908-ef14-45cf-84f8-768b5384da45',
	[Parameter()]$TemplateTypeName = 'Agile',
	[Switch]$Wait)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	if ($PSBoundParameters.ContainsKey('TemplateTypeName'))
	{
		$TemplateTypeId = Get-VstsProcess -Session $Session | Where Name -EQ $TemplateTypeName | Select -ExpandProperty Id
		if ($TemplateTypeId -eq $null)
		{
			throw "Template $TemplateTypeName not found."
		}
	}

	$Body = @{
		name = $Name
		description = $Description
		capabilities = @{
			versioncontrol = @{
				sourceControlType = $SourceControlType
			}
			processTemplate = @{
				templateTypeId = $TemplateTypeId
			}
		}
	} | ConvertTo-Json

	Invoke-VstsEndpoint -Session $Session -Path 'projects' -Method POST -Body $Body

	if ($Wait)
	{
		Wait-VSTSProject -Session $Session -Name $Name -Exists
	}
}

function Remove-VSTSProject {
	<#
		.SYNOPSIS
			Deletes a project from the specified VSTS account.
	#>
	param(
		[Parameter(Mandatory, ParameterSetname='Account')]$AccountName,
		[Parameter(Mandatory, ParameterSetname='Account')]$User,
		[Parameter(Mandatory, ParameterSetname='Account')]$Token,
		[Parameter(Mandatory, ParameterSetname='Session')]$Session,
		[Parameter(Mandatory)]$Name,
		[Parameter()][Switch]$Wait)

		if ($PSCmdlet.ParameterSetName -eq 'Account')
		{
			$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
		}

		$Id = Get-VstsProject -Session $Session -Name $Name | Select -ExpandProperty Id

		if ($Id -eq $null)
		{
			throw "Project $Name not found in $AccountName."
		}

		Invoke-VstsEndpoint -Session $Session -Path "projects/$Id" -Method DELETE

		if ($Wait)
		{
			Wait-VSTSProject -Session $Session -Name $Name
		}
}

function Get-VstsWorkItem {
<#
	.SYNOPSIS
		Get work items from VSTS
#>
	param(
	[Parameter(Mandatory, ParameterSetname='Account')]$AccountName,
	[Parameter(Mandatory, ParameterSetname='Account')]$User,
	[Parameter(Mandatory, ParameterSetname='Account')]$Token,
	[Parameter(Mandatory, ParameterSetname='Session')]$Session,
	[Parameter(Mandatory)]$Id)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	Invoke-VstsEndpoint -Session $Session -Path 'wit/workitems' -QueryStringParameters @{ids = $id}
}

function New-VstsWorkItem {
<#
	.SYNOPSIS
		Create new work items in VSTS
#>
	param(
	[Parameter(Mandatory, ParameterSetname='Account')]
	$AccountName,
	[Parameter(Mandatory, ParameterSetname='Account')]
	$User,
	[Parameter(Mandatory, ParameterSetname='Account')]
	$Token,
	[Parameter(Mandatory, ParameterSetname='Session')]
	$Session,
	[Parameter(Mandatory)]
	$Project,
	[Parameter()]
	[Hashtable]
	$PropertyHashtable,
	[Parameter(Mandatory)]
	[string]
	$WorkItemType
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	if ($PropertyHashtable -ne $null)
	{
		$Fields = foreach($kvp in $PropertyHashtable.GetEnumerator())
		{
			[PSCustomObject]@{
				op = 'add'
				path = '/fields/' + $kvp.Key
				value = $kvp.value
			}
		}

		$Body = $Fields | ConvertTo-Json
	}
	else
	{
		$Body = [String]::Empty
	}

	Invoke-VstsEndpoint -Session $Session -Path "wit/workitems/`$$($WorkItemType)" -Method PATCH -Project $Project -Body $Body
}

function Get-VstsWorkItemQuery {
	<#
	.SYNOPSIS
		Returns a list of work item queries from the specified folder.
	#>
	param(
	[Parameter(Mandatory, ParameterSetname='Account')]
	$AccountName,
	[Parameter(Mandatory, ParameterSetname='Account')]
	$User,
	[Parameter(Mandatory, ParameterSetname='Account')]
	$Token,
	[Parameter(Mandatory, ParameterSetname='Session')]
	$Session,
	[Parameter(Mandatory=$true)]$Project,
	$FolderPath)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	$Result = Invoke-VstsEndpoint -Session $Session -Project $Project -Path 'wit/queries' -QueryStringParameters @{depth=1}

	foreach($value in $Result.Value)
	{
		if ($Value.isFolder -and $Value.hasChildren)
		{
			Write-Verbose "$Value.Name"
			foreach($child in $value.Children)
			{
				if (-not $child.isFolder)
				{
					$child
				}
			}
		}
	}
}

function New-VstsGitRepository {
	<#
		.SYNOPSIS
			Creates a new Git repository in the specified team project.
	#>
	param(
	[Parameter(Mandatory, ParameterSetname='Account')]
	$AccountName,
	[Parameter(Mandatory, ParameterSetname='Account')]
	$User,
	[Parameter(Mandatory, ParameterSetname='Account')]
	$Token,
	[Parameter(Mandatory, ParameterSetname='Session')]
	$Session,
	[Parameter(Mandatory=$true)]
	$Project,
	[Parameter(Mandatory=$true)]
	$RepositoryName)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	if (-not (Test-Guid $Project))
	{
		$Project = Get-VstsProject -Session $Session -Name $Project | Select -ExpandProperty Id
	}

	$Body = @{
		Name = $RepositoryName
		Project = @{
			Id = $Project
		}
	} | ConvertTo-Json

	Invoke-VstsEndpoint -Session $Session -Method POST -Path 'git/repositories' -Body $Body
}

function Get-VstsGitRepository {
	<#
		.SYNOPSIS
			Gets Git repositories in the specified team project.
	#>
		param(
		[Parameter(Mandatory, ParameterSetname='Account')]
		$AccountName,
		[Parameter(Mandatory, ParameterSetname='Account')]
		$User,
		[Parameter(Mandatory, ParameterSetname='Account')]
		$Token,
		[Parameter(Mandatory, ParameterSetname='Session')]
		$Session,
		[Parameter(Mandatory=$true)]$Project)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	 $Result = Invoke-VstsEndpoint -Session $Session -Project $Project -Path 'git/repositories' -QueryStringParameters @{depth=1}
	 $Result.Value
}

function Get-VstsCodePolicy {
	<#
		.SYNOPSIS
			Get code policies for the specified project.
	#>

	param(
		[Parameter(Mandatory, ParameterSetname='Account')]
		$AccountName,
		[Parameter(Mandatory, ParameterSetname='Account')]
		$User,
		[Parameter(Mandatory, ParameterSetname='Account')]
		$Token,
		[Parameter(Mandatory, ParameterSetname='Session')]
		$Session,
		[Parameter(Mandatory=$true)]$Project)


	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	 $Result = Invoke-VstsEndpoint -Session $Session -Project $Project -Path 'policy/configurations' -ApiVersion '2.0-preview.1'
	 $Result.Value
}

function New-VstsCodePolicy {
	<#
		.SYNOPSIS
			Creates a new Code Policy configuration for the specified project.
	#>

	param(
		[Parameter(Mandatory, ParameterSetname='Account')]
		$AccountName,
		[Parameter(Mandatory, ParameterSetname='Account')]
		$User,
		[Parameter(Mandatory, ParameterSetname='Account')]
		$Token,
		[Parameter(Mandatory, ParameterSetname='Session')]
		$Session,
		[Parameter(Mandatory=$true)]
		$Project,
		[Guid]
		$RepositoryId = [Guid]::Empty,
		[int]
		$MinimumReviewers,
		[string[]]
		$Branches)

	$RepoId = $null
	if ($RepositoryId -ne [Guid]::Empty)
	{
		$RepoId = $RepositoryId.ToString()
	}

	$scopes = foreach($branch in $Branches)
	{
		@{
			repositoryId = $RepoId
			refName = "refs/heads/$branch"
			matchKind = "exact"
		}
	}

	$Policy = @{
		isEnabled = $true
		isBlocking = $false
		type = @{
			id = 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd'
		}
		settings = @{
			minimumApproverCount = $MinimumReviewers
			creatorVoteCounts = $false
			scope = @($scopes)
		}
	} | ConvertTo-Json -Depth 10

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	Invoke-VstsEndpoint -Session $Session -Project $Project -ApiVersion '2.0-preview.1' -Body $Policy -Method POST
}

function Get-VstsProcess {
	<#
		.SYNOPSIS
			Gets team project processes.
	#>

	param(
		[Parameter(Mandatory)]
		$Session)

	 $Result = Invoke-VstsEndpoint -Session $Session -Path 'process/processes'
	 $Result.Value
}

<#
	.SYNOPSIS
		Gets team project builds.

	.DESCRIPTION
		This cmdlet will return a list of builds
		or a single build if Id is specified.

		It can also be provided with additional query parmeters
		to allow additional filters to be applied.
#>
function Get-VstsBuild {
	[CmdletBinding(DefaultParameterSetName = 'Query')]
	param
	(
		[Parameter(Mandatory)]
		$Session,

		[Parameter(Mandatory)]
		$Project,

		[Parameter(ParameterSetName = 'Id')]
		[Int32] $Id,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Definitions,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Queues,

		[Parameter(ParameterSetName = 'Query')]
		[Int32] $Top
	)

	$Path = 'build/builds'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'definitions','queues'
			QueryStringExtParameters = Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'top'
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
function Get-VstsBuildDefinition {
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

	$Path = 'build/definitions'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'name'
			QueryStringExtParameters = Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Top'
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
		-Project $Project `
		-ApiVersion '2.0' `
		@additionalInvokeParameters

	return $Result.Value
}


function Test-Guid {
	param([Parameter(Mandatory)]$Input)

	$Guid = [Guid]::Empty
	[Guid]::TryParse($Input, [ref]$Guid)
}

function New-VstsBuildDefinition {
	<#
		.SYNOPSIS
			Gets build definitions for the specified project.
	#>

	param(
		[Parameter(Mandatory)]
		$Session,
		[Parameter(Mandatory=$true)]
		$Project,
		[Parameter(Mandatory=$true)]
		$Name,
		[Parameter()]
		$DisplayName = $Name,
		[Parameter()]
		$Comment,
		[Parameter(Mandatory=$true)]
		$Queue,
		[Parameter(Mandatory=$true)]
		[PSCustomObject]$Repository
	)

	if (-not (Test-Guid -Input $Queue))
	{
		$Queue = Get-VstsBuildQueue -Session $Session | Where Name -EQ $Queue | Select -ExpandProperty Id
	}

	$Body = @{
	  name =  $Name
	  type = "build"
	  quality = "definition"
	  queue = @{
		id = $Queue
	  }
	  build = @(
		@{
		  enabled = $true
		  continueOnError = $false
		  alwaysRun = $false
		  displayName = $DisplayName
		  task = @{
			id = "71a9a2d3-a98a-4caa-96ab-affca411ecda"
			versionSpec = "*"
		  }
		  inputs = @{
			"solution" = "**\\*.sln"
			"msbuildArgs" = ""
			"platform" = '$(platform)'
			"configuration"= '$(config)'
			"clean" = "false"
			"restoreNugetPackages" = "true"
			"vsLocationMethod" = "version"
			"vsVersion" = "latest"
			"vsLocation" =  ""
			"msbuildLocationMethod" = "version"
			"msbuildVersion" = "latest"
			"msbuildArchitecture" = "x86"
			"msbuildLocation" = ""
			"logProjectEvents" = "true"
		  }
		},
		@{
		  "enabled" = $true
		  "continueOnError" = $false
		  "alwaysRun" = $false
		  "displayName" = "Test Assemblies **\\*test*.dll;-:**\\obj\\**"
		  "task" = @{
			"id" = "ef087383-ee5e-42c7-9a53-ab56c98420f9"
			"versionSpec" = "*"
		  }
		  "inputs" = @{
			"testAssembly" = "**\\*test*.dll;-:**\\obj\\**"
			"testFiltercriteria" = ""
			"runSettingsFile" = ""
			"codeCoverageEnabled" = "true"
			"otherConsoleOptions" = ""
			"vsTestVersion" = "14.0"
			"pathtoCustomTestAdapters" = ""
		  }
		}
	  )
	  "repository" = @{
		"id" = $Repository.Id
		"type" = "tfsgit"
		"name" = $Repository.Name
		"localPath" = "`$(sys.sourceFolder)/$($Repository.Name)"
		"defaultBranch" ="refs/heads/master"
		"url" = $Repository.Url
		"clean" = "false"
	  }
	  "options" = @(
		@{
		  "enabled" = $true
		  "definition" = @{
			"id" = "7c555368-ca64-4199-add6-9ebaf0b0137d"
		  }
		  "inputs" = @{
			"parallel" = "false"
			"multipliers" = @("config","platform")
		  }
		}
	  )
	  "variables" = @{
		"forceClean" = @{
		  "value" = "false"
		  "allowOverride" = $true
		}
		"config" =  @{
		  "value" = "debug, release"
		  "allowOverride" = $true
		}
		"platform" = @{
		  "value" = "any cpu"
		  "allowOverride" = $true
		}
	  }
	  "triggers" = @()
	  "comment" = $Comment
	} | ConvertTo-Json -Depth 20

	Invoke-VstsEndpoint -Session $Session -Path 'build/definitions' -ApiVersion 2.0 -Method POST -Body $Body -Project $Project
}

<#
	.SYNOPSIS
	Gets build queues for the collection.
#>
function Get-VstsBuildQueue {
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
			QueryStringParameters = Get-VSTSQueryStringParametersFromParams `
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
function ConvertTo-VstsGitRepository {
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
	if ($gitCommand -eq $null -or $gitCommand.CommandType -ne 'Application' -or $gitCommand.Name -ne 'git.exe')
	{
		throw "Git-tfs needs to be installed to use this command. See https://github.com/git-tfs/git-tfs. You can install with Chocolatey: cinst gittfs"
	}

	$gitTfsCommand = Get-Command git-tfs
	if ($gitTfsCommand -eq $null -or $gitTfsCommand.CommandType -ne 'Application' -or $gitTfsCommand.Name -ne 'git-tfs.exe')
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
function Get-VstsBuildArtifact {
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
function Get-VstsReleaseDefinition {
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
			QueryStringParameters = (Get-VSTSQueryStringParametersFromParams `
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
function Get-VstsRelease {
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
		[ValidateSet('Draft','Active','Abandoned')]
		[String] $StatusFilter,

		[Parameter(ParameterSetName = 'Query')]
		[ValidateSet('ascending','descending')]
		[String] $QueryOrder
	)

	$path = 'release/releases'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = (Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'DefinitionId','CreatedBy','StatusFilter','QueryOrder')
			QueryStringExtParameters = Get-VSTSQueryStringParametersFromParams `
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
function New-VstsRelease {
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
		description = $Description
		artifacts = $Artifacts
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
function Get-VstsQueryStringParametersFromParams {
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
