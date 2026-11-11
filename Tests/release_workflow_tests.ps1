$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module "$PSScriptRoot/../scripts/release-tools.psm1" -Force

$script:Passed = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -cne $Actual) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
    $script:Passed += 1
}

function Assert-True {
    param([bool]$Value, [string]$Message)
    if (-not $Value) {
        throw $Message
    }
    $script:Passed += 1
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    try {
        & $Action
    } catch {
        $script:Passed += 1
        return
    }
    throw $Message
}

Assert-Equal 'final' (Get-RgmsReleaseKind '1.2.3') 'Final release classification failed.'
Assert-Equal 'prerelease' (Get-RgmsReleaseKind '1.2.3-alpha.1') 'General prerelease classification failed.'
Assert-Equal 'prerelease' (Get-RgmsReleaseKind '1.2.3-0') 'Numeric prerelease classification failed.'
Assert-Throws { Get-RgmsReleaseKind '1.2.3+build.1' } 'Build metadata must not be accepted.'
Assert-Throws { Get-RgmsReleaseKind '1.2.3-01' } 'Leading-zero numeric prerelease identifiers must not be accepted.'

$temporaryManifest = New-TemporaryFile
try {
    @'
## Version: 1.2.3
## X-RGMS-Retail-Version: 12.1.5 (build 12345)
## X-RGMS-Forever-Version: 1.60.1 (build 67890)
## X-Curse-Project-ID: 1741733
'@ | Set-Content -LiteralPath $temporaryManifest -Encoding utf8NoBOM
    Assert-Equal '12.1.5 (build 12345)' (Get-RgmsManifestField $temporaryManifest 'X-RGMS-Retail-Version') 'Retail manifest metadata was not preserved.'
    Assert-Equal '12.1.5' (Get-RgmsRetailGameVersion (Get-RgmsManifestField $temporaryManifest 'X-RGMS-Retail-Version')) 'Retail version extraction failed.'
    Assert-Equal '1.60.1 (build 67890)' (Get-RgmsManifestField $temporaryManifest 'X-RGMS-Forever-Version') 'Forever manifest metadata was not preserved.'
    Assert-Equal '1.60.1' (Get-RgmsForeverGameVersion (Get-RgmsManifestField $temporaryManifest 'X-RGMS-Forever-Version')) 'Forever version extraction failed.'
    Assert-Equal '1741733' (Get-RgmsManifestField $temporaryManifest 'X-Curse-Project-ID') 'CurseForge project identity was not read.'
} finally {
    Remove-Item -LiteralPath $temporaryManifest -Force
}
Assert-Throws { Get-RgmsRetailGameVersion 'Retail 12.1.5' } 'Retail versions must begin with X.Y.Z.'
Assert-Throws { Get-RgmsForeverGameVersion '1.60' } 'Forever versions must begin with X.Y.Z.'

$versions = @(
    [pscustomobject]@{ id = 16984; gameVersionTypeID = 517; name = '12.1.5' },
    [pscustomobject]@{ id = 26001; gameVersionTypeID = 88568; name = '1.60.1' },
    [pscustomobject]@{ id = 26002; gameVersionTypeID = 88568; name = '12.1.5' },
    [pscustomobject]@{ id = 16985; gameVersionTypeID = 517; name = '1.60.1' }
)
Assert-Equal 16984L (Resolve-CurseForgeRetailGameVersion $versions '12.1.5') 'Retail game-version lookup selected the wrong ID.'
Assert-Equal 26001L (Resolve-CurseForgeForeverGameVersion $versions '1.60.1') 'Forever game-version lookup selected the wrong ID.'
$nestedVersions = ,$versions
Assert-Equal 16984L (Resolve-CurseForgeRetailGameVersion $nestedVersions '12.1.5') 'Nested Invoke-RestMethod arrays must be flattened.'
Assert-Equal 26001L (Resolve-CurseForgeForeverGameVersion $nestedVersions '1.60.1') 'Nested Forever version responses must be flattened.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion @([pscustomobject]@{ id = 26002; gameVersionTypeID = 88568; name = '12.1.5' }) '12.1.5' } 'A wrong-product Retail match must fail.'
Assert-Throws { Resolve-CurseForgeForeverGameVersion @([pscustomobject]@{ id = 16985; gameVersionTypeID = 517; name = '1.60.1' }) '1.60.1' } 'A wrong-product Forever match must fail.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion @($versions + [pscustomobject]@{ id = 16986; gameVersionTypeID = 517; name = '12.1.5' }) '12.1.5' } 'Ambiguous Retail game versions must fail.'
Assert-Throws { Resolve-CurseForgeForeverGameVersion @($versions + [pscustomobject]@{ id = 26003; gameVersionTypeID = 88568; name = '1.60.1' }) '1.60.1' } 'Ambiguous Forever game versions must fail.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion $versions '12.1.6' } 'Missing Retail game versions must fail.'
Assert-Throws { Resolve-CurseForgeForeverGameVersion $versions '1.60.2' } 'Missing Forever game versions must fail rather than substituting another version.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion @([pscustomobject]@{ status = 'error' }) '12.1.5' } 'Malformed game-version responses must fail.'
$malformedIds = @($null, '16984', 0, -1, 1.5, $true)
foreach ($malformedId in $malformedIds) {
    $malformedVersions = @([pscustomobject]@{ id = $malformedId; gameVersionTypeID = 517; name = '12.1.5' })
    Assert-Throws { Resolve-CurseForgeRetailGameVersion $malformedVersions '12.1.5' } "Malformed game-version ID '$malformedId' must fail."
}
Assert-Throws {
    Resolve-CurseForgeRetailGameVersion @(
        [pscustomobject]@{ id = 16984; gameVersionTypeID = 517; name = '12.1.5' },
        [pscustomobject]@{ id = $null; gameVersionTypeID = 517; name = '12.1.5' }
    ) '12.1.5'
} 'A valid target alongside a malformed same-name ID must fail.'
Assert-Throws {
    Resolve-CurseForgeRetailGameVersion @(
        [pscustomobject]@{ id = 16984; gameVersionTypeID = 517; name = '12.1.5' },
        [pscustomobject]@{ id = 16985; gameVersionTypeID = $null; name = '12.1.5' }
    ) '12.1.5'
} 'A valid target alongside a malformed same-name product type must fail.'
Assert-Throws {
    Resolve-CurseForgeRetailGameVersion @([pscustomobject]@{ id = 16984; gameVersionTypeID = '517'; name = '12.1.5' }) '12.1.5'
} 'String game-version type IDs must fail.'
$missingVersionMessage = try {
    Resolve-CurseForgeRetailGameVersion $versions '12.1.6'
    ''
} catch {
    $_.Exception.Message
}
Assert-True ($missingVersionMessage.Contains('The API returned 4 valid entries.')) 'Missing-version errors must report the safe catalog count.'
Assert-True ($missingVersionMessage.Contains('Same-major versions include: 12.1.5.')) 'Missing-version errors must report nearby versions.'

$targets = Resolve-CurseForgeGameVersionTargets $versions '12.1.5' '1.60.1'
Assert-Equal 16984L $targets.RetailGameVersionId 'Combined target resolution selected the wrong Retail ID.'
Assert-Equal 26001L $targets.ForeverGameVersionId 'Combined target resolution selected the wrong Forever ID.'
Assert-Equal 2 $targets.GameVersionIds.Count 'Combined target resolution must return exactly two IDs.'
Assert-Equal 16984L $targets.GameVersionIds[0] 'Combined targets must put Retail first.'
Assert-Equal 26001L $targets.GameVersionIds[1] 'Combined targets must put Forever second.'
$duplicateTargetVersions = @(
    [pscustomobject]@{ id = 30001; gameVersionTypeID = 517; name = '12.1.5' },
    [pscustomobject]@{ id = 30001; gameVersionTypeID = 88568; name = '1.60.1' }
)
Assert-Throws { Resolve-CurseForgeGameVersionTargets $duplicateTargetVersions '12.1.5' '1.60.1' } 'Duplicate Retail and Forever target IDs must fail in preflight.'

$metadata = New-CurseForgeReleaseMetadata `
    -ReleaseVersion '1.2.3' `
    -Changelog '### Added`n- Feature' `
    -RetailGameVersionId 13001 `
    -ForeverGameVersionId 26001
Assert-Equal 'RGMS-1.2.3.zip' $metadata.displayName 'Display name is incorrect.'
Assert-True ($metadata.changelog.StartsWith("## 1.2.3`n`n### Added")) 'CurseForge changelog must start with the release version heading.'
Assert-Equal 'release' $metadata.releaseType 'Release type is incorrect.'
Assert-Equal $false $metadata.isMarkedForManualRelease 'Manual-release flag is incorrect.'
Assert-Equal 2 $metadata.gameVersions.Count 'Metadata must contain exactly two game-version IDs.'
Assert-Equal 13001L $metadata.gameVersions[0] 'Retail metadata target must be first.'
Assert-Equal 26001L $metadata.gameVersions[1] 'Forever metadata target must be second.'
Assert-True (($metadata | ConvertTo-Json -Depth 8 -Compress).Contains('"gameVersions":[13001,26001]')) 'Metadata JSON must preserve deterministic Retail-then-Forever target order.'
Assert-Equal 'markdown' $metadata.changelogType 'Changelog type is incorrect.'
Assert-Equal 'libdbicon-1-0' $metadata.relations.projects[0].slug 'Embedded library slug is incorrect.'
Assert-Equal 15552 $metadata.relations.projects[0].projectID 'Embedded library project ID is incorrect.'
Assert-True ($metadata.relations.projects[0].projectID -is [int]) 'Embedded library project ID must serialize as a JSON integer.'
Assert-Equal 'embeddedLibrary' $metadata.relations.projects[0].type 'Embedded library relationship is incorrect.'
Assert-Throws { New-CurseForgeReleaseMetadata '1.2.3-beta.2' 'changes' 13001 26001 } 'Prerelease metadata construction must be rejected.'
Assert-Throws { New-CurseForgeReleaseMetadata '1.2.3' 'changes' 0 26001 } 'Nonpositive Retail metadata IDs must be rejected.'
Assert-Throws { New-CurseForgeReleaseMetadata '1.2.3' 'changes' 13001 -1 } 'Nonpositive Forever metadata IDs must be rejected.'
Assert-Throws { New-CurseForgeReleaseMetadata '1.2.3' 'changes' 13001 13001 } 'Duplicate metadata target IDs must be rejected.'

Assert-Equal 20402L (Get-CurseForgeUploadedFileId '{"id":20402}') 'Numeric upload file ID was not accepted.'
Assert-Throws { Get-CurseForgeUploadedFileId '{"id":"20402"}' } 'String upload file IDs must be rejected.'
Assert-Throws { Get-CurseForgeUploadedFileId '{"status":"ok"}' } 'Missing upload file IDs must be rejected.'
Assert-Equal 'CurseForge API error 1003: Missing field `file`.' (Get-CurseForgeApiErrorMessage '{"errorCode":1003,"errorMessage":"Missing field `file`."}') 'Structured API failures must preserve their code and message.'
Assert-Equal 'CurseForge returned an error response that was not valid JSON.' (Get-CurseForgeApiErrorMessage '<html>Error</html>') 'Non-JSON API failures must be reported safely.'
$guidance = Get-CurseForgeUploadFailureGuidance
Assert-True ($guidance.Contains('Re-run failed jobs')) 'Failure guidance must explain the retry control.'
Assert-True ($guidance.Contains('Files dashboard')) 'Failure guidance must cover ambiguous upload outcomes.'
Assert-True ($guidance.Contains('idempotency key')) 'Failure guidance must explain the duplicate-upload risk.'

$workflow = Get-Content -Raw -LiteralPath "$PSScriptRoot/../.github/workflows/create-release.yml"
Assert-True ($workflow.Contains('run-name: Create Release v${{ inputs.version }}')) 'Release runs must display their requested version.'
Assert-True (-not $workflow.Contains('inputs.commit')) 'Release dispatch must not require a copied commit SHA.'
Assert-True ($workflow.Contains('ref: ${{ github.sha }}')) 'Release checkout must pin the workflow dispatch SHA.'
Assert-True ($workflow.Contains('RELEASE_COMMIT: ${{ github.sha }}')) 'Release validation must use the workflow dispatch SHA.'
Assert-True ($workflow.Contains("-Uri 'https://wow.curseforge.com/api/game/wow/versions'")) 'Version lookup must use the game-scoped WoW author API endpoint.'
Assert-Equal 1 ([regex]::Matches($workflow, [regex]::Escape("-Uri 'https://wow.curseforge.com/api/game/wow/versions'")).Count) 'Retail and Forever must share one catalog request.'
Assert-True ($workflow.Contains("-Uri 'https://wow.curseforge.com/api/projects/1741733/upload-file'")) 'Upload must use the WoW CurseForge author API host.'
Assert-Equal 1 ([regex]::Matches($workflow, [regex]::Escape("-Uri 'https://wow.curseforge.com/api/projects/1741733/upload-file'")).Count) 'The canonical ZIP must have one upload path.'
Assert-True (-not $workflow.Contains('https://wow.curseforge.com/api/game/versions')) 'The unscoped legacy version endpoint must not be used.'
Assert-True ($workflow.Contains("curseforge_preflight:`n    name: CurseForge preflight")) 'CurseForge preflight must remain a distinct job.'
Assert-True ($workflow.Contains("publish_curseforge:`n    name: Publish CurseForge")) 'CurseForge publication must remain a distinct retryable job.'
Assert-True ($workflow.Contains("curseforge_preflight:`n    name: CurseForge preflight`n    needs:`n      - validate`n      - build_and_test")) 'Preflight must receive the canonical filename and checksum before publication.'
Assert-True ($workflow.Contains("Get-RgmsManifestField RGMS.toc 'X-RGMS-Retail-Version'")) 'Preflight must read the Retail product version.'
Assert-True ($workflow.Contains("Get-RgmsManifestField RGMS.toc 'X-RGMS-Forever-Version'")) 'Preflight must read the Forever product version.'
Assert-True ($workflow.Contains('Resolve-CurseForgeGameVersionTargets')) 'Preflight must resolve and validate both product targets together.'
Assert-True ($workflow.Contains("needs.curseforge_preflight.result == 'success'")) 'GitHub publication must require successful final-release preflight.'
Assert-Equal 2 ([regex]::Matches($workflow, [regex]::Escape('secrets.CURSEFORGE_API_TOKEN')).Count) 'The CurseForge token must be confined to preflight and upload.'
Assert-Equal 2 ([regex]::Matches($workflow, "if: needs\.validate\.outputs\.is_final == 'true'").Count) 'Both CurseForge jobs must skip prereleases.'
Assert-True ($workflow.Contains('gh release download "$RELEASE_TAG" --pattern "$ARTIFACT_NAME" --dir .release/github')) 'CurseForge publication must download the GitHub release asset.'
Assert-True ($workflow.Contains('GitHub release asset checksum changed before the CurseForge upload.')) 'CurseForge publication must reject a changed GitHub asset before upload.'
Assert-True ($workflow.Contains("-SkipHttpErrorCheck`n")) 'The upload path must inspect the HTTP response without retrying it.'
Assert-Equal 1 ([regex]::Matches($workflow, 'Invoke-WebRequest').Count) 'CurseForge publication must make one upload request.'
Assert-Equal 1 ([regex]::Matches($workflow, 'New-CurseForgeReleaseMetadata').Count) 'Both targets must be placed in one metadata object.'
Assert-True ($workflow.Contains('-RetailGameVersionId ([long]$env:RETAIL_GAME_VERSION_ID)')) 'Upload metadata must receive the Retail target ID first.'
Assert-True ($workflow.Contains('-ForeverGameVersionId ([long]$env:FOREVER_GAME_VERSION_ID)')) 'Upload metadata must receive the Forever target ID second.'
Assert-True ($workflow.Contains('CurseForge upload failed: $failureReason')) 'Upload failures must preserve the underlying safe API error.'
Assert-True ($workflow.Contains('$displayName = "RGMS-$($env:RELEASE_VERSION).zip"')) 'CurseForge display name must match the uploaded filename.'
Assert-True ($workflow.Contains('- One canonical filename:')) 'Failure guidance must identify the one uploaded filename.'
Assert-True ($workflow.Contains('- Shared SHA-256:')) 'Summaries and failure guidance must identify the shared checksum.'
Assert-True ($workflow.Contains('Retail version / catalog version / target ID:')) 'Failure guidance must identify the Retail request and target.'
Assert-True ($workflow.Contains('Forever version / catalog version / target ID:')) 'Failure guidance must identify the Forever request and target.'

Write-Output "$script:Passed release workflow tests: $script:Passed passed, 0 failed"
