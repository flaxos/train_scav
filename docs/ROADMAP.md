# Roadmap — Playable Increments

## Delivery philosophy

This project uses playable increments rather than speculative feature development.

Each sprint has:
- one gameplay hypothesis;
- a bounded scope;
- explicit exclusions;
- a playable acceptance test.

A sprint does not expand because adjacent ideas are attractive. New ideas go to `PARKING_LOT.md`.

## Phase A — Proof of Concept

### Sprint 0 — Project skeleton
**Hypothesis:** The repository can support disciplined, repeatable Godot/Codex development.

Deliverables:
- runnable Godot project;
- Git repository hygiene;
- documentation pack installed;
- prototype scene;
- basic automated/headless project validation where practical;
- debug conventions;
- project baseline documented.

Acceptance:
- clean clone/open can launch the prototype scene;
- Codex can read project instructions and identify the active sprint;
- project validation completes without parser errors.

### Sprint 1 — Train moves on rails
**Hypothesis:** Track-constrained real-time movement can feel controllable enough for later shunting.

Build:
- one locomotive;
- one main track;
- one branch/siding;
- one points/switch object;
- forward/reverse;
- throttle/basic speed control;
- brake/stop;
- track following;
- visible debug state.

Exclude:
- wagons;
- couplers;
- crew;
- resources;
- procedural generation;
- final art.

Acceptance:
> The player can drive the locomotive from the main line into the siding, stop, reverse, change the points and return to the main line reliably.

### Sprint 2 — Rolling stock and consist operations
**Hypothesis:** Physical coupling/decoupling and consist manipulation is satisfying enough to justify the game.

Build:
- minimum two wagon types using programmer art;
- front/rear couplers;
- coupled consist movement;
- decoupling;
- recoupling;
- basic mass aggregation;
- simple low-speed coupling constraints;
- test yard.

Acceptance:
> Starting with `[L][A][B]` and `[C]` on a siding, the player can physically recover `C` using rail movement, points, coupling and decoupling with no teleport/reorder command; the resulting consist order follows the exposed couplers that actually touched.

**POC GO/NO-GO GATE:** If this is not enjoyable or understandable, improve the interaction before adding colony systems.

### Sprint 3 — Crew exists physically
**Hypothesis:** Requiring people to perform railway tasks strengthens rather than slows shunting gameplay.

Build:
- ~5 simple survivors;
- selection;
- walking inside simple rolling stock / local yard;
- leave/board stopped train;
- task assignment;
- manual points operation by survivor;
- physical uncoupling task by survivor.

Acceptance:
> A player can assign a survivor to operate points and another to uncouple a wagon, then execute a successful shunting manoeuvre.

### Sprint 4 — Railway operations systems
**Hypothesis:** Multiple systemic solutions make yards interesting rather than repetitive.

Build a hand-authored yard supporting at least two approaches:
- manual points;
- repair/use local shunter OR temporary secondary locomotive;
- repair/power yard control as infrastructure state, with remote switching parked until the crew-operated UAT is clearer.

Potential supporting systems:
- damaged/offline points state;
- electrical/mechanical tasks;
- portable/train-supplied power abstraction;
- basic rail crew coordination.

Acceptance:
> The same salvage target can be recovered through at least two materially different player strategies without scripted branching.

## Phase B — Colony Vertical Slice

### Sprint 5 — Train becomes a colony
**Status:** COMPLETE — ALL AUTOMATED TESTS PASSING (28/28)

Build:
- initial carriage interiors;
- survivors moving through connected train;
- minimal needs: health, hunger, rest;
- minimal skills;
- jobs/roles;
- automatic task assignment;
- initial carriage set: locomotive, bunk/passenger, storage, workshop.

Acceptance:
> During travel/stops, survivors visibly satisfy basic jobs/needs and an engineer automatically responds to a relevant maintenance task according to priorities.

### Sprint 6 — Sector lifecycle
**Status:** COMPLETE — Sprint 6B Sector Clarity Stabilisation has passed automated validation and human UAT.

Build:
- sector container;
- entry/exit boundaries;
- persistent train transfer across sectors;
- destruction of previous sector;
- generation/loading of next sector;
- run journal summary;
- initial deterministic template-composed sector lifecycle.

Acceptance:
> Train drives forward onto a visible eastbound exit track, the player confirms sector disposal with clear left-behind-asset warnings, Sector A is destroyed, train state persists, and the train enters a newly generated Sector B. Returning to A is impossible.

Sprint 6B acceptance:
> Sector 1 no longer reads like a reset of Sector 0: the guide, debug state and entry marker identify the new sector, disembarking remains in the active sector, and reversing left cannot backtrack.

### Sprint 7 — Scavenging/resources
**Status:** COMPLETE — implemented and committed.

Build:
- local POIs;
- expedition selection;
- searchable objects/areas;
- hauling back to train;
- minimum resources: diesel, food, parts;
- stopping has resource/time consequence.

Acceptance:
> The player must stop, search, retrieve a required resource, return the team, and depart to sustain the train.

### Sprint 8 — First vertical slice
**Status:** ACTIVE — automated implementation ready; human playtest pending.

Combine the systems into the agreed first-30-minute structure:
- moving train;
- obstruction;
- small expedition;
- irreversible sector exit;
- onboard fault/job response;
- next industrial sector;
- workshop wagon discovery;
- yard operations;
- physical recovery;
- workshop activation;
- route/recruitment/resource decision.

Acceptance:
> A fresh player can complete one meaningful travel→stop→explore→shunt→upgrade→depart cycle and understand why the train and its physical configuration matter.

## Phase C — Depth, Variety & Replayability

Only after the vertical slice is fun, Phase C should deepen the systems that make repeated runs feel different without losing the physical train/sector focus.

| Sprint | Focus | Why now |
| --- | --- | --- |
| 9 | Production procedural railway sectors | Wires the proven Sprint 9 generator into the normal sector lifecycle after the authored opening, with three bounded procedural railway forms. |
| 10 | Rolling-stock ecosystem | Gives generated yards meaningful things to contain and recover. |
| 11 | Locomotive acquisition & multi-loco operations | Expands the defining railway gameplay once rolling-stock variety exists. |
| 12 | Infrastructure hazards | Bridges, tunnels, damaged track, crossings and waterways create route problems. |
| 13 | Survivor depth | Makes expedition and job decisions more consequential after world variety exists. |
| 14 | Settlements, factions & trading | Gives people, resources and route choices persistent external meaning. |
| 15 | Threats/combat | Adds danger after non-combat exploration already has depth. |
| 16 | Run systems | Adds save/load, difficulty, world config and run setup once the loop is stable. |
| 17 | Player UX pass | Improves onboarding, information architecture and controls after the systems settle. |
| 18 | Presentation pipeline | Adds generated/authored art, audio and environmental presentation after gameplay shape is proven. |

### Sprint 9 — Procedural Railway & World Grammar

Sprint 9 was implemented as gated increments so procedural variety did not rewrite validated railway gameplay in one large step.

Status:
> Implemented - final normal-game human UAT pending.

Sprint 9 increments:
- 9A: railway/world grammar research, schema and fixtures;
- 9B: immutable `SectorBlueprint` and six authored semantic archetypes;
- 9C: semantic/topological validation with structured diagnostics;
- 9D: one authored blueprint plus authored spatial embedding reconstructed into `RailMovement`;
- 9E: all six authored archetypes reconstructed through the same runtime path;
- 9F: deterministic generation request/context, named RNG streams and generation trace;
- 9G: first generated semantic railway, `village_passing_station`;
- closeout: production `SectorLifecycle` handoff after the authored opening -> deterministic procedural `SectorDefinition` -> generated `SectorInstance` -> existing gameplay systems.

9A acceptance:
> The project has an explicit, versioned semantic railway/world schema and validated reference fixtures that later Sprint 9 generation work can consume without hard-coding authored yards or depending directly on external map tags.

9B acceptance:
> Six authored researched railway archetypes parse, validate, construct immutable `SectorBlueprint` objects, expose the same semantic query API, hash stably, remain materially different graphs and leave the existing playable sector lifecycle unchanged.

9C acceptance:
> Semantic blueprints with nonsensical railway topology or world relationships are rejected with useful diagnostic codes and IDs while all six Sprint 9B authored archetypes still validate and the active playable sector lifecycle remains unchanged.

Final Sprint 9 acceptance:
> After authored sectors 0 and 1, the normal production game automatically creates deterministic procedural sectors from run seed, sector index and generation identity. Generated sectors support rural-through, village-passing and small-town-goods railway forms, validate semantic graphs before use, reconstruct through the existing runtime pipeline, preserve the persistent train/crew/resources/consist, reuse existing scavenging and physical coupling/shunting systems, dispose previous sectors irreversibly, and reproduce the same sector chain for the same seed.

Sprint 9 does not implement terrain generation, additional procedural archetypes, a shunting solver, new wagon ecosystem content, save/load changes or a replacement production sector lifecycle.

## Phase D — Demo

A public-facing demo is a presentation and onboarding milestone, not merely a larger POC.

Requirements later:
- coherent art direction;
- polished first session;
- usable settings/input;
- readable UI;
- stable saves;
- audio feedback;
- performance target;
- player-facing tutorialisation without excessive modal instruction;
- telemetry/playtest feedback process if desired.
