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

    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects?api-version=1.0" -Method GET -ContentType 'application/json' -Headers @{Authorization=$authorization} 
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
    "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/wit/workitems/$($WorkItemType)?api-version=1.0"
    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/wit/workitems/`$$($WorkItemType)?api-version=1.0" -Method PATCH -ContentType 'application/json-patch+json' -Headers @{Authorization=$authorization} -Body $Body
}

function Get-VstsWorkItemQuery {
    <#
    .SYNOPSIS 
        Returns a list of work item queries from the specified folder.
    #>
    param($AccountName, $User, $Token, $Project, $FolderPath)

    $authorization = Get-VstsAuthorization -User $user -Token $token

    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/wit/queries?`$depth=1&api-version=1.0" -Method GET -ContentType 'application/json' -Headers @{Authorization=$authorization} 
}

