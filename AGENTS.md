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

## Commit messages

- For a commit tied to a GitHub issue, use this format:

  ```text
  <Type> #123: <Brief Description>

  <One to three sentences describing the problem or goal of the issue>

  - <Change made>
  - <Change made>

  Closes #123
  ```

- Replace `123` with the actual issue number.
- Determine `<Type>` from the issue's labels by inspecting the issue on GitHub.
  Use `Feature`, `Bug`, or `Chore`, matching the corresponding label. If more
  than one is present, use this priority: `Feature`, then `Bug`, then `Chore`.
  If none of those labels is present, stop and ask the user which type to use.
- The prose paragraph must be one to three sentences explaining the problem
  the issue is intended to solve or the capability, fix, or refactoring it is
  intended to add.
- Follow the prose paragraph with the usual bulleted summary of the changes in
  the commit.
- Include the `Closes #123` footer only on the final planned commit for the
  issue, when no follow-up commits are expected. Omit it from earlier commits.
- For a commit that is not tied to a GitHub issue, omit the `<Type> #123:`
  prefix and begin the subject with the brief description. Also omit the
  `Closes` footer; retain the prose paragraph and bulleted change summary.

## Changelog

- Every implementation task must update `CHANGELOG.md` with a concise summary
  of the completed work under `## Unreleased`, whether or not the task is tied
  to a GitHub issue.
- If `CHANGELOG.md` does not contain an `## Unreleased` section, add one above
  the most recent version section before recording the change.
