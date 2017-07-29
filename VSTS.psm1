# System.Web is not always loaded by default, so ensure it is loaded.
Add-Type -AssemblyName System.Web

function New-VstsSession {
	param([Parameter()]$AccountName, 
          [Parameter(Mandatory=$true)]$User, 
          [Parameter(Mandatory=$true)]$Token,
		  [Parameter()][string]$Collection = 'DefaultCollection',
		  [Parameter()][string]$Server = 'visualstudio.com',
		  [Parameter()][ValidateSet('HTTP', 'HTTPS')]$Scheme = 'HTTPS'
		  )

	[PSCustomObject]@{
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
		Invokes the VSTS REST API endpoint.

	.PARAMETER EndpointName
		Set an alternate VSTS endpoint to call.
		This is required by API calls for to preview APIs that are not
		yet available on the primary endpoint.

	.PARAMETER Top
		This will add the cause the '$top' parameter to the querystring
#>
function Invoke-VstsEndpoint {
    param(
		  [Parameter(Mandatory=$true)]$Session,
		  [Hashtable]$QueryStringParameters,
		  [string]$Project,
          [Uri]$Path, 
          [string]$ApiVersion='1.0', 
          [ValidateSet('GET', 'PUT', 'POST', 'DELETE', 'PATCH')]$Method='GET',
		  [string]$Body,
		  [string]$EndpointName,
  		  [Hashtable]$QueryStringExtParameters
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
	$queryString = $queryString.ToString();

	$authorization = Get-VstsAuthorization -User $Session.User -Token $Session.Token
	if ([String]::IsNullOrEmpty($Session.AccountName))
	{
		$UriBuilder = New-Object System.UriBuilder -ArgumentList "$($Session.Scheme)://$($Session.Server)"
	}
	else
	{
		if ([String]::IsNullOrEmpty($EndpointName))
		{
			$UriBuilder = New-Object System.UriBuilder -ArgumentList "$($Session.Scheme)://$($Session.AccountName).visualstudio.com"
		}
		else
		{
			$UriBuilder = New-Object System.UriBuilder -ArgumentList "$($Session.Scheme)://$($Session.AccountName).$EndpointName.visualstudio.com"
		}
	}
	$Collection = $Session.Collection
	
    $UriBuilder.Query = $queryString
    if ([String]::IsNullOrEmpty($Project))
    {
        $UriBuilder.Path = "$Collection/_apis/$Path"
    }
    else 
    {
        $UriBuilder.Path = "$Collection/$Project/_apis/$Path"
    }

    $Uri = $UriBuilder.Uri

    Write-Verbose "Invoke URI [$uri]"

	$ContentType = 'application/json'
	if ($Method -eq 'PUT' -or $Method -eq 'POST' -or $Method -eq 'PATCH')
	{
		if ($Method -eq 'PATCH')
		{
			$ContentType = 'application/json-patch+json'
		}

		$restResult = Invoke-RestMethod $Uri -Method $Method -ContentType $ContentType -Headers @{Authorization=$authorization} -Body $Body
	}
	else
	{
		$restResult = Invoke-RestMethod $Uri -Method $Method -ContentType $ContentType -Headers @{Authorization=$authorization} 
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
    param(
		[Parameter(Mandatory, ParameterSetname='Account')]$AccountName, 
		[Parameter(Mandatory, ParameterSetname='Account')]$User, 
		[Parameter(Mandatory, ParameterSetname='Account')]$Token, 
		[Parameter(Mandatory, ParameterSetname='Session')]$Session, 
		[string]$Name)
    
	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VSTSSession -AccountName $AccountName -User $User -Token $Token
	}

	$Value = Invoke-VstsEndpoint -Session $Session -Path 'projects' 

	if ($PSBoundParameters.ContainsKey("Name"))
	{
		$Value.Value | Where Name -eq $Name
	}
	else
	{
		$Value.Value 
	}
}

function Wait-VSTSProject {
	param([Parameter(Mandatory)]$Session, 
	      [Parameter(Mandatory)]$Name, 
		  $Attempts = 30, 
		  [Switch]$Exists)

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
		[Parameter(Mandatory)]
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

function ConvertTo-VstsGitRepository {
	<#
		.SYNOPSIS
			Converts a TFVC repository to a VSTS Git repository. 
	#>
    param(
		[Parameter(Mandatory)]$Session,
		[Parameter(Mandatory)]$TargetName, 
		[Parameter(Mandatory)]$SourceFolder, 
		[Parameter(Mandatory)]$ProjectName)

	$GitCommand = Get-Command git 
	if ($GitCommand -eq $null -or $GitCommand.CommandType -ne 'Application' -or $GitCommand.Name -ne 'git.exe')
	{
		throw "Git-tfs needs to be installed to use this command. See https://github.com/git-tfs/git-tfs. You can install with Chocolatey: cinst gittfs"
	}

	$GitTfsCommand = Get-Command git-tfs 
	if ($GitTfsCommand -eq $null -or $GitTfsCommand.CommandType -ne 'Application' -or $GitTfsCommand.Name -ne 'git-tfs.exe')
	{
		throw "Git-tfs needs to be installed to use this command. See https://github.com/git-tfs/git-tfs. You can install with Chocolatey: cinst gittfs"
	}

    git tfs clone "https://$($Session.AccountName).visualstudio.com/defaultcollection" "$/$ProjectName/$SourceFolder" --branches=none

    Push-Location (Split-Path $SourceFolder -Leaf)

    New-VstsGitRepository -Session $Session -RepositoryName $TargetName -Project $ProjectName | Out-Null

    git checkout -b develop
    git remote add origin https://$($Session.AccountName).visualstudio.com/DefaultCollection/$ProjectName/_git/$TargetName
    git push --all origin
    git tfs cleanup

    Pop-Location
	Remove-Item (Split-Path $SourceFolder -Leaf) -Force
}

<#
	.SYNOPSIS
		Gets team project build artifacts.
#>
function Get-VstsBuildArtifact {

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

function Get-VstsReleaseDefinition {
    <#
        .SYNOPSIS
            Gets team project release definitions.
    #>

	param
	(
		[Parameter(Mandatory)]
		$Session,
		[Parameter(Mandatory)]
		$Project,
		[Int32] $Id
	)

	$Path = 'release/definitions'
	if ($PSBoundParameters.ContainsKey('Id')) {
		$Path = ('{0}/{1}' -f $Path, $Id)
	}

	$Result = Invoke-VstsEndpoint -Session $Session -Path $Path -Project $Project -ApiVersion '3.0-preview.2' -EndpointName 'vsrm'
	
	if ($Result.Value) {
		$Result.Value
	}
	else 
	{
		$Result
	}
}

<#
	.SYNOPSIS
		Gets team project release definitions.

	.PARAMETER Session
		The session object created by New-VstsSession.

	.PARAMETER Project
		The name of the project to create the new release in.

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

	$Path = 'release/releases'
	$additionalInvokeParameters = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Query')
	{
		$additionalInvokeParameters = @{
			QueryStringParameters = (Get-VSTSQueryStringParametersFromParams `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'DefinitionId','CreatedBy','StatusFilter','QueryOrder')
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
		-User 'joe.bloggs@outlook.com' `
		-Token 'hiwpxk5usaag6jslczsfbqmlkngvhr3czqyh65jdvlvtt3qkh4ya'

	Get-VstsBuild `
		-Session $vstsSession `

	New-VstsRelease `
		-Session $vstsSession `
		-Project 'pipeline' -verbose -DefinitionId 2 -Description 'Test from API' -Artifacts @( @{ Alias = 'WebApp-Master'; instanceReference = @{ id = 2217 } } )
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
	Helper function that takes an array of parameters
	and an array of parameter names and creates a hash
	table containing each parameter that appears in the
	list.
#>
function Get-VSTSQueryStringParametersFromParams {
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
