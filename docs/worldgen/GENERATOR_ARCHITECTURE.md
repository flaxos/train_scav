# Generator Architecture — Sprint 9 Direction

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
Sprint 9 should progress through these gates:

```text
9A: research/schema/fixtures
  ↓
9B: deterministic semantic graph generation
  ↓
9C: physical rail/world geometry embedding
  ↓
9D: POIs, rolling stock, problems, solvability and UAT
```

The long-term sector creation shape is:

```text
run seed
  -> region/archetype profile
  -> semantic rail graph
  -> world relationship graph
  -> constraint validation
  -> 2D physical embedding
  -> terrain/roads/water/settlement/industry
  -> POIs/rolling stock/problems
  -> solvability validation
  -> immutable sector blueprint
  -> existing runtime systems
```

## Sprint 9A Non-Goals
Do not implement these in 9A:
- generated rail geometry;
- random sector generation;
- runtime loading into `RailMovement`;
- generated POIs or rolling-stock placement;
- shunting solvers;
- OSM import pipeline;
- YAML runtime parsing.

## Validation Direction
9A validation is intentionally cheap:
- schema/fixture files parse;
- graph IDs are unique;
- edge references resolve;
- entry-to-exit connectivity exists;
- world relations reference known entities/tracks;
- bad fixtures fail with clear messages.

Later 9C/9D validation should add geometry bounds, turnout continuity, rolling-stock overlap checks, crew reachability and bounded shunting recovery witnesses.
