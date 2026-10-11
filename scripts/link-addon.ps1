[CmdletBinding()]
param(
    [string]$RetailPath = (Join-Path ${env:ProgramFiles(x86)} "World of Warcraft\_retail_")
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
New-Item -ItemType Directory -Path $addonsPath -Force | Out-Null

$linkPath = Join-Path $addonsPath "RGMS"
if (Test-Path -LiteralPath $linkPath) {
    throw "The target already exists: $linkPath`nMove or remove it after confirming it is safe, then run this script again."
}

New-Item -ItemType Junction -Path $linkPath -Target $repositoryPath | Out-Null
Write-Host "Linked RGMS addon:"
Write-Host "  $linkPath"
Write-Host "    -> $repositoryPath"
