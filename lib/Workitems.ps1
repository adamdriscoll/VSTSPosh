<#
    .SYNOPSIS
    Get work items from VSTS.

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

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
        [String] $Id,

        [Parameter()]
        [String[]] $Ids,

        [Parameter()]
        [String] $AsOf,

        [Parameter()]
        [ValidateSet('All', 'Relations', 'None')]
        [String] $Expand
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    $path = 'wit/workitems'
    $additionalInvokeParameters = @{}

    if ($PSBoundParameters.ContainsKey('Id'))
    {
        $path = ('{0}/{1}' -f $path, $Id)
    }
    else
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

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.

    .PARAMETER Project
    The name of the project to get the policy configuration from.

    .PARAMETER WorkItemType
    The work item type to create.

    .PARAMETER PropertyHashtable
    A hash table containing the properties to set for the new
    work item.

    .EXAMPLE
    >
    $vstsSession = New-VSTSSession `
        -AccountName 'myvstsaccount' `
        -User 'joe.bloggs@fabrikam.com' `
        -Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

    New-VstsWorkItem `
        -Session $vstsSession `
        -Project 'FabrikamFiber' `
        -WorkItemType 'User Story' `
        -PropertyHashtable @{ 'System.Title' = 'Add support for creating new work item' }

    Creates a new user story in FabrikamFiber project with the
    title 'Add support for creating new work item'
#>
function New-VstsWorkItem
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

        [Parameter(Mandatory = $True)]
        [string] $WorkItemType,

        [Parameter(Mandatory = $True)]
        [Hashtable]	$PropertyHashtable
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    $path = ('wit/workitems/${0}' -f $WorkItemType)

    $fields = foreach ($kvp in $PropertyHashtable.GetEnumerator())
    {
        [PSCustomObject] @{
            op    = 'add'
            path  = ('/fields/{0}' -f $kvp.Key)
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

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.
#>
function Get-VstsWorkItemQuery
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
        [String] $Project
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    $path = 'wit/queries'

    $result = Invoke-VstsEndpoint `
        -Session $Session `
        -Project $Project `
        -Path $path `
        -QueryStringParameters @{ depth = 1 }

    foreach ($value in $result.Value)
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
