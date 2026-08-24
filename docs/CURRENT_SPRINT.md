# Current Sprint - Sprint 9E: Multi-Archetype Runtime Reconstruction

**Status:** IMPLEMENTED - REVIEW READY

## Hypothesis
The same semantic-blueprint -> authored-embedding -> runtime-reconstruction pipeline can represent and physically reconstruct all six researched railway archetypes without archetype-specific `RailMovement` or reconstruction code.

Sprint 9E proves this breadth pipeline:

```text
authored semantic fixture
  -> SectorBlueprint
  -> Sprint 9C semantic validation
  -> authored spatial embedding
  -> WorldgenRuntimeReconstructor
  -> RailMovement.configure_track_layout()
  -> dedicated multi-archetype harness
```

No procedural generation is introduced in 9E.

## Reference Fixtures
Sprint 9E reconstructs all six Sprint 9B reference archetypes:

```text
rural_through
village_passing_station
small_town_goods_station
agricultural_loading_point
river_valley_constrained
declining_abandoned_branch
```

## In Scope
1. Authored spatial embeddings for the five archetypes not reconstructed in 9D.
2. A reference embedding registry for all six authored fixtures.
3. Generic route-preset metadata for the development harness only.
4. Generic display-only runtime segment metadata for visible non-routable railway.
5. Display-only `ABANDONED_TRACK` geometry that maps semantic edges without entering the active movement graph.
6. A dedicated multi-archetype reconstruction harness scene.
7. Automated reconstruction and representative movement tests across all six archetypes.

## Embedding Boundary
The semantic fixture describes what railway exists and why. The embedding describes where each authored reference layout is physically placed for runtime proof.

Semantic nodes may be decomposed into multiple ordinary runtime turnouts and short connectors when needed. This remains authored placement data, not a procedural spatial solver.

Route presets are harness convenience metadata only. Applying a preset sets ordinary point routes through `RailMovement.set_point_route()`; it does not introduce a competing routing system.

## Abandoned Track Boundary
`ABANDONED_TRACK` may be mapped to runtime geometry with `runtime_status: "display_only"`.

Display-only segments:
- render in the 9E harness;
- retain semantic edge IDs and roles;
- are included in deterministic runtime topology metadata;
- are rejected if an embedding attempts to route active movement into them.

They do not support repair, recommissioning or gameplay interaction in 9E.

## Authority Rules
- `SectorBlueprint` remains immutable semantic data.
- `WorldgenRuntimeReconstructor` translates generic embedding data only.
- `RailMovement` remains the live authority for movement, points, speed, reversing, contact and draw transforms.
- The active `SectorDefinition`, `SectorInstance`, `SectorLifecycle`, production `main.gd` and production `Main.tscn` path remain unchanged.
- No rolling stock, POIs, terrain, roads, rivers or gameplay problems are generated from worldgen data in 9E.

## Automated Acceptance
- [x] All six reference fixtures load and validate through the Sprint 9C validator.
- [x] All six authored embeddings load separately from semantic fixtures.
- [x] All six reconstruct through the same `WorldgenRuntimeReconstructor` API.
- [x] All six configure `RailMovement` through `configure_track_layout()`.
- [x] Semantic edge IDs map deterministically to runtime segment IDs, including display-only abandoned edges.
- [x] Blueprint canonical hashes are unchanged by reconstruction.
- [x] Runtime topology snapshots are deterministic and materially different across archetypes.
- [x] Rural through reconstructs without fake turnouts.
- [x] Village, small-town, river-valley and declining loops route through ordinary point settings.
- [x] Agricultural and small-town loading spurs are reachable and reversible.
- [x] Declining abandoned branch renders abandoned geometry as non-routable display-only track.

## Human UAT
Launch:

```bash
/home/flax/bin/godot --path . scenes/worldgen/Sprint9EMultiArchetypeReconstruction.tscn
```

Approximate 10-15 minute script:
1. Use `[` and `]` to cycle all six layouts and confirm they read differently.
2. Rural through: press `1`, `Space`, and drive west to east.
3. Village passing station: use `1` for main, reset with `0`, then use `2` for loop.
4. Small-town goods station: confirm `1` main, `2` loop, `3` goods loading and `4` headshunt.
5. Agricultural loading point: use `1` main, then reset and use `2` grain loading; stop and reverse out with `R`.
6. River valley constrained: use `1` main and `2` short loop; confirm no bad joins.
7. Declining abandoned branch: use `1` active main, `2` active loop and `3` old storage.
8. Confirm abandoned/disused track is visually distinct and is not treated as ordinary active routing.
9. Confirm no teleports at reconstructed turnouts.

## Explicit Exclusions
Do not implement in Sprint 9E:
- procedural generation;
- RNG streams;
- archetype selection;
- weighted topology choices;
- automatic spatial solving;
- terrain, roads, rivers, towns or POIs as generated geometry;
- bridge/tunnel generation;
- rolling-stock procedural placement;
- damage/gameplay mutations;
- repair/recommissioning abandoned railway;
- shunting-solvability search;
- train-length/headshunt clearance solving;
- seed sweeps;
- active `SectorLifecycle` replacement;
- save/load changes;
- art polish.

## Next Possible Increment
Future work may start deterministic semantic generation or procedural spatial embedding only after an explicit sprint plan. 9E remains authored breadth proof, not generation.
