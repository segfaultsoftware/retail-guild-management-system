# Portal UI architecture

Issue 66 keeps UI construction and Retail API calls in `UI/UI.lua`. Behavioral
decisions live in `UI/Portal.lua`, where they can be tested without FrameXML.
The controller owns numeric dropdown fallback, contextual controls, view/session
state, command admission, drag admission, modal state, and the global scan lock.

## Roster presentation terminology

Roster is one primary workflow with two presentation modes over the existing
roster-backed reports:

- **ByName** is the default mode. It is the former Mains/Alts presentation and
  retains grouped and ungrouped characters, grouping controls, name search, tag
  filters, notes, selections, expansion, and virtualized rows.
- **ByTenure** is the former Roster presentation. It shows current characters
  in the selected numeric guild rank using the existing tenure cohorts and row
  presentation.

The user-facing checkbox is labeled **By rank**; ByName and ByTenure are the
standard internal terms. The mode is session-only: navigation to Guild Bank,
Provisions, or Tags preserves it and each mode's transient state, while closing
RGMS resets Roster to a clean ByName presentation. The selected numeric rank
remains saved through its existing SavedVariables field.

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
- The Roster merge reuses those two established native presentation adapters
  behind one navigation entry. A third-party view router or state library would
  add lifecycle and SavedVariables risk without solving compatibility concerns
  beyond the portal's small tested session controller.
- The Provisions view also stays on RGMS's native frame and fixed-row adapter.
  AceGUI remains maintained and adopted, but introducing it for one view would
  duplicate the portal's scan lock, control styling, and lifecycle without
  providing bank-snapshot aggregation or atomic per-guild mutations. Crafting
  quality uses Blizzard's `C_TradeSkillUI.GetItemReagentQualityByItemInfo`
  instead of a third-party item database. Blizzard's maintained
  `ScrollUtil.AddLinearDragBehavior` was also evaluated for manual ordering,
  but it requires replacing this fixed-row `ScrollFrame` with a ScrollBox data
  provider. The local adapter instead adds only threshold detection, floating
  row preview, midpoint movement, and edge auto-scroll to the existing view.
- AceGUI, Details Framework, LibDropDownMenu, lib-ScrollingTable,
  LibSharedMedia, and other UI frameworks were rejected because the ticket
  explicitly excludes them and the maintained Blizzard menu API covers the
  ecosystem-sensitive dropdown behavior.

Only Inter v4.1 and six Lucide 1.59.0 icons are bundled. Their pinned sources,
licenses, and exact runtime files are recorded in `THIRD_PARTY_NOTICES.md`.
