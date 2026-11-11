[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version,

    [string]$OutputDirectory = ".release",

    [string]$LuaCommand
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$semanticVersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$'
$productVersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:[ \t]+\S(?:.*\S)?)?$'
$requiredManifestFields = @(
    "Interface",
    "AllowLoadGameType",
    "Title",
    "Notes",
    "Author",
    "Version",
    "X-RGMS-Retail-Version",
    "X-RGMS-Forever-Version",
    "X-Curse-Project-ID",
    "SavedVariables",
    "SavedVariablesPerCharacter",
    "OptionalDeps"
)
$requiredManifestValues = [ordered]@{
    "AllowLoadGameType" = "standard, camelot"
    "X-Curse-Project-ID" = "1741733"
    "SavedVariables" = "RGMSAccountDB"
    "SavedVariablesPerCharacter" = "RGMSCharacterDB"
    "OptionalDeps" = "Auctionator"
}
$distributionFiles = @(
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "assets/rgms-logo.png",
    "assets/rgms-minimap-icon.png",
    "assets/fonts/Inter-Regular.ttf",
    "assets/fonts/Inter-SemiBold.ttf",
    "assets/icons/check.png",
    "assets/icons/chevron-down.png",
    "assets/icons/chevron-right.png",
    "assets/icons/loader-circle.png",
    "assets/icons/notebook-pen.png",
    "assets/icons/refresh-cw.png",
    "assets/icons/tag.png",
    "assets/icons/x.png",
    "licenses/Inter-OFL.txt",
    "licenses/Lucide-ISC.txt"
)

function Assert-ReleaseVersion {
    param([string]$Candidate)

    if ($Candidate -cnotmatch $semanticVersionPattern) {
        throw "Release version '$Candidate' is not a valid semantic version. Use X.Y.Z or X.Y.Z-prerelease."
    }
}

function Assert-RegularFile {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description does not exist: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (
        -not [string]::IsNullOrWhiteSpace($item.LinkType) -or
        ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
    ) {
        throw "$Description must be a regular file, not a link: $Path"
    }
}

function Assert-NoLinkedPathComponents {
    param(
        [string]$RepositoryPath,
        [string]$RelativePath,
        [string]$Description
    )

    $systemRelativePath = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $segments = @($systemRelativePath.Split(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.StringSplitOptions]::RemoveEmptyEntries
    ))
    $currentPath = $RepositoryPath
    for ($index = 0; $index -lt $segments.Count - 1; $index += 1) {
        $currentPath = Join-Path $currentPath $segments[$index]
        if (-not (Test-Path -LiteralPath $currentPath)) {
            break
        }

        $item = Get-Item -LiteralPath $currentPath -Force
        if (
            -not [string]::IsNullOrWhiteSpace($item.LinkType) -or
            ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        ) {
            throw "$Description must not traverse a linked directory: $currentPath"
        }
    }
}

function Get-ManifestRuntimePath {
    param([string]$Entry)

    $directiveStart = [regex]::Match($Entry, '\s+\[')
    if (-not $directiveStart.Success) {
        if ($Entry.Contains('[') -or $Entry.Contains(']')) {
            throw "Manifest runtime entry has a malformed inline directive: $Entry"
        }
        return $Entry
    }

    $sourcePath = $Entry.Substring(0, $directiveStart.Index).TrimEnd()
    $directiveText = $Entry.Substring($directiveStart.Index).Trim()
    if ([string]::IsNullOrWhiteSpace($sourcePath)) {
        throw "Manifest runtime entry has no source path before its inline directives: $Entry"
    }

    $directivePattern = [regex]'\G\s*\[(?<Name>AllowLoadGameType|ExcludeLoadGameType)\s+(?<Values>[a-z]+(?:\s*,\s*[a-z]+)*)\]'
    $directiveNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $allowedGameTypes = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $excludedGameTypes = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $offset = 0
    while ($offset -lt $directiveText.Length) {
        $directive = $directivePattern.Match($directiveText, $offset)
        if (-not $directive.Success -or $directive.Index -ne $offset) {
            throw "Manifest runtime entry has a malformed or unsupported inline directive: $Entry"
        }

        $directiveName = $directive.Groups['Name'].Value
        if (-not $directiveNames.Add($directiveName)) {
            throw "Manifest runtime entry declares '$directiveName' more than once: $Entry"
        }

        $directiveGameTypes = $excludedGameTypes
        if ($directiveName -ceq 'AllowLoadGameType') {
            $directiveGameTypes = $allowedGameTypes
        }
        foreach ($gameTypeValue in $directive.Groups['Values'].Value -split ',') {
            $gameType = $gameTypeValue.Trim()
            if ($gameType -cne 'standard' -and $gameType -cne 'camelot') {
                throw "Manifest runtime entry uses unsupported game type '$gameType': $Entry"
            }
            if (-not $directiveGameTypes.Add($gameType)) {
                throw "Manifest runtime entry repeats game type '$gameType' in '$directiveName': $Entry"
            }
        }

        $offset += $directive.Length
    }

    foreach ($gameType in $allowedGameTypes) {
        if ($excludedGameTypes.Contains($gameType)) {
            throw "Manifest runtime entry both allows and excludes game type '$gameType': $Entry"
        }
    }

    return $sourcePath
}

function Get-ManifestInterfaces {
    param([string]$Value)

    $interfaces = [System.Collections.Generic.List[string]]::new()
    $interfaceSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($rawInterface in $Value -split ',') {
        $interface = $rawInterface.Trim()
        if ([string]::IsNullOrWhiteSpace($interface)) {
            throw "Manifest Interface contains an empty value; found '$Value'."
        }
        if ($interface -cnotmatch '^[0-9]+$') {
            throw "Manifest Interface values must be numeric and comma-delimited; found '$Value'."
        }

        $canonicalInterface = $interface.TrimStart('0')
        if ($canonicalInterface.Length -eq 0) {
            $canonicalInterface = '0'
        }
        if (-not $interfaceSet.Add($canonicalInterface)) {
            throw "Manifest Interface value '$interface' is declared more than once."
        }
        $interfaces.Add($interface)
    }

    if ($interfaces.Count -ne 2) {
        throw "Manifest Interface must contain exactly two unique numeric values in Retail-then-Forever order; found '$Value'."
    }
    return $interfaces.ToArray()
}

function Get-ManifestInformation {
    param(
        [string]$ManifestPath,
        [string]$ExpectedVersion,
        [string]$RepositoryPath
    )

    Assert-RegularFile -Path $ManifestPath -Description "Manifest"

    $metadata = @{}
    $runtimeFiles = [System.Collections.Generic.List[string]]::new()
    $runtimeFileSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($line in Get-Content -LiteralPath $ManifestPath) {
        if ($line -match '^\s*##\s+([^:]+):\s*(.*?)\s*$') {
            $fieldName = $Matches[1].Trim()
            $fieldValue = $Matches[2].Trim()
            if ($metadata.ContainsKey($fieldName)) {
                throw "Manifest field '$fieldName' is declared more than once."
            }
            $metadata[$fieldName] = $fieldValue
            continue
        }

        $trimmedLine = $line.Trim()
        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith("#")) {
            continue
        }

        $sourcePath = Get-ManifestRuntimePath -Entry $trimmedLine
        $portablePath = $sourcePath.Replace('\', '/')
        $pathSegments = @($portablePath -split '/')
        if (
            $sourcePath.Contains('[') -or
            $sourcePath.Contains(']') -or
            $portablePath.StartsWith("/") -or
            $portablePath -match '^[A-Za-z]:' -or
            $portablePath.Contains(':') -or
            $pathSegments.Count -eq 0 -or
            @($pathSegments | Where-Object {
                $_.Length -eq 0 -or $_ -ceq '.' -or $_ -ceq '..'
            }).Count -ne 0
        ) {
            throw "Manifest runtime path is not a normalized repository-relative path: $sourcePath"
        }
        if (-not $portablePath.EndsWith(".lua", [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Manifest runtime entry is not a Lua file: $sourcePath"
        }
        if (-not $runtimeFileSet.Add($portablePath)) {
            throw "Manifest runtime file is listed more than once: $sourcePath"
        }

        $systemRelativePath = $portablePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $runtimePath = [System.IO.Path]::GetFullPath((Join-Path $RepositoryPath $systemRelativePath))
        $repositoryPrefix = $RepositoryPath.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $runtimePath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Manifest runtime path leaves the repository: $sourcePath"
        }
        Assert-RegularFile -Path $runtimePath -Description "Manifest runtime file '$sourcePath'"
        Assert-NoLinkedPathComponents `
            -RepositoryPath $RepositoryPath `
            -RelativePath $portablePath `
            -Description "Manifest runtime file '$sourcePath'"

        $runtimeFiles.Add($portablePath)
    }

    foreach ($fieldName in $requiredManifestFields) {
        if (-not $metadata.ContainsKey($fieldName) -or [string]::IsNullOrWhiteSpace($metadata[$fieldName])) {
            throw "Manifest field '$fieldName' is missing or empty."
        }
    }
    $interfaces = @(Get-ManifestInterfaces -Value $metadata["Interface"])
    foreach ($requiredValue in $requiredManifestValues.GetEnumerator()) {
        if ($metadata[$requiredValue.Key] -cne $requiredValue.Value) {
            throw "Manifest field '$($requiredValue.Key)' must equal '$($requiredValue.Value)'; found '$($metadata[$requiredValue.Key])'."
        }
    }
    foreach ($productVersionField in @(
        "X-RGMS-Retail-Version",
        "X-RGMS-Forever-Version"
    )) {
        if ($metadata[$productVersionField] -cnotmatch $productVersionPattern) {
            throw "Manifest field '$productVersionField' must begin with a canonical X.Y.Z product version followed only by optional build text; found '$($metadata[$productVersionField])'."
        }
    }
    if ($metadata["Version"] -cne $ExpectedVersion) {
        throw "Manifest version '$($metadata["Version"])' does not match requested release '$ExpectedVersion'."
    }
    if ($runtimeFiles.Count -eq 0) {
        throw "Manifest does not list any runtime files."
    }

    [pscustomobject]@{
        Metadata = $metadata
        Interfaces = $interfaces
        RuntimeFiles = $runtimeFiles.ToArray()
    }
}

function Get-Sha256 {
    param([string]$Path)

    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function New-ExpectedFileHashes {
    param(
        [string]$RepositoryPath,
        [string[]]$RelativePaths
    )

    $hashes = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($relativePath in $RelativePaths) {
        $systemRelativePath = $relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $sourcePath = Join-Path $RepositoryPath $systemRelativePath
        Assert-RegularFile -Path $sourcePath -Description "Required distribution file '$relativePath'"
        Assert-NoLinkedPathComponents `
            -RepositoryPath $RepositoryPath `
            -RelativePath $relativePath `
            -Description "Required distribution file '$relativePath'"
        $hashes.Add("RGMS/$relativePath", (Get-Sha256 -Path $sourcePath))
    }
    $hashes
}

function New-ReleaseArchive {
    param(
        [string]$RepositoryPath,
        [string[]]$RelativePaths,
        [string]$ArchivePath
    )

    Add-Type -AssemblyName System.IO.Compression
    $archiveStream = [System.IO.File]::Open(
        $ArchivePath,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None
    )
    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $archiveStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )
        try {
            foreach ($relativePath in $RelativePaths) {
                $entry = $archive.CreateEntry(
                    "RGMS/$relativePath",
                    [System.IO.Compression.CompressionLevel]::NoCompression
                )
                $entry.LastWriteTime = [System.DateTimeOffset]::new(1980, 1, 1, 0, 0, 0, [System.TimeSpan]::Zero)
                # A fixed regular-file 0644 mode keeps metadata stable across operating systems.
                $entry.ExternalAttributes = -2119958528

                $systemRelativePath = $relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
                $sourceStream = [System.IO.File]::OpenRead((Join-Path $RepositoryPath $systemRelativePath))
                try {
                    $entryStream = $entry.Open()
                    try {
                        $sourceStream.CopyTo($entryStream)
                    }
                    finally {
                        $entryStream.Dispose()
                    }
                }
                finally {
                    $sourceStream.Dispose()
                }
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $archiveStream.Dispose()
    }

    # ZipArchive records its host operating system in each central-directory
    # entry. Normalize those bytes so Windows, macOS, and Linux emit the same
    # archive for the same source content.
    $archiveBytes = [System.IO.File]::ReadAllBytes($ArchivePath)
    $endOfCentralDirectory = -1
    $minimumOffset = [System.Math]::Max(0, $archiveBytes.Length - 65557)
    for ($offset = $archiveBytes.Length - 22; $offset -ge $minimumOffset; $offset -= 1) {
        if (
            $archiveBytes[$offset] -eq 0x50 -and
            $archiveBytes[$offset + 1] -eq 0x4b -and
            $archiveBytes[$offset + 2] -eq 0x05 -and
            $archiveBytes[$offset + 3] -eq 0x06
        ) {
            $endOfCentralDirectory = $offset
            break
        }
    }
    if ($endOfCentralDirectory -lt 0) {
        throw "Generated archive has no end-of-central-directory record: $ArchivePath"
    }

    $entryCount = [System.BitConverter]::ToUInt16($archiveBytes, $endOfCentralDirectory + 10)
    $centralDirectoryOffset = [int][System.BitConverter]::ToUInt32(
        $archiveBytes,
        $endOfCentralDirectory + 16
    )
    for ($entryIndex = 0; $entryIndex -lt $entryCount; $entryIndex += 1) {
        if (
            $archiveBytes[$centralDirectoryOffset] -ne 0x50 -or
            $archiveBytes[$centralDirectoryOffset + 1] -ne 0x4b -or
            $archiveBytes[$centralDirectoryOffset + 2] -ne 0x01 -or
            $archiveBytes[$centralDirectoryOffset + 3] -ne 0x02
        ) {
            throw "Generated archive has a malformed central-directory entry at index $entryIndex."
        }

        # ZIP specification version 2.0 on the canonical DOS/Windows platform.
        $archiveBytes[$centralDirectoryOffset + 4] = 20
        $archiveBytes[$centralDirectoryOffset + 5] = 0
        # No internal attributes; fixed Unix regular-file 0644 external mode.
        $archiveBytes[$centralDirectoryOffset + 36] = 0
        $archiveBytes[$centralDirectoryOffset + 37] = 0
        $archiveBytes[$centralDirectoryOffset + 38] = 0
        $archiveBytes[$centralDirectoryOffset + 39] = 0
        $archiveBytes[$centralDirectoryOffset + 40] = 0xa4
        $archiveBytes[$centralDirectoryOffset + 41] = 0x81

        $fileNameLength = [System.BitConverter]::ToUInt16($archiveBytes, $centralDirectoryOffset + 28)
        $extraFieldLength = [System.BitConverter]::ToUInt16($archiveBytes, $centralDirectoryOffset + 30)
        $commentLength = [System.BitConverter]::ToUInt16($archiveBytes, $centralDirectoryOffset + 32)
        $centralDirectoryOffset += 46 + $fileNameLength + $extraFieldLength + $commentLength
    }

    [System.IO.File]::WriteAllBytes($ArchivePath, $archiveBytes)
}

function Assert-ReleaseArchive {
    param(
        [string]$ArchivePath,
        [System.Collections.Generic.Dictionary[string, string]]$ExpectedHashes
    )

    Add-Type -AssemblyName System.IO.Compression
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $actualEntries = @($archive.Entries | ForEach-Object { $_.FullName })
        $expectedEntries = @($ExpectedHashes.Keys)
        [System.Array]::Sort($actualEntries, [System.StringComparer]::Ordinal)
        [System.Array]::Sort($expectedEntries, [System.StringComparer]::Ordinal)

        if ($actualEntries.Count -ne $expectedEntries.Count) {
            throw "Archive contains $($actualEntries.Count) entries; expected $($expectedEntries.Count)."
        }
        for ($index = 0; $index -lt $expectedEntries.Count; $index += 1) {
            if ($actualEntries[$index] -cne $expectedEntries[$index]) {
                throw "Archive layout mismatch at entry $($index + 1): found '$($actualEntries[$index])', expected '$($expectedEntries[$index])'."
            }
        }

        $seenEntries = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )
        foreach ($entry in $archive.Entries) {
            $entryName = $entry.FullName
            if (-not $seenEntries.Add($entryName)) {
                throw "Archive contains a duplicate entry: $entryName"
            }
            if (
                -not $entryName.StartsWith("RGMS/", [System.StringComparison]::Ordinal) -or
                $entryName.Length -le "RGMS/".Length -or
                $entryName.Contains('\') -or
                $entryName -match '(^|/)\.\.(/|$)'
            ) {
                throw "Archive entry is outside the single RGMS addon directory: $entryName"
            }
            if ($entryName -match '(?i)(^|/)(Tests|fixtures|docs|scripts|\.github|\.git|\.release|node_modules|vendor|coverage)(/|$)') {
                throw "Archive contains a contributor-only or generated path: $entryName"
            }
            if ($entryName -match '(?i)(^|/)(\.env(?:\..*)?|\.pkgmeta|\.gitignore|credentials(?:\..*)?|secrets?(?:\..*)?|id_rsa|.*\.(?:pem|key|pfx))$') {
                throw "Archive contains a forbidden metadata, credential, or secret-like file: $entryName"
            }

            $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
            try {
                $entryStream = $entry.Open()
                try {
                    $actualHash = [System.Convert]::ToHexString(
                        $hashAlgorithm.ComputeHash($entryStream)
                    ).ToLowerInvariant()
                }
                finally {
                    $entryStream.Dispose()
                }
            }
            finally {
                $hashAlgorithm.Dispose()
            }

            if ($actualHash -cne $ExpectedHashes[$entryName]) {
                throw "Archive entry content does not match the verified source file: $entryName"
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Invoke-LuaTests {
    param(
        [string]$RepositoryPath,
        [string]$RequestedLuaCommand
    )

    $candidateCommands = if ([string]::IsNullOrWhiteSpace($RequestedLuaCommand)) {
        @("lua5.1", "lua")
    }
    else {
        @($RequestedLuaCommand)
    }

    $lua = $null
    foreach ($candidateCommand in $candidateCommands) {
        $lua = Get-Command $candidateCommand -ErrorAction SilentlyContinue
        if ($null -ne $lua) {
            break
        }
    }
    if ($null -eq $lua) {
        throw "Lua was not found. Install Lua 5.1 or pass its executable path with -LuaCommand."
    }

    Write-Host "Running automated tests with $($lua.Source)..."
    if ($env:OS -eq "Windows_NT") {
        $git = Get-Command git.exe -ErrorAction SilentlyContinue
        if ($null -eq $git) {
            throw "Git Bash is required to run the Lua suite safely on Windows."
        }
        $gitBash = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $git.Source -Parent) "..\bin\bash.exe"))
        if (-not (Test-Path -LiteralPath $gitBash -PathType Leaf)) {
            throw "Git Bash was not found at the expected Git installation path: $gitBash"
        }
        $portableRepository = $RepositoryPath.Replace('\', '/')
        if ($portableRepository -match '^([A-Za-z]):(.*)$') {
            $portableRepository = "/$($Matches[1].ToLowerInvariant())$($Matches[2])"
        }
        $portableLua = $lua.Source.Replace('\', '/')
        & $gitBash -lc "cd '$portableRepository' && '$portableLua' Tests/run.lua"
    }
    else {
        Push-Location $RepositoryPath
        try {
            & $lua.Source "Tests/run.lua"
        }
        finally {
            Pop-Location
        }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Automated tests failed with exit code $LASTEXITCODE. No release archive was produced."
    }
}

Assert-ReleaseVersion -Candidate $Version

$repositoryPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $repositoryPath "RGMS.toc"
$manifest = Get-ManifestInformation `
    -ManifestPath $manifestPath `
    -ExpectedVersion $Version `
    -RepositoryPath $repositoryPath

$packageFiles = @("RGMS.toc") + @($manifest.RuntimeFiles) + $distributionFiles
$packageFileSet = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($packageFile in $packageFiles) {
    if (-not $packageFileSet.Add($packageFile)) {
        throw "Distribution file is included more than once: $packageFile"
    }
}
[System.Array]::Sort($packageFiles, [System.StringComparer]::Ordinal)

$resolvedOutputDirectory = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $repositoryPath $OutputDirectory))
}
[System.IO.Directory]::CreateDirectory($resolvedOutputDirectory) | Out-Null

$artifactName = "RGMS-$Version.zip"
$artifactPath = Join-Path $resolvedOutputDirectory $artifactName
if (Test-Path -LiteralPath $artifactPath) {
    throw "Refusing to overwrite existing release artifact: $artifactPath"
}

Invoke-LuaTests -RepositoryPath $repositoryPath -RequestedLuaCommand $LuaCommand

$expectedHashes = New-ExpectedFileHashes `
    -RepositoryPath $repositoryPath `
    -RelativePaths $packageFiles

$firstTemporaryPath = Join-Path $resolvedOutputDirectory ".$artifactName.$([System.Guid]::NewGuid().ToString('N')).first.tmp"
$secondTemporaryPath = Join-Path $resolvedOutputDirectory ".$artifactName.$([System.Guid]::NewGuid().ToString('N')).second.tmp"
try {
    New-ReleaseArchive `
        -RepositoryPath $repositoryPath `
        -RelativePaths $packageFiles `
        -ArchivePath $firstTemporaryPath
    Assert-ReleaseArchive -ArchivePath $firstTemporaryPath -ExpectedHashes $expectedHashes

    New-ReleaseArchive `
        -RepositoryPath $repositoryPath `
        -RelativePaths $packageFiles `
        -ArchivePath $secondTemporaryPath
    Assert-ReleaseArchive -ArchivePath $secondTemporaryPath -ExpectedHashes $expectedHashes

    $firstHash = Get-Sha256 -Path $firstTemporaryPath
    $secondHash = Get-Sha256 -Path $secondTemporaryPath
    if ($firstHash -cne $secondHash) {
        throw "Two builds from the same source produced different archives. No release artifact was retained."
    }

    [System.IO.File]::Move($firstTemporaryPath, $artifactPath)
}
finally {
    foreach ($temporaryPath in @($firstTemporaryPath, $secondTemporaryPath)) {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

Write-Host "Created and verified deterministic release archive:"
Write-Host "  $artifactPath"
Write-Host "SHA-256: $(Get-Sha256 -Path $artifactPath)"
Write-Host "Archive contents:"
foreach ($packageFile in $packageFiles) {
    Write-Host "  RGMS/$packageFile"
}
