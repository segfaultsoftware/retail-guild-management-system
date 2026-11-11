Set-StrictMode -Version Latest

$script:ReleaseVersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*)?$'
$script:CurseForgeRetailGameVersionTypeId = 517L
$script:CurseForgeForeverGameVersionTypeId = 88568L

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

function Get-RgmsProductGameVersion {
    param(
        [Parameter(Mandatory)][string]$ProductName,
        [Parameter(Mandatory)][string]$ProductVersion
    )

    if ($ProductVersion -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:[ \t]|$)') {
        throw "$ProductName version '$ProductVersion' must begin with X.Y.Z."
    }
    return "$($Matches[1]).$($Matches[2]).$($Matches[3])"
}

function Get-RgmsRetailGameVersion {
    param([Parameter(Mandatory)][string]$RetailVersion)

    return Get-RgmsProductGameVersion -ProductName 'Retail' -ProductVersion $RetailVersion
}

function Get-RgmsForeverGameVersion {
    param([Parameter(Mandatory)][string]$ForeverVersion)

    return Get-RgmsProductGameVersion -ProductName 'Forever' -ProductVersion $ForeverVersion
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

function Test-RgmsPositiveIntegerValue {
    param([Parameter(Mandatory)][AllowNull()][object]$Value)

    if ($null -eq $Value -or $Value -isnot [ValueType] -or $Value -is [bool]) {
        return $false
    }
    try {
        $integerValue = [long]$Value
        $decimalValue = [decimal]$Value
    } catch {
        return $false
    }
    return $integerValue -gt 0 -and $decimalValue -eq [decimal]$integerValue
}

function Resolve-CurseForgeProductGameVersion {
    param(
        [Parameter(Mandatory)][object[]]$GameVersions,
        [Parameter(Mandatory)][string]$ProductName,
        [Parameter(Mandatory)][string]$GameVersion,
        [Parameter(Mandatory)][long]$GameVersionTypeId
    )

    # PowerShell 7 preserves a top-level JSON array returned directly by
    # Invoke-RestMethod as one nested Object[] in some expression contexts.
    # Passing each pipeline item through output enumeration normalizes both
    # flat and nested responses before inspecting individual version records.
    $normalizedGameVersions = @($GameVersions | ForEach-Object { $_ })
    $validGameVersions = @(
        $normalizedGameVersions | Where-Object {
            (Test-RgmsPositiveIntegerValue -Value $_.id) -and
            (Test-RgmsPositiveIntegerValue -Value $_.gameVersionTypeID) -and
            -not [string]::IsNullOrWhiteSpace([string]$_.name)
        }
    )
    $nameMatches = @(
        $normalizedGameVersions | Where-Object {
            $null -ne $_.name -and ([string]$_.name) -ceq $GameVersion
        }
    )
    $malformedNameMatches = @(
        $nameMatches | Where-Object {
            -not (Test-RgmsPositiveIntegerValue -Value $_.id) -or
            -not (Test-RgmsPositiveIntegerValue -Value $_.gameVersionTypeID)
        }
    )
    if ($malformedNameMatches.Count -gt 0) {
        throw "CurseForge returned $($malformedNameMatches.Count) malformed game-version record(s) named '$GameVersion'."
    }
    if ($validGameVersions.Count -eq 0) {
        throw 'CurseForge did not return a valid game-version list.'
    }

    $matches = @(
        $nameMatches | Where-Object {
            ([long]$_.gameVersionTypeID) -eq $GameVersionTypeId
        }
    )
    if ($matches.Count -ne 1) {
        $matchingTypeIds = @(
            $nameMatches |
                ForEach-Object { [string]$_.gameVersionTypeID } |
                Sort-Object -Unique
        )
        $typeDetail = if ($matchingTypeIds.Count -gt 0) {
            " Matching game-version type IDs: $($matchingTypeIds -join ', ')."
        } else {
            ''
        }
        $majorVersion = $GameVersion.Split('.')[0]
        $nearbyVersions = @(
            $validGameVersions |
                Where-Object {
                    ([string]$_.name) -like "$majorVersion.*" -and
                    (Test-RgmsPositiveIntegerValue -Value $_.gameVersionTypeID) -and
                    ([long]$_.gameVersionTypeID) -eq $GameVersionTypeId
                } |
                ForEach-Object { [string]$_.name } |
                Sort-Object -Unique -Descending |
                Select-Object -First 10
        )
        $catalogDetail = " The API returned $($validGameVersions.Count) valid entries."
        if ($nearbyVersions.Count -gt 0) {
            $catalogDetail += " Same-major versions include: $($nearbyVersions -join ', ')."
        }
        throw "CurseForge must return exactly one $ProductName game version named '$GameVersion' with game-version type ID $GameVersionTypeId; found $($matches.Count).$typeDetail$catalogDetail"
    }

    if (-not (Test-RgmsPositiveIntegerValue -Value $matches[0].id)) {
        throw "CurseForge returned an invalid $ProductName game-version ID for '$GameVersion'."
    }
    return [long]$matches[0].id
}

function Resolve-CurseForgeRetailGameVersion {
    param(
        [Parameter(Mandatory)][object[]]$GameVersions,
        [Parameter(Mandatory)][string]$RetailVersion
    )

    return Resolve-CurseForgeProductGameVersion `
        -GameVersions $GameVersions `
        -ProductName 'Retail' `
        -GameVersion $RetailVersion `
        -GameVersionTypeId $script:CurseForgeRetailGameVersionTypeId
}

function Resolve-CurseForgeForeverGameVersion {
    param(
        [Parameter(Mandatory)][object[]]$GameVersions,
        [Parameter(Mandatory)][string]$ForeverVersion
    )

    return Resolve-CurseForgeProductGameVersion `
        -GameVersions $GameVersions `
        -ProductName 'Forever' `
        -GameVersion $ForeverVersion `
        -GameVersionTypeId $script:CurseForgeForeverGameVersionTypeId
}

function Resolve-CurseForgeGameVersionTargets {
    param(
        [Parameter(Mandatory)][object[]]$GameVersions,
        [Parameter(Mandatory)][string]$RetailVersion,
        [Parameter(Mandatory)][string]$ForeverVersion
    )

    $retailGameVersionId = Resolve-CurseForgeRetailGameVersion `
        -GameVersions $GameVersions `
        -RetailVersion $RetailVersion
    $foreverGameVersionId = Resolve-CurseForgeForeverGameVersion `
        -GameVersions $GameVersions `
        -ForeverVersion $ForeverVersion
    if ($retailGameVersionId -eq $foreverGameVersionId) {
        throw "Retail and Forever CurseForge game-version IDs must be distinct; both resolved to $retailGameVersionId."
    }

    return [pscustomobject][ordered]@{
        RetailGameVersionId = [long]$retailGameVersionId
        ForeverGameVersionId = [long]$foreverGameVersionId
        GameVersionIds = [long[]]@($retailGameVersionId, $foreverGameVersionId)
    }
}

function New-CurseForgeReleaseMetadata {
    param(
        [Parameter(Mandatory)][string]$ReleaseVersion,
        [Parameter(Mandatory)][string]$Changelog,
        [Parameter(Mandatory)][long]$RetailGameVersionId,
        [Parameter(Mandatory)][long]$ForeverGameVersionId
    )

    if ((Get-RgmsReleaseKind -Version $ReleaseVersion) -ne 'final') {
        throw 'CurseForge metadata may be created only for an exact X.Y.Z final release.'
    }
    if ([string]::IsNullOrWhiteSpace($Changelog)) {
        throw 'CurseForge changelog must not be empty.'
    }
    if ($RetailGameVersionId -le 0 -or $ForeverGameVersionId -le 0) {
        throw 'CurseForge Retail and Forever game-version IDs must be positive integers.'
    }
    if ($RetailGameVersionId -eq $ForeverGameVersionId) {
        throw 'CurseForge Retail and Forever game-version IDs must be distinct.'
    }

    return [ordered]@{
        changelog = "## $ReleaseVersion`n`n$Changelog"
        changelogType = 'markdown'
        displayName = "RGMS-$ReleaseVersion.zip"
        gameVersions = @($RetailGameVersionId, $ForeverGameVersionId)
        releaseType = 'release'
        isMarkedForManualRelease = $false
        relations = [ordered]@{
            projects = @(
                [ordered]@{
                    slug = 'libdbicon-1-0'
                    projectID = 15552
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

function Get-CurseForgeApiErrorMessage {
    param([Parameter(Mandatory)][string]$ResponseBody)

    try {
        $response = $ResponseBody | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return 'CurseForge returned an error response that was not valid JSON.'
    }

    $errorCode = if ($null -ne $response.errorCode) { [string]$response.errorCode } else { 'unknown' }
    $errorMessage = if ([string]::IsNullOrWhiteSpace([string]$response.errorMessage)) {
        'No error message was provided.'
    } else {
        ([string]$response.errorMessage).Trim()
    }
    return "CurseForge API error $errorCode`: $errorMessage"
}

function Get-CurseForgeUploadFailureGuidance {
    return 'The GitHub tag and release remain intact. Use Re-run failed jobs to retry only the CurseForge job. If the request timed out or its outcome is unclear, first check the CurseForge Files dashboard for the same RGMS-X.Y.Z.zip display name; the author Upload API does not document an idempotency key or a safe duplicate-upload check.'
}

Export-ModuleMember -Function @(
    'Test-RgmsReleaseVersion',
    'Get-RgmsReleaseKind',
    'Get-RgmsManifestField',
    'Get-RgmsRetailGameVersion',
    'Get-RgmsForeverGameVersion',
    'Get-RgmsChangelogSection',
    'Resolve-CurseForgeRetailGameVersion',
    'Resolve-CurseForgeForeverGameVersion',
    'Resolve-CurseForgeGameVersionTargets',
    'New-CurseForgeReleaseMetadata',
    'Get-CurseForgeUploadedFileId',
    'Get-CurseForgeApiErrorMessage',
    'Get-CurseForgeUploadFailureGuidance'
)
