# Current Sprint - Sprint 12.5: Operational UI / UX Clarity Pass

**Status:** IN PROGRESS

## Hypothesis
Transforming developer-heavy diagnostics into an intuitive, structured player-facing operational interface with readable route eligibility, physical action hints, and strict message prioritization allows players to understand why routes are blocked and what physical railway actions are needed to proceed, without reading internal debug telemetry.

## Scope Contract
- Introduce a pure presentation helper `OperationalUIPresenter` to format domain state into player-facing information:
  - **Sector / Objective:** Human-readable location names and clear objectives (hiding generator hashes, versions, raw seeds).
  - **Train Summary:** Operational mass, consist size, crew/driver state, qualitative length, and capability badges (`Workshop ✓`, `Storage ✓`, `Crew Accommodation ✕`).
  - **Resource Stock:** Diesel (with departure cost requirement), food, and parts.
  - **Route Decision UI:** List all exit branches with clear status (`AVAILABLE` vs `BLOCKED`), detailed human-readable limitation descriptions, physical action hints, and current switch alignment.
  - **Crew Summary:** Clean survivor status (`Iris — Yard Shunter (Driving)`, `Marta — Workshop (Idle)`).
- Fix the status message priority hierarchy so critical action/departure blockers outrank flavour and scenario text and are never shadowed.
- Update world labels for switches and exit boundaries to use clean railway terminology (*Direct Line*, *Industrial Line*, *Settlement Line*, *P2 → Industrial Line*).
- Implement an explicit debug mode toggle (`F3`) to hide internal telemetry in normal play while keeping full diagnostics accessible for development.
- Preserve complete backward compatibility for existing test surfaces (`get_compact_debug_lines()`, `get_uat_tutorial_lines()`).
- Add comprehensive automated tests verifying message priority, route presentation, and debug separation.

## Explicit Exclusions
Do not implement during Sprint 12.5:
- Final art, HUD textures, or art asset pipelines;
- Survivor portrait systems, minimaps, or world maps;
- Redesign of simulation systems (`RailMovement`, `RouteRequirementEvaluator`, `SectorLifecycle`, `CrewSimulation`);
- Automated route planning or wagon-removal solvers;
- Multi-locomotive control or new rolling stock types;
- Changes to sector procedural generation algorithms.

## Acceptance
Sprint 12.5 is complete when:
- Normal gameplay displays clean, player-facing operational UI instead of a wall of debug telemetry.
- Critical departure blockers outrank generic scenario/flavour text and remain clearly visible when a route exit is blocked.
- The route decision UI explains why each route is available or blocked with explicit deltas (e.g. 277t vs 250t limit) and actionable physical hints.
- Train capabilities and mobility summary are presented in clear, readable terms without raw pixel dimensions.
- Railway branches and switch controls visually connect to player-facing route names.
- Crew and survivor tasks are presented as clean readable summaries.
- Pressing `F3` toggles the full developer diagnostics overlay.
- All domain simulation systems remain authoritative and unchanged.
- Automated unit tests and scripted UAT rehearsals pass cleanly.

