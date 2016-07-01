
if ($env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null)
{
    $res = Invoke-Pester -Path ".\" -OutputFormat NUnitXml -OutputFile TestsResults.xml -PassThru -Tag Integration
    (New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path .\TestsResults.xml))
    if ($res.FailedCount -gt 0) { 
        throw "$($res.FailedCount) integration tests failed."
    }
}

$res = Invoke-Pester -Path ".\" -OutputFormat NUnitXml -OutputFile TestsResults.xml -PassThru -Tag Unit
(New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path .\TestsResults.xml))
if ($res.FailedCount -gt 0) { 
	throw "$($res.FailedCount) unit tests failed."
}