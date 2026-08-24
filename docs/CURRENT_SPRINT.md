# Current Sprint - Sprint 9B: Semantic Blueprint Archetype Coverage

**Status:** IMPLEMENTED - AUTOMATED VALIDATION READY

## Hypothesis
One common immutable semantic blueprint model can accurately represent all six researched railway archetypes without archetype-specific runtime code.

Sprint 9B proves representation coverage only:

```text
SPRINT 9A SCHEMA
  -> AUTHORED REFERENCE FIXTURES
  -> NORMALISED LOAD
  -> IMMUTABLE SectorBlueprint
  -> CANONICAL HASH / QUERY API TESTS
```

Roadmap acceptance:
> All six authored reference archetypes parse, validate, construct `SectorBlueprint`, expose correct semantic queries, produce stable canonical hashes, remain materially different graphs, and do not alter the existing playable game or sector lifecycle.

## Baseline Dependencies
Sprint 9B builds directly on the accepted Sprint 9A semantic contract and research inputs:
- `docs/deep-research-report-grammer.md` and `docs/deep-research-report-prompts.md`;
- source-neutral rail graph roles and world relationship graph vocabulary;
- the 9A JSON fixtures and validator;
- completed Sprint 1-8 rail, crew, scavenging, sector lifecycle and vertical-slice systems.

Do not replace `RailMovement`, `SectorDefinition`, `SectorInstance`, `SectorPOIs`, coupling, crew tasks, sector lifecycle or the vertical-slice scenario in 9B.

## In Scope
The active build adds the smallest proof that the 9A schema is broad enough for materially different railway places:
1. `SectorBlueprint` as an immutable query wrapper over authored semantic data.
2. Canonical deterministic serialization and SHA-256 hash generation for authored semantic dictionaries.
3. A small fixture loader for canonical JSON reference archetypes.
4. Six authored reference archetype fixtures under `data/worldgen/archetypes/reference/`.
5. A fixture registry under `data/worldgen/archetypes/reference_archetypes_v1.json`.
6. Tests proving all six fixtures parse, validate, construct blueprints, share one schema/API, hash stably and remain materially different.
7. Defensive-copy tests for blueprint queries and dictionary export.
8. Documentation and decision updates recording the narrowed 9B boundary.

Required `SectorBlueprint` semantic API:
- `get_tracks_by_role()`
- `get_nodes_by_type()`
- `get_entities_by_type()`
- `get_station()`
- `get_goods_yards()`
- `get_industries()`
- `get_water_crossings()`
- `has_rail_path()`
- `get_canonical_hash()`
- `to_dictionary()`

## Reference Archetypes
The six Sprint 9B fixtures are authored semantic data, not generated sectors:
1. Rural through.
2. Village passing station.
3. Small-town goods station.
4. Agricultural loading point.
5. River-valley constrained.
6. Declining/abandoned branch.

Each fixture must use the same 9A schema and the same `SectorBlueprint` query API. Differences belong in authored graph data, not archetype-specific runtime branches.

## Authority Rules
- `SectorBlueprint` is a read-only semantic description artifact. It is not live railway authority.
- The active game remains on the existing authored `SectorDefinition` path.
- `SectorDefinition` must not automatically generate or attach a blueprint in 9B.
- The 9A validator may receive only small compatibility fixes needed for these fixtures.
- Runtime fixtures must use source-neutral semantic roles, not raw OSM/OpenRailwayMap tags.
- No physical `Vector2` track geometry, rolling stock, POI placement, terrain, routes or gameplay problems are authored through 9B blueprints.

## Explicit Exclusions
Do NOT implement in Sprint 9B:
- `WorldgenRngStreams`;
- `WorldgenSemanticGenerator`;
- procedural archetype selection;
- weighted feature generation;
- procedural topology construction;
- generation retries or fallbacks;
- 500-seed or large seed sweeps;
- gameplay/problem generation;
- geometry or terrain generation;
- runtime `RailMovement` reconstruction from blueprints;
- rolling-stock instantiation;
- POI spawning;
- integration into the active `SectorLifecycle`;
- replacement of `SectorDefinition`'s existing authored generation path;
- 9C work.

## Automated Acceptance
- [x] Six authored reference fixtures are registered.
- [x] All six fixtures parse from canonical JSON.
- [x] All six fixtures validate through the 9A semantic validator.
- [x] All six fixtures construct `SectorBlueprint`.
- [x] All six fixtures expose semantic queries through the same API.
- [x] All six fixtures produce stable canonical hashes across repeated loads.
- [x] All six fixtures have distinct canonical hashes.
- [x] All six fixtures have materially different graph signatures.
- [x] Blueprint query/export methods return defensive copies.
- [x] Existing Sprint 9A schema validation remains green.
- [x] Existing Sprint 1-8 regression tests remain green.
- [x] Headless launch has no parse/compile/runtime script errors.

## Human Review Gate
Sprint 9B has no playable procedural-sector UAT. It is complete when the user accepts that one common immutable blueprint API can represent the six researched archetypes without changing the active game.

## Definition of Done
Sprint 9B is complete only after the focused 9B tests pass, the broader regression suite remains green, headless launch succeeds, and no runtime sector lifecycle or railway authority path has been replaced.

## Next Possible Increment
Deterministic semantic generation from seeds remains deferred. Do not begin it, 9C geometry work, runtime loading, POI spawning or rolling-stock placement without an explicit new sprint plan.
