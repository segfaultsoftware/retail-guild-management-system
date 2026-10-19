# Portal UI architecture

Issue 66 keeps UI construction and Retail API calls in `UI/UI.lua`. Behavioral
decisions live in `UI/Portal.lua`, where they can be tested without FrameXML.
The controller owns numeric dropdown fallback, contextual controls, view/session
state, command admission, drag admission, modal state, and the global scan lock.

## Shared-solution evaluation

The implementation was checked against the maintained Retail sources on the
`live` branch:

- Blizzard Menu's `DropdownButton` and `MenuUtil` support radio selections,
  click-away/Escape closure, keyboard rotation, and a 240 px scroll extent.
  RGMS uses that API and adds only its visual label, icon, and palette layer.
- Blizzard `ScrollBox`/`DataProvider` and `TableBuilder` were evaluated for the
  tables. RGMS's existing rows combine pooled interactive controls, item-click
  handling, expandable nested rows, missing-member indicators, and report-owned
  scroll anchoring. Replacing that working interaction layer solely to adopt
  `TableBuilder` would broaden the ticket into a functional rewrite. RGMS keeps
  its small row adapter and native scroll frames while providing fixed headers,
  deterministic row extents, wheel/thumb scrolling, and pure-Lua row/state
  decisions.
- AceGUI, Details Framework, LibDropDownMenu, lib-ScrollingTable,
  LibSharedMedia, and other UI frameworks were rejected because the ticket
  explicitly excludes them and the maintained Blizzard menu API covers the
  ecosystem-sensitive dropdown behavior.

Only Inter v4.1 and six Lucide 1.59.0 icons are bundled. Their pinned sources,
licenses, and exact runtime files are recorded in `THIRD_PARTY_NOTICES.md`.
