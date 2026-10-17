# Project Instructions

## Automated tests

- On Windows, run the Lua test suite from Git Bash with
  `lua.exe Tests/run.lua`.
- Do not invoke the suite through PowerShell. The installed Lua 5.1 runtime can
  fail there with a Windows DLL-relocation error.

## Changelog

- Every implementation task must update `CHANGELOG.md` with a concise summary
  of the completed work under `## Unreleased`, whether or not the task is tied
  to a GitHub issue.
- If `CHANGELOG.md` does not contain an `## Unreleased` section, add one above
  the most recent version section before recording the change.
