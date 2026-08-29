# Current Sprint - Sprint 14: Infrastructure Hazards

**Status:** COMPLETE (UAT PASSED)

## Hypothesis
Railway infrastructure conditions (damaged points, restricted bridges, and damaged track) create meaningful operational problems that the player must solve physically using existing train, crew, repair, and route-choice systems, without scripted quest chains.

## Scope Contract
- **Bounded Infrastructure Hazard Set (3 Types)**:
  - **Damaged / Jammed Points (Turnout)**:
    - Turnout cannot be operated/toggled while damaged.
    - Locked in current alignment until repaired by crew via `TASK_REPAIR_POINT` (optionally consuming 1 part if available).
  - **Restricted Bridge / Track Section**:
    - Bridges with structural mass limits (e.g. `max_mass: 240.0t`) feed directly into `RouteRequirementEvaluator`.
    - Solvable by uncoupling heavy wagons, taking alternate open paths, or repairing.
  - **Damaged Track Section**:
    - Track segment marked `condition: "damaged"` blocks departure routes requiring it.
    - Repaired by crew via `TASK_REPAIR_TRACK`, consuming parts (2 parts) and engineer labor.
- **Route Requirements & UI Integration**:
  - `RouteRequirementEvaluator` checks `required_segments_operational` and `required_switches_operational`.
  - `OperationalUIPresenter` clearly presents hazard blockers, limits, and actionable physical hints.
- **Deterministic Worldgen & Solvability**:
  - Deterministically placed using `STREAM_GAMEPLAY_PROBLEM` subseed.
  - Semantically matched to archetypes (e.g. `river_valley_constrained` creek bridge, `village_passing_station` turnouts, `small_town_goods` yard switches).
  - Guaranteed solvable under current UAT assumptions (resources provided or alternate route available).

## Explicit Exclusions
Do not implement during Sprint 14:
- Bridge collapse physics, derailments, or hydrology/flooding;
- Signalling, interlocking, or timetable systems;
- Terrain deformation, landslides, or weather simulation;
- Save/load overhauls or new procgen archetypes;
- Final art, animations, or UI redesign.

## Acceptance
Sprint 14 is complete when:
- At least two meaningful infrastructure hazard types exist.
- Hazards use existing railway semantics rather than arbitrary coordinates.
- Route restrictions use the existing Sprint 12/13 evaluator.
- Crew can physically repair repairable hazards using existing APIs and parts.
- Infrastructure state changes meaningfully affect railway operation and route eligibility.
- Generated hazard states are deterministic.
- Generated hazard sectors are guaranteed solvable.
- Player UI clearly explains infrastructure blockers and action hints.
- Sprint 13 multi-loco and rolling stock behaviours remain valid.
- Full automated test suite passes.

