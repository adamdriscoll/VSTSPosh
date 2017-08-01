<#
	.SYNOPSIS
	Get projects in a VSTS account.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to return.

	.PARAMETER StateFilter
	If specified will return all projects matching this state.

	.PARAMETER Top
	Restrict the number of projects to be returned.

	.PARAMETER Skip
	Do not return the first 'skip' number of projects.
#>
function Get-VstsProject
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
		[String] $Name,

		[Parameter()]
		[ValidateSet('WellFormed', 'CreatePending', 'Deleting', 'New', 'All')]
		[String] $StateFilter,

		[Parameter()]
		[Int32] $Top,

		[Parameter()]
		[Int32] $Skip
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = 'projects'
	$additionalInvokeParameters = @{}

	if ($PSBoundParameters.ContainsKey('Name'))
	{
		$path = ('{0}/{1}' -f $path, $Name)
	}
	else
	{
		$additionalInvokeParameters = @{
			QueryStringParameters    = (Get-VstsQueryStringParametersFromBound `
					-BoundParameters $PSBoundParameters `
					-ParameterList 'stateFilter')
			QueryStringExtParameters = Get-VstsQueryStringParametersFromBound `
				-BoundParameters $PSBoundParameters `
				-ParameterList 'Top', 'Skip'
		}
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		@additionalInvokeParameters

	return $result.Value
}

<#
	.SYNOPSIS
	Wait for a project to be created or deleted.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to wait for.

	.PARAMETER Attempts
	The number of attempts to make when waiting for the project.

	.PARAMETER Exists
	Specifies if the cmdlet will wait for the project to exist
	or be absent (e.g. if being deleted).

	.PARAMETER RetryIntervalSec
	The number of seconds to wait between each check for the
	project.

	.PARAMETER State
	Specifies if the cmdlet will wait for the project to enter
	a specific state. This only applies if the Exists switch is
	enabled.
#>
function Wait-VSTSProject
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
		[String] $Name,

		[Parameter()]
		[Int32] $Attempts = 30,

		[Parameter()]
		[Switch] $Exists,

		[Parameter()]
		[Int32] $RetryIntervalSec = 2,

		[Parameter()]
		[ValidateSet('WellFormed', 'CreatePending', 'Deleting', 'New', 'All')]
		[String] $State
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	if ($Exists)
	{
		$existsMessage = 'exists'
	}
	else
	{
		$existsMessage = 'does not exist'
	}

	$retries = 0
	do
	{
		# Takes a few seconds for the project to be created
		Start-Sleep -Seconds $RetryIntervalSec

		Write-Verbose -Message ('Checking project {0} {1}' -f $Name, $existsMessage)
		$project = Get-VSTSProject `
			-Session $Session `
			-Name $Name `
			-ErrorAction SilentlyContinue

		# If waiting for project to exist and state specified then wait for it to match state
		if ($Exists -and $PSBoundParameters.ContainsKey('State') -and $project.State -ne $State)
		{
			Write-Verbose -Message ('Project exists but state is {0} and not {1}' -f $project.State, $State)
			$project = $null
		}

		$retries++
	} while ((($null -eq $project -and $Exists) -or ($null -ne $project -and -not $Exists)) -and $retries -le $Attempts)

	if (($null -eq $project -and $Exists) -or ($null -ne $project -and -not $Exists) )
	{
		throw ('Project {0} {1}' -f $Name, $existsMessage)
	}
}

<#
	.SYNOPSIS
	Creates a new project in a VSTS account.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to create.

	.PARAMETER Description
	The description of the project to create.

	.PARAMETER SourceControlType
	The type of source control system to use.
	Defaults to 'Git'.

	.PARAMETER TemplateTypeId
	The template type Id for the type of work item management
	to use for the project.

	.PARAMETER TemplateTypeName
	The template type Name for the type of work item management
	to use for the project.

	.PARAMETER Wait
	Switch to cause the cmdlet to wait for the project to be
	created before returning.
#>
function New-VstsProject
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
		[String] $Name,

		[Parameter()]
		[String] $Description,

		[Parameter()]
		[ValidateSet('Git', 'Tfvc')]
		[String] $SourceControlType = 'Git',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[String] $TemplateTypeId,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[String] $TemplateTypeName = 'Agile',

		[Parameter()]
		[Switch] $Wait
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = 'projects'

	if ([String]::IsNullOrEmpty($TemplateTypeId))
	{
		Write-Verbose -Message ('Getting template Id for process {0}' -f $templateTypeName)

		$templateTypeId = Get-VstsProcess -Session $Session |
			Where-Object -Property Name -EQ $TemplateTypeName |
			Select-Object -ExpandProperty Id

		if ($null -eq $templateTypeId)
		{
			throw "Template $TemplateTypeName not found."
		}

		Write-Verbose -Message ('Template Id {0} found for process {1}' -f $templateTypeId, $templateTypeName)
	}

	$body = @{
		name         = $Name
		description  = $Description
		capabilities = @{
			versioncontrol  = @{
				sourceControlType = $SourceControlType
			}
			processTemplate = @{
				templateTypeId = $templateTypeId
			}
		}
	} | ConvertTo-Json

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		-Method 'POST' `
		-Body $body `
		-ErrorAction Stop

	if ($Wait)
	{
		Write-Verbose -Message ('Waiting for project {0} to be created' -f $Name)
		Wait-VSTSProject -Session $Session -Name $Name -Exists -State WellFormed
	}

	return $result.Value
}

<#
	.SYNOPSIS
	Deletes a project from the specified VSTS account.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Name
	The name of the project to delete.

	.PARAMETER Wait
	Switch to cause the cmdlet to wait for the project to be
	deleted before returning.
#>
function Remove-VSTSProject
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
		[String] $Name,

		[Parameter()]
		[Switch] $Wait
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$projectId = (Get-VstsProject -Session $Session -Name $Name).Id

	if ($null -eq $projectId)
	{
		throw "Project $Name not found."
	}

	$path = ('projects/{0}' -f $projectId)

	Write-Verbose -Message ('Removing project Id {0}' -f $projectId)
	$null = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path `
		-Method 'DELETE'

	if ($Wait)
	{
		Write-Verbose -Message ('Waiting for project {0} to be deleted' -f $Name)
		Wait-VSTSProject -Session $Session -Name $Name
	}
}

<#
	.SYNOPSIS
	Gets available team processes.

	.PARAMETER AccountName
	The name of the VSTS account to use.

	.PARAMETER User
	This user name to authenticate to VSTS.

	.PARAMETER Token
	This personal access token to use to authenticate to VSTS.

	.PARAMETER Session
	The session object created by New-VstsSession.

	.PARAMETER Id
	The process Id of the process to return. This is a Guid.
#>
function Get-VstsProcess
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
		[String] $Id
	)

	if ($PSCmdlet.ParameterSetName -eq 'Account')
	{
		$Session = New-VstsSession -AccountName $AccountName -User $User -Token $Token
	}

	$path = 'process/processes'

	if ($PSBoundParameters.ContainsKey('Id'))
	{
		$path = ('{0}/{1}' -f $path, $Id)
	}

	$result = Invoke-VstsEndpoint `
		-Session $Session `
		-Path $path

	return $result.Value
}
