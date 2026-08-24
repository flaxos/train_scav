# Generator Architecture - Sprint 9 Direction

## Boundary
The existing runtime remains authoritative:

```text
RailMovement owns live railway movement, points, contact and coupling.
CrewSimulation owns live survivor movement and tasks.
SectorPOIs owns live search and available loot state.
SectorLifecycle owns irreversible departure/disposal.
```

Generated data may author initial sector state later, but it must not become a competing runtime authority.

## Intended Pipeline
Sprint 9 should progress through gated increments:

```text
9A: research/schema/fixtures
  ↓
9B: authored semantic blueprint coverage
  ↓
9C: semantic topology/world-relationship validation
  ↓
9D: one authored blueprint plus authored embedding reconstructed into RailMovement
  ↓
9E+: deterministic semantic generation, broader embedding, POIs, rolling stock, problems, solvability and UAT
```

Sprint numbering after 9C may be revised by an explicit sprint plan, but 9C itself is only semantic validation.

## Sprint 9B Boundary
9B constructs immutable `SectorBlueprint` objects from loaded authored fixture dictionaries:

```text
canonical JSON fixture
  -> parse/load
  -> 9A semantic validation
  -> defensive-copy SectorBlueprint
  -> semantic query API
  -> canonical serialization/hash
```

The active playable game remains unchanged:

```text
SectorDefinition -> existing authored sector setup -> existing runtime systems
```

`SectorDefinition` must not automatically generate, load, validate or attach a blueprint in 9B or 9C.

## Sprint 9C Boundary
9C validates immutable semantic data before any physical embedding:

```text
semantic generator/data
  -> SectorBlueprint
  -> semantic validator
  -> VALID / INVALID + diagnostics
```

The validator is independent of:
- Godot scene nodes;
- `RailMovement` runtime geometry;
- `SectorLifecycle`;
- POI spawning;
- rolling-stock simulation.

Abandoned/disused track remains meaningful semantic data, but `ABANDONED_TRACK` does not satisfy active entry-to-exit connectivity or active-service requirements.

## Sprint 9D Boundary
9D is a one-fixture runtime reconstruction proof:

```text
small-town goods SectorBlueprint
  -> 9C semantic validation
  -> authored spatial embedding
  -> WorldgenRuntimeReconstructor
  -> RailMovement.configure_track_layout()
  -> dedicated 9D harness
```

The spatial embedding is authored fixture placement, not a procedural solver. The west semantic station throat may be decomposed into multiple ordinary physical turnouts in the embedding when that is simpler and safer for the existing runtime.

The active playable game path remains:

```text
SectorDefinition -> existing authored sector setup -> existing runtime systems
```

9D does not make `SectorDefinition` automatically generate or attach blueprints.

## Future Pipeline Shape
When generation is explicitly promoted into a later sprint, the likely long-term sector creation shape is:

```text
run seed
  -> region/archetype profile
  -> deterministic semantic generation
  -> semantic rail graph
  -> world relationship graph
  -> constraint validation
  -> immutable sector blueprint
  -> 2D physical embedding
  -> terrain/roads/water/settlement/industry
  -> POIs/rolling stock/problems
  -> solvability validation
  -> existing runtime systems
```

This must still preserve the runtime authority boundary above.

## Deferred From 9B
Do not implement these in 9B:
- independent RNG streams;
- procedural archetype selection;
- weighted feature decisions;
- procedural rail topology construction;
- world relationship generation;
- generation retries/fallbacks;
- 500-seed sweeps;
- gameplay/problem generation;
- geometry or terrain;
- runtime `RailMovement` reconstruction;
- rolling-stock instantiation;
- POI spawning;
- active `SectorLifecycle` integration.

## Deferred From 9C
Do not implement these in 9C:
- seeded semantic generation;
- independent RNG streams;
- weighted archetype decisions;
- geometry or terrain embedding;
- runtime `RailMovement` reconstruction;
- shunting solvability search;
- rolling-stock reachability;
- train-length/headshunt clearance calculations;
- generated POIs/resources;
- damage/gameplay mutations;
- active `SectorLifecycle` integration.

## Deferred From 9D
Do not implement these in 9D:
- procedural generation;
- RNG streams;
- archetype selection;
- reconstruction of all six reference fixtures;
- general procedural spatial embedding;
- terrain, roads, rivers, towns or POIs as generated geometry;
- rolling-stock procedural placement;
- shunting-solvability search;
- train-length/headshunt clearance solving;
- active `SectorLifecycle` replacement.

## Validation Direction
9B validation is intentionally cheap:
- all six reference archetype files parse;
- graph IDs are unique through the existing 9A validator;
- edge references resolve through the existing 9A validator;
- entry-to-exit connectivity exists;
- world relations reference known entities/tracks;
- bad 9A fixtures continue to fail with clear messages;
- `SectorBlueprint` queries return defensive copies;
- canonical hashes are stable and distinct.

9C validation adds semantic diagnostic codes and IDs for invalid topology/world relationships while staying geometry-free.

Later validation should add generator seed contracts, geometry bounds, turnout continuity, rolling-stock overlap checks, crew reachability and bounded shunting recovery witnesses.
