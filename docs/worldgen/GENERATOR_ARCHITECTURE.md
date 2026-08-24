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
9C: deterministic semantic graph generation
  ↓
9D+: physical rail/world geometry, POIs, rolling stock, problems, solvability and UAT
```

Sprint numbering after 9B may be revised by an explicit sprint plan, but 9B itself is only the authored-fixture proof.

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

`SectorDefinition` must not automatically generate, load or attach a blueprint in 9B.

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

Later validation should add generator seed contracts, geometry bounds, turnout continuity, rolling-stock overlap checks, crew reachability and bounded shunting recovery witnesses.
