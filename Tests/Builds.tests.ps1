$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName
{
    [Guid]::NewGuid().ToString().Replace('-', '').Substring(10)
}

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath 'VSTS.psm1'
Import-Module -Name $modulePath -Force

Describe 'Builds' -Tags 'Unit' {
    InModuleScope -ModuleName VSTS {
        # All unit tests run in VSTS module scope

        # Prep mock objects and parameters
        $testAccountName = 'testAccount'
        $testUser = 'testUser'
        $testToken = 'testToken'
        $testCollection = 'DefaultCollection'
        $testServer = 'visualstudio.com'
        $testScheme = 'HTTPS'

        $testSessionObject = [PSCustomObject] @{
            AccountName = $testAccountName
            User        = $testUser
            Token       = $testToken
            Collection  = $testCollection
            Server      = $testServer
            Scheme      = $testScheme
        }

        $testSessionParameters = @{
            Session = $testSessionObject
            Verbose = $True
        }

        $testAccountParameters = @{
            AccountName = $testAccountName
            User        = $testUser
            Token       = $testToken
            Verbose     = $True
        }

        $testProject = 'testProject'
        $testDefinitionId = 1
        $testDefinitionName = 'testDefinition'

        $mockReturnOKString = 'Result OK'
        $mockReturnOKObject = [psobject] @{
            Value = $mockReturnOKString
        }

        Context 'Test Get-VstsBuildDefinition' {
            Context 'Id not passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Project -eq $testProject -and `
                            $Path -eq 'build/definitions'
                        } `
                        -MockWith { $mockReturnOKObject }
                }

                Context 'Session Object passed' {
                    $getVstsBuildDefinitionParameters = $testSessionParameters.Clone()
                    $getVstsBuildDefinitionParameters += @{
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsBuildDefinitionResult = Get-VstsBuildDefinition @getVstsBuildDefinitionParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsBuildDefinitionResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $getVstsBuildDefinitionParameters = $testAccountParameters.Clone()
                    $getVstsBuildDefinitionParameters += @{
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsBuildDefinitionResult = Get-VstsBuildDefinition @getVstsBuildDefinitionParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsBuildDefinitionResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }

            Context 'Id passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Project -eq $testProject -and `
                            $Path -eq ('build/definitions/{0}' -f $testDefinitionId)
                        } `
                        -MockWith { $mockReturnOKObject }
                }

                Context 'Session Object passed' {
                    $getVstsBuildDefinitionParameters = $testSessionParameters.Clone()
                    $getVstsBuildDefinitionParameters += @{
                        Id = $testDefinitionId
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsBuildDefinitionResult = Get-VstsBuildDefinition @getVstsBuildDefinitionParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsBuildDefinitionResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $getVstsBuildDefinitionParameters = $testAccountParameters.Clone()
                    $getVstsBuildDefinitionParameters += @{
                        Id = $testDefinitionId
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsBuildDefinitionResult = Get-VstsBuildDefinition @getVstsBuildDefinitionParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsBuildDefinitionResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }

            Context 'Id not passed, Name and Top passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Project -eq $testProject -and `
                            $Path -eq 'build/definitions' -and `
                            $QueryStringParameters['name'] -eq $testDefinitionName -and `
                            $QueryStringExtParameters['top'] -eq 1
                        } `
                        -MockWith { $mockReturnOKObject }
                }

                Context 'Session Object passed' {
                    $getVstsBuildDefinitionParameters = $testSessionParameters.Clone()
                    $getVstsBuildDefinitionParameters += @{
                        Name = $testDefinitionName
                        Top = 1
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsBuildDefinitionResult = Get-VstsBuildDefinition @getVstsBuildDefinitionParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsBuildDefinitionResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $getVstsBuildDefinitionParameters = $testAccountParameters.Clone()
                    $getVstsBuildDefinitionParameters += @{
                        Name = $testDefinitionName
                        Top = 1
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsBuildDefinitionResult = Get-VstsBuildDefinition @getVstsBuildDefinitionParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsBuildDefinitionResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }
        }
    }
}

Describe 'Builds' -Tags 'Integration' {
    BeforeAll {
        $projectName = New-ProjectName
        $session = New-VSTSSession -AccountName $account -User $userName -Token $token
        Write-Verbose -Verbose -Message ('Creating VSTS test project {0}' -f $projectName)
        New-VSTSProject -Session $session -Name $projectName
        Wait-VSTSProject -Session $session -Name $projectName -Exists -State 'WellFormed' -Attempts 50 -RetryIntervalSec 5
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
