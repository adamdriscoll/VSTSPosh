# System.Web is not always loaded by default, so ensure it is loaded.
Add-Type -AssemblyName System.Web

# Import all the lib files
$moduleRoot = Split-Path `
	-Path $MyInvocation.MyCommand.Path `
	-Parent

$libs = Get-ChildItem `
	-Path (Join-Path -Path $moduleRoot -ChildPath 'lib') `
	-Include '*.ps1' `
	-Recurse
$libs.Foreach(
 {
		Write-Verbose -Message ('Importing the lib file {0}' -f $_.Fullname)
		. $_.Fullname
	}
)

<#
	.SYNOPSIS
	Create a new VSTS session object that needs to be passed
	to other VSTS module calls to provide connection
	information. It can be used to connect to VSTS or TFS
	APIs.

	.PARAMETER AccountName
	The name of the VSTS account to use. Not required for TFS
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

		[Parameter()]
		[Hashtable] $QueryStringParameters,

		[Parameter()]
		[String] $Project,

		[Parameter()]
		[Uri] $Path,

		[Parameter()]
		[String] $ApiVersion = '1.0',

		[ValidateSet('GET', 'PUT', 'POST', 'DELETE', 'PATCH')]
		[String] $Method = 'GET',

		[Parameter()]
		[String] $Body,

		[Parameter()]
		[String] $EndpointName,

		[Parameter()]
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
	$invokeRestMethodParameters = @{
		Uri         = $Uri
		Method      = $Method
		ContentType = $ContentType
		Headers     = @{ Authorization = $authorization }
	}

	if ($Method -eq 'PUT' -or $Method -eq 'POST' -or $Method -eq 'PATCH')
	{
		if ($Method -eq 'PATCH')
		{
			$invokeRestMethodParameters['contentType'] = 'application/json-patch+json'
		}

		$invokeRestMethodParameters += @{
			Body = $Body
		}
	}

	$restResult = Invoke-RestMethod @invokeRestMethodParameters

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
	Checks that a Guid is valid.

	.PARAMETER Input
	The Guid to validate.

	.OUTPUTS
	Returns true if the Guid is valid.
#>
function Test-Guid
{
	[CmdletBinding()]
	[OutputType([Boolean])]
	param
	(
		[Parameter(Mandatory = $True)]
		$Input
	)

	$Guid = [Guid]::Empty
	[Guid]::TryParse($Input, [ref]$Guid)
}
