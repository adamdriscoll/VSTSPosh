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

# Always run unit tests first (test pyramid)
$unitTestResultsPath = (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'TestsResults.Unit.xml')
$result = Invoke-Pester `
    -Path (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'Tests') `
    -OutputFormat NUnitXml `
    -OutputFile $unitTestResultsPath  `
    -PassThru `
    -Tag Unit `
    -CodeCoverage @(
        (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath '*.psm1')
        (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'lib\*.ps1')
    )

if ($env:APPVEYOR -eq $true)
{
    Write-Verbose -Message 'Uploading Unit Test results to AppVeyor...' -Verbose
    (New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $unitTestResultsPath)

    # Upload code coverage (only for unit tests)
    if ($result.CodeCoverage)
    {
        Write-Verbose -Message 'Uploading CodeCoverage to CodeCov.io...' -Verbose
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CodeCovIo.psd1')
        $jsonPath = Export-CodeCovIoJson -CodeCoverage $result.CodeCoverage -repoRoot $env:APPVEYOR_BUILD_FOLDER
        Invoke-UploadCoveCoveIoReport -Path $jsonPath
    }
    else
    {
        Write-Warning -Message 'Could not create CodeCov.io report because pester results object did not contain a CodeCoverage object'
    }
}

if ($result.FailedCount -gt 0)
{
    throw "$($result.FailedCount) unit tests failed."
}

# Run integration tests if not a PR or if run manually
if ($null -eq $env:APPVEYOR_PULL_REQUEST_NUMBER)
{
    $integrationTestResultsPath = (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'TestsResults.Integration.xml')
    $result = Invoke-Pester `
        -Path (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'Tests') `
        -OutputFormat NUnitXml `
        -OutputFile $integrationTestResultsPath `
        -PassThru `
        -Tag Integration

    if ($env:APPVEYOR -eq $true)
    {
        Write-Verbose -Message 'Uploading Integration Test results to AppVeyor...' -Verbose
        (New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $integrationTestResultsPath)
    }

    if ($result.FailedCount -gt 0)
    {
        throw "$($result.FailedCount) integration tests failed."
    }
}

