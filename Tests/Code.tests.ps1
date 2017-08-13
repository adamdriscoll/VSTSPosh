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

Describe 'Code' -Tags 'Unit' {
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
        $testRepository = 'testRepository'

        $mockReturnOKString = 'Result OK'
        $mockReturnOKObject = [psobject] @{
            Value = $mockReturnOKString
        }

        Context 'Test Get-VstsGitRepository' {
            Context 'Both Project and Repository passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Project -eq $testProject -and `
                            $Path -eq ('git/repositories/{0}' -f $testRepository)
                        } `
                        -MockWith { $mockReturnOKObject }
                }

                Context 'Session Object passed' {
                    $getVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $getVstsGitRepositoryParameters += @{
                        Project = $testProject
                        Repository = $testRepository
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsGitRepositoryResult = Get-VstsGitRepository @getVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsGitRepositoryResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $getVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $getVstsGitRepositoryParameters += @{
                        Project = $testProject
                        Repository = $testRepository
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsGitRepositoryResult = Get-VstsGitRepository @getVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsGitRepositoryResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }

            Context 'Only Project passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Project -eq $testProject -and `
                            $Path -eq 'git/repositories'
                        } `
                        -MockWith { $mockReturnOKObject }
                }

                Context 'Session Object passed' {
                    $getVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $getVstsGitRepositoryParameters += @{
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsGitRepositoryResult = Get-VstsGitRepository @getVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsGitRepositoryResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $getVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $getVstsGitRepositoryParameters += @{
                        Project = $testProject
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsGitRepositoryResult = Get-VstsGitRepository @getVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsGitRepositoryResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }

            Context 'Only repository passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Path -eq ('git/repositories/{0}' -f $testRepository)
                        } `
                        -MockWith { $mockReturnOKObject }
                }

                Context 'Session Object passed' {
                    $getVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $getVstsGitRepositoryParameters += @{
                        Repository = $testRepository
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsGitRepositoryResult = Get-VstsGitRepository @getVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsGitRepositoryResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $getVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $getVstsGitRepositoryParameters += @{
                        Repository = $testRepository
                    }

                    It 'Should not throw an exception' {
                        { $script:getVstsGitRepositoryResult = Get-VstsGitRepository @getVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should return expected object' {
                        $script:getVstsGitRepositoryResult | Should Be $mockReturnOKString
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }
        }
    }
}

Describe 'Code' -Tags 'Integration' {
    $testRepoName = 'TestRepo'

    BeforeAll {
        $projectName = New-ProjectName
        $session = New-VSTSSession -AccountName $account -User $userName -Token $token
        Write-Verbose -Verbose -Message ('Creating VSTS test project {0}' -f $projectName)
        New-VSTSProject -Session $session -Name $projectName -Wait
    }

    Context 'Create a repository, get the repository and remove the repository' {
        It 'Should create repository' {
            { $script:newRepo = New-VSTSGitRepository `
                    -Session $session `
                    -Project $projectName `
                    -RepositoryName $testRepoName `
                    -Verbose } | Should Not Throw
            $script:newRepo.Name | Should Be $testRepoName
        }

        It 'Should get the repository' {
            { $script:existingRepo = Get-VSTSGitRepository `
                    -Session $session `
                    -Project $projectName `
                    -Repository $testRepoName `
                    -Verbose } | Should Not Throw
            $script:existingRepo.Name | Should Be $testRepoName
        }

        It 'Should delete the repository' {
            { Remove-VSTSGitRepository `
                    -Session $session `
                    -Project $projectName `
                    -Repository $testRepoName `
                    -Verbose } | Should Not Throw
            { $script:existingRepo = Get-VSTSGitRepository `
                    -Session $session `
                    -Project $projectName `
                    -Repository $testRepoName `
                    -Verbose } | Should Throw
        }
    }

    AfterAll {
        Write-Verbose -Verbose -Message ('Deleting VSTS test project {0}' -f $projectName)
        Remove-VSTSProject -Session $session -Name $projectName
    }
}
