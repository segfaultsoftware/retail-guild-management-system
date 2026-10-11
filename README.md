# Retail Guild Management System

RGMS is a World of Warcraft Retail addon that will integrate with the hosted
RGMS application and help guild officers inspect guild-roster and guild-bank
data.

The repository currently includes a minimal addon skeleton. When it loads, it
prints a development confirmation in chat and exposes `/rgms help` so a
contributor can verify their local setup before working on product features.
`/rgms reset` provides a confirmation-protected, per-character observation
reset and also recovers from corrupt or incompatible saved data.

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
