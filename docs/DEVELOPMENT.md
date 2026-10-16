# Developing RGMS for World of Warcraft Retail

This guide takes a first-time World of Warcraft addon contributor from a clean
checkout to a visible in-game proof that RGMS loaded. It applies only to the
current live **Retail** client. Classic, Classic Era, PTR, and Beta clients use
different directories and interface versions and are out of scope.

For subsystem ownership, architecture boundaries, coding conventions, and test
organization, continue with [`CONTRIBUTING.md`](../CONTRIBUTING.md). Maintainers
preparing a distributable package should use the complete
[`RELEASING.md`](RELEASING.md) runbook.

## What you need

- The current live World of Warcraft Retail client, installed through the
  Battle.net desktop app.
- Git.
- On Windows, Windows PowerShell 5.1 or PowerShell 7. On macOS, the built-in
  Terminal and a POSIX-compatible shell are sufficient.
- A text editor. Visual Studio Code is convenient but not required.

There are no packages to download and no build step. WoW embeds its own Lua
runtime, so a separately installed Lua interpreter is neither needed nor an
exact substitute for testing inside the client. Addon code should use the Lua
features and WoW APIs supplied by the current Retail client; it cannot use the
normal operating-system, filesystem, or networking libraries.

The repository root is the addon root. `RGMS.toc` is the manifest, and the Lua
files named in that manifest are loaded in order. Runtime source is grouped by
responsibility in `Core`, `UI`, `Roster`, and `Bank`; development-only tests
belong in `Tests` and are not loaded by the game.

## 1. Find the Retail installation

The normal directory layouts are:

```text
Windows
C:\Program Files (x86)\World of Warcraft\_retail_\
└── Interface\
    └── AddOns\

macOS
/Applications/World of Warcraft/_retail_/
└── Interface/
    └── AddOns/
```

These are defaults, not requirements. If Battle.net installed WoW elsewhere,
select World of Warcraft in Battle.net, use the gear menu next to **Play**, and
choose the option that reveals the installation in Explorer or Finder. The
directory needed by this guide is the one literally named `_retail_`.

Close the WoW client before creating the addon link or copying the checkout.

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
```

An extra nested directory such as
`AddOns/RGMS/retail-guild-management-system/RGMS.toc` will not work.

### Windows: create a directory junction

From the repository root, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1
```

The command uses the default installation path shown above. For a custom Retail
location, pass its `_retail_` directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -RetailPath "D:\Games\World of Warcraft\_retail_"
```

The script creates an `RGMS` directory junction. Creating a junction normally
does not require Administrator privileges. It refuses to replace an existing
file or directory.

To remove the junction before testing an installed package, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1 -Unlink
```

Pass the same `-RetailPath` value when unlinking from a custom Retail location.
Unlinking is safe to repeat: the script succeeds when the junction is already
absent. It refuses to remove a regular file or directory, or a junction that
does not point to the current checkout.

### macOS: create a symbolic link

From the repository root, run:

```sh
sh ./scripts/link-addon.sh
```

For a custom Retail location, supply its `_retail_` directory as the first
argument:

```sh
sh ./scripts/link-addon.sh "/Volumes/Games/World of Warcraft/_retail_"
```

### Copy instead of link

You can instead copy the checkout to a directory named `RGMS` inside
`_retail_/Interface/AddOns`. Verify that `RGMS.toc` is directly inside that
directory. After every source change, copy the changed files again before using
`/reload`; linking avoids this extra step.

## 4. Enable and load RGMS

1. Start the live Retail client and reach the character-selection screen.
2. Select **AddOns**.
3. Find **Retail Guild Management System (RGMS)** and check its box for the
   character you will use. The name comes from the `Title` field in `RGMS.toc`.
4. Log in with that character.
5. Look for `RGMS: [development] loaded. Type /rgms help for available
   commands.` in the default chat frame.
6. Enter `/rgms help`. A second RGMS-owned message confirms that the slash
   command path is operational.

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
per-character `RGMSCharacterDB` with `SavedVariablesPerCharacter`. Retail writes
the account-wide file at:

```text
Windows
C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\RGMS.lua

macOS
/Applications/World of Warcraft/_retail_/WTF/Account/<ACCOUNT>/SavedVariables/RGMS.lua
```

The per-character file remains at:

```text
Windows
C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\<REALM>\<CHARACTER>\SavedVariables\RGMS.lua

macOS
/Applications/World of Warcraft/_retail_/WTF/Account/<ACCOUNT>/<REALM>/<CHARACTER>/SavedVariables/RGMS.lua
```

`<ACCOUNT>`, `<REALM>`, and `<CHARACTER>` are directory names selected by the
client. Custom WoW installations have the same path relative to `_retail_`.

Use `/reload` or log out to make the client flush current values. Then fully
close WoW before opening or copying `RGMS.lua`. Inspecting the file as plain
text while WoW is closed is safe. Do not edit it while the client is running:
WoW keeps an in-memory copy and can overwrite manual changes on reload, logout,
or exit. Treat real account and character names in the path or data as private
when sharing diagnostics.

Both saved values are versioned and validated before RGMS exposes them to scans
or reports. See [SAVED_DATA.md](SAVED_DATA.md) for their exact schemas,
supported migrations, disabled states, and recovery steps.

## Runtime and manifest assumptions

- The target is the current live Retail client only.
- `RGMS.toc` currently declares Retail interface `120100`. The number is a
  compatibility marker, not a Lua language version. Retail can change it with
  a game patch.
- The manifest's `Title`, `Notes`, `Author`, and `Version` fields provide the
  addon-list and project metadata. Keep the development version placeholder
  until a release process supplies a real release version.
- WoW supplies a sandboxed, modified Lua runtime and the Retail FrameXML/API
  globals. Test behavior in WoW even if an editor or external linter is used.
- Files are plain UTF-8 text. Keep the manifest's file list and load order in
  sync when adding modules.
- Each Lua file receives the same private `RGMS` addon table from WoW. Share
  module state through that table rather than adding new global variables;
  `RGMSCharacterDB` and WoW's slash-command registration globals are the
  deliberate exceptions.
- The automated tests use the project's dependency-free Lua runner and target
  Lua 5.1-compatible syntax. With a Lua interpreter installed, run them outside
  WoW with `lua Tests/run.lua`; no package-manager or network step is required.
- Test files are omitted from `RGMS.toc`, and the repository-owned release
  builder's explicit allowlist excludes development files from addon archives.

The client can report its current interface number in chat:

```text
/dump select(4, GetBuildInfo())
```

If it differs from the `Interface` value in `RGMS.toc`, update the manifest as
part of validating RGMS against that Retail patch.

## Troubleshooting

### RGMS is not listed

- Confirm you launched live Retail and used the `_retail_` directory, not a
  `_classic_`, `_ptr_`, or `_beta_` directory.
- Confirm the exact path is `Interface/AddOns/RGMS/RGMS.toc`; remove any extra
  nesting.
- Confirm the file is really named `RGMS.toc`, not `RGMS.toc.txt`.
- If using a link, confirm its target still points to this checkout.
- Restart the client after creating or moving the addon directory.

### RGMS is marked out of date

Run `/dump select(4, GetBuildInfo())` on the live Retail client and compare the
result with the first line of `RGMS.toc`. Update that `Interface` value after
testing RGMS on the new patch. As a short-lived diagnostic, the character
screen's AddOns panel can enable **Load out of date AddOns**, but updating and
testing the manifest is the correct project fix.

### A Lua error appears at startup

1. Keep `/console scriptErrors 1` enabled and copy the complete first error,
   including the file and line number.
2. Confirm the checkout is current and `/reload` once.
3. Temporarily disable every addon except RGMS to rule out an interaction.
4. Open the named source line in this checkout. Startup errors often mean a
   file in `RGMS.toc` was renamed, the manifest load order is wrong, or a Retail
   API changed.
5. Include the Retail version from `GetBuildInfo()` and reproduction steps when
   opening an issue. Do not share account or character identifiers from the
   `WTF` directory.
