# Current Sprint — Sprint 1: Train Moves on Rails

**Status:** READY TO START

## Sprint objective
Build the first playable rail movement prototype: one locomotive constrained to a hand-authored track layout with one main line, one siding and one points/switch.

## Hypothesis
Track-constrained real-time movement can feel controllable enough for later shunting.

## In scope
- One locomotive using programmer art.
- One main track.
- One branch/siding.
- One points/switch object.
- Forward/reverse command.
- Throttle/basic speed control.
- Brake/stop.
- Track-following movement.
- Visible debug state.
- Headless validation of the core acceptance route where practical.

## Out of scope
Do NOT implement:
- wagons/couplers;
- crew;
- inventory/resources;
- procedural generation;
- combat;
- final UI;
- final art;
- Google/Gemini image generation integration;
- plugins/addons unless required merely to run the existing project.

## Acceptance test
Sprint 1 is complete only when all are true:

- [ ] The player can drive the locomotive from the main line into the siding.
- [ ] The player can stop the locomotive.
- [ ] The player can reverse the locomotive.
- [ ] The player can change the points/switch.
- [ ] The player can return the locomotive to the main line reliably.
- [ ] Visible debug state shows the current track segment, speed, direction, throttle and points state.
- [ ] No known GDScript parser errors remain.
- [ ] `git status` is understood and unrelated user work is preserved.
- [ ] A repeatable validation command/process is recorded in `README.md` or this file.

## Definition of done
A playable rail movement prototype is more important than architectural completeness. Do not pre-build future shunting, consist, crew, resource, combat or procedural systems.

## Next sprint
After Sprint 1 acceptance, replace this file's active content with Sprint 2 from `ROADMAP.md`: **Rolling Stock and Consist Operations**.
