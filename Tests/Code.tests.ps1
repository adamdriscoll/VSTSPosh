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
        $testRepositoryId = [Guid]::NewGuid().Guid

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
                        Project    = $testProject
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
                        Project    = $testProject
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

        Context 'Test Remove-VstsGitRepository' {
            Context 'Both Project and Repository Id passed' {
                Context 'Session Object passed' {
                    $removeVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Project    = $testProject
                        Repository = $testRepositoryId
                    }

                    It 'Should throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Throw 'If repository Id is passed then Project should not be passed.'
                    }
                }

                Context 'Account Details passed' {
                    $removeVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Project    = $testProject
                        Repository = $testRepositoryId
                    }

                    It 'Should throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Throw 'If repository Id is passed then Project should not be passed.'
                    }
                }
            }

            Context 'Repository Id passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Path -eq ('git/repositories/{0}' -f $testRepositoryId) -and `
                            $Method -eq 'DELETE'
                        }
                }

                Context 'Session Object passed' {
                    $removeVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Repository = $testRepositoryId
                    }

                    It 'Should not throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $removeVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Repository = $testRepositoryId
                    }

                    It 'Should not throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                    }
                }
            }

            Context 'Repository and Project passed' {
                BeforeEach {
                    Mock `
                        -CommandName Invoke-VstsEndpoint `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Path -eq ('git/repositories/{0}' -f $testRepositoryId) -and `
                            $Method -eq 'DELETE'
                        }

                    Mock `
                        -CommandName Get-VstsGitRepository `
                        -ParameterFilter {
                            $Session.AccountName -eq $testSessionObject.AccountName -and `
                            $Session.User -eq $testSessionObject.User -and `
                            $Session.Token -eq $testSessionObject.Token -and `
                            $Project -eq $testProject -and `
                            $Repository -eq $testRepository
                        } `
                        -MockWith { @{ id = $testRepositoryId } }
                    }

                Context 'Session Object passed' {
                    $removeVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Project    = $testProject
                        Repository = $testRepository
                    }

                    It 'Should not throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-VstsGitRepository -Exactly -Times 1
                    }
                }

                Context 'Account Details passed' {
                    $removeVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Project    = $testProject
                        Repository = $testRepository
                    }

                    It 'Should not throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Not Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Invoke-VstsEndpoint -Exactly -Times 1
                        Assert-MockCalled -CommandName Get-VstsGitRepository -Exactly -Times 1
                    }
                }
            }

            Context 'Only Repository passed' {
                Context 'Session Object passed' {
                    $removeVstsGitRepositoryParameters = $testSessionParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Repository = $testRepository
                    }

                    It 'Should throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Throw 'If repository Name is passed then Project must be passed.'
                    }
                }

                Context 'Account Details passed' {
                    $removeVstsGitRepositoryParameters = $testAccountParameters.Clone()
                    $removeVstsGitRepositoryParameters += @{
                        Repository = $testRepository
                    }

                    It 'Should throw an exception' {
                        { $script:removeVstsGitRepositoryResult = Remove-VstsGitRepository @removeVstsGitRepositoryParameters } | Should Throw 'If repository Name is passed then Project must be passed.'
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
        New-VSTSProject -Session $session -Name $projectName
        Wait-VSTSProject -Session $session -Name $projectName -Exists -State 'WellFormed' -Attempts 50 -RetryIntervalSec 5
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
