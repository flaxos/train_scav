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
**Current Active Increment:** Sprint 6A — Disposable Sector Lifecycle (uses two deterministic prototype sector templates: Sector A & Sector B; richer composition deferred to 6B if needed).

Build:
- sector container;
- entry/exit boundaries;
- persistent train transfer across sectors;
- destruction of previous sector;
- generation/loading of next sector;
- run journal summary;
- initial deterministic template-composed sector lifecycle.

Acceptance:
> Train exits Sector A, Sector A is destroyed, Train state persists, and the train enters a newly generated Sector B. Returning to A is impossible.

### Sprint 7 — Scavenging/resources
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

## Phase C — Post-validation systems

Only after the vertical slice is fun:
- deeper procedural sector variety;
- additional rolling stock;
- locomotive acquisition and multi-loco operation;
- richer survivor simulation;
- combat/threat systems;
- factions/trading;
- weather/environmental hazards;
- damaged bridges/tunnels/track repair;
- improved UI/onboarding;
- full save/load;
- difficulty/world configuration;
- generated/authored art pipeline;
- audio and presentation.

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
