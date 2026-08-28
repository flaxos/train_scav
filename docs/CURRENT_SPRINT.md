# Current Sprint - Sprint 11: Procgen Variety Pass

**Status:** AUTOMATED VALIDATION COMPLETE - HUMAN UAT PENDING

## Hypothesis
Generated sectors feel more replayable when the production generator can produce a wider set of already-researched railway places, while still using the existing sector lifecycle, rail movement, POIs, resources and rolling-stock ownership systems.

The player should see different generated sectors after the authored opening:

```text
rural through
village passing station
small-town goods sector
agricultural loading point
river-valley constrained sector
declining abandoned branch
```

Each form must remain a real `SectorDefinition` and `SectorInstance` that drives through the existing `RailMovement` authority.

## Scope Contract
- Promote the existing Sprint 9 reference archetypes `agricultural_loading_point`, `river_valley_constrained` and `declining_abandoned_branch` into production procedural generation.
- Keep authored sectors 0-1 intact.
- Keep Sprint 10 rolling-stock catalogue and physical ownership rules intact.
- Use deterministic generation identity and named RNG streams.
- Add only bounded spatial/topological variation around already-proven archetype shapes.
- Reuse existing POI/resource/scavenging systems.
- Ensure every generated sector remains escapable through a main route.

## Explicit Exclusions
Do not implement during Sprint 11:
- locomotive acquisition;
- multi-locomotive control;
- independent trains;
- infrastructure hazards as gameplay damage;
- bridge failure simulation;
- terrain/road/water rendering as a full system;
- general graph layout solving;
- shunting solvability search;
- new rolling-stock types;
- new economy/resource balance;
- save/load changes;
- final UI/art/audio.

## Production Archetypes
Sprint 11 production generation must support all six bounded railway forms:

| Archetype | Required production behavior |
| --- | --- |
| `rural_through` | Sparse active main, simple resource opportunity. |
| `village_passing_station` | Double-ended passing loop with station/platform semantics. |
| `small_town_goods` | Loop plus reachable goods/loading track and Sprint 10 salvage. |
| `agricultural_loading_point` | Through main plus reachable agricultural spur/loading/headshunt. |
| `river_valley_constrained` | Constrained loop plus bridge/water semantic relation. |
| `declining_abandoned_branch` | Active main/loop plus reachable overgrown storage and display-only abandoned track. |

## Variety Model
Keep the model small and inspectable.

Allowed Sprint 11 variation:
- archetype selection among all six forms;
- side/offset/length choices for loop-based layouts;
- agricultural spur side, spur length and loading length;
- river-valley bridge approach length and constrained loop shape;
- declining-branch yard side, storage length and abandoned display-track shape;
- POI naming/resource placement matched to the generated form.

Disallowed variation:
- arbitrary recursive module composition;
- topology retries/fallbacks beyond clear failure diagnostics;
- generated hazards that block departure;
- generated unreachable mandatory resources.

## Acceptance
Sprint 11 is complete when:
- `WorldgenProductionSectorGenerator` deterministically supports all six production archetypes.
- The three promoted archetypes produce valid `SectorBlueprint` data from seed/context, not by loading authored fixture files at runtime.
- Procedural spatial embedding supports all six production archetypes with bounded deterministic variation.
- Main-route traversal works for a broad generated seed sweep.
- Branch/stub routes for agricultural loading and declining storage are physically reachable and reversible.
- Declining abandoned tracks remain display-only and cannot be routed by `RailMovement`.
- River-valley sectors include bridge/water semantic relations and remain traversable.
- Generated POIs provide enough obtainable diesel for departure in every supported archetype.
- Existing Sprint 10 salvage behavior remains intact for `small_town_goods`.
- Normal `Main.tscn` can enter all six generated archetypes using seeded/debug-start UAT commands.
- Full `tests/*.gd` suite, production headless launch and `git diff --check` pass.

## Automated Validation
Add focused Sprint 11 tests covering:
- catalogue of six supported production archetypes;
- deterministic identity for promoted archetypes;
- large generated seed sweep across all six archetypes;
- route traversal for main, agricultural loading, declining storage and river loop;
- POI/resource safety for all forms;
- display-only abandoned-track safety;
- normal `Main.tscn` debug-start visibility for all six production archetypes.
- scripted normal-`Main.tscn` debug-start UAT rehearsal for agricultural loading, river-valley and declining-branch route behavior.
- scripted normal-game UAT rehearsal that starts in authored Sector 0, transitions through authored Sector 1, and reaches the promoted generated forms in Sector 2.

## Human UAT
Use normal `res://scenes/bootstrap/Main.tscn`.

Targeted debug-start UAT may use:

```bash
TRAIN_SCAV_RUN_SEED=<known_seed> TRAIN_SCAV_START_SECTOR=2 TRAIN_SCAV_START_ROUTE=<profile> /home/flax/bin/godot --path .
```

Known sector-2 `industrial` fixtures:

| Seed | Expected archetype |
| --- | --- |
| `6003` | `rural_through` |
| `6012` | `village_passing_station` |
| `6001` | `small_town_goods` |
| `6005` | `agricultural_loading_point` |
| `6004` | `river_valley_constrained` |
| `6008` | `declining_abandoned_branch` |

Final UAT should confirm at least three promoted/generated forms in play:
1. agricultural loading point: inspect route/debug state, drive main route, enter the loading/headshunt route and reverse out.
2. river-valley constrained: inspect route/debug state, confirm bridge/water semantic form in debug, drive main and loop route.
3. declining abandoned branch: inspect route/debug state, enter active storage, confirm abandoned track is visible/display-only and not routable, reverse out.

Automated debug-start rehearsal:

```bash
/home/flax/bin/godot --headless --path . --script tests/sprint11_scripted_uat_rehearsal.gd
```

Automated normal-game handoff rehearsal:

```bash
/home/flax/bin/godot --headless --path . --script tests/sprint11_normal_game_uat_rehearsal.gd
```

Do not start the later locomotive, hazard or survivor-depth sprints during Sprint 11.
