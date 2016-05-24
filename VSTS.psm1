function Get-TfsAuthorization {
    param($user, $token)

    $Value = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))
    ("Basic {0}" -f $value)
}

function New-TfsWorkItem {
    param($AccountName, $Project, $User, $Token, $PropertyHashtable, $WorkItemType)

    $authorization = Get-TfsAuthorization -User $user -Token $token

    $Fields = foreach($kvp in $PropertyHashtable)
    {
        [PSCustomObject]@{
            op = 'add'
            path = '/fields/' + $kvp.Key
            value = $kvp.value
        }
    }

    $Body = $Fields | ConvertTo-Json
    "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/wit/workitems/$($WorkItemType)?api-version=1.0"
    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/wit/workitems/$($WorkItemType)?api-version=1.0" -Method POST -ContentType 'application/json' -Headers @{Authorization=$authorization} -Body $Body
}

