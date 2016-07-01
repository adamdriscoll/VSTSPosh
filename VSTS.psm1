function Invoke-VstsEndpoint {
    param([Parameter(Mandatory=$true)]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
          [Parameter(Mandatory=$true)]$Token, 
          [Hashtable]$QueryStringParameters, 
          $Project,
          [Uri]$Path, 
          $ApiVersion='1.0', 
          [ValidateSet('Get', 'PUT', 'POST', 'DELETE')]$Method='GET')

    $queryString = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
   
    if ($QueryStringParameters -ne $null)
    {
        foreach($parameter in $QueryStringParameters.GetEnumerator())
        {
            $queryString[$parameter.Key] = $parameter.Value
        }
    }

    $queryString["api-version"] = $ApiVersion
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

function New-VstsProject 
{
	<#
		.SYNOPSIS
			Creates a new project in a VSTS account
	#>
	param(
	[Parameter(Mandatory)]$AccountName, 
	[Parameter(Mandatory)]$User, 
	[Parameter(Mandatory)]$Token, 
	[Parameter(Mandatory)]$Name, 
	[Parameter()]$Description, 
	[Parameter()][ValidateSet('Git')]$SourceControlType = 'Git',
	[Parameter()]$TemplateTypeId = '6b724908-ef14-45cf-84f8-768b5384da45')

    $authorization = Get-VstsAuthorization -User $user -Token $token

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

    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects?api-version=1.0" -Method POST -ContentType 'application/json' -Headers @{Authorization=$authorization} -Body $Body
}

function Remove-VSTSProject {
	<#
		.SYNOPSIS 
			Deletes a project from the specified VSTS account.
	#>
	param(
		[Parameter(Mandatory)]$AccountName, 
		[Parameter(Mandatory)]$User, 
		[Parameter(Mandatory)]$Token, 
		[Parameter(Mandatory)]$Name)

		$Id = Get-VstsProject -AccountName $AccountName -User $User -Token $Token | Where Name -EQ $Name | Select -ExpandProperty Id

		if ($Id -eq $null)
		{
			throw "Project $Name not found in $AccountName."
		}
		
		$authorization = Get-VstsAuthorization -User $user -Token $token

		Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/_apis/projects/$($Id)?api-version=1.0" -Method DELETE -Headers @{Authorization=$authorization}
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

function Get-VstsCodePolicy {
    <#
        .SYNOPSIS
            Get code policies for the specified project. 
    #>

    param([Parameter(Mandatory=$true)]$AccountName, 
              [Parameter(Mandatory=$true)]$User, 
              [Parameter(Mandatory=$true)]$Token, 
              [Parameter(Mandatory=$true)]$Project)
			  
     $Result = Invoke-VstsEndpoint -AccountName $AccountName -User $User -Token $Token -Project $Project -Path 'policy/configurations' -ApiVersion '2.0-preview.1'
     $Result.Value     
}

function New-VstsCodePolicy {
    <#
        .SYNOPSIS
            Creates a new Code Policy configuration for the specified project.
    #>

    param([Parameter(Mandatory=$true)]$AccountName, 
                  [Parameter(Mandatory=$true)]$User, 
                  [Parameter(Mandatory=$true)]$Token, 
                  [Parameter(Mandatory=$true)]$Project,
                  [Guid]$RepositoryId = [Guid]::Empty,
                  [int]$MinimumReviewers,
                  [string[]]$Branches)

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

    $authorization = Get-VstsAuthorization -User $user -Token $token

    Invoke-RestMethod "https://$AccountName.visualstudio.com/DefaultCollection/$Project/_apis/policy/configurations/?api-version=2.0-preview.1" -Method POST -ContentType 'application/json' -Headers @{Authorization=$authorization} -Body $Policy
}

function Get-VstsBuildDefinition {
	<#
        .SYNOPSIS
            Gets build definitions for the specified project.
    #>

	param([Parameter(Mandatory=$true)]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
		  [Parameter(Mandatory=$true)]$Token,
	      [Parameter(Mandatory=$true)]$Project)

	 $Result = Invoke-VstsEndpoint -AccountName $AccountName -User $User -Token $Token -Project $Project -Path 'build/definitions' -ApiVersion 2.0
     $Result.Value              
}

function New-VstsBuildDefinition {
	<#
        .SYNOPSIS
            Gets build definitions for the specified project.
    #>

	param([Parameter(Mandatory=$true)]$AccountName, 
        [Parameter(Mandatory=$true)]$User, 
		[Parameter(Mandatory=$true)]$Token,
	    [Parameter(Mandatory=$true)]$Project,
		[Parameter(Mandatory=$true)]$Name,
		[Parameter()]$DisplayName = $Name,
		[Parameter(Mandatory=$true)]$QueueId
	)

	@{
	  name =  $Name
	  type = "build"
	  quality = "definition"
	  queue = @{
		id = $QueueId
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
        "platform" = "$(platform)"
        "configuration"= "$(config)"
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
    "id" = "278d5cd2-584d-4b63-824a-2ba458937249"
    "type" = "tfsgit"
    "name" = "Fabrikam-Fiber-Git"
    "localPath" = "$(sys.sourceFolder)/MyGitProject"
    "defaultBranch" ="refs/heads/master"
    "url" = "https://fabrikam-fiber-inc.visualstudio.com/DefaultCollection/_git/Fabrikam-Fiber-Git"
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
  "comment" = "my first definition"
}
}

function Get-VstsBuildQueue {
	<#
        .SYNOPSIS
            Gets build definitions for the collection.
    #>

	param([Parameter(Mandatory=$true)]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
          [Parameter(Mandatory=$true)]$Token)

	 $Result = Invoke-VstsEndpoint -AccountName $AccountName -User $User -Token $Token -Path 'build/queues' -ApiVersion 2.0
     $Result.Value   
}