# Current Sprint - Sprint 9D: One Semantic Blueprint to Playable Runtime Railway

**Status:** IMPLEMENTED - REVIEW READY

## Hypothesis
One validated authored `SectorBlueprint` can be converted into an actual playable Godot railway using the existing `RailMovement` runtime, without procedural generation, without changing sector lifecycle semantics, and without hard-coding the fixture's semantic meaning into gameplay code.

Sprint 9D proves this narrow pipeline:

```text
authored small-town goods fixture
  -> SectorBlueprint
  -> Sprint 9C semantic validation
  -> authored spatial embedding
  -> WorldgenRuntimeReconstructor
  -> RailMovement.configure_track_layout()
  -> dedicated playable 9D harness
```

## Reference Fixture
Sprint 9D uses only:

```text
data/worldgen/archetypes/reference/small_town_goods_station_v1.json
```

The other five Sprint 9B reference archetypes remain semantic validation fixtures only. They are not reconstructed in 9D.

## In Scope
1. A separate authored embedding for the small-town goods station fixture.
2. A `WorldgenRuntimeReconstructor` that validates the blueprint and translates embedding data into runtime layout data.
3. A minimal `RailMovement.configure_track_layout()` seam.
4. Deterministic semantic-edge to runtime-segment mapping.
5. Preservation of existing P1/P2/P3 wrappers and default authored railway behavior.
6. A dedicated 9D visual harness scene for inspection and driving.
7. Automated reconstruction and movement tests.

## Embedding Boundary
The semantic fixture describes what railway exists and why. The 9D embedding describes where the one authored fixture is physically placed.

The west semantic station throat is physically embedded as two ordinary runtime turnouts:

```text
west_yard_switch: main route vs goods-yard lead
west_loop_switch: platform main vs passing loop
```

This keeps `RailMovement` on ordinary route choices instead of introducing a multi-route special-case switch. The extra `west_station_throat` runtime connector is authored embedding data, not a semantic rail edge and not a procedural spatial solver.

## Authority Rules
- `SectorBlueprint` remains immutable semantic data.
- `WorldgenRuntimeReconstructor` translates data only; it is not railway authority.
- `RailMovement` remains the live authority for rail-space movement, route state, speed, reversing, contact and draw transforms.
- The active `SectorDefinition`, `SectorInstance`, `SectorLifecycle` and production `Main.tscn` path remain unchanged in 9D.
- No rolling stock, POIs, terrain, roads, rivers or gameplay problems are generated from worldgen data in 9D.

## Automated Acceptance
- [x] The small-town goods fixture loads and validates through the Sprint 9C validator.
- [x] The authored embedding loads separately from the semantic fixture.
- [x] Reconstruction succeeds without mutating the blueprint or changing its canonical hash.
- [x] Semantic edge IDs map deterministically to runtime segment IDs.
- [x] The west station throat is decomposed into ordinary runtime turnouts.
- [x] `RailMovement` accepts the reconstructed layout through `configure_track_layout()`.
- [x] A locomotive can traverse entry to east exit via the platform main.
- [x] A locomotive can route through the passing loop and reconnect to the exit segment.
- [x] A locomotive can enter the goods loading track, stop at the buffer and reverse back to the main approach.
- [x] Existing Sprint 1-9C regression tests remain green.
- [x] Headless launch has no parse/compile/runtime script errors.

## Human UAT
Launch:

```bash
/home/flax/bin/godot --path . scenes/worldgen/Sprint9DReconstruction.tscn
```

Approximate 5-10 minute script:
1. Confirm semantic rail labels are visible.
2. Press `1`, then `Space`, and drive from west entry through the platform main.
3. Reset with `0`, press `2`, and traverse the passing loop.
4. Reset with `0`, press `3`, enter the goods loading track, stop at the buffer, reverse with `R`, and return to the main approach.
5. Confirm there are no teleports, impossible jumps, disconnected rails or obvious geometry overlaps.

## Explicit Exclusions
Do not implement in Sprint 9D:
- procedural generation;
- RNG streams;
- archetype selection;
- reconstruction of all six fixtures;
- general procedural spatial embedding;
- terrain, roads, rivers, towns or POIs as generated geometry;
- rolling-stock procedural placement;
- damage/gameplay mutations;
- shunting-solvability search;
- train-length/headshunt clearance solving;
- seed sweeps;
- active `SectorLifecycle` replacement;
- save/load changes;
- art polish.

## Next Possible Increment
Future work may broaden runtime reconstruction, embed more fixtures or begin procedural spatial solving only after an explicit sprint plan. The 9D embedding is a proof fixture, not the general geometry generator.
