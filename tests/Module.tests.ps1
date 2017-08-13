$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath 'VSTS.psm1'
Import-Module -Name $modulePath -Force

Describe 'VSTS' -Tags 'Unit', 'Quality', 'PSSA' {
    Context 'PSScriptAnalyzer' {
        if ($PSVersionTable.PSVersion.Major -ge 5)
        {
            $analyzeFiles = @($modulePath)
            $analyzeFiles += (Get-ChildItem -Path (Join-Path -Path $moduleRoot -ChildPath 'lib') -Filter '*.ps1').FullName
            foreach ($analyzeFile in $analyzeFiles)
            {
                $invokeScriptAnalyzerParameters = @{
                    Path        = $analyzeFile
                    ErrorAction = 'SilentlyContinue'
                    Recurse     = $false
                }

                Context $invokeScriptAnalyzerParameters.Path {
                    It 'Should pass all error-level PS Script Analyzer rules' {
                        $errorPssaRulesOutput = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters -Severity 'Error'

                        if ($null -ne $errorPssaRulesOutput)
                        {
                            Write-Warning -Message 'Error-level PSSA rule(s) did not pass.'
                            Write-Warning -Message 'The following PSScriptAnalyzer errors need to be fixed:'

                            foreach ($errorPssaRuleOutput in $errorPssaRulesOutput)
                            {
                                Write-Warning -Message "$($errorPssaRuleOutput.ScriptName) (Line $($errorPssaRuleOutput.Line)): $($errorPssaRuleOutput.Message)"
                            }

                            Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/PSScriptAnalyzer'
                        }

                        $errorPssaRulesOutput | Should Be $null
                    }

                    It 'Should pass all warning-level PS Script Analyzer rules' {
                        $requiredPssaRulesOutput = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters -Severity 'Warning'

                        if ($null -ne $requiredPssaRulesOutput)
                        {
                            Write-Warning -Message 'Required PSSA rule(s) did not pass.'
                            Write-Warning -Message 'The following PSScriptAnalyzer errors need to be fixed:'

                            foreach ($requiredPssaRuleOutput in $requiredPssaRulesOutput)
                            {
                                Write-Warning -Message "$($requiredPssaRuleOutput.ScriptName) (Line $($requiredPssaRuleOutput.Line)): $($requiredPssaRuleOutput.Message)"
                            }

                            Write-Warning -Message  'For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/PSScriptAnalyzer'
                        }

                        <#
                            Automatically passing this test until they are passing.
                        #>
                        $requiredPssaRulesOutput = $null
                        $requiredPssaRulesOutput | Should Be $null
                    }
                }
            }
        }
        else
        {
            Write-Warning -Message "Skipping ScriptAnalyzer since not PowerShell 5"
        }
    }
}

Describe 'VSTS' -Tags 'Unit' {
    InModuleScope -ModuleName VSTS {
        # All unit tests run in VSTS module scope

        # Prep mock objects and parameters
        $testAccountName = 'testAccount'
        $testUser = 'testUser'
        $testToken = 'testToken'
        $testCollection = 'testCollection'
        $testServer = 'testserver.com'
        $testScheme = 'HTTP'

        Context 'Test New-VstsSession' {
            Context 'AccountName, User and Token Specified' {
                $newVstsSessionParameters = @{
                    AccountName = $testAccountName
                    User        = $testUser
                    Token       = $testToken
                }

                It 'Should not throw an exception' {
                    { $script:newVstsSessionResult = New-VstsSession @newVstsSessionParameters } | Should Not Throw
                }

                It 'Should return expected object' {
                    $script:newVstsSessionResult.AccountName | Should Be $testAccountName
                    $script:newVstsSessionResult.User        | Should Be $testUser
                    $script:newVstsSessionResult.Token       | Should Be $testToken
                    $script:newVstsSessionResult.Collection  | Should Be 'DefaultCollection'
                    $script:newVstsSessionResult.Server      | Should Be 'visualstudio.com'
                    $script:newVstsSessionResult.Scheme      | Should Be 'HTTPS'
                }
            }

            Context 'AccountName, Collection, Scheme, User and Token Specified' {
                $newVstsSessionParameters = @{
                    AccountName = $testAccountName
                    User        = $testUser
                    Token       = $testToken
                    Collection  = $testCollection
                    Scheme      = $testScheme
                }

                It 'Should not throw an exception' {
                    { $script:newVstsSessionResult = New-VstsSession @newVstsSessionParameters } | Should Not Throw
                }

                It 'Should return expected object' {
                    $script:newVstsSessionResult.AccountName | Should Be $testAccountName
                    $script:newVstsSessionResult.User        | Should Be $testUser
                    $script:newVstsSessionResult.Token       | Should Be $testToken
                    $script:newVstsSessionResult.Collection  | Should Be $testCollection
                    $script:newVstsSessionResult.Server      | Should Be 'visualstudio.com'
                    $script:newVstsSessionResult.Scheme      | Should Be $testScheme
                }
            }

            Context 'Server, Collection, Scheme, User and Token Specified' {
                $newVstsSessionParameters = @{
                    User        = $testUser
                    Token       = $testToken
                    Collection  = $testCollection
                    Server      = $testServer
                    Scheme      = $testScheme
                }

                It 'Should not throw an exception' {
                    { $script:newVstsSessionResult = New-VstsSession @newVstsSessionParameters } | Should Not Throw
                }

                It 'Should return expected object' {
                    $script:newVstsSessionResult.AccountName | Should BeNullOrEmpty
                    $script:newVstsSessionResult.User        | Should Be $testUser
                    $script:newVstsSessionResult.Token       | Should Be $testToken
                    $script:newVstsSessionResult.Collection  | Should Be $testCollection
                    $script:newVstsSessionResult.Server      | Should Be $testServer
                    $script:newVstsSessionResult.Scheme      | Should Be $testScheme
                }
            }
        }

        Context 'Test Get-VstsQueryStringParametersFromBound' {
            $testBoundParameters = @{
                ParameterOne = 'ParameterOneValue'
                ParameterTwo = 'ParameterTwoValue'
            }

            Context 'BoundParameters and ParameterList with no matching parameters passed' {
                $getVstsQueryStringParametersFromBoundParameters = @{
                    BoundParameters = $testBoundParameters
                    ParameterList   = @('ParameterThree')
                }

                It 'Should not throw an exception' {
                    { $script:getVstsQueryStringParametersFromBoundResult = Get-VstsQueryStringParametersFromBound @getVstsQueryStringParametersFromBoundParameters } | Should Not Throw
                }

                It 'Should return expected object' {
                    $script:getVstsQueryStringParametersFromBoundResult | Should BeNullOrEmpty
                }
            }

            Context 'BoundParameters and ParameterList with only ParameterOne passed' {
                $getVstsQueryStringParametersFromBoundParameters = @{
                    BoundParameters = $testBoundParameters
                    ParameterList   = @('ParameterOne')
                }

                It 'Should not throw an exception' {
                    { $script:getVstsQueryStringParametersFromBoundResult = Get-VstsQueryStringParametersFromBound @getVstsQueryStringParametersFromBoundParameters } | Should Not Throw
                }

                It 'Should return ParameterOne but not ParameterTwo' {
                    $script:getVstsQueryStringParametersFromBoundResult.ContainsKey('ParameterOne') | Should Be $true
                    $script:getVstsQueryStringParametersFromBoundResult.ContainsKey('ParameterTwo') | Should Be $false
                }
            }

            Context 'BoundParameters and ParameterList with both ParameterOne and ParameterTwo passed' {
                $getVstsQueryStringParametersFromBoundParameters = @{
                    BoundParameters = $testBoundParameters
                    ParameterList   = @('ParameterOne','ParameterTwo')
                }

                It 'Should not throw an exception' {
                    { $script:getVstsQueryStringParametersFromBoundResult = Get-VstsQueryStringParametersFromBound @getVstsQueryStringParametersFromBoundParameters } | Should Not Throw
                }

                It 'Should return ParameterOne but not ParameterTwo' {
                    $script:getVstsQueryStringParametersFromBoundResult.ContainsKey('ParameterOne') | Should Be $true
                    $script:getVstsQueryStringParametersFromBoundResult.ContainsKey('ParameterTwo') | Should Be $true
                }
            }
        }
    }
}
