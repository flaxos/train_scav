# Current Sprint - Sprint 9F: Deterministic Worldgen Infrastructure

**Status:** IMPLEMENTED - REVIEW READY

## Hypothesis
A world-generation request can own deterministic, versioned and independently reproducible random streams so future procedural topology, terrain, gameplay and decoration can vary without accidentally changing one another.

Sprint 9F proves this upper worldgen pipeline only:

```text
GenerationRequest
  -> GenerationContext
  -> named deterministic RNG streams
  -> generation trace / reproducibility metadata
```

No procedural `SectorBlueprint` generation is introduced in 9F.

## In Scope
1. Immutable/effectively immutable `WorldgenGenerationRequest` identity data.
2. `WorldgenGenerationContext` for deterministic stream subseeds and trace construction.
3. Fresh named RNG stream creation per stream request.
4. Stable SHA-256 based subseed derivation.
5. Serializable/canonical `WorldgenGenerationTrace`.
6. Focused deterministic tests with golden subseeds and trace hash.
7. Documentation of generator versioning and range semantics.

## Generation Identity
Each request records:

```text
run_seed
sector_index
route_profile
region_pack
grammar_version
generator_version
```

`generator_version` is generation identity metadata. It does not change the existing Sprint 9A authored fixture `generator_version` expected by the semantic validator.

## Named Streams
Sprint 9F defines these independent streams:

```text
archetype
topology
spatial
terrain
world_entities
pois
rolling_stock
gameplay_problem
decay
decoration
```

`make_rng(stream_name)` returns a fresh stream reset to that stream's deterministic subseed. Consumers that need continuing state must keep the returned stream explicitly. Creating or consuming one stream must not affect any other stream.

## Stable Subseed Contract
Subseeds are derived by:

1. Building seed material with namespace `train_scav_worldgen_stream_seed_v1` plus the full generation identity and stream name.
2. Serializing the material with `WorldgenCanonical.canonical_stringify()`.
3. Hashing that UTF-8 canonical string with SHA-256.
4. Reading digest bytes `0..7` in digest order as an unsigned big-endian integer.
5. Reducing that value modulo `2147483646`.
6. Adding `1`.

The valid stream seed range is therefore `1..2147483646`. This contract is covered by a golden test vector.

## RNG Range Semantics
`WorldgenRandomStream` uses a project-owned Park-Miller LCG with multiplier `48271` and modulus `2147483647`.

Range contracts:
- `next_int()` returns `1..2147483646`.
- `next_float()` returns `[0.0, 1.0)`.
- `range_int(min, max)` uses inclusive integer bounds.
- `range_float(min, max)` returns `[min, max)`.

## Golden Trace Example
For:

```text
run_seed: 12345
sector_index: 7
route_profile: industrial
region_pack: central_eu_v1
grammar_version: central_eu_small_town_station_v1
generator_version: 9f_deterministic_worldgen_infra_v1
```

The golden subseeds are:

```text
archetype: 238576771
topology: 2064870995
spatial: 2091214199
terrain: 661731090
world_entities: 1947510623
pois: 789851001
rolling_stock: 1781333302
gameplay_problem: 1381368502
decay: 855139671
decoration: 250620168
```

Canonical generation trace hash:

```text
c29825cacac716621dacb2a8cf7a5450eddb7645fbe49382d304df05bcb117a6
```

## Automated Acceptance
- [x] Same complete generation input produces the same subseeds and trace hash.
- [x] Different `sector_index` changes stream subseeds.
- [x] Different `run_seed` changes stream subseeds.
- [x] Different `generator_version` changes stream subseeds and trace identity.
- [x] Consuming `decoration` does not perturb `topology`.
- [x] Creating/consuming `terrain` before `topology` does not perturb `topology`.
- [x] Recreating a named stream returns a defined reset deterministic sequence.
- [x] Unknown stream names fail with structured diagnostics.
- [x] Range semantics are covered by tests.
- [x] No procedural topology, spatial generation or runtime integration is introduced.

## Explicit Exclusions
Do not implement in Sprint 9F:
- procedural archetype selection;
- procedural railway topology;
- weighted loops, yards or spurs;
- random track graphs;
- procedural spatial embeddings;
- terrain, roads, rivers, towns or POIs;
- rolling-stock placement;
- damage/gameplay mutations;
- shunting solvability;
- generated railway seed sweeps;
- production `SectorDefinition` integration;
- active `SectorLifecycle` integration;
- save/load changes;
- route-map gameplay;
- art changes.

## Developer Acceptance
No gameplay UAT is required for 9F. Developer acceptance is the golden generation trace plus automated proof that decoration/terrain stream consumption does not alter topology.

## Next Possible Increment
Future work may build semantic generation on top of `WorldgenGenerationContext`, but only after an explicit sprint plan promotes procedural archetype/topology work.
