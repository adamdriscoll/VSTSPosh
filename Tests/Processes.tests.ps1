$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount 

function New-ProjectName {
	[Guid]::NewGuid().ToString().Replace('-','').Substring(10)
}

Import-Module (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force
t 
Describe "Processes" -Tags "Integration" {
	$ProjectName = New-ProjectName
	$Session = New-VSTSSession -AccountName $Account -User $userName -Token $token
	New-VSTSProject -Session $Session -Name $ProjectName -Wait

	Context "Has default process templates" {		
 		It "Returns default process template" {		
 			$Process = Get-VstsProcess -Session $Session | Where Name -EQ 'Agile'		
 			$Process | Should not be $null		
 					
 			$Process = Get-VstsProcess -Session $Session | Where Name -EQ 'CMMI'		
 			$Process | Should not be $null		
 		
 			$Process = Get-VstsProcess -Session $Session | Where Name -EQ 'SCRUM'		
 			$Process | Should not be $null		
 		}		
 	}

	Remove-VSTSProject -Session $Session -Name $ProjectName
}