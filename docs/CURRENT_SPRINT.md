# Current Sprint - Sprint 9C: Semantic Railway Topology Validation

**Status:** IMPLEMENTED - AUTOMATED VALIDATION READY

## Hypothesis
A semantic railway blueprint can be mechanically rejected when its railway topology or world relationships are operationally nonsensical, before physical geometry or runtime `RailMovement` objects exist.

Sprint 9C strengthens validation only:

```text
SPRINT 9A SCHEMA
  -> SPRINT 9B SectorBlueprint
  -> SEMANTIC VALIDATOR
  -> VALID / INVALID + STRUCTURED DIAGNOSTICS
```

Roadmap acceptance:
> Invalid semantic railway/world graph data is rejected with useful diagnostic codes and IDs before geometry, scene nodes, runtime rail objects, rolling stock or sector lifecycle integration exist.

## Baseline Dependencies
Sprint 9C builds directly on the accepted Sprint 9A/9B worldgen contracts:
- `docs/deep-research-report-grammer.md` and `docs/deep-research-report-prompts.md`;
- source-neutral rail graph roles and world relationship graph vocabulary from 9A;
- the existing 9A JSON fixtures and validator;
- immutable `SectorBlueprint`, canonical hashes and six authored reference archetypes from 9B;
- completed Sprint 1-8 rail, crew, scavenging, sector lifecycle and vertical-slice systems.

Do not replace or integrate with `RailMovement`, `SectorDefinition`, `SectorInstance`, `SectorPOIs`, coupling, crew tasks, sector lifecycle or the vertical-slice scenario in 9C.

## In Scope
The active build adds the smallest useful semantic validation layer for future authored and generated blueprints:
1. Structured validation diagnostics with error code, concise message, relevant track/node/entity/relationship IDs and optional context.
2. A `validate_blueprint()` API in the existing worldgen validator.
3. Backward-compatible `validate_semantic_graph()` results preserving string `errors` for 9A/9B tests.
4. Conservative active-rail connectivity checks that exclude `ABANDONED_TRACK` from active entry-to-exit and active-service requirements.
5. Passing-loop, yard, spur, stub and isolated-active-track semantic checks.
6. Conservative world-relationship checks for platform, freight/loading, industry service, road access, bridge/crossing and settlement/station references.
7. Focused mutation tests proving useful diagnostic codes/IDs for malformed semantic data.
8. Positive regression tests proving the six Sprint 9B authored archetypes still validate.

## Authority Rules
- `SectorBlueprint` is a read-only semantic description artifact. It is not live railway authority.
- `WorldgenSchemaValidator` validates semantic dictionaries or blueprint data only.
- The active game remains on the existing authored `SectorDefinition` path.
- `SectorDefinition` must not automatically generate, load, validate or attach a blueprint in 9C.
- Runtime fixtures must use source-neutral semantic roles, not raw OSM/OpenRailwayMap tags.
- Intentional abandoned/disused semantics must be preserved.
- Abandoned track must not satisfy active entry-to-exit connectivity or active-service requirements.
- No physical `Vector2` track geometry, rolling stock, POI placement, terrain, routes, shunting solvability or gameplay problems are authored or validated in 9C.

## Required Diagnostics
Validation must not merely return true/false. Structured diagnostics should include:
- `code`
- `message`
- `track_id`
- `node_id`
- `entity_id`
- `relationship_id`
- `context`

The legacy `errors` array may contain formatted strings derived from diagnostics for compatibility, but future procgen debugging should use `diagnostics`.

## Explicit Exclusions
Do NOT implement in Sprint 9C:
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
- shunting solvability search;
- rolling-stock reachability;
- train-length/headshunt clearance calculations;
- damage/gameplay mutations;
- rolling-stock instantiation;
- POI spawning;
- integration into the active `SectorLifecycle`;
- replacement of `SectorDefinition`'s existing authored generation path;
- 9D work.

## Automated Acceptance
- [x] All six 9B reference archetype blueprints still validate.
- [x] Disconnected entry/exit is rejected with a diagnostic code and relevant node context.
- [x] One-ended passing loop is rejected with `PASSING_LOOP_NOT_DOUBLE_ENDED` and track ID.
- [x] Isolated active track is rejected with `ISOLATED_ACTIVE_TRACK`.
- [x] Unresolved world relationship is rejected with diagnostic code and relationship ID.
- [x] Disconnected yard track is rejected with `YARD_TRACK_DISCONNECTED`.
- [x] Spur with missing served facility is rejected with `SPUR_MISSING_SERVED_FACILITY`.
- [x] Bridge without corresponding obstacle crossing is rejected with `BRIDGE_CROSSING_MISSING`.
- [x] Platform referencing a nonexistent/invalid track is rejected with `PLATFORM_TRACK_REFERENCE_INVALID`.
- [x] Validation does not mutate a blueprint.
- [x] Validation does not change a blueprint canonical hash.
- [x] Existing Sprint 9A and 9B tests remain green.
- [x] Existing Sprint 1-8 regression tests remain green.
- [x] Headless launch has no parse/compile/runtime script errors.

## Human Review Gate
Sprint 9C has no playable procedural-sector UAT. It is complete when the user accepts that semantic graph diagnostics are useful enough for future authored and generated blueprint debugging without changing the active game.

## Definition of Done
Sprint 9C is complete only after the focused 9C tests pass, the existing 9A/9B tests pass, the broader regression suite remains green, headless launch succeeds, and no runtime sector lifecycle, scene or railway authority path has been changed.

## Next Possible Increment
Deterministic semantic generation from seeds remains deferred. Do not begin it, geometry work, runtime loading, POI spawning, rolling-stock placement or shunting solvability without an explicit new sprint plan.
