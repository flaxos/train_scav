# Current Sprint - Sprint 2: Rolling Stock and Consist Operations

**Status:** IMPLEMENTED - READY FOR HUMAN PLAYTEST

## Sprint objective
Build the first playable consist prototype: a locomotive and wagons that can be physically coupled, decoupled and reassembled in a hand-authored test yard.

## Hypothesis
Physical coupling/decoupling and consist manipulation is satisfying enough to justify the larger game.

## In scope
- Minimum two wagon types using programmer art.
- Front/rear couplers.
- Coupled consist movement.
- Decoupling.
- Recoupling.
- Basic mass aggregation.
- Simple low-speed coupling constraints.
- Hand-authored test yard.
- Visible debug state for consist, couplers, mass and switching.
- Headless validation of the core acceptance route where practical.

## Out of scope
Do NOT implement:
- crew;
- survivor tasks;
- resources/inventory;
- procedural generation;
- combat;
- final UI;
- final art;
- multi-locomotive operations;
- advanced braking/air-line simulation;
- damage/maintenance;
- save/load;
- plugins/addons unless required merely to run the existing project.

## Acceptance test
Sprint 2 is complete only when all are true:

- [x] The yard starts with `[L][A][B]` coupled on the main line and `[C]` on a siding.
- [x] At least two wagon types are visible using programmer art.
- [x] Rolling stock exposes front/rear coupler state.
- [x] The coupled consist moves as one physical train under locomotive control.
- [x] The player can decouple `B` from `[L][A][B]` without teleporting or reordering wagons.
- [x] The player can move `[L][A]` through the points to the siding and couple `C` at low speed.
- [x] Coupling is blocked when the active consist is moving too fast.
- [x] The player can return to the main line and recouple `B`, producing `[L][A][C][B]`.
- [x] Basic total mass changes as wagons are removed and added.
- [x] Visible debug state shows consist order, speed, throttle, direction, brake state, points route, mass and coupler status.
- [x] No known GDScript parser errors remain.
- [x] `git status` is understood and unrelated user work is preserved.
- [x] A repeatable validation command/process is recorded in `README.md` or this file.

## Definition of done
The player must physically perform the shunting sequence in the test yard. Do not add colony, crew, resource, procedural, combat or presentation systems to compensate for unclear consist interaction.

## Next sprint
After Sprint 2 acceptance, replace this file's active content with Sprint 3 from `ROADMAP.md`: **Crew exists physically**.
