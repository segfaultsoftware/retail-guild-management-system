[CmdletBinding()]
param(
    [string]$LuaCommand
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:Passed = 0
$script:Scenario = 0
$script:RepositoryPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:PowerShellCommand = (Get-Command pwsh -ErrorAction Stop).Source
$script:DistributionFiles = @(
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    'THIRD_PARTY_NOTICES.md',
    'assets/rgms-logo.png',
    'assets/rgms-minimap-icon.png',
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/icons/check.png',
    'assets/icons/chevron-down.png',
    'assets/icons/chevron-right.png',
    'assets/icons/loader-circle.png',
    'assets/icons/notebook-pen.png',
    'assets/icons/refresh-cw.png',
    'assets/icons/tag.png',
    'assets/icons/x.png',
    'licenses/Inter-OFL.txt',
    'licenses/Lucide-ISC.txt'
)
$script:DefaultRuntimeEntries = @(
    'Core\Shared.lua',
    'Core\Retail.lua [AllowLoadGameType standard]',
    'Core\Forever.lua [AllowLoadGameType camelot][ExcludeLoadGameType standard]'
)
$script:RuntimeFiles = @(
    'Core/Shared.lua',
    'Core/Retail.lua',
    'Core/Forever.lua'
)

if ([string]::IsNullOrWhiteSpace($LuaCommand)) {
    foreach ($candidate in @('lua5.1', 'lua', 'lua.exe')) {
        $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $resolved) {
            $LuaCommand = $resolved.Source
            break
        }
    }
}
if ([string]::IsNullOrWhiteSpace($LuaCommand)) {
    throw 'Lua was not found. Pass its executable path with -LuaCommand.'
}
$testCommandName = [System.IO.Path]::GetFileNameWithoutExtension($LuaCommand)
$script:UsesShellTestProgram = $testCommandName -ieq 'bash' -or
    $testCommandName -ieq 'sh'

$script:TemporaryRoot = Join-Path (
    [System.IO.Path]::GetTempPath()
) "rgms-build-release-tests-$([System.Guid]::NewGuid().ToString('N'))"
[System.IO.Directory]::CreateDirectory($script:TemporaryRoot) | Out-Null

function Assert-True {
    param([bool]$Value, [string]$Message)

    if (-not $Value) {
        throw $Message
    }
    $script:Passed += 1
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)

    if ($Expected -cne $Actual) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
    $script:Passed += 1
}

function Assert-Contains {
    param([string]$Text, [string]$Expected, [string]$Message)

    if (-not $Text.Contains($Expected, [System.StringComparison]::Ordinal)) {
        throw "$Message Missing '$Expected'. Output:`n$Text"
    }
    $script:Passed += 1
}

function Assert-SequenceEqual {
    param([string[]]$Expected, [string[]]$Actual, [string]$Message)

    $expectedText = [string]::Join("`n", $Expected)
    $actualText = [string]::Join("`n", $Actual)
    if ($expectedText -cne $actualText) {
        throw "$Message`nExpected:`n$expectedText`nActual:`n$actualText"
    }
    $script:Passed += 1
}

function Write-Utf8File {
    param([string]$Path, [string]$Content)

    $parent = Split-Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($parent)) {
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    }
    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Write-FixtureManifest {
    param(
        [string]$FixturePath,
        [AllowEmptyString()]
        [string]$InterfaceValue,
        [string[]]$RuntimeEntries = $script:DefaultRuntimeEntries
    )

    $lines = @(
        "## Interface: $InterfaceValue",
        '## AllowLoadGameType: standard, camelot',
        '## Title: RGMS package fixture',
        '## Notes: Deterministic package fixture.',
        '## Author: RGMS tests',
        '## Version: 1.2.3',
        '## X-RGMS-Retail-Version: 12.1.5 (build 12345)',
        '## X-RGMS-Forever-Version: 1.60.1 (build 67890)',
        '## X-Curse-Project-ID: 1741733',
        '## SavedVariables: RGMSAccountDB',
        '## SavedVariablesPerCharacter: RGMSCharacterDB',
        '## OptionalDeps: Auctionator',
        ''
    ) + @($RuntimeEntries)
    $content = [string]::Join("`r`n", $lines) + "`r`n"
    Write-Utf8File -Path (Join-Path $FixturePath 'RGMS.toc') -Content $content
}

function Set-FixtureManifestField {
    param(
        [string]$FixturePath,
        [string]$Name,
        [AllowEmptyString()]
        [string]$Value
    )

    $manifestPath = Join-Path $FixturePath 'RGMS.toc'
    $lines = @([System.IO.File]::ReadAllLines($manifestPath))
    $prefix = "## ${Name}:"
    $indexes = @(
        for ($index = 0; $index -lt $lines.Count; $index += 1) {
            if ($lines[$index].StartsWith($prefix, [System.StringComparison]::Ordinal)) {
                $index
            }
        }
    )
    if ($indexes.Count -ne 1) {
        throw "Fixture manifest must contain exactly one '$Name' field."
    }
    $lines[$indexes[0]] = "$prefix $Value"
    Write-Utf8File `
        -Path $manifestPath `
        -Content ([string]::Join("`r`n", $lines) + "`r`n")
}

function Remove-FixtureManifestField {
    param(
        [string]$FixturePath,
        [string]$Name
    )

    $manifestPath = Join-Path $FixturePath 'RGMS.toc'
    $prefix = "## ${Name}:"
    $lines = @([System.IO.File]::ReadAllLines($manifestPath))
    $remaining = @(
        $lines | Where-Object {
            -not $_.StartsWith($prefix, [System.StringComparison]::Ordinal)
        }
    )
    if ($remaining.Count -ne ($lines.Count - 1)) {
        throw "Fixture manifest must contain exactly one '$Name' field."
    }
    Write-Utf8File `
        -Path $manifestPath `
        -Content ([string]::Join("`r`n", $remaining) + "`r`n")
}

function New-Fixture {
    param([string]$Name, [string]$InterfaceValue = '120105, 16001')

    $script:Scenario += 1
    $fixturePath = Join-Path $script:TemporaryRoot (
        "scenario-$($script:Scenario)-$Name"
    )
    [System.IO.Directory]::CreateDirectory($fixturePath) | Out-Null
    [System.IO.Directory]::CreateDirectory(
        (Join-Path $fixturePath 'scripts')
    ) | Out-Null
    Copy-Item -LiteralPath (
        Join-Path $script:RepositoryPath 'scripts/build-release.ps1'
    ) -Destination (Join-Path $fixturePath 'scripts/build-release.ps1')

    foreach ($relativePath in $script:DistributionFiles) {
        $systemPath = $relativePath.Replace(
            '/',
            [System.IO.Path]::DirectorySeparatorChar
        )
        Write-Utf8File `
            -Path (Join-Path $fixturePath $systemPath) `
            -Content "fixture content for $relativePath`n"
    }
    foreach ($relativePath in $script:RuntimeFiles) {
        $systemPath = $relativePath.Replace(
            '/',
            [System.IO.Path]::DirectorySeparatorChar
        )
        Write-Utf8File `
            -Path (Join-Path $fixturePath $systemPath) `
            -Content "-- fixture runtime: $relativePath`n"
    }
    $testProgram = if ($script:UsesShellTestProgram) {
        "#!/usr/bin/env bash`necho '1 tests: 1 passed, 0 failed'`n"
    }
    else {
        'print("1 tests: 1 passed, 0 failed")' + "`n"
    }
    Write-Utf8File `
        -Path (Join-Path $fixturePath 'Tests/run.lua') `
        -Content $testProgram
    Write-Utf8File `
        -Path (Join-Path $fixturePath 'Tests/invoke-build.ps1') `
        -Content @'
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BuildScript,
    [Parameter(Mandatory)]
    [string]$OutputDirectory,
    [Parameter(Mandatory)]
    [string]$LuaCommand
)

$ErrorActionPreference = 'Stop'
try {
    & $BuildScript `
        -Version 1.2.3 `
        -OutputDirectory $OutputDirectory `
        -LuaCommand $LuaCommand
}
catch {
    Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    exit 1
}
'@

    # These files prove that packaging remains an explicit allowlist rather
    # than a repository-tree copy operation.
    Write-Utf8File -Path (Join-Path $fixturePath '.env') -Content "TOKEN=nope`n"
    Write-Utf8File -Path (Join-Path $fixturePath '.pkgmeta') -Content "ignore: []`n"
    Write-Utf8File `
        -Path (Join-Path $fixturePath 'docs/contributor-notes.md') `
        -Content "not distributable`n"
    Write-Utf8File `
        -Path (Join-Path $fixturePath 'Tests/credentials.key') `
        -Content "not a real credential`n"

    Write-FixtureManifest `
        -FixturePath $fixturePath `
        -InterfaceValue $InterfaceValue
    return $fixturePath
}

function Invoke-FixtureBuild {
    param([string]$FixturePath, [string]$OutputName)

    $outputPath = Join-Path $FixturePath $OutputName
    $arguments = @(
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-File',
        (Join-Path $FixturePath 'Tests/invoke-build.ps1'),
        '-BuildScript',
        (Join-Path $FixturePath 'scripts/build-release.ps1'),
        '-OutputDirectory',
        $outputPath,
        '-LuaCommand',
        $LuaCommand
    )
    $outputLines = @(& $script:PowerShellCommand @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($outputLines | Out-String)
        OutputPath = $outputPath
        ArchivePath = Join-Path $outputPath 'RGMS-1.2.3.zip'
    }
}

function Assert-NoRetainedArtifact {
    param([string]$OutputPath, [string]$Message)

    $retained = @(
        if (Test-Path -LiteralPath $OutputPath) {
            Get-ChildItem -LiteralPath $OutputPath -File -Force -Recurse |
                Where-Object {
                    $_.Name.EndsWith('.zip', [System.StringComparison]::OrdinalIgnoreCase) -or
                    $_.Name.EndsWith('.tmp', [System.StringComparison]::OrdinalIgnoreCase)
                }
        }
    )
    Assert-Equal 0 $retained.Count $Message
}

function Assert-BuildFailsCleanly {
    param(
        [string]$FixturePath,
        [string]$OutputName,
        [string]$ExpectedOutput
    )

    $result = Invoke-FixtureBuild `
        -FixturePath $FixturePath `
        -OutputName $OutputName
    Assert-True ($result.ExitCode -ne 0) 'Invalid package fixture built successfully.'
    if (-not [string]::IsNullOrEmpty($ExpectedOutput)) {
        Assert-Contains `
            -Text $result.Output `
            -Expected $ExpectedOutput `
            -Message 'Package failure did not explain the rejected input.'
    }
    Assert-NoRetainedArtifact `
        -OutputPath $result.OutputPath `
        -Message 'A failed package build retained an archive or temporary ZIP.'
}

function Get-Sha256 {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-ZipEntryBytes {
    param([System.IO.Compression.ZipArchiveEntry]$Entry)

    $entryStream = $Entry.Open()
    try {
        $memory = [System.IO.MemoryStream]::new()
        try {
            $entryStream.CopyTo($memory)
            return ,$memory.ToArray()
        }
        finally {
            $memory.Dispose()
        }
    }
    finally {
        $entryStream.Dispose()
    }
}

function Assert-Archive {
    param([string]$FixturePath, [string]$ArchivePath)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $expectedRelativePaths = @('RGMS.toc') +
        @($script:RuntimeFiles) +
        @($script:DistributionFiles)
    [System.Array]::Sort(
        $expectedRelativePaths,
        [System.StringComparer]::Ordinal
    )
    $expectedEntries = @(
        $expectedRelativePaths | ForEach-Object { "RGMS/$_" }
    )

    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $actualEntries = @($archive.Entries | ForEach-Object { $_.FullName })
        Assert-SequenceEqual `
            -Expected $expectedEntries `
            -Actual $actualEntries `
            -Message 'The archive layout or deterministic entry order is wrong.'
        Assert-Equal `
            1 `
            @($archive.Entries | Where-Object { $_.FullName.EndsWith('.toc') }).Count `
            'The archive must contain exactly one source manifest.'

        foreach ($relativePath in $expectedRelativePaths) {
            $entryName = "RGMS/$relativePath"
            $entry = $archive.GetEntry($entryName)
            Assert-True ($null -ne $entry) "Archive entry is missing: $entryName"
            Assert-Equal `
                '1980-01-01T00:00:00' `
                $entry.LastWriteTime.DateTime.ToString('s') `
                "Archive timestamp is not fixed: $entryName"
            Assert-Equal `
                -2119958528 `
                $entry.ExternalAttributes `
                "Archive permissions are not fixed: $entryName"
            Assert-Equal `
                $entry.Length `
                $entry.CompressedLength `
                "Archive entry was not stored deterministically: $entryName"

            $sourceRelativePath = $relativePath.Replace(
                '/',
                [System.IO.Path]::DirectorySeparatorChar
            )
            $sourceBytes = [System.IO.File]::ReadAllBytes(
                (Join-Path $FixturePath $sourceRelativePath)
            )
            $entryBytes = Read-ZipEntryBytes -Entry $entry
            Assert-Equal `
                ([System.Convert]::ToBase64String($sourceBytes)) `
                ([System.Convert]::ToBase64String($entryBytes)) `
                "Archive content differs from its verified source: $entryName"
        }
    }
    finally {
        $archive.Dispose()
    }
}

try {
    # A dual-interface manifest packages the union of shared, standard-only,
    # and camelot-only runtime files while preserving its exact source bytes.
    $dualFixture = New-Fixture -Name 'dual-interface'
    $firstBuild = Invoke-FixtureBuild `
        -FixturePath $dualFixture `
        -OutputName 'output-a'
    Assert-Equal 0 $firstBuild.ExitCode "Dual-product build failed.`n$($firstBuild.Output)"
    Assert-True `
        (Test-Path -LiteralPath $firstBuild.ArchivePath -PathType Leaf) `
        'Dual-product build did not create its one canonical archive.'
    Assert-Archive `
        -FixturePath $dualFixture `
        -ArchivePath $firstBuild.ArchivePath
    $outputArchives = @(
        Get-ChildItem -LiteralPath $firstBuild.OutputPath -File -Force
    )
    Assert-Equal 1 $outputArchives.Count 'A build produced product-specific or temporary archives.'
    Assert-Equal 'RGMS-1.2.3.zip' $outputArchives[0].Name 'The canonical archive name changed.'

    $reportedHash = [regex]::Match(
        $firstBuild.Output,
        '(?im)^SHA-256:\s*([0-9a-f]{64})\s*$'
    )
    Assert-True $reportedHash.Success 'The package builder did not report a SHA-256 checksum.'
    Assert-Equal `
        (Get-Sha256 -Path $firstBuild.ArchivePath) `
        $reportedHash.Groups[1].Value.ToLowerInvariant() `
        'The reported SHA-256 does not match the canonical archive.'

    # A second external invocation must reproduce the same bytes, in addition
    # to the builder's own two-build equality check within each invocation.
    $secondBuild = Invoke-FixtureBuild `
        -FixturePath $dualFixture `
        -OutputName 'output-b'
    Assert-Equal 0 $secondBuild.ExitCode "Repeated package build failed.`n$($secondBuild.Output)"
    Assert-Equal `
        (Get-Sha256 -Path $firstBuild.ArchivePath) `
        (Get-Sha256 -Path $secondBuild.ArchivePath) `
        'Repeated package builds produced different checksums.'
    Assert-Equal `
        ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($firstBuild.ArchivePath))) `
        ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($secondBuild.ArchivePath))) `
        'Repeated package builds were not byte-for-byte identical.'

    # Refusing an overwrite must leave the existing artifact untouched and
    # must not run far enough to retain temporary build files.
    $beforeOverwriteHash = Get-Sha256 -Path $firstBuild.ArchivePath
    $overwriteAttempt = Invoke-FixtureBuild `
        -FixturePath $dualFixture `
        -OutputName 'output-a'
    Assert-True ($overwriteAttempt.ExitCode -ne 0) 'An existing release artifact was overwritten.'
    Assert-Contains `
        -Text $overwriteAttempt.Output `
        -Expected 'Refusing to overwrite existing release artifact' `
        -Message 'The overwrite refusal was not reported.'
    Assert-Equal `
        $beforeOverwriteHash `
        (Get-Sha256 -Path $firstBuild.ArchivePath) `
        'The refused overwrite changed the existing archive.'
    Assert-Equal `
        1 `
        @(Get-ChildItem -LiteralPath $firstBuild.OutputPath -File -Force).Count `
        'The refused overwrite retained a temporary build file.'

    # Whitespace is accepted around the required dual-interface values.
    $whitespaceFixture = New-Fixture `
        -Name 'interface-whitespace' `
        -InterfaceValue ' 120105 , 16001 '
    $whitespaceBuild = Invoke-FixtureBuild `
        -FixturePath $whitespaceFixture `
        -OutputName 'output'
    Assert-Equal 0 $whitespaceBuild.ExitCode "Whitespace interface list failed.`n$($whitespaceBuild.Output)"

    # Missing targets, empty items, duplicate values, non-numeric values, and
    # malformed separators fail before an artifact can be retained.
    $invalidInterfaces = @(
        '',
        '120105',
        ',120105',
        '120105,',
        '120105,,16001',
        '120105,   ,16001',
        '120105,120105',
        '120105, 120105',
        '120105, camelot',
        '120105;16001',
        '120105,16001,11509'
    )
    foreach ($invalidInterface in $invalidInterfaces) {
        $fixture = New-Fixture `
            -Name 'invalid-interface' `
            -InterfaceValue $invalidInterface
        Assert-BuildFailsCleanly `
            -FixturePath $fixture `
            -OutputName 'output' `
            -ExpectedOutput ''
    }

    # Every package carries the complete canonical dual-client metadata. A
    # missing, renamed, reordered, or substituted declaration fails before the
    # Lua gate or archive creation.
    $requiredDualMetadata = @(
        'AllowLoadGameType',
        'X-RGMS-Retail-Version',
        'X-RGMS-Forever-Version',
        'X-Curse-Project-ID',
        'SavedVariables',
        'SavedVariablesPerCharacter',
        'OptionalDeps'
    )
    foreach ($fieldName in $requiredDualMetadata) {
        $fixture = New-Fixture -Name 'missing-dual-metadata'
        Remove-FixtureManifestField -FixturePath $fixture -Name $fieldName
        Assert-BuildFailsCleanly `
            -FixturePath $fixture `
            -OutputName 'output' `
            -ExpectedOutput "Manifest field '$fieldName' is missing or empty."
    }

    $invalidExactMetadata = @(
        @{
            Name = 'AllowLoadGameType'
            Value = 'camelot, standard'
            Expected = "must equal 'standard, camelot'"
        },
        @{
            Name = 'X-Curse-Project-ID'
            Value = '1741734'
            Expected = "must equal '1741733'"
        },
        @{
            Name = 'SavedVariables'
            Value = 'RGMSOtherAccountDB'
            Expected = "must equal 'RGMSAccountDB'"
        },
        @{
            Name = 'SavedVariablesPerCharacter'
            Value = 'RGMSOtherCharacterDB'
            Expected = "must equal 'RGMSCharacterDB'"
        },
        @{
            Name = 'OptionalDeps'
            Value = 'Auctionator, OtherAddon'
            Expected = "must equal 'Auctionator'"
        }
    )
    foreach ($metadataCase in $invalidExactMetadata) {
        $fixture = New-Fixture -Name 'invalid-dual-metadata'
        Set-FixtureManifestField `
            -FixturePath $fixture `
            -Name $metadataCase.Name `
            -Value $metadataCase.Value
        Assert-BuildFailsCleanly `
            -FixturePath $fixture `
            -OutputName 'output' `
            -ExpectedOutput $metadataCase.Expected
    }

    $invalidProductVersions = @(
        @{ Name = 'X-RGMS-Retail-Version'; Value = 'Retail 12.1.5' },
        @{ Name = 'X-RGMS-Retail-Version'; Value = '12.1' },
        @{ Name = 'X-RGMS-Forever-Version'; Value = '01.60.1' },
        @{ Name = 'X-RGMS-Forever-Version'; Value = '1.60.1build67890' }
    )
    foreach ($metadataCase in $invalidProductVersions) {
        $fixture = New-Fixture -Name 'invalid-product-version'
        Set-FixtureManifestField `
            -FixturePath $fixture `
            -Name $metadataCase.Name `
            -Value $metadataCase.Value
        Assert-BuildFailsCleanly `
            -FixturePath $fixture `
            -OutputName 'output' `
            -ExpectedOutput "Manifest field '$($metadataCase.Name)' must begin with a canonical X.Y.Z product version"
    }

    # Every supported inline directive is trailing, syntactically complete,
    # restricted to standard/camelot, unique, and non-conflicting.
    $invalidDirectiveEntries = @(
        'Core\Retail.lua [AllowLoadGameType standard',
        'Core\Retail.lua [AllowLoadGameType ]',
        'Core\Retail.lua [UnknownDirective standard]',
        'Core\Retail.lua [AllowLoadGameType forever]',
        'Core\Retail.lua [AllowLoadGameType standard] trailing-junk',
        'Core\Retail.lua [AllowLoadGameType standard,,camelot]',
        'Core\Retail.lua [AllowLoadGameType standard][AllowLoadGameType camelot]',
        'Core\Retail.lua [AllowLoadGameType standard][ExcludeLoadGameType standard]',
        'Core\[Game]\Retail.lua [AllowLoadGameType standard]',
        '[AllowLoadGameType standard] Core\Retail.lua'
    )
    foreach ($invalidEntry in $invalidDirectiveEntries) {
        $fixture = New-Fixture -Name 'invalid-directive'
        Write-FixtureManifest `
            -FixturePath $fixture `
            -InterfaceValue '120105, 16001' `
            -RuntimeEntries @('Core\Shared.lua', $invalidEntry)
        Assert-BuildFailsCleanly `
            -FixturePath $fixture `
            -OutputName 'output' `
            -ExpectedOutput ''
    }

    $missingFixture = New-Fixture -Name 'missing-conditional-file'
    Remove-Item -LiteralPath (Join-Path $missingFixture 'Core/Forever.lua') -Force
    Assert-BuildFailsCleanly `
        -FixturePath $missingFixture `
        -OutputName 'output' `
        -ExpectedOutput 'does not exist'

    $duplicateFixture = New-Fixture -Name 'duplicate-conditional-file'
    Write-FixtureManifest `
        -FixturePath $duplicateFixture `
        -InterfaceValue '120105, 16001' `
        -RuntimeEntries @(
            $script:DefaultRuntimeEntries +
                'Core/Retail.lua [AllowLoadGameType camelot]'
        )
    Assert-BuildFailsCleanly `
        -FixturePath $duplicateFixture `
        -OutputName 'output' `
        -ExpectedOutput 'listed more than once'

    $parentPathFixture = New-Fixture -Name 'parent-path'
    Write-FixtureManifest `
        -FixturePath $parentPathFixture `
        -InterfaceValue '120105, 16001' `
        -RuntimeEntries @('../outside.lua [AllowLoadGameType standard]')
    Assert-BuildFailsCleanly `
        -FixturePath $parentPathFixture `
        -OutputName 'output' `
        -ExpectedOutput 'repository-relative'

    $outsidePath = Join-Path $script:TemporaryRoot 'absolute-outside.lua'
    Write-Utf8File -Path $outsidePath -Content "-- outside`n"
    $absolutePathFixture = New-Fixture -Name 'absolute-path'
    Write-FixtureManifest `
        -FixturePath $absolutePathFixture `
        -InterfaceValue '120105, 16001' `
        -RuntimeEntries @($outsidePath)
    Assert-BuildFailsCleanly `
        -FixturePath $absolutePathFixture `
        -OutputName 'output' `
        -ExpectedOutput 'repository-relative'

    # Exercise regular-file enforcement where the host permits creating a
    # detectable symbolic link without elevation.
    $linkFixture = New-Fixture -Name 'linked-runtime'
    $linkTarget = Join-Path $script:TemporaryRoot 'link-target.lua'
    Write-Utf8File -Path $linkTarget -Content "-- linked outside source`n"
    $linkPath = Join-Path $linkFixture 'Core/Linked.lua'
    $linkCreated = $false
    try {
        New-Item `
            -ItemType SymbolicLink `
            -Path $linkPath `
            -Target $linkTarget `
            -ErrorAction Stop | Out-Null
        $linkItem = Get-Item -LiteralPath $linkPath -Force
        $linkCreated = -not [string]::IsNullOrWhiteSpace($linkItem.LinkType) -or
            (($linkItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    }
    catch {
        Write-Output 'Skipped linked-runtime assertion: this host cannot create symbolic links.'
    }
    if ($linkCreated) {
        Write-FixtureManifest `
            -FixturePath $linkFixture `
            -InterfaceValue '120105, 16001' `
            -RuntimeEntries @('Core\Linked.lua [AllowLoadGameType standard]')
        Assert-BuildFailsCleanly `
            -FixturePath $linkFixture `
            -OutputName 'output' `
            -ExpectedOutput 'must be a regular file, not a link'
    }

    # The Lua gate must remain mandatory and precede archive creation.
    $luaFailureFixture = New-Fixture -Name 'lua-gate-failure'
    $failingTestProgram = if ($script:UsesShellTestProgram) {
        "#!/usr/bin/env bash`necho 'intentional test failure' >&2`nexit 7`n"
    }
    else {
        'io.stderr:write("intentional Lua failure\n")' + "`n" +
            'os.exit(7)' + "`n"
    }
    Write-Utf8File `
        -Path (Join-Path $luaFailureFixture 'Tests/run.lua') `
        -Content $failingTestProgram
    Assert-BuildFailsCleanly `
        -FixturePath $luaFailureFixture `
        -OutputName 'output' `
        -ExpectedOutput 'Automated tests failed with exit code 7'

    Write-Output "$($script:Passed) build release tests: $($script:Passed) passed, 0 failed"
}
finally {
    if (Test-Path -LiteralPath $script:TemporaryRoot) {
        Remove-Item -LiteralPath $script:TemporaryRoot -Recurse -Force
    }
}
