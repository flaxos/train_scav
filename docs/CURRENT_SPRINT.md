# Current Sprint - Sprint 9G: First Procedural Semantic Railway Topology

**Status:** IMPLEMENTED - REVIEW READY

## Hypothesis
Using only deterministic generation inputs and named RNG streams, the project can generate multiple valid semantic members of one researched railway archetype without authored per-sector topology and without touching runtime geometry.

Sprint 9G generates only:

```text
village_passing_station
```

The implemented pipeline is:

```text
GenerationRequest
  -> GenerationContext
  -> topology/world_entities RNG streams
  -> WorldgenSemanticGenerator
  -> SectorBlueprint
  -> WorldgenSchemaValidator
  -> valid generated semantic blueprint
```

There is no spatial embedding, runtime reconstruction, `RailMovement` integration or sector-lifecycle integration in 9G.

## In Scope
1. `WorldgenSemanticGenerator` for one semantic archetype: `village_passing_station`.
2. Deterministic generated IDs and generated semantic graph data.
3. Validation of every successful output through the Sprint 9C semantic validator.
4. Stable generated `SectorBlueprint` canonical hashes for identical generation requests.
5. Stable generation traces with appended 9G stage decisions.
6. Focused tests for determinism, validation, stream isolation, version mismatch and restrained variation.

## Version Contract
The generated semantic blueprint keeps the existing validator-compatible field:

```text
generator_version: 9a_schema_v1
```

The actual 9G semantic generation algorithm is identified by:

```text
WorldgenSemanticGenerator.GENERATOR_VERSION = 9g_village_passing_station_semantic_v1
```

`WorldgenGenerationRequest.generator_version` must match this 9G value before generation. A mismatch returns a structured `GENERATOR_VERSION_MISMATCH` diagnostic and no blueprint.

## RNG Ownership
9G uses named streams conservatively:

- `topology` owns rail-semantic variation such as `platform_track`.
- `world_entities` owns world-relationship variation such as optional station road access.

9G does not use spatial choices such as loop side or station side, because no geometry or spatial hint is generated in this sprint.

`make_rng()` returns fresh deterministic streams, so consuming `decoration` or `world_entities` outside the generator does not perturb topology-owned decisions.

## Generated Grammar
The generated village passing station contains:

- one `ENTRY`;
- one `EXIT`;
- active entry-to-exit railway connectivity;
- one double-ended `PASSING_LOOP`;
- station, platform and settlement entities;
- `PLATFORM_SERVES_TRACK` targeting either the station main or passing loop;
- optional road access relationship owned by `world_entities`.

It does not create goods yards, industries, agricultural loading, water crossings, abandoned branches or geometry.

## Automated Acceptance
- [x] Wrong generator identity is rejected with `GENERATOR_VERSION_MISMATCH`.
- [x] Same complete request produces identical blueprint hash, trace hash and decisions.
- [x] Generated blueprint keeps semantic `generator_version: 9a_schema_v1`.
- [x] Generation trace records `generator_version: 9g_village_passing_station_semantic_v1`.
- [x] Generated blueprint validates through the Sprint 9C validator.
- [x] Generated graph has entry-to-exit connectivity and a true passing loop.
- [x] Generated graph has station, platform and settlement semantics.
- [x] World relationships resolve and platform references a usable active track.
- [x] Generation trace appends 9G decisions rather than replacing existing decisions.
- [x] Consuming `decoration` does not change generated topology or trace.
- [x] Consuming `world_entities` does not change topology-owned rail graph hash or platform decision.
- [x] A 150-request semantic sweep validates and produces restrained variation.
- [x] The generator does not load or clone the authored village fixture.

## Developer Acceptance
No gameplay UAT is required for 9G because it creates semantic topology only.

Developer acceptance is to inspect printed generated summaries, for example:

```text
seed 100: hash=... platform_track=station_main road_access=true
seed 101: hash=... platform_track=passing_loop road_access=false
seed 102: hash=... platform_track=passing_loop road_access=false
```

The same seed must reproduce exactly, different seeds may show restrained semantic variation, and all generated blueprints must validate.

## Explicit Exclusions
Do not implement in Sprint 9G:

- procedural spatial embedding;
- random coordinates or geometry;
- runtime reconstruction of generated sectors;
- `RailMovement` changes;
- scene or harness changes;
- production `SectorDefinition` integration;
- active `SectorLifecycle` integration;
- procedural goods yards, industrial spurs, agricultural loading, river valleys or abandoned branches;
- terrain, roads or rivers as physical geometry;
- POIs/resources;
- rolling-stock placement;
- decay/damage mutations;
- gameplay problems;
- shunting solvability;
- save/load changes.

## Next Possible Increment
Future work may add authored/procedural spatial embedding for generated blueprints or broaden semantic generation to another researched archetype, but only after an explicit sprint plan promotes that work.
