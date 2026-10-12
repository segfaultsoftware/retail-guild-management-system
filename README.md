# Retail Guild Management System

RGMS is a World of Warcraft Retail addon that will integrate with the hosted
RGMS application and help guild officers inspect guild-roster and guild-bank
data.

The repository includes the addon shell, per-character saved data, and a
transactional Retail guild-roster scanner. Each login attempts one background
roster scan for guilded characters; `/rgms scanroster` and the Roster refresh
button start the same transaction manually. Incomplete and failed scans leave
the last successful observation untouched. Successful scans track each current
member's tenure at their numeric rank position using Pacific calendar dates.
Members absent from a successful scan are retained with a warning state for up
to 21 Pacific calendar days so officers can review recent departures without
keeping stale records indefinitely.
Opening the default guild-bank window starts a transactional scan of every
purchased tab the character can access. The Bank refresh button can repeat the
scan while the bank is open; incomplete, failed, timed-out, and canceled scans
leave the last successful bank observation untouched.
`/rgms reset` provides a
confirmation-protected observation reset and also recovers from corrupt or
incompatible saved data.

## Tests

With Lua installed, run the complete test suite outside World of Warcraft from
the repository root:

```text
lua Tests/run.lua
```

The suite is dependency-free and deterministic. See
[Tests/README.md](Tests/README.md) for Lua version details, fixture and test
examples, and the intentional failure check.

## Quick start

1. Install the current live **World of Warcraft Retail** client.
2. Clone this repository.
3. Link the checkout into Retail's `Interface/AddOns` directory:
   - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\link-addon.ps1`
   - macOS: `sh ./scripts/link-addon.sh`
4. Start Retail, enable **Retail Guild Management System (RGMS)** for a
   character, and log in.
5. Confirm that `RGMS: [development] loaded` appears in chat, then run
   `/rgms help`.

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the complete setup,
SavedVariables, runtime assumptions, iteration workflow, and troubleshooting
guide.

The versioned per-character persistence schema, validation behavior, and
recovery procedure are documented in
[docs/SAVED_DATA.md](docs/SAVED_DATA.md).
