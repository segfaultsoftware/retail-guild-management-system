$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:Passed = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -cne $Actual) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
    $script:Passed += 1
}

function Assert-False {
    param([bool]$Value, [string]$Message)
    if ($Value) {
        throw $Message
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

function Assert-RepositoryJunction {
    param([string]$Path, [string]$RepositoryPath, [string]$Message)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    Assert-True ($null -ne $item) "$Message The junction does not exist."
    Assert-Equal 'Junction' $item.LinkType "$Message The target is not a junction."

    $targets = @($item.Target)
    Assert-Equal 1 $targets.Count "$Message The junction target is ambiguous."
    $actualTarget = (Resolve-Path -LiteralPath $targets[0]).Path
    Assert-True (
        [System.StringComparer]::OrdinalIgnoreCase.Equals($RepositoryPath, $actualTarget)
    ) "$Message The junction does not point to the repository."
}

$scriptPath = (Resolve-Path "$PSScriptRoot/../scripts/link-addon.ps1").Path
$repositoryPath = (Resolve-Path "$PSScriptRoot/..").Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "rgms-link-addon-tests-$([guid]::NewGuid())"
$originalProgramFilesX86 = ${env:ProgramFiles(x86)}

$retailPath = Join-Path $testRoot 'World of Warcraft\_retail_'
$foreverPath = Join-Path $testRoot 'World of Warcraft\_forever_'
$customPath = Join-Path $testRoot 'custom-client'
$otherTarget = Join-Path $testRoot 'other-target'
$retailLink = Join-Path $retailPath 'Interface\AddOns\RGMS'
$foreverLink = Join-Path $foreverPath 'Interface\AddOns\RGMS'
$customLink = Join-Path $customPath 'Interface\AddOns\RGMS'
$possibleJunctions = @($retailLink, $foreverLink, $customLink)

try {
    New-Item -ItemType Directory -Path $retailPath, $foreverPath, $customPath, $otherTarget -Force | Out-Null
    ${env:ProgramFiles(x86)} = $testRoot

    & $scriptPath
    Assert-RepositoryJunction $retailLink $repositoryPath 'Default Retail linking failed.'
    Assert-False (Test-Path -LiteralPath $foreverLink) 'Default Retail linking must not create a Forever junction.'
    & $scriptPath -Unlink
    Assert-False (Test-Path -LiteralPath $retailLink) 'Default Retail unlinking failed.'

    & $scriptPath -Forever
    Assert-RepositoryJunction $foreverLink $repositoryPath 'Default Forever linking failed.'
    Assert-False (Test-Path -LiteralPath $retailLink) 'Forever linking must not create a Retail junction.'
    & $scriptPath -Forever -Unlink
    Assert-False (Test-Path -LiteralPath $foreverLink) 'Forever unlinking failed.'
    & $scriptPath -Forever -Unlink
    Assert-False (Test-Path -LiteralPath $foreverLink) 'Repeated Forever unlinking must remain idempotent.'

    & $scriptPath -Forever -RetailPath $customPath
    Assert-RepositoryJunction $customLink $repositoryPath 'An explicit path must override the Forever default.'
    Assert-False (Test-Path -LiteralPath $foreverLink) 'An explicit path must not create a junction in the default Forever directory.'
    & $scriptPath -Forever -RetailPath $customPath -Unlink
    Assert-False (Test-Path -LiteralPath $customLink) 'Explicit-path Forever unlinking failed.'

    New-Item -ItemType Directory -Path $foreverLink -Force | Out-Null
    Assert-Throws {
        & $scriptPath -Forever -Unlink
    } 'Forever unlinking must refuse to remove a regular directory.'
    Assert-True (Test-Path -LiteralPath $foreverLink -PathType Container) 'A refused regular directory must remain intact.'
    [System.IO.Directory]::Delete($foreverLink)

    New-Item -ItemType Junction -Path $foreverLink -Target $otherTarget | Out-Null
    Assert-Throws {
        & $scriptPath -Forever -Unlink
    } 'Forever unlinking must refuse to remove a junction to another target.'
    Assert-True (Test-Path -LiteralPath $foreverLink -PathType Container) 'A refused foreign junction must remain intact.'
    [System.IO.Directory]::Delete($foreverLink)
} finally {
    ${env:ProgramFiles(x86)} = $originalProgramFilesX86

    foreach ($candidate in $possibleJunctions) {
        $item = Get-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and $item.LinkType -eq 'Junction') {
            [System.IO.Directory]::Delete($candidate)
        }
    }

    $temporaryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    if (
        $resolvedTestRoot.StartsWith($temporaryRoot, [System.StringComparison]::OrdinalIgnoreCase) -and
        [System.IO.Path]::GetFileName($resolvedTestRoot).StartsWith('rgms-link-addon-tests-', [System.StringComparison]::Ordinal)
    ) {
        [System.IO.Directory]::Delete($resolvedTestRoot, $true)
    }
}

Write-Output "$script:Passed link-addon tests: $script:Passed passed, 0 failed"
