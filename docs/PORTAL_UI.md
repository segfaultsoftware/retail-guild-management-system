# Portal UI architecture

`UI/UI.lua` is the stable `RGMS.UI` facade and cross-feature coordinator.
Behavioral decisions remain in `UI/Portal.lua`, where they can be tested
without FrameXML, and pure placement calculations remain in `UI/Layout.lua`.
The facade preserves the existing public methods while delegating construction,
rendering, and component lifecycle to these owners:

| Owner | Responsibility |
| --- | --- |
| `UI/Window.lua` | Root window, positioning, visibility, primary navigation, and the global scan overlay |
| `UI/Widgets.lua` | Shared native-frame styling, dropdown, scrollbar, text, and refresh-button helpers |
| `UI/Roster/ByName.lua` | Grouped and virtualized ByName roster, search, selection, expansion, and group actions |
| `UI/Roster/ByTenure.lua` | ByTenure rank selection, headers, rows, and scrolling |
| `UI/Roster/TagPopovers.lua` | Character tag editor, filter, preview, and dismissal lifecycle |
| `UI/Tags.lua` | Tag-management view and deletion confirmation |
| `UI/Bank.lua` | Bank tabs, inventory rows, item interaction, controls, and scrolling |
| `UI/Provisions.lua` | Provision editor, rows, reports, selection, and control state |
| `UI/ProvisionDrag.lua` | Provision drag threshold, preview, ordering, auto-scroll, interruption, and restoration |
| `UI/Notes.lua` | Character-note editor construction, rendering, and lifecycle |
| `UI/News.lua` | News drawer construction, rendering, scrolling, acknowledgment, and lifecycle |
| `UI/Tooltip.lua` | RGMS-owned tooltip construction and ownership |
| `UI/Toast.lua` | Toast construction, timing, stacking, fading, reflow, and cleanup |

## Load and dependency flow

`RGMS.toc` loads `UI/Layout.lua` and `UI/Portal.lua` before the Retail-facing UI
modules. `UI/Widgets.lua` establishes a private registry on the addon namespace;
each component then registers its implementation and the small set of facade
methods it owns. `UI/Window.lua` loads after the components it constructs, and
`UI/UI.lua` loads last, builds the private component scope, and binds the stable
`RGMS.UI` facade to those interfaces. Registration does not construct frames,
so initialization remains lazy and the dependency direction is acyclic.

Every UI runtime file receives the existing private addon namespace through
`local _, RGMS = ...`. Shared implementation names are resolved only inside the
private component scope; no new Lua globals or SavedVariables are introduced.

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
- The single-responsibility extraction adds no framework. AceGUI and similar
  component systems would replace native frames and alter lifecycle or styling,
  while a general dependency-injection library would add runtime surface for a
  fixed manifest load graph. The private registry supplies only the load-time
  composition needed to preserve the existing Retail behavior.

Only Inter v4.1 and six Lucide 1.59.0 icons are bundled. Their pinned sources,
licenses, and exact runtime files are recorded in `THIRD_PARTY_NOTICES.md`.
