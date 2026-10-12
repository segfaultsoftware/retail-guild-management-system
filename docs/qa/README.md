# Release QA records

Store completed, text-only release-candidate evidence in this directory.

Copy `../MVP_SCENARIO_CHECKLIST.md` to a name that identifies both the candidate
and tester, such as `0.1.0-rc.1-segfaultsoftware.md`. Fill it while testing;
never mark steps complete from memory. Remove private account and character
identifiers before committing the record.

The release promotion workflow requires the preparation script's exact
`Release candidate` and `Package SHA-256` values, no unchecked checklist boxes,
and this exact completed disposition line:

```text
- [x] Final release-candidate disposition: PASS
```

For a documented exception, check the applicable item and explain the exception
next to it or in the evidence location. A blank checkbox cannot pass the
automated promotion gate.

Large screenshots, videos, and other binary evidence belong on the associated
GitHub issue or release. Link them from the completed record. Do not put secrets,
CurseForge credentials, or SavedVariables containing private identifiers here.
