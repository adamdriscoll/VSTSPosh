# Change Log

## Unreleased

- Changelog.md:
  - Created
- Readme.md:
  - Fixed Markdown rule violations.
  - Added missing cmdlets.
- Get-VstsEndpointUri Cmdlet:
  - Added function to return the VSTS endpoint URI builder object.
- Get-VstsQueryStringParametersFromParams Cmdlet:
  - Added function to support additional parameters and queries.
- New-VstsSession Cmdlet:
  - Added documentation.
  - Style consistency cleanup.
  - Added CmdletBinding and other PowerShell best practice changes.
- Invoke-VstsEndpoint Cmdlet:
  - Added documentation.
  - Added support for alternate endpoint names to support VSRM
    API endpoint.
  - Added support for extended query parameters to support
    parameters pre-pended with `$`, such as `top`.
  - Added CmdletBinding and other PowerShell best practice changes.
- Get-VstsAuthorization Cmdlet:
  - Added documentation.
  - Added CmdletBinding and other PowerShell best practice changes.
- Get-VstsProject Cmdlet:
  - Added documentation.
  - Style consistency cleanup.
  - Added CmdletBinding and other PowerShell best practice changes.
  - BREAKING: Remove support for passing session parameters to match
    pattern of other calls. Also to enable QueryString and Name
    parameter set.
  - Added StateFilter parameter for querying on StateFilter.
  - Added Top and Skip parameter for limiting result set.
- Get-VstsBuildArtifact Cmdlet:
  - Added documentation.
  - Style consistency cleanup.
  - Added CmdletBinding and other PowerShell best practice changes.
- Get-VstsReleaseDefinition Cmdlet:
  - Added cmdlet to get a specific release definitions or all
    release definitions.
- Get-VstsRelease Cmdlet:
  - Added cmdlet to get a list of releases by query or all
    releases.
- New-VstsRelease Cmdlet:
  - Added cmdlet to create a new release.

## 1.0.0.0

- Initial versions
