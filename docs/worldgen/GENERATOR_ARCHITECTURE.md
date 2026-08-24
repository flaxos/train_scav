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
9E: all six authored reference blueprints plus authored embeddings reconstructed into RailMovement
  ↓
9F: deterministic generation request/context/RNG trace infrastructure only
  ↓
9G: one-archetype procedural semantic topology only
  ↓
9H+: procedural embedding, broader archetypes, POIs, rolling stock, problems, solvability and UAT
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

## Sprint 9E Boundary
9E is a breadth proof for authored runtime reconstruction:

```text
each Sprint 9B reference SectorBlueprint
  -> 9C semantic validation
  -> authored spatial embedding
  -> WorldgenRuntimeReconstructor
  -> RailMovement.configure_track_layout()
  -> dedicated multi-archetype harness
```

The same reconstructor interprets generic embedding data for all six archetypes. Archetype differences belong in semantic fixtures and authored embeddings, not in reconstruction branches.

Route presets are optional harness metadata that set ordinary point routes. They are not a new route planner or movement authority.

`ABANDONED_TRACK` can be represented as display-only runtime geometry. It remains mapped to semantic edges for inspection, but is rejected if an embedding attempts to include it in active movement connections.

9E does not make `SectorDefinition`, `SectorLifecycle` or production `Main.tscn` use semantic reconstruction.

## Sprint 9F Boundary
9F adds deterministic worldgen infrastructure above semantic generation:

```text
GenerationRequest
  -> GenerationContext
  -> named deterministic RNG streams
  -> GenerationTrace
```

It does not choose archetypes, construct random rail topology, produce spatial embeddings, generate terrain or alter the active sector lifecycle.

Each request records:
- `run_seed`;
- `sector_index`;
- `route_profile`;
- `region_pack`;
- `grammar_version`;
- `generator_version`.

The request `generator_version` is generation identity metadata for future procedural output. It does not replace the authored Sprint 9A fixture `generator_version` currently checked by `WorldgenSchemaValidator`.

Named streams are:
- `archetype`;
- `topology`;
- `spatial`;
- `terrain`;
- `world_entities`;
- `pois`;
- `rolling_stock`;
- `gameplay_problem`;
- `decay`;
- `decoration`.

Calling `make_rng("topology")` returns a fresh deterministic stream reset to the topology subseed. Consuming `decoration`, `terrain` or any other stream cannot perturb topology because stream seeds derive from generation identity and stream name, not construction or draw order.

Subseed derivation is intentionally fixed:
1. Build seed material containing namespace `train_scav_worldgen_stream_seed_v1`, full generation identity and stream name.
2. Serialize that dictionary with `WorldgenCanonical.canonical_stringify()`.
3. Hash the UTF-8 canonical string with SHA-256.
4. Read SHA-256 digest bytes `0..7` in digest order as an unsigned big-endian integer.
5. Reduce modulo `2147483646`.
6. Add `1`, producing a seed in `1..2147483646`.

The project-owned worldgen stream is a Park-Miller LCG using multiplier `48271` and modulus `2147483647`. Its range contracts are:
- `next_int()` returns `1..2147483646`;
- `next_float()` returns `[0.0, 1.0)`;
- `range_int(min, max)` is inclusive of both integer bounds;
- `range_float(min, max)` returns `[min, max)`.

## Sprint 9G Boundary
9G adds the first procedural semantic topology generator:

```text
WorldgenGenerationRequest
  -> WorldgenGenerationContext
  -> WorldgenSemanticGenerator
  -> SectorBlueprint
  -> WorldgenSchemaValidator
```

It generates only `village_passing_station` semantic data. The generator does not read authored fixture files, produce physical coordinates, call the runtime reconstructor, touch `RailMovement`, or integrate with `SectorDefinition`/`SectorLifecycle`.

The generation algorithm identity is:

```text
9g_village_passing_station_semantic_v1
```

Requests with any other `generator_version` are rejected with `GENERATOR_VERSION_MISMATCH`. The generated blueprint dictionary still keeps `generator_version: 9a_schema_v1` because that field is the existing semantic schema compatibility contract checked by `WorldgenSchemaValidator`.

9G stream ownership is intentionally small:
- `topology` chooses rail-semantic variation such as which valid station track the platform serves;
- `world_entities` chooses world-relationship variation such as optional road access.

No spatial side/orientation decisions are recorded in 9G because no spatial embedding exists yet. 9G appends its stage decisions to any existing trace decisions from the context.

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

## Deferred From 9E
Do not implement these in 9E:
- seeded semantic generation;
- RNG streams;
- archetype selection or weighted topology choices;
- automatic spatial solving;
- terrain, generated rivers, roads, bridges, towns or POIs;
- rolling-stock procedural placement;
- damage/gameplay mutations;
- abandoned-track repair or recommissioning;
- shunting-solvability search;
- train-length/headshunt clearance solving;
- seed sweeps;
- active `SectorLifecycle` integration.

## Deferred From 9F
Do not implement these in 9F:
- procedural archetype selection;
- procedural railway topology;
- weighted loops, yards or spurs;
- random track graphs;
- procedural spatial embeddings;
- terrain, generated rivers, roads, bridges, towns or POIs;
- rolling-stock procedural placement;
- damage/gameplay mutations;
- shunting-solvability search;
- generated railway seed sweeps;
- active `SectorDefinition` or `SectorLifecycle` integration;
- save/load changes;
- route-map gameplay;
- art changes.

## Deferred From 9G
Do not implement these in 9G:
- procedural spatial embeddings;
- random coordinates or geometry;
- `RailMovement` or runtime reconstruction of generated sectors;
- production `SectorDefinition` or `SectorLifecycle` integration;
- procedural goods yards, industrial spurs, agricultural loading, river valleys or abandoned branches;
- terrain, generated rivers, roads, bridges, towns or POIs;
- rolling-stock placement;
- decay/damage mutations;
- gameplay problems;
- shunting-solvability search;
- save/load changes.

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

9F adds golden-tested generator seed contracts and trace determinism. Later validation should add generated semantic graph validity, geometry bounds, turnout continuity, rolling-stock overlap checks, crew reachability and bounded shunting recovery witnesses.
