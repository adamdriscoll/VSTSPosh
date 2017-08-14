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

    }
}

Describe 'Projects' -Tags 'Integration' {
    $Script:Session = New-VSTSSession -AccountName $account -User $userName -Token $token

    Context "Project doesn't exist" {
        Context 'Using session object' {
            Context 'Using no parameters' {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    Session = $Script:Session
                    Name    = $projectName
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                }

                It "Should wait for new project '$projectName' to be WellFormed" {
                    {
                        Wait-VSTSProject @parameterDetails `
                            -Exists `
                            -State 'WellFormed' `
                            -Attempts 50 `
                            -RetryIntervalSec 5
                    } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                }
            }

            Context "Using template name 'Scrum'" {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    Session = $Script:Session
                    Name    = $projectName
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -TemplateTypeName 'Scrum' -Verbose } | Should Not Throw
                }

                It "Should wait for new project '$projectName' to be WellFormed" {
                    {
                        Wait-VSTSProject @parameterDetails `
                            -Exists `
                            -State 'WellFormed' `
                            -Attempts 50 `
                            -RetryIntervalSec 5
                    } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                }
            }
        }

        Context 'Using account details' {
            Context 'Using no parameters' {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    AccountName = $account
                    User        = $userName
                    Token       = $Token
                    Name        = $projectName
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                }

                It "Should wait for new project '$projectName' to be WellFormed" {
                    {
                        Wait-VSTSProject @parameterDetails `
                            -Exists `
                            -State 'WellFormed' `
                            -Attempts 50 `
                            -RetryIntervalSec 5
                    } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                }
            }

            Context "Using template name 'Scrum'" {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    AccountName = $account
                    User        = $userName
                    Token       = $Token
                    Name        = $projectName
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -TemplateTypeName 'Scrum' -Verbose } | Should Not Throw
                }

                It "Should wait for new project '$projectName' to be WellFormed" {
                    {
                        Wait-VSTSProject @parameterDetails `
                            -Exists `
                            -State 'WellFormed' `
                            -Attempts 50 `
                            -RetryIntervalSec 5
                    } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails -Verbose } | Should Not Throw
                }
            }

        }
    }

    Context 'Process' {
        Context 'Using session object' {
            $parameterDetails = @{
                Session = $Script:Session
                Verbose = $True
            }

            It 'Should returns default process templates' {
                { $script:Result = Get-VstsProcess @parameterDetails } | Should Not Throw
                $script:Result | Where-Object -Property Name -EQ 'Agile' | Should Not BeNullOrEmpty
                $script:Result | Where-Object -Property Name -EQ 'CMMI' | Should Not BeNullOrEmpty
                $script:Result | Where-Object -Property Name -EQ 'Scrum' | Should Not BeNullOrEmpty
            }
        }

        Context 'Using account details' {
            $parameterDetails = @{
                AccountName = $account
                User        = $userName
                Token       = $Token
                Verbose     = $True
            }

            It 'Should returns default process templates' {
                { $script:Result = Get-VstsProcess @parameterDetails } | Should Not Throw
                $script:Result | Where-Object -Property Name -EQ 'Agile' | Should Not BeNullOrEmpty
                $script:Result | Where-Object -Property Name -EQ 'CMMI' | Should Not BeNullOrEmpty
                $script:Result | Where-Object -Property Name -EQ 'Scrum' | Should Not BeNullOrEmpty
            }
        }

    }
}
