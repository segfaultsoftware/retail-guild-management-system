Set-StrictMode -Version Latest

$script:ReleaseVersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*)?$'
$script:CurseForgeRetailGameVersionTypeId = 517L

function Test-RgmsReleaseVersion {
    param([Parameter(Mandatory)][string]$Version)

    return $Version -cmatch $script:ReleaseVersionPattern
}

function Get-RgmsReleaseKind {
    param([Parameter(Mandatory)][string]$Version)

    if (-not (Test-RgmsReleaseVersion -Version $Version)) {
        throw "Release version '$Version' must be X.Y.Z or X.Y.Z-prerelease without build metadata."
    }
    if ($Version.Contains('-')) {
        return 'prerelease'
    }
    return 'final'
}

function Get-RgmsManifestField {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    $escapedName = [regex]::Escape($Name)
    $matches = @(
        Get-Content -LiteralPath $Path |
            Where-Object { $_ -cmatch "^##[ \t]+${escapedName}:[ \t]*(.*?)[ \t]*$" } |
            ForEach-Object { $Matches[1] }
    )
    if ($matches.Count -ne 1 -or [string]::IsNullOrWhiteSpace($matches[0])) {
        throw "$Path must contain exactly one non-empty '$Name' manifest field."
    }
    return $matches[0]
}

function Get-RgmsRetailGameVersion {
    param([Parameter(Mandatory)][string]$RetailVersion)

    if ($RetailVersion -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:[ \t]|$)') {
        throw "Retail version '$RetailVersion' must begin with X.Y.Z."
    }
    return "$($Matches[1]).$($Matches[2]).$($Matches[3])"
}

function Get-RgmsChangelogSection {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Version
    )

    $changelog = Get-Content -Raw -LiteralPath $Path
    $escapedVersion = [regex]::Escape($Version)
    $matches = [regex]::Matches(
        $changelog,
        "(?ms)^## (?:\[${escapedVersion}\]|${escapedVersion})(?:[ \t]+[^\r\n]*)?\r?\n(.*?)(?=^## |\z)"
    )
    if ($matches.Count -ne 1 -or [string]::IsNullOrWhiteSpace($matches[0].Groups[1].Value)) {
        throw "$Path must contain exactly one non-empty section for $Version."
    }
    return $matches[0].Groups[1].Value.Trim()
}

function Resolve-CurseForgeRetailGameVersion {
    param(
        [Parameter(Mandatory)][object[]]$GameVersions,
        [Parameter(Mandatory)][string]$RetailVersion
    )

    $matches = @(
        $GameVersions | Where-Object {
            ([string]$_.name) -ceq $RetailVersion -and
            $null -ne $_.gameVersionTypeID -and
            ([long]$_.gameVersionTypeID) -eq $script:CurseForgeRetailGameVersionTypeId
        }
    )
    if ($matches.Count -ne 1 -or $null -eq $matches[0].id) {
        throw "CurseForge must return exactly one Retail game version named '$RetailVersion'; found $($matches.Count)."
    }

    $gameVersionId = [long]$matches[0].id
    if ($gameVersionId -le 0) {
        throw "CurseForge returned an invalid game-version ID for '$RetailVersion'."
    }
    return $gameVersionId
}

function New-CurseForgeReleaseMetadata {
    param(
        [Parameter(Mandatory)][string]$ReleaseVersion,
        [Parameter(Mandatory)][string]$Changelog,
        [Parameter(Mandatory)][long]$GameVersionId
    )

    if ((Get-RgmsReleaseKind -Version $ReleaseVersion) -ne 'final') {
        throw 'CurseForge metadata may be created only for an exact X.Y.Z final release.'
    }
    if ([string]::IsNullOrWhiteSpace($Changelog)) {
        throw 'CurseForge changelog must not be empty.'
    }
    if ($GameVersionId -le 0) {
        throw 'CurseForge game-version ID must be a positive integer.'
    }

    return [ordered]@{
        changelog = $Changelog
        changelogType = 'markdown'
        displayName = "RGMS $ReleaseVersion"
        gameVersions = @($GameVersionId)
        releaseType = 'release'
        isMarkedForManualRelease = $false
        relations = [ordered]@{
            projects = @(
                [ordered]@{
                    slug = 'libdbicon-1-0'
                    projectID = '15552'
                    type = 'embeddedLibrary'
                }
            )
        }
    }
}

function Get-CurseForgeUploadedFileId {
    param([Parameter(Mandatory)][string]$ResponseBody)

    try {
        $response = $ResponseBody | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw 'CurseForge upload response was not valid JSON.'
    }
    if ($null -eq $response.id -or $response.id -isnot [ValueType]) {
        throw 'CurseForge upload response did not contain a numeric file ID.'
    }
    $fileId = [long]$response.id
    if ($fileId -le 0 -or ([double]$response.id) -ne $fileId) {
        throw 'CurseForge upload response did not contain a positive integer file ID.'
    }
    return $fileId
}

function Get-CurseForgeUploadFailureGuidance {
    return 'The GitHub tag and release remain intact. Use Re-run failed jobs to retry only the CurseForge job. If the request timed out or its outcome is unclear, first check the CurseForge Files dashboard for the same RGMS display name; the author Upload API does not document an idempotency key or a safe duplicate-upload check.'
}

Export-ModuleMember -Function @(
    'Test-RgmsReleaseVersion',
    'Get-RgmsReleaseKind',
    'Get-RgmsManifestField',
    'Get-RgmsRetailGameVersion',
    'Get-RgmsChangelogSection',
    'Resolve-CurseForgeRetailGameVersion',
    'New-CurseForgeReleaseMetadata',
    'Get-CurseForgeUploadedFileId',
    'Get-CurseForgeUploadFailureGuidance'
)
