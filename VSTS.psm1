function Invoke-VstsEndpoint {
    param([Parameter(Mandatory=$true)]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
          [Parameter(Mandatory=$true)]$Token, 
          [Hashtable]$QueryStringParameters, 
          $Project,
          [Uri]$Path, 
          [Version]$ApiVersion='1.0', 
          [ValidateSet('Get', 'PUT', 'POST', 'DELETE')]$Method='GET')

    $queryString = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
   
    if ($QueryStringParameters -ne $null)
    {
        foreach($parameter in $QueryStringParameters.GetEnumerator())
        {
            $queryString[$parameter.Key] = $parameter.Value
        }
    }

    $queryString["api-version"] = $ApiVersion.ToString()
    $queryString = $queryString.ToString();

    $authorization = Get-VstsAuthorization -User $user -Token $token

    $UriBuilder = New-Object System.UriBuilder -ArgumentList "https://$AccountName.visualstudio.com"
    $UriBuilder.Query = $queryString
    if ([String]::IsNullOrEmpty($Project))
    {
        $UriBuilder.Path = "DefaultCollection/_apis/$Path"
    }
    else 
    {
        $UriBuilder.Path = "DefaultCollection/$Project/_apis/$Path"
    }

  
    $Uri = $UriBuilder.Uri

    Write-Verbose "Invoke URI [$uri]"

    Invoke-RestMethod $Uri -Method $Method -ContentType 'application/json' -Headers @{Authorization=$authorization} 
}

function Get-VstsAuthorization {
<#
    .SYNOPSIS
        Generates a VSTS authorization header value from a username and Personal Access Token. 
#>
    param($user, $token)

    $Value = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))
    ("Basic {0}" -f $value)
}

function Get-VstsProject {
<#
    .SYNOPSIS 
        Get projects in a VSTS account.
#>
    param($AccountName, $User, $Token)
    
    $authorization = Get-VstsAuthorization -User $user -Token $token

    $Value  = Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects?api-version=1.0" -Method GET -ContentType 'application/json' -Headers @{Authorization=$authorization}

    $Value.Value 
}

function Get-VstsWorkItem {
<#
    .SYNOPSIS 
        Get work items from VSTS
#>
    param($AccountName, $User, $Token, [Parameter(Mandatory)]$Id)

    $authorization = Get-VstsAuthorization -User $user -Token $token

    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/_apis/wit/workitems?api-version=1.0&ids=$Id" -Method GET -ContentType 'application/json' -Headers @{Authorization=$authorization} 
}

function New-VstsWorkItem {
<#
    .SYNOPSIS 
        Create new work items in VSTS
#>
    param($AccountName, $Project, $User, $Token, $PropertyHashtable, $WorkItemType)

    $authorization = Get-VstsAuthorization -User $user -Token $token

    $Fields = foreach($kvp in $PropertyHashtable.GetEnumerator())
    {
        [PSCustomObject]@{
            op = 'add'
            path = '/fields/' + $kvp.Key
            value = $kvp.value
        }
    }

    $Body = $Fields | ConvertTo-Json
    
    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/wit/workitems/`$$($WorkItemType)?api-version=1.0" -Method PATCH -ContentType 'application/json-patch+json' -Headers @{Authorization=$authorization} -Body $Body
}

function Get-VstsWorkItemQuery {
    <#
    .SYNOPSIS 
        Returns a list of work item queries from the specified folder.
    #>
    param([Parameter(Mandatory=$true)]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
          [Parameter(Mandatory=$true)]$Token, 
          [Parameter(Mandatory=$true)]$Project, 
          $FolderPath)

    $Result = Invoke-VstsEndpoint -AccountName $AccountName -User $User -Token $Token -Project $Project -Path 'wit/queries' -QueryStringParameters @{depth=1}

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
    param([Parameter(Mandatory=$true)]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
          [Parameter(Mandatory=$true)]$Token, 
          [Parameter(Mandatory=$true)]$ProjectId,
          [Parameter(Mandatory=$true)]$RepositoryName)  

    $authorization = Get-VstsAuthorization -User $user -Token $token

    $Body = @{
        Name = $RepositoryName
        Project = @{
            Id = $ProjectId
        }
    } | ConvertTo-Json

    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/_apis/git/repositories/?api-version=1.0" -Method POST -ContentType 'application/json' -Headers @{Authorization=$authorization} -Body $Body
}

function Get-VstsGitRepository {
    <#
        .SYNOPSIS
            Gets Git repositories in the specified team project. 
    #>
        param([Parameter(Mandatory=$true)]$AccountName, 
              [Parameter(Mandatory=$true)]$User, 
              [Parameter(Mandatory=$true)]$Token, 
              [Parameter(Mandatory=$true)]$Project)

     $Result = Invoke-VstsEndpoint -AccountName $AccountName -User $User -Token $Token -Project $Project -Path 'git/repositories' -QueryStringParameters @{depth=1}
     $Result.Value              
}

