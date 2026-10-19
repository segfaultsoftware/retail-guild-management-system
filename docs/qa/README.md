# Release QA records

Store completed, text-only release-candidate evidence in this directory.

Copy `../MVP_SCENARIO_CHECKLIST.md` to a name that identifies both the candidate
and tester, such as `0.1.0-rc.1-segfaultsoftware.md`. Fill it while testing;
never mark steps complete from memory. Remove private account and character
identifiers before committing the record.

After the candidate source is pushed to its `release/X.Y` branch, dispatch the
**Build Release Candidate** workflow from `main` with that branch and its full
tip SHA. The workflow produces the only ZIP that may be live-tested or
promoted. Its workflow artifact also contains `qa-record.md`, with the release
branch, candidate commit, build run, automated result, package checksum, and
evidence path populated by automation. Replace the prepared record with that
file at the recorded path, then test the ZIP in the same artifact; do not
substitute a local rebuild.

Checkboxes and evidence fields are the tester's working record and are not
automated release gates. Finish the record with exactly one signoff block:

```text
## QA signoff

- QA GitHub username: @YOUR-NAME
- QA date (Pacific): YYYY-MM-DD
- Result: PASS
```

`FAIL` is valid QA evidence but stops release promotion. Use the Pacific date
on which the tester made the final determination. Document exceptions and
failures next to the applicable item or in the evidence location.

Commit exactly one completed QA record as the only file change and push it to
the same `release/X.Y` branch. Then dispatch **Release** from `main` with that
branch and the full SHA of the resulting commit. The workflow infers the one
changed record and its version, verifies the branch tip, candidate run, and
immutable artifact, downloads the same ZIP, and refuses promotion if the
commit changes anything else.

Large screenshots, videos, and other binary evidence belong on the associated
GitHub issue or release. Link them from the completed record. Do not put secrets,
CurseForge credentials, or SavedVariables containing private identifiers here.
