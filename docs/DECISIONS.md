# Design & Architecture Decision Log

Record decisions that would otherwise be repeatedly re-litigated. Keep entries concise.

## D-001 — Top-down 2D Godot
**Decision:** Build as a top-down 2D Godot 4.x game.  
**Reason:** Matches desired colony/railway visibility and keeps scope achievable.

## D-002 — Physical train
**Decision:** The train is a physical object/consist in the world rather than an abstract colony menu.  
**Reason:** Central product identity.

## D-003 — Real-time train movement
**Decision:** The train moves physically in real time.  
**Reason:** Travel, stopping, escape and railway operations need to feel continuous.

## D-004 — Physical shunting
**Decision:** Rolling stock cannot be click-drag reordered. Players use track, points, locomotives, crew and shunting operations.  
**Reason:** Defining mechanic and differentiator.

## D-005 — Forward-only sectors
**Decision:** Once the train exits a sector, the player can never return to it.  
**Reason:** Strong procedural-game identity, consequential decisions and simpler scalable simulation.

## D-006 — No simulation of departed sectors
**Decision:** Departed sectors are destroyed rather than simulated in the background.  
**Reason:** Nothing can return from them under current design; retaining simulation adds cost without gameplay benefit.

## D-007 — Persistent train, disposable world
**Decision:** Train/survivor/run state persists independently of sector scenes.  
**Reason:** Required by D-005 and D-006.

## D-008 — One community train
**Decision:** Core game centres on one train. Additional locomotives may later be added to that consist for push/pull/double-heading/shunting.  
**Reason:** Maintains intimacy and avoids fleet-management scope.

## D-009 — Crew automation
**Decision:** Survivors can be assigned roles/jobs that auto-create routine tasks.  
**Reason:** Allows detailed physical people without late-game micromanagement collapse.

## D-010 — Permadeath
**Decision:** Survivor death may be permanent.  
**Reason:** Skills and emergent history should create meaningful loss.

## D-011 — Failure by irrecoverable mobility/survival loss
**Decision:** A temporarily disabled locomotive is not automatically game over; irrecoverable loss of viable mobility/survival is.  
**Reason:** Recovery scenarios are more interesting than arbitrary HP thresholds.

## D-012 — Combat deferred
**Decision:** Combat is not required for the initial POC. Direction is lightweight click-to-engage/tactical commands, subject to later validation.  
**Reason:** Combat could consume the project before rail gameplay is proven.

## D-013 — Programmer art first
**Decision:** Early sprints use primitive/programmer art.  
**Reason:** Visual polish must not mask weak gameplay or block iteration.

## D-014 — AI art is an offline tool pipeline
**Decision:** Future generative art services produce source assets outside the runtime game. Godot consumes processed assets; the game does not depend on a live image-generation API.  
**Reason:** Reproducibility, cost, latency, licensing review, consistency and runtime reliability.

## D-015 — Endpoint-based coupling
**Decision:** Coupling is valid only from a controlled rail-space contact event between two exposed, compatible coupler endpoints on the same reachable rail path. The contacted endpoints determine whether the target consist is prepended or appended.
**Reason:** Physical shunting depends on the actual couplers that touched; nearby-wagon scanning or generic append operations break consist order, switch topology and future push/pull operations.

## D-016 — Per-unit rail transforms and locomotive authority
**Decision:** Each rolling-stock unit renders from its own rail-space position and local tangent. Physical consist order, rolling-stock identity and traction/control authority are separate; Sprint 2 control remains attached to locomotive `L` even if wagons sit ahead of it in the consist. Front/rear decoupling keeps the active controlled consist on the segment containing `L` and rejects commands that would promote a wagon to control.
**Reason:** Switches and curved/diverging track require per-vehicle orientation, and shunting must never let a wagon inherit locomotive type or control authority from array position.

## D-017 — Crew tasks orchestrate rail authority
**Decision:** Sprint 3 crew tasks validate and reserve explicit physical interaction anchors, move a survivor there, then call the existing rail-domain operation. Points operation uses the rail points API; uncoupling targets a specific existing coupled joint and uses the rail joint-split API. Aboard survivor transforms derive from the host rolling-stock transform.
**Reason:** Physical crew should deepen shunting without duplicating railway simulation, corrupting consist identity or bypassing rail-space authority.

## D-018 — Railway operations are systemic world state
**Decision:** Sprint 4 yard operations model mechanical point state, yard-control repair, abstract power and local shunter repair as independent world-object state. Current UAT points remain local-only: repaired/powered yard control does not grant remote switch throwing, and remote commands reject without mutating routes. Multiple powered units may exist, but the controlled powered unit is selected explicitly and never inferred from consist order.
**Reason:** The same salvage objective should support manual and shunter solutions through interacting systems rather than scripted strategy branches or identity-changing shortcuts. Remote switching is promising, but it is parked until the physical crew-control model is easier to read and test.

## D-019 — Crew presence gates playable railway operations
**Decision:** In the playable scene, throttle control for a locomotive/shunter requires at least one survivor aboard that powered unit. Coupling and uncoupling are crew tasks against explicit contact/joint anchors; normal UI actions do not directly splice or append consists.
**Reason:** The demo should prove Train Scav's core idea that railway operations are physical work done by people and rolling stock, not hidden keyboard shortcuts or proximity-based array mutations.

## D-020 — Yard layouts use explicit railway grammar
**Decision:** Hand-authored yards should read as railway infrastructure: a dominant main line, yard leads, facing turnouts, roughly parallel sidings and deliberate buffered ends. Sprint 4.5 makes P3 an authoritative second-stage turnout from the P1 yard lead into storage/repair sidings.
**Reason:** Track can remain simplified without looking arbitrary; recognisable railway grammar supports the intended transport-management feel and gives later procedural generation a reusable topology vocabulary.

## D-021 — Context-menu commands capture their crew actor
**Decision:** Right-clicking a survivor selects that survivor before menu creation. Object right-click preserves the current crew selection. Every menu command stores the actor ID captured when the menu opens, and the menu visibly names both crew and target.
**Reason:** A mutable global selection must not silently redirect an already-presented order to another survivor, especially once Sprint 5 adds needs and automatic jobs.

## D-022 — Carriage interiors depend on physical consist topology
**Decision:** Survivor onboard movement uses rolling-stock IDs and local carriage coordinates, and asks the railway domain which units belong to the same physical consist. Colony code does not duplicate or mutate consist topology. A survivor may cross only walkable adjacent vehicles in the current consist; uncoupling immediately invalidates routes across that joint.
**Reason:** The train must remain one physical simulation. This allows crew to move while carriages translate/rotate on track, makes shunting materially affect colony accessibility, and prevents a future colony pathfinder from inventing connections that the railway no longer has.

## D-023 — Sector departure is explicit forward disposal
**Decision:** A sector transition is triggered only by forward movement across a visible eastbound exit track, then confirmed by the player before the disposable sector is destroyed. Cancelling departure hard-brakes the train before the boundary. The confirmation warns about detached rolling stock and reserves space for future supply/resource abandonment.
**Reason:** Forward-only sectors should feel consequential and understandable; accidental reverse-side triggers or invisible disposal undermine trust in the run lifecycle.

## D-024 — Scavenging ownership is physical
**Decision:** Sprint 7 separates resource ownership by domain. Sector POIs own searched state and uncollected loot; survivors own carried cargo; the train owns deposited diesel/food/parts. Searching reveals resources but never adds them to the train. Deposit at the train storage point transfers carried cargo into the train stockpile. Sector departure requires and consumes train diesel, and cannot strand survivors outside the train.
**Reason:** The stop/search/haul/depart loop only proves the hypothesis if useful supplies remain physically outside the train until people retrieve them. The Sprint 6 lifecycle remains the sole authority for irreversible sector departure and disposal.

## D-025 — First vertical slice composes existing systems
**Decision:** Sprint 8 uses a small authored scenario coordinator to compose existing train, crew, sector, scavenging, yard and resource systems. The coordinator may configure deterministic sector templates, expose objectives and report scenario blockers, but it observes authoritative gameplay state instead of owning parallel copies. Workshop wagon `W` is recovered only by physical coupling, workshop activation is a separate crew/resource task after recovery, and the final route branch writes run/next-sector metadata rather than resolving the slice through a scripted mission branch. Developer UAT may be paced for a 10-15 minute prototype run instead of literally taking the eventual first-session duration.
**Reason:** The vertical slice should prove that the established systems form one coherent game loop without replacing them with a quest framework or hiding physical railway consequences behind scripted shortcuts.

## D-026 — Route choice is physical rail egress
**Decision:** Sprint 8's final route decision is made by driving the upgraded train across one of the authored exit branches. Route intel and labels explain where each branch leads, but no menu command chooses the route. The sector/lifecycle exit state tells the scenario which branch was crossed, and only then is persistent run route metadata written.
**Reason:** Route choice should reinforce the core railway premise: track topology, switch state and physical train position determine where the colony goes next.

## D-027 — Procedural railway generation starts with semantic graphs
**Decision:** Sprint 9 worldgen represents railway meaning as a source-neutral semantic rail graph plus a separate world relationship graph before any physical geometry or gameplay placement is generated. Runtime fixtures use canonical JSON and internal roles such as `THROUGH_MAIN`, `PASSING_LOOP`, `GOODS_YARD_TRACK` and `AGRICULTURAL_SPUR`; raw external map tags remain research provenance only.
**Reason:** Procedural sectors need railway places the game can reason about without copying real station geometry, depending on OSM/ORM tags at runtime, or replacing the validated `RailMovement`, crew, POI and sector-lifecycle authorities.

## D-028 — Sprint 9B proves blueprint coverage before generation
**Decision:** Sprint 9B uses six authored reference archetype fixtures to prove one immutable `SectorBlueprint` query API and canonical hash contract before implementing seeded semantic generation. `SectorDefinition` and the active sector lifecycle remain on the existing authored path.
**Reason:** The 9A schema first needs to show it can represent materially different researched railway places without archetype-specific runtime code. Deferring RNG streams, procedural topology and runtime loading keeps 9B from jumping ahead into later procgen and preserves the playable prototype.

## D-029 — Sprint 9C validates semantic topology before geometry
**Decision:** Sprint 9C strengthens `WorldgenSchemaValidator` with structured diagnostics for semantic railway topology and world-relationship errors while remaining independent of scene nodes, `RailMovement`, `SectorLifecycle`, POIs and rolling-stock simulation.
**Reason:** Future authored and generated blueprints need actionable rejection reasons before geometry or runtime reconstruction exists. Keeping validation semantic-only catches bad graph meaning early without expanding into generator, shunting solvability or physical railway authority scope.

## D-030 — Sprint 9D reconstructs one authored blueprint through the existing rail runtime
**Decision:** Sprint 9D reconstructs only the `small_town_goods_station` reference blueprint into a playable railway by pairing the immutable semantic fixture with a separate authored spatial embedding and passing the resulting layout into a minimal `RailMovement.configure_track_layout()` seam. The active `SectorDefinition`, `SectorInstance`, `SectorLifecycle` and production `Main.tscn` path remain unchanged.
**Reason:** Runtime reconstruction needs proof against the real rail authority before procedural geometry is attempted. Keeping the embedding separate preserves the 9A-9C semantic contract, while decomposing the west semantic throat into ordinary runtime turnouts avoids destabilising `RailMovement` with a multi-route special case.

## D-031 — Sprint 9E broadens authored runtime reconstruction without generation
**Decision:** Sprint 9E reconstructs all six Sprint 9B reference archetypes through the same `SectorBlueprint` -> semantic validation -> authored embedding -> `WorldgenRuntimeReconstructor` -> `RailMovement.configure_track_layout()` path. Route presets are harness metadata only, and `ABANDONED_TRACK` may map to display-only runtime geometry that is visible and semantically mapped but excluded from active movement routing.
**Reason:** Before procedural generation, the project needs proof that the 9D reconstruction seam is generic across materially different railway forms. Keeping variation in fixture/embedding data prevents archetype-specific runtime construction while preserving the existing rail authority and production sector lifecycle.

## D-032 — Sprint 9F fixes deterministic generation identity before generation
**Decision:** Sprint 9F introduces `WorldgenGenerationRequest`, `WorldgenGenerationContext`, named deterministic RNG streams and canonical generation traces without generating new semantic topology. Stream subseeds are derived from SHA-256 over canonical generation identity plus stream name, using digest bytes `0..7` as an unsigned big-endian value modulo `2147483646`, plus one. `make_rng()` returns a fresh reset stream for the requested name.
**Reason:** Future procedural stages need reproducible failures and independent variation boundaries before they create railway graphs. Versioned, golden-tested stream derivation prevents decoration, terrain or gameplay-problem random draws from accidentally changing topology and preserves save/replay compatibility.

## D-033 — Sprint 9G generates one semantic archetype under explicit algorithm identity
**Decision:** Sprint 9G adds `WorldgenSemanticGenerator` for only the `village_passing_station` semantic archetype. The generator requires `WorldgenGenerationRequest.generator_version` to equal `9g_village_passing_station_semantic_v1`, but generated blueprint dictionaries keep the current validator-required `generator_version: 9a_schema_v1`. 9G appends stage decisions to the existing generation trace, uses `topology` only for rail-semantic choices, and uses `world_entities` only for world-relationship variation such as optional road access.
**Reason:** The project needs its first procedural semantic topology without redesigning the Sprint 9A schema field or coupling future topology to world/decorative randomness. Restricting 9G to one researched archetype proves the deterministic generator boundary while leaving geometry, runtime reconstruction, wider archetype selection and production sector integration for later sprints.

## D-034 — Sprint 9 production generation starts after the authored opening
**Decision:** Sprint 9 keeps authored sectors 0 and 1 intact, then uses `SectorDefinitionProvider` to resolve sector index 2 and beyond through `WorldgenProductionSectorGenerator`. The production generator uses named RNG streams to select one of three bounded archetypes (`rural_through`, `village_passing_station`, `small_town_goods`), generate semantic data, validate a `SectorBlueprint`, create a bounded procedural spatial embedding, reconstruct a runtime layout, and return a real generated `SectorDefinition`. `SectorLifecycle` remains the authority for departure validation, diesel cost, irreversible disposal, persistent train transfer, crew relinking and run-journal recording.
**Reason:** The isolated Sprint 9 harnesses proved the railway generation engine, but Sprint 9 is only gameplay-complete when the normal game can continue past the crafted opening into deterministic procedural sectors without a separate game mode. Keeping generation behind a provider boundary preserves the existing lifecycle and gameplay authorities while making generated sectors part of the real run.

## D-035 — Sprint 10 rolling stock is catalogue metadata plus physical ownership
**Decision:** Sprint 10 formalises rolling stock through a small `RollingStockCatalog` keyed by type ID. Procedural salvage receives explicit `unit_id -> type_id` metadata; legacy ID/prefix inference remains only as a compatibility fallback. `RailMovement` exposes catalogue-backed type, capability and resource-capacity queries, while `SectorLifecycle` persists only the physically coupled active consist and its type map. Unrecovered detached generated stock remains sector-local and is discarded with the old `SectorInstance`.
**Reason:** Wagon function should matter without creating a generic rolling-stock simulation framework. The catalogue makes generated wagons inspectable and mechanically useful, but existing physical coupling/shunting stays authoritative for ownership and consist order.

## D-036 — Sprint 11 promotes researched procgen forms without a solver
**Decision:** Sprint 11 expands production procedural sector generation from three to six bounded archetypes by adding `agricultural_loading_point`, `river_valley_constrained` and `declining_abandoned_branch` to the existing semantic, spatial and production generator pipeline. Archetype selection preserves the Sprint 10 `small_town_goods` seed bucket so known salvage UAT seeds remain valid, then varies rural/station families through the existing archetype RNG stream. New forms use small deterministic spatial grammars, generated POIs, route presets and semantic relations; they do not introduce a general layout solver, terrain renderer, hazard system, new rolling stock or multi-locomotive play.
**Reason:** The next replayability gain comes from more distinct generated railway places, not broader simulation architecture. Keeping each form explicit and bounded lets normal `SectorLifecycle`, `RailMovement`, `SectorPOIs`, resources and Sprint 10 physical wagon ownership remain the authorities while the generator gains meaningful variety.

## D-037 — Standardized train mobility summary and structured route requirements
**Decision:** Sprint 12 formalises consist burden and route restrictions through a standardized `Train Mobility Summary` contract (`total_mass`, `total_length`, `unit_count`, `has_traction`, `powered_unit_id`, `capabilities`) exposed on `RailMovement` and evaluated by a pure `RouteRequirementEvaluator`. Sector route exits declare structured requirement dictionaries (`max_mass`, `min_mass`, `max_length`, `max_units`, `require_traction`, `required_capabilities`), which `SectorLifecycle` validates on departure gating with explicit, readable rejection reasons. Sector 0 and baseline procedural main routes remain unrestricted; authored Sector 1 branch routes enforce distinct mass, length, and capability requirements.
**Reason:** Train composition should create tactical and strategic tradeoffs when choosing route branches without requiring complex multi-locomotive physics, hazards, or fuel rebalancing. A pure evaluation contract keeps physical railway movement and sector lifecycle authority completely clean and decoupled.

## D-038 — Single-consist multi-locomotive operations and aggregate traction
**Decision:** Sprint 13 introduces multi-locomotive consist operations without introducing multi-train simulation, distributed dispatch, or locomotive AI. Aggregate available traction is defined as the sum of traction ratings across all operational coupled powered units in `active_units` (`get_available_traction()`), provided the explicit controlled cab (`controlled_power_unit_id`) is operational and present in the consist. Control authority remains explicit on one cab and is never inferred from consist array index or vehicle positioning. Rolling stock catalog defines `traction_rating: 1.0` and capabilities for locomotives and shunters. Route gating via `RouteRequirementEvaluator` evaluates `min_traction` against aggregate traction, and `SectorLifecycle` persists multiple powered unit IDs, operational conditions, and consist order across sector disposal.
**Reason:** Recovering and shunting an additional locomotive should meaningfully expand train capabilities and unlock heavier/steeper routes, while strictly maintaining the core design invariant of one community train and one physical consist simulation.
