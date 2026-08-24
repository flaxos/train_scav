# Current Sprint - Sprint 9: Production Procedural Sectors

**Status:** IMPLEMENTED - FINAL HUMAN UAT PENDING

## Hypothesis
After the existing authored/demo opening sectors, the normal production `SectorLifecycle` can deterministically request procedural railway sectors from the Sprint 9 generator using run seed, sector index and generation identity. The generated sectors become real `SectorDefinition`/`SectorInstance` objects and reuse the existing train, crew, resource, scavenging, rolling-stock and irreversible departure systems.

Sprint 9 is complete only after the normal-game human UAT below passes. Do not create Sprint 9H, 9I or further railway-generator foundation work.

## Authored -> Procedural Boundary
The crafted opening remains intact:

```text
sector 0: authored departure yard
sector 1: authored forward industrial yard / route choice
sector 2+: deterministic procedural sectors
```

`SectorDefinitionProvider.FIRST_PROCEDURAL_SECTOR_INDEX` is the explicit handoff boundary.

## Implemented Production Pipeline

```text
RunState
  -> SectorLifecycle
  -> SectorDefinitionProvider
  -> authored SectorDefinition when sector_index < 2
  -> WorldgenProductionSectorGenerator when sector_index >= 2
  -> WorldgenGenerationRequest / WorldgenGenerationContext
  -> STREAM_ARCHETYPE selection
  -> WorldgenSemanticGenerator
  -> SectorBlueprint
  -> WorldgenSchemaValidator
  -> WorldgenProceduralSpatialEmbedding
  -> WorldgenRuntimeReconstructor
  -> generated SectorDefinition
  -> SectorInstance
  -> RailMovement.configure_track_layout()
  -> normal gameplay
```

`SectorLifecycle` still owns departure validation, diesel cost, previous-sector disposal, train transfer, crew relinking and run-journal recording. Worldgen only supplies the next sector definition/content.

## Procedural Archetypes
Sprint 9 production generation supports three bounded railway forms:

| Archetype | Gameplay role |
| --- | --- |
| `rural_through` | Sparse travel-through sector with active entry -> exit railway. |
| `village_passing_station` | Through route with genuine double-ended passing loop and station/platform semantics. |
| `small_town_goods` | Through route plus connected goods/loading track and existing rolling-stock salvage opportunity. |

Deferred procedural archetypes remain deferred: agricultural loading, river-valley constrained, and declining/abandoned branch.

## Determinism
Generation identity includes:
- run seed;
- sector index;
- route profile;
- region pack;
- grammar version;
- generator version.

Named RNG stream ownership:
- `archetype`: selects one of the three supported production forms;
- `topology`: semantic railway decisions;
- `world_entities`: station/settlement/freight relationship choices;
- `spatial`: bounded physical layout choices;
- `pois`: generated searchable opportunities using existing `SectorPOIs`;
- `rolling_stock`: existing-type detached wagon placement for goods sectors;
- `decoration`: not used for gameplay state and proven not to perturb generated results.

## Existing Gameplay Reuse
- Generated track is configured through `WorldgenRuntimeReconstructor` -> `RailMovement.configure_track_layout()`.
- Generated POIs are loaded into `SectorPOIs`; searching still follows discover -> carry -> deposit -> owned resource.
- Every generated production sector includes enough obtainable diesel in POIs to satisfy the next departure cost from a low-diesel entry state.
- Generated goods rolling stock uses existing wagon type prefixes and is placed as detached rail state; ownership still requires physical coupling through `RailMovement`.
- `FirstRunScenario` skips authored-scenario mutation for procedural definitions so generated sector content is not overwritten.

## Sprint 9 Increment Summary
- 9A: source-neutral railway/world grammar, schema and reference fixtures.
- 9B: immutable `SectorBlueprint`, canonical hashes and six authored archetypes.
- 9C: semantic/topological validation with structured diagnostics.
- 9D: one authored blueprint plus authored embedding reconstructed into `RailMovement`.
- 9E: all six authored archetypes reconstructed through the same runtime path.
- 9F: deterministic generation request/context, named RNG streams and trace metadata.
- 9G: first generated semantic railway, `village_passing_station`, validated through 9C.
- Final closeout: production sector lifecycle automatically enters deterministic procedural sectors after the authored opening.

## Automated Acceptance
- [x] Existing authored sector 0 and sector 1 remain selected before the handoff.
- [x] Sector index 2+ is selected through the procedural provider.
- [x] Same seed/index reproduces archetype, blueprint hash, trace hash, spatial embedding hash, runtime topology hash, POI signature and rolling-stock signature.
- [x] Known deterministic sample covers all three supported archetypes.
- [x] A 120-sector generated sweep validates semantics, reconstructs runtime layouts and drives entry -> exit.
- [x] Decoration stream pre-consumption does not alter generated gameplay output.
- [x] Rural, village and goods procedural sectors include enough obtainable diesel to avoid mandatory-departure fuel softlocks.
- [x] A low-diesel authored -> rural procedural handoff can refuel through normal search, carry, deposit and return-crew flow.
- [x] Generated goods sector places existing rolling stock off the main and recovers it only by physical coupling.
- [x] Production lifecycle test covers authored -> procedural and procedural -> procedural transitions.
- [x] Persistent consist, controlled power, crew, survivor needs/skills and resources survive transitions.
- [x] Previous sectors are disposed and cannot be revisited.
- [x] Normal `Main.tscn` reports procedural source, archetype and blueprint hash.

## Human UAT Required
Sprint 9 can be marked complete after this normal-game UAT passes:

1. Launch the normal production game from `res://scenes/bootstrap/Main.tscn`.
2. Start a fresh run with a known seed.
3. Play through authored sector 0 and confirm the departure yard behaves as before.
4. Depart normally to authored sector 1 and recover/activate the workshop wagon as before.
5. Cross one route exit in sector 1 and depart normally.
6. Confirm sector 2 is automatically generated without using a debug regenerate command.
7. Confirm debug state shows the same run seed, sector index `2`, `PROCEDURAL`, selected archetype and blueprint hash.
8. Confirm the same locomotive, consist, survivors and owned resources persisted.
9. Reverse toward the old boundary and confirm the authored sector cannot be revisited.
10. Drive/explore the generated sector normally.
11. If the archetype is `village_passing_station`, operate the passing route and use the station POI through normal scavenging.
12. If the archetype is `small_town_goods`, enter the goods/loading track and recover the generated wagon through existing coupling/shunting.
13. Return all crew to the train and depart normally.
14. Confirm sector 3 is another procedural sector, sector index increments and persistent state survives again.
15. Restart with the same seed and confirm the same procedural sector chain identities reproduce.
16. Start or test another known seed and confirm materially different procedural topology/archetype occurs.

Use a goods-producing seed for at least one UAT pass so existing shunting/coupling is proven inside a procedural sector.

## Explicit Exclusions
Do not implement as part of Sprint 9:
- new wagon ecosystem/types;
- multiple powered locomotives;
- procedural agricultural, river-valley or abandoned-branch generators;
- generic graph layout or constraint solving;
- terrain, rivers, roads, bridges, towns or generated world geometry;
- POI/resource system replacement;
- rolling-stock ownership shortcuts;
- shunting-solvability search;
- save/load changes;
- UI/art/audio polish;
- Sprint 10 work.

## Next Roadmap Item
After human UAT passes, Sprint 9 is complete and the roadmap moves to Sprint 10 - Rolling-stock ecosystem.
