<#
    .SYNOPSIS
    Gets team project release definitions.

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.

    .PARAMETER Project
    The name of the project to get the release from.

    .PARAMETER DefinitionId
    The DefinitionId of the release to return.
#>
function Get-VstsReleaseDefinition
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

        [Parameter()]
        [Int32] $DefinitionId
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

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

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

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

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

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
                    -ParameterList 'definitionId', 'createdBy', 'statusFilter', 'queryOrder')
            QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
                -BoundParameters $PSBoundParameters `
                -ParameterList 'top'
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
    >
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
        [Int32] $DefinitionId,

        [Parameter(Mandatory = $true)]
        [String] $Description,

        [Parameter(Mandatory = $true)]
        [HashTable[]] $Artifacts
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

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


<#
    .SYNOPSIS
    Creates a team project release definition.

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.

    .PARAMETER Project
    The name of the project in which to create the release.

    .PARAMETER Name
    The name of release definition to create.

    .PARAMETER EnvironmentNames
    A list of Environments to create. Will be created with identical defaults.
#>
function New-VstsReleaseDefinition
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

        [Parameter(Mandatory = $true)]
        [String] $Name,

        [Parameter(Mandatory = $false)]
        [string[]]$EnvironmentNames = @('Staging'),

        [Parameter(Mandatory = $false)]
        [string]$ReleaseNameFormat
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    [psobject[]]$environments  = for($i = 0; $i -lt $environmentNames.Count; $i++){
        $environmentDefinition =  @{
            id                  = $i
            name                = $EnvironmentNames[$i]
            variables           = ""
            preDeployApprovals  = @{
                approvals = @(
                    @{
                        rank             = 1
                        isAutomated      = $true
                        isNotificationOn = $false
                        id               = 0
                    }
                )
            }
            postDeployApprovals = @{
                approvals = @(
                    @{
                        rank             = 1
                        isAutomated      = $true
                        isNotificationOn = $false
                        id               = 0
                    }
                )
            }
            deployPhases        = @(
                @{
                    deploymentInput = @{
                        parallelExecution     = @{
                            parallelExecutionType = "none"
                        }
                        skipArtifactsDownload = $false
                        timeoutInMinutes      = 0
                        queueId               = 45
                        demands               = @()
                        enableAccessToken     = $false
                    }
                    rank            = 1
                    phaseType       = "agentBasedDeployment"
                    name            = "Run on agent"
                    workflowTasks   = @()
                }
            )
            environmentOptions  = @{
                emailNotificationType   = "OnlyOnFailure"
                emailRecipients         = "release.environment.owner;release.creator"
                skipArtifactsDownload   = $false
                timeoutInMinutes        = 0
                enableAccessToken       = $false
                publishDeploymentStatus = $false
            }
            demands             = @()
            conditions          = @()
            executionPolicy     = @{
                concurrencyCount = 0
                queueDepthCount  = 0
            }
            schedules           = @()
            retentionPolicy     = @{
                daysToKeep     = 30
                releasesToKeep = 3
                retainBuild    = $true
            }
        }
        Write-Output $environmentDefinition
    }


    $body = @{
        source = "undefined"
        id = 0
        revision = 1
        name =  $name
        createdBy =  $null
        createdOn =  "0001-01-01T00:00:00"
        modifiedBy =  $null
        modifiedOn =  "0001-01-01T00:00:00"
        lastRelease =  $null
        path =  $null
        variables =  ""
        variableGroups =  @()
        environments =  $environments
        artifacts =  @()
        triggers =  @()
        releaseNameFormat = $ReleaseNameFormat
        _links =  ""
        tags =  @()
        properties =  ""
    } | ConvertTo-Json -Depth 20 -Verbose

    $result = Invoke-VstsEndpoint `
        -Session $Session `
        -Project $Project `
        -Path 'Release/definitions' `
        -ApiVersion '4.0-preview.3' `
        -EndpointName 'vsrm' `
        -Method POST `
        -Body $Body


    Write-Output $result.Value
}
