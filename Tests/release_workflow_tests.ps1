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
## X-Curse-Project-ID: 1741733
'@ | Set-Content -LiteralPath $temporaryManifest -Encoding utf8NoBOM
    Assert-Equal '12.1.5 (build 12345)' (Get-RgmsManifestField $temporaryManifest 'X-RGMS-Retail-Version') 'Retail manifest metadata was not preserved.'
    Assert-Equal '12.1.5' (Get-RgmsRetailGameVersion (Get-RgmsManifestField $temporaryManifest 'X-RGMS-Retail-Version')) 'Retail version extraction failed.'
    Assert-Equal '1741733' (Get-RgmsManifestField $temporaryManifest 'X-Curse-Project-ID') 'CurseForge project identity was not read.'
} finally {
    Remove-Item -LiteralPath $temporaryManifest -Force
}

$versions = @(
    [pscustomobject]@{ id = 16984; gameVersionTypeID = 517; name = '12.1.5' },
    [pscustomobject]@{ id = 13002; gameVersionTypeID = 674; name = '1.15.9' }
)
Assert-Equal 16984L (Resolve-CurseForgeRetailGameVersion $versions '12.1.5') 'Retail game-version lookup selected the wrong ID.'
$nestedVersions = ,$versions
Assert-Equal 16984L (Resolve-CurseForgeRetailGameVersion $nestedVersions '12.1.5') 'Nested Invoke-RestMethod arrays must be flattened.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion @($versions + [pscustomobject]@{ id = 13003; gameVersionTypeID = 517; name = '12.1.5' }) '12.1.5' } 'Ambiguous Retail game versions must fail.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion $versions '12.1.6' } 'Missing Retail game versions must fail.'
Assert-Throws { Resolve-CurseForgeRetailGameVersion @([pscustomobject]@{ status = 'error' }) '12.1.5' } 'Malformed game-version responses must fail.'
$missingVersionMessage = try {
    Resolve-CurseForgeRetailGameVersion $versions '12.1.6'
    ''
} catch {
    $_.Exception.Message
}
Assert-True ($missingVersionMessage.Contains('The API returned 2 valid entries.')) 'Missing-version errors must report the safe catalog count.'
Assert-True ($missingVersionMessage.Contains('Same-major versions include: 12.1.5.')) 'Missing-version errors must report nearby versions.'

$metadata = New-CurseForgeReleaseMetadata '1.2.3' '### Added`n- Feature' 13001
Assert-Equal 'RGMS 1.2.3' $metadata.displayName 'Display name is incorrect.'
Assert-Equal 'release' $metadata.releaseType 'Release type is incorrect.'
Assert-Equal $false $metadata.isMarkedForManualRelease 'Manual-release flag is incorrect.'
Assert-Equal 13001L $metadata.gameVersions[0] 'Game-version ID is incorrect.'
Assert-Equal 'markdown' $metadata.changelogType 'Changelog type is incorrect.'
Assert-Equal 'libdbicon-1-0' $metadata.relations.projects[0].slug 'Embedded library slug is incorrect.'
Assert-Equal 15552 $metadata.relations.projects[0].projectID 'Embedded library project ID is incorrect.'
Assert-True ($metadata.relations.projects[0].projectID -is [int]) 'Embedded library project ID must serialize as a JSON integer.'
Assert-Equal 'embeddedLibrary' $metadata.relations.projects[0].type 'Embedded library relationship is incorrect.'
Assert-Throws { New-CurseForgeReleaseMetadata '1.2.3-beta.2' 'changes' 13001 } 'Prerelease metadata construction must be rejected.'

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
Assert-True ($workflow.Contains("-Uri 'https://wow.curseforge.com/api/projects/1741733/upload-file'")) 'Upload must use the WoW CurseForge author API host.'
Assert-True (-not $workflow.Contains('https://wow.curseforge.com/api/game/versions')) 'The unscoped legacy version endpoint must not be used.'
Assert-True ($workflow.Contains("curseforge_preflight:`n    name: CurseForge preflight")) 'CurseForge preflight must remain a distinct job.'
Assert-True ($workflow.Contains("publish_curseforge:`n    name: Publish CurseForge")) 'CurseForge publication must remain a distinct retryable job.'
Assert-Equal 2 ([regex]::Matches($workflow, [regex]::Escape('secrets.CURSEFORGE_API_TOKEN')).Count) 'The CurseForge token must be confined to preflight and upload.'
Assert-Equal 2 ([regex]::Matches($workflow, "if: needs\.validate\.outputs\.is_final == 'true'").Count) 'Both CurseForge jobs must skip prereleases.'
Assert-True ($workflow.Contains('gh release download "$RELEASE_TAG" --pattern "$ARTIFACT_NAME" --dir .release/github')) 'CurseForge publication must download the GitHub release asset.'
Assert-True ($workflow.Contains("-SkipHttpErrorCheck`n")) 'The upload path must inspect the HTTP response without retrying it.'
Assert-True ($workflow.Contains('CurseForge upload failed: $failureReason')) 'Upload failures must preserve the underlying safe API error.'

Write-Output "$script:Passed release workflow tests: $script:Passed passed, 0 failed"
