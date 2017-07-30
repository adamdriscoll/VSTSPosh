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
	>
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
			path  = '/fields/{0}' -f ($kvp.Key.Replace('_', '.'))
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
