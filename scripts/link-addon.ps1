[CmdletBinding()]
param(
    [string]$RetailPath = (Join-Path ${env:ProgramFiles(x86)} "World of Warcraft\_retail_"),
    [switch]$Unlink
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $repositoryPath "RGMS.toc"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "RGMS.toc was not found at the repository root: $repositoryPath"
}

if (-not (Test-Path -LiteralPath $RetailPath -PathType Container)) {
    throw "Retail directory not found: $RetailPath`nPass the path to your _retail_ directory with -RetailPath."
}

$addonsPath = Join-Path $RetailPath "Interface\AddOns"
$linkPath = Join-Path $addonsPath "RGMS"

if ($Unlink) {
    $linkItem = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
    if ($null -eq $linkItem) {
        Write-Host "RGMS addon is already unlinked:"
        Write-Host "  $linkPath"
        return
    }

    if ($linkItem.LinkType -ne "Junction") {
        throw "Refusing to remove a target that is not a directory junction: $linkPath"
    }

    $junctionTargets = @($linkItem.Target)
    if ($junctionTargets.Count -ne 1) {
        throw "Unable to determine the junction target safely: $linkPath"
    }

    $junctionTarget = (Resolve-Path -LiteralPath $junctionTargets[0]).Path
    if (-not [System.StringComparer]::OrdinalIgnoreCase.Equals($junctionTarget, $repositoryPath)) {
        throw "Refusing to remove a junction to another location: $linkPath`nExpected: $repositoryPath`nActual:   $junctionTarget"
    }

    [System.IO.Directory]::Delete($linkPath)
    Write-Host "Unlinked RGMS addon:"
    Write-Host "  $linkPath"
    return
}

New-Item -ItemType Directory -Path $addonsPath -Force | Out-Null

if (Test-Path -LiteralPath $linkPath) {
    throw "The target already exists: $linkPath`nMove or remove it after confirming it is safe, then run this script again."
}

New-Item -ItemType Junction -Path $linkPath -Target $repositoryPath | Out-Null
Write-Host "Linked RGMS addon:"
Write-Host "  $linkPath"
Write-Host "    -> $repositoryPath"
