# Retail Guild Management System

RGMS is a World of Warcraft Retail addon that will integrate with the hosted
RGMS application and help guild officers inspect guild-roster and guild-bank
data.

The repository currently includes a minimal addon skeleton. When it loads, it
prints a development confirmation in chat and exposes `/rgms help` so a
contributor can verify their local setup before working on product features.

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
