$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName
{
    [Guid]::NewGuid().ToString().Replace('-', '').Substring(10)
}

Import-Module -Name (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe 'Builds' -Tags 'Integration' {
    BeforeAll {
        $projectName = New-ProjectName
        $session = New-VSTSSession -AccountName $account -User $userName -Token $token
        Write-Verbose -Verbose -Message ('Creating VSTS test project {0}' -f $projectName)
        New-VSTSProject -Session $session -Name $projectName -Wait
    }

    Context 'Has default build queues' {
        It 'Should return default build queues' {
            { $script:queue = Get-VstsBuildQueue -Session $session } | Should Not Throw
            $script:queue | Where-Object -Property Name -EQ 'Default' | Should Not BeNullOrEmpty
            $script:queue | Where-Object -Property Name -EQ 'Hosted' | Should Not BeNullOrEmpty
            $script:queue | Where-Object -Property Name -EQ 'Hosted Linux Preview' | Should Not BeNullOrEmpty
            $script:queue | Where-Object -Property Name -EQ 'Hosted VS2017' | Should Not BeNullOrEmpty
        }
    }

    AfterAll {
        Write-Verbose -Verbose -Message ('Deleting VSTS test project {0}' -f $projectName)
        Remove-VSTSProject -Session $session -Name $projectName
    }
}
