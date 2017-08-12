$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName
{
    [Guid]::NewGuid().ToString().Replace('-', '').Substring(10)
}

Import-Module -Name (Join-Path $PSScriptRoot '..\VSTS.psm1') -Force

Describe 'Projects' -Tags 'Integration' {
    $Script:Session = New-VSTSSession -AccountName $account -User $userName -Token $token

    Context "Project doesn't exist" {
        Context 'Using session object' {
            Context 'Using no parameters' {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    Session = $Script:Session
                    Name    = $projectName
                    Verbose = $True
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -Wait } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails } | Should Not Throw
                }
            }

            Context "Using template name 'Scrum'" {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    Session = $Script:Session
                    Name    = $projectName
                    Verbose = $True
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -TemplateTypeName 'Scrum' -Wait } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails } | Should Not Throw
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
                    Verbose     = $True
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -Wait } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails } | Should Not Throw
                }
            }

            Context "Using template name 'Scrum'" {
                $projectName = New-ProjectName

                $parameterDetails = @{
                    AccountName = $account
                    User        = $userName
                    Token       = $Token
                    Name        = $projectName
                    Verbose     = $True
                }

                It "Should create a new project '$projectName'" {
                    { New-VSTSProject @parameterDetails -TemplateTypeName 'Scrum' -Wait } | Should Not Throw
                }

                It "Should return the new project '$projectName'" {
                    { $script:Result = Get-VSTSProject @parameterDetails } | Should Not Throw
                    $script:Result.Name | Should BeExactly $projectName
                }

                It "Should delete the new project '$projectName'" {
                    { Remove-VSTSProject @parameterDetails } | Should Not Throw
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
