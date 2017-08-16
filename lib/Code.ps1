<#
    .SYNOPSIS
    Gets Git repositories in the specified team project.

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.

    .PARAMETER Project
    The name of the project to get the repositories from.

    .PARAMETER Repository
    The id or name of the repository. If this is a repository
    id then the Project is optional.

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
        [ValidateNotNullOrEmpty()]
        [String] $Project,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $Repository
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    $path = 'git/repositories'

    if ($PSBoundParameters.ContainsKey('Repository'))
    {
        $path = ('{0}/{1}' -f $path, $Repository)
    }

    $invokeParameters = @{
        Session = $Session
        Path    = $Path
    }

    if ($PSBoundParameters.ContainsKey('Project'))
    {
        $invokeParameters += @{ Project = $Project }
    }

    $result = Invoke-VstsEndpoint @invokeParameters

    return $result.Value
}

<#
    .SYNOPSIS
    Creates a new Git repository in the specified team project.

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.

    .PARAMETER Project
    The name of the project to create the repositories in.

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
        [String] $RepositoryName
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    $path = 'git/repositories'

    # Ensure we have what looks like a Project Id Guid.
    if (Test-Guid -Guid $Project)
    {
        $projectId = $Project
    }
    else
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
    Deletes a Git repository from the specified team project.

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

    .PARAMETER Session
    The session object created by New-VstsSession.

    .PARAMETER Project
    The name of the project to delete the repository from.

    .PARAMETER RepositoryName
    The name of the repository to delete.

    .EXAMPLE
    >
    $vstsSession = New-VSTSSession `
        -AccountName 'myvstsaccount' `
        -User 'joe.bloggs@fabrikam.com' `
        -Token 'hi3pxk5usaag6jslczs5bqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

    Remove-VstsGitRepository `
        -Session $session `
        -Project 'FabrikamFiber' `
        -RepositoryName 'PortalApp'

    Delete the PortalAll repository from the FabrikamFiber project.
#>
function Remove-VstsGitRepository
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
        [ValidateNotNullOrEmpty()]
        [String] $Project,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String] $Repository
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

    # Make sure the Repository Id Guid is available
    if (Test-Guid -Guid $Repository)
    {
        if ($PSBoundParameters.ContainsKey('Project'))
        {
            Throw 'If repository Id is passed then Project should not be passed.'
        }

        $repositoryId = $Repository
    }
    else
    {
        if (-not $PSBoundParameters.ContainsKey('Project'))
        {
            Throw 'If repository Name is passed then Project must be passed.'
        }

        $repositoryId = (Get-VstsGitRepository -Session $Session -Project $Project -Repository $Repository).Id
        Write-Verbose -Message ('Repository Id {0} retrieved for repository {1}' -f $repositoryId, $Repository)
    }

    $path = ('git/repositories/{0}' -f $repositoryId)

    $invokeParameters = @{
        Session     = $Session
        Path        = $Path
        Method      = 'DELETE'
        ErrorAction = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Project'))
    {
        $invokeParameters += @{ Project = $Project }
    }

    $null = Invoke-VstsEndpoint @invokeParameters
}

<#
    .SYNOPSIS
    Get code policy configurations for the specified project.

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

    .PARAMETER Id
    The Id of the policy configuration to return.

    .PARAMETER Top
    Restrict the number of policy configurations to be returned.

    .PARAMETER Skip
    Do not return the first 'skip' number of policy configurations.
#>
function Get-VstsCodePolicyConfiguration
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
        [String] $Id,

        [Parameter()]
        [Int32] $Top,

        [Parameter()]
        [Int32] $Skip

    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

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

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

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
        [Guid] $RepositoryId = [Guid]::Empty,

        [Parameter()]
        [Int] $MinimumReviewers = 1,

        [Parameter(Mandatory = $True)]
        [String[]] $Branches
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

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

    .PARAMETER AccountName
    The name of the VSTS account to use.

    .PARAMETER User
    This user name to authenticate to VSTS.

    .PARAMETER Token
    This personal access token to use to authenticate to VSTS.

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
        $Project,

        [Parameter(Mandatory = $True)]
        $TargetName,

        [Parameter(Mandatory = $True)]
        $SourceFolder
    )

    if ($PSCmdlet.ParameterSetName -eq 'Account')
    {
        $Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
    }

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
