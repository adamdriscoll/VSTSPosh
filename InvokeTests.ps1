$repoPath = $PSScriptRoot

if ($PSVersionTable.PSVersion.Major -ge 5)
{
    Write-Verbose -Message 'Installing PSScriptAnalyzer' -Verbose
    $PSScriptAnalyzerModuleName = 'PSScriptAnalyzer'
    $PSScriptAnalyzerModule = Get-Module -Name $PSScriptAnalyzerModuleName -ListAvailable
    if (-not $PSScriptAnalyzerModule)
    {
        Install-PackageProvider -Name NuGet -Force
        Install-Module -Name $PSScriptAnalyzerModuleName -Scope CurrentUser -Force
        $PSScriptAnalyzerModule = Get-Module -Name $PSScriptAnalyzerModuleName -ListAvailable

        if ($PSScriptAnalyzerModule)
        {
            # Import the module if it is available
            $PSScriptAnalyzerModule | Import-Module -Force
        }
        else
        {
            # Module could not/would not be installed - so warn user that tests will fail.
            Write-Warning -Message ( @(
                    "The 'PSScriptAnalyzer' module is not installed. "
                    "The 'PowerShell modules scriptanalyzer' Pester test will fail."
                ) -Join '' )
        }
    }
}
else
{
    Write-Warning -Message ( @(
            "Skipping installation of 'PSScriptAnalyzer' since it requires "
            "PSVersion 5.0 or greater. Found PSVersion: $($PSVersionTable.PSVersion.Major)"
        ) -Join '' )
}

# Always run unit tests first
$result = Invoke-Pester `
    -Path (Join-Path -Path $repoPath -ChildPath 'Tests') `
    -OutputFormat NUnitXml `
    -OutputFile (Join-Path -Path $repoPath -ChildPath 'TestsResults.Unit.xml')  `
    -PassThru `
    -Tag Unit

if ($env:APPVEYOR -eq $true)
{
    (New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Join-Path -Path $repoPath -ChildPath 'TestsResults.Unit.xml'))
}

if ($result.FailedCount -gt 0)
{
    throw "$($result.FailedCount) unit tests failed."
}

# Run integration tests if not a PR or if run manually
if ($null -eq $env:APPVEYOR_PULL_REQUEST_NUMBER)
{
    $result = Invoke-Pester `
        -Path (Join-Path -Path $repoPath -ChildPath 'Tests') `
        -OutputFormat NUnitXml `
        -OutputFile (Join-Path -Path $repoPath -ChildPath 'TestsResults.Integration.xml') `
        -PassThru `
        -Tag Integration `
        -CodeCoverage @(
            (Join-Path -Path $repoPath -ChildPath '*.psm1')
            (Join-Path -Path $repoPath -ChildPath 'lib\*.ps1')
        )

    if ($env:APPVEYOR -eq $true)
    {
        (New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Join-Path -Path $repoPath -ChildPath 'TestsResults.Integration.xml'))
    }

    if ($result.FailedCount -gt 0)
    {
        throw "$($result.FailedCount) integration tests failed."
    }
}
