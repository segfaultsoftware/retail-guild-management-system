# Chart Rendering Decision

RGMS uses a small native FrameXML chart adapter backed by pure Lua history and
geometry units. The decision was made after reviewing the established WoW graph
library ecosystem for issue #129.

## Libraries reviewed

- **LibGraph-2.0** is still bundled by active addons such as
  [Details](https://github.com/Tercioo/Details-Damage-Meter/tree/master/Libs/LibGraph-2.0),
  and exposes line, scatter, regression, grid, and pie primitives. Its source
  identifies revision 62 and old WowAce/SVN documentation, the active host
  repository does not assert a reusable SPDX license, and the implementation
  still marks plot-bound clipping as unfinished.
- Repository and code searches found copies of LibGraph-2.0 in other addons,
  but no maintained LibGraph-3.0 successor or another adopted Retail chart
  library with clearer licensing and the required interaction model.

LibGraph-2.0 also couples scaling, grid generation, rendering, and regression
to its frame objects. RGMS needs a fixed 180-date Pacific-calendar domain with
plotting coordinates inset far enough to leave explicit clearance around the
outer edges of its dots, observation-only Y scaling, regression clipping, item
gaps, deterministic nearest-point hover, series lifecycle rules, and testable
selector reconciliation. Adapting
the library would require replacing most of those behaviors while adding a
third-party dependency and assets.

The native adapter therefore draws only pooled textures and frames. All date
retention, aggregation, selection, scaling, regression, month-boundary, and
nearest-point decisions remain in `Charts/Model.lua`, where the Lua test suite
can verify them without a Retail client.
