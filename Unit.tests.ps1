Describe "VSTS" -Tags Unit {
    Context 'PSScriptAnalyzer' {
        It "passes Invoke-ScriptAnalyzer" {

            # Perform PSScriptAnalyzer scan.
            # Using ErrorAction SilentlyContinue not to cause it to fail due to parse errors caused by unresolved resources.
            # Many of our examples try to import different modules which may not be present on the machine and PSScriptAnalyzer throws parse exceptions even though examples are valid.
            # Errors will still be returned as expected.
            $PSScriptAnalyzerErrors = Invoke-ScriptAnalyzer -path $PSSCriptRoot -Severity Error -Recurse -ErrorAction SilentlyContinue
            if ($PSScriptAnalyzerErrors -ne $null) {
                Write-Error "There are PSScriptAnalyzer errors that need to be fixed:`n $PSScriptAnalyzerErrors"
                Write-Error "For instructions on how to run PSScriptAnalyzer on your own machine, please go to https://github.com/powershell/psscriptAnalyzer/"
                $PSScriptAnalyzerErrors.Count | Should Be $null
            }
        }     
    }
}