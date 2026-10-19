# Project Instructions

## Prefer established libraries

- Before implementing substantial functionality from scratch, spend at least a few research cycles looking for established, popular shared libraries that address the problem.
- Evaluate promising libraries for maintenance activity, adoption, compatibility, licensing, documentation, and fit with the project.
- Prefer a validated shared solution when it handles important compatibility or ecosystem concerns that a custom implementation could overlook.
- Document why a custom implementation is preferable when no suitable library is found.
- For example, minimap functionality should account for established minimap libraries, other minimap addons, and minimap-button grouping solutions before introducing custom positioning or rotation logic.

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
