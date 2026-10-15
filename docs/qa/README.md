# Release QA records

Store completed, text-only release-candidate evidence in this directory.

Copy `../MVP_SCENARIO_CHECKLIST.md` to a name that identifies both the candidate
and tester, such as `0.1.0-rc.1-segfaultsoftware.md`. Fill it while testing;
never mark steps complete from memory. Remove private account and character
identifiers before committing the record.

After the candidate source is merged to `main`, the **Build Release Candidate**
workflow produces the only ZIP that may be live-tested or promoted. Copy its
exact `Candidate commit`, `Candidate build run`, `Candidate artifact ID`,
automated result, and `Package SHA-256` values into the QA record. Download and
test the ZIP inside that workflow artifact; do not substitute a local rebuild.

The release promotion workflow requires those exact candidate values, no
unchecked checklist boxes, and this exact completed disposition line:

```text
- [x] Final release-candidate disposition: PASS
```

For a documented exception, check the applicable item and explain the exception
next to it or in the evidence location. A blank checkbox cannot pass the
automated promotion gate.

Commit completed QA records as the only file changes after the candidate
commit. Merge that QA-only change to `main`, then promote the resulting commit.
The workflow verifies the candidate run and immutable artifact, downloads the
same ZIP, and refuses promotion if anything outside `docs/qa` changed.

Large screenshots, videos, and other binary evidence belong on the associated
GitHub issue or release. Link them from the completed record. Do not put secrets,
CurseForge credentials, or SavedVariables containing private identifiers here.
