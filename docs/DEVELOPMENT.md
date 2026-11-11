# Developing RGMS for World of Warcraft Retail and Forever

This guide takes a first-time World of Warcraft addon contributor from a clean
checkout to a visible in-game proof that RGMS loaded. It applies to current
live **Retail** and Blizzard's official **Forever** client. Classic products
other than Forever, PTR, and Beta clients use different product contracts and
are out of scope.

For subsystem ownership, architecture boundaries, coding conventions, and test
organization, continue with [`CONTRIBUTING.md`](../CONTRIBUTING.md). Maintainers
preparing a distributable package should use the complete
[`RELEASING.md`](RELEASING.md) runbook.

## What you need

- The current live World of Warcraft Retail or Forever client, installed
  through the Battle.net desktop app. Install both for dual-client validation.
- Git.
- Git Bash and Lua 5.1 for the automated suite on Windows.
- Windows PowerShell 5.1 for addon linking; PowerShell 7 for release-tool and
  package-builder tests.
- A text editor. Visual Studio Code is convenient but not required.

There is no package manager or runtime build step before loading the checkout
in WoW. WoW embeds its own Lua runtime, so a separately installed interpreter is
not required merely to load the addon and is not an exact substitute for live
testing. The repository's automated suite does require Lua 5.1. Addon code
should use the Lua features and WoW APIs shared by the supported clients; it
cannot use the normal operating-system, filesystem, or networking libraries.

The repository root is the addon root. `RGMS.toc` is the manifest, and the Lua
files named in that manifest are loaded in order. Runtime source is grouped by
responsibility in `Core`, `UI`, `Roster`, and `Bank`; development-only tests
belong in `Tests` and are not loaded by the game.

## 1. Find the Retail or Forever installation

The normal directory layouts are:

```text
Windows Retail
C:\Program Files (x86)\World of Warcraft\_retail_\
└── Interface\
    └── AddOns\

Windows Forever
C:\Program Files (x86)\World of Warcraft\_forever_\
└── Interface\
    └── AddOns\
```

These are defaults, not requirements. If Battle.net installed WoW elsewhere,
select World of Warcraft in Battle.net, use the gear menu next to **Play**, and
choose the option that reveals the installation in Explorer. The directory
needed by this guide is the one literally named `_retail_` or `_forever_`.

Close the WoW client before creating the addon link or copying the checkout.
Retail and Forever both load the same `RGMS.toc` and runtime source.

## 2. Clone the repository

Run this in the parent directory where you keep source code:

```text
git clone https://github.com/segfaultsoftware/retail-guild-management-system.git
cd retail-guild-management-system
```

Do not install RGMS through CurseForge. Local development and Git access are
all that this workflow requires.

## 3. Put the checkout in `Interface/AddOns`

A directory link is recommended: edits in the checkout are immediately visible
to WoW after a UI reload, and Git metadata stays in the normal development
location. The resulting layout must be exactly:

```text
_retail_/Interface/AddOns/RGMS/RGMS.toc
_retail_/Interface/AddOns/RGMS/Core/Bootstrap.lua

or

_forever_/Interface/AddOns/RGMS/RGMS.toc
_forever_/Interface/AddOns/RGMS/Core/Bootstrap.lua
```

An extra nested directory such as
`AddOns/RGMS/retail-guild-management-system/RGMS.toc` will not work.

### Windows: create a directory junction

From the repository root, choose exactly one supported client. For Retail, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Retail
```

The command uses the default Retail installation path shown above. For the
default Forever installation, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Forever
```

For a custom installation, pass its product directory with `-ClientPath`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Retail -ClientPath "D:\Games\World of Warcraft\_retail_"
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Forever -ClientPath "D:\Games\World of Warcraft\_forever_"
```

An explicit `-ClientPath` is authoritative, so pass the actual `_retail_` or
`_forever_` product directory selected by the required product switch. The old
`-RetailPath` spelling remains an alias for compatibility with existing local
commands, but new instructions use the product-neutral name.

The script creates an `RGMS` directory junction. Creating a junction normally
does not require Administrator privileges. It refuses to replace an existing
file or directory.

To remove the junction before testing an installed package, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Retail -Unlink
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Forever -Unlink
```

Exactly one of `-Retail` or `-Forever` is required for both link and unlink
operations; omitting both or passing both fails before touching either client.
Pass the same product and path options when unlinking from a custom location.
Unlinking is safe to repeat: the script succeeds when the junction is already
absent. It refuses to remove a regular file or directory, or a junction that
does not point to the current checkout.

### Copy instead of link

You can instead copy the checkout to a directory named `RGMS` inside the
selected client's `Interface/AddOns` directory, such as
`_retail_/Interface/AddOns` or `_forever_/Interface/AddOns`. Verify that
`RGMS.toc` is directly inside that directory. After every source change, copy
the changed files again before using `/reload`; linking avoids this extra step.

## 4. Enable and load RGMS

1. Start the supported client you are testing and reach the
   character-selection screen.
2. Select **AddOns**.
3. Find **Retail Guild Management System (RGMS)** and check its box for the
   character you will use. The name comes from the `Title` field in `RGMS.toc`.
4. Log in with that character.
5. Look for `RGMS: [development] loaded. Type /rgms help for available
   commands.` in the default chat frame.
6. Enter `/rgms help`. A second RGMS-owned message confirms that the slash
   command path is operational.
7. Confirm the RGMS minimap button is present, then enter `/rgms` and confirm
   the branded main window opens and closes.

Enable built-in Lua error dialogs while developing:

```text
/console scriptErrors 1
/reload
```

After editing a Lua or manifest file, save it and enter `/reload` in chat. WoW
reloads the entire user interface and rereads addon files; it does not require
a full game restart for ordinary Lua changes. A newly added addon directory is
most reliably discovered by returning to character selection or restarting the
client.

To turn the built-in error dialogs off again:

```text
/console scriptErrors 0
```

## 5. Inspect SavedVariables

`RGMS.toc` declares account-wide `RGMSAccountDB` with `SavedVariables` and
per-character `RGMSCharacterDB` with `SavedVariablesPerCharacter`. The selected
client writes the account-wide file under its own product directory:

```text
C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\RGMS.lua
C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account\<ACCOUNT>\SavedVariables\RGMS.lua
```

The per-character file remains at:

```text
C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\<REALM>\<CHARACTER>\SavedVariables\RGMS.lua
C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account\<ACCOUNT>\<REALM>\<CHARACTER>\SavedVariables\RGMS.lua
```

`<ACCOUNT>`, `<REALM>`, and `<CHARACTER>` are directory names selected by the
client. Custom WoW installations have the same paths relative to `_retail_` or
`_forever_`.

Use `/reload` or log out to make the client flush current values. Then fully
close WoW before opening or copying `RGMS.lua`. Inspecting the file as plain
text while WoW is closed is safe. Do not edit it while the client is running:
WoW keeps an in-memory copy and can overwrite manual changes on reload, logout,
or exit. Treat real account and character names in the path or data as private
when sharing diagnostics.

Both saved values are versioned and validated before RGMS exposes them to scans
or reports. See [SAVED_DATA.md](SAVED_DATA.md) for their exact schemas,
supported migrations, disabled states, and recovery steps.

## 6. Run automated and package checks

From Git Bash at the repository root on Windows, run the complete Lua suite and
the transactional release-preparation tests:

```text
lua.exe Tests/run.lua
bash ./Tests/prepare_release_tests.sh
```

From PowerShell 7, run the Windows install-helper, deterministic
package-builder, and release-workflow helper tests:

```text
pwsh.exe -NoProfile -File .\Tests\link_addon_tests.ps1
pwsh.exe -NoProfile -File .\Tests\build_release_tests.ps1 -LuaCommand 'C:\Program Files (x86)\Lua\5.1\lua.exe'
pwsh.exe -NoProfile -File .\Tests\release_workflow_tests.ps1
```

Each command must exit with status `0`. The Lua suite prints its exact total,
passed, and failed count; the shell and PowerShell suites print their own
passing assertion or scenario counts. To build the deterministic local archive
after those checks, return to Git Bash and run:

```text
./scripts/build-local-release.sh
```

The builder runs the Lua gate again, creates the ZIP twice, requires byte-for-
byte equality, inspects the archive against its explicit allowlist, and reports
the final SHA-256. The complete live-client procedure is in
[`MVP_SCENARIO_CHECKLIST.md`](MVP_SCENARIO_CHECKLIST.md).

## Runtime and manifest assumptions

- The targets are the current supported Retail and Forever clients.
- `RGMS.toc` declares the tested Retail interface first and Forever interface
  second in one comma-delimited `Interface` field. Interface numbers are
  compatibility markers, not Lua language versions, and can change with a
  client patch.
- `AllowLoadGameType` restricts the addon to `standard` and `camelot`. Use
  `camelot`, never `forever`, in client-parsed load directives.
- Runtime files are shared and unconditional unless their implementation
  genuinely differs by product. `Core/ClientFlavor.lua` loads before every
  product-sensitive identity, persistence, adapter, and UI consumer and accepts
  only valid, distinct WoW project globals identifying Mainline or Camelot.
  Missing, invalid, or unknown values produce an unsupported profile, so
  identity and capability-dependent behavior fails closed. Consumers use the
  resulting Retail/Forever and crafting-quality queries instead of reading raw
  project IDs or comparing client versions.
- The manifest's `Title`, `Notes`, `Author`, and `Version` fields provide the
  addon-list and project metadata. Keep the development version placeholder
  until a release process supplies a real release version.
- WoW supplies a sandboxed, modified Lua runtime and each supported client's
  FrameXML/API globals. Test behavior in both clients even if an editor or
  external linter is used.
- Files are plain UTF-8 text. Keep the manifest's file list and load order in
  sync when adding modules.
- Each Lua file receives the same private `RGMS` addon table from WoW. Share
  module state through that table rather than adding new global variables;
  `RGMSCharacterDB` and WoW's slash-command registration globals are the
  deliberate exceptions.
- The automated tests use the project's dependency-free Lua runner and target
  Lua 5.1-compatible syntax. On Windows, run them from Git Bash with
  `lua.exe Tests/run.lua`; no package-manager or network step is required.
- Test files are omitted from `RGMS.toc`, and the repository-owned release
  builder's explicit allowlist excludes development files from addon archives.

Immediately before live verification, collect and record the complete
version/build and interface from each supported client:

```text
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
```

The Retail result must match the first `Interface` value and
`X-RGMS-Retail-Version`; the Forever result must match the second value and
`X-RGMS-Forever-Version`. If either differs, update the manifest only after
validating RGMS against that exact client build.

For a dual-client smoke check, link or install the same checkout or package in
both product directories. In each client, confirm the AddOns list shows RGMS
without an out-of-date or wrong-product warning, login produces the development
load message without a Lua error, both saved-variable files initialize,
`/rgms help` responds, the minimap button toggles the main window, and `/rgms`
opens the branded window.

## Troubleshooting

### RGMS is not listed

- Confirm you launched a supported product and used its `_retail_` or
  `_forever_` directory, not another Classic, PTR, or Beta directory.
- Confirm the exact path is `Interface/AddOns/RGMS/RGMS.toc`; remove any extra
  nesting.
- Confirm the file is really named `RGMS.toc`, not `RGMS.toc.txt`.
- If using a link, confirm its target still points to this checkout.
- Restart the client after creating or moving the addon directory.

### RGMS is marked out of date or for the wrong product

Run `/dump GetBuildInfo()` and `/dump select(4, GetBuildInfo())` on the affected
client. Compare Retail with the first manifest interface and Forever with the
second, and confirm `AllowLoadGameType` contains `standard, camelot`. Update
metadata only after testing RGMS on the new patch. As a short-lived diagnostic,
the AddOns panel can enable **Load out of date AddOns**, but updating and testing
the shared manifest is the correct project fix.

### A Lua error appears at startup

1. Keep `/console scriptErrors 1` enabled and copy the complete first error,
   including the file and line number.
2. Confirm the checkout is current and `/reload` once.
3. Temporarily disable every addon except RGMS to rule out an interaction.
4. Open the named source line in this checkout. Startup errors often mean a
   file in `RGMS.toc` was renamed, the manifest load order is wrong, or a
   supported-client API changed.
5. Include the product and complete `GetBuildInfo()` result with reproduction
   steps when opening an issue. Do not share account or character identifiers
   from the `WTF` directory.
