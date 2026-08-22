# Current Sprint — Sprint 6A: Disposable Sector Lifecycle

**Status:** COMPLETE — ALL AUTOMATED TESTS PASSING (29/29)

## Hypothesis
If the active train and crew can cross a deterministic sector exit, survive replacement of the entire sector-local world, and appear at the next sector's entry with persistent identities and state intact, then the game can support an irreversible journey through disposable generated sectors.

## Architectural Ownership Rule
**Sector state is disposable. Train and run state are persistent.**

A sector may reference the active train while present, but must NOT authoritatively own:
- rolling-stock identity;
- physical consist identity and order;
- coupler relationships;
- controlled locomotive or power-unit identity;
- survivor identity;
- survivor needs, skills or jobs;
- run seed, sector index or journal.

Destroying or disposing a sector must not reconstruct the persistent colony from prototype defaults.

## In-Scope Behaviour
1. Persistent run-level state (`RunState`) exists independently of disposable sector instances.
2. Sector container (`SectorInstance`) manages sector ID, seed, sector index, entry/exit boundaries, sector-local rail/yard state, and active/disposed lifecycle state.
3. The run starts in deterministic Sector A at sector index 0.
4. Two deterministic prototype sector templates exist: Sector A (index 0) and Sector B (index 1+).
5. Controlled train crossing Sector A's exit boundary requests a transition.
6. Departure Safety Rule: All persistent survivors must be aboard the persistent train before sector disposal. If any survivor is in the yard, departure is blocked with a clear reason.
7. Upon transition, persistent train/crew/broker state is retained, Sector A is disposed, Sector B is generated deterministically, and the train is placed on Sector B's entry rail position.
8. Returning to Sector A is impossible.
9. A run journal entry records departed sector ID, entered sector ID, destination seed, and consist order.
10. Debug panel visibly exposes current sector ID, seed, sector index, transition count, previous-sector disposal state, and consist order.

## Persistence Contract
Preserve across transition:
- rolling-stock IDs and physical consist order;
- coupler relationships;
- controlled locomotive/power-unit ID;
- survivor IDs, host-carriage IDs, health, hunger, rest values, skills, and jobs;
- automatic task-dispatch enabled/disabled preference;
- run seed, sector index, and run journal.

## Departure Safety Rule
All persistent survivors must be aboard the departing persistent train (`SPATIAL_ABOARD`). If any survivor is in the yard (`SPATIAL_YARD`), block departure and expose a clear status message.

## Explicit Exclusions
Do NOT implement in 6A:
- disk save/load or full serialisation;
- random terrain generation or procedural rail networks;
- POIs, scavenging, expeditions, resources (diesel, food, parts);
- combat, threats, factions, weather;
- multiple simultaneously loaded sectors or backtracking;
- minimap, loading screens, or endless sector generation.

## Automated Acceptance
- [x] Existing Sprint 1–5 regression suite remains green (28/28).
- [x] Run starts in deterministic Sector A with run seed and index 0.
- [x] Departure blocked if any survivor is in the yard.
- [x] Authoritative exit boundary crossing triggers transition once all survivors are aboard.
- [x] Sector A is disposed (`disposed == true`).
- [x] Sector B becomes active at index 1 with deterministic seed.
- [x] Persistent train/crew/needs/skills/jobs/broker state preserved intact.
- [x] Sector-local tasks/reservations from Sector A cancelled.
- [x] Sector B entry does not re-trigger transition (idempotent).
- [x] Run journal records transition details.
- [x] Debug state exposes sector lifecycle telemetry.
- [x] Full regression suite (Sprint 1–6A) passes 100%.

## Human Playtest Gate
- Launch project, confirm starting sector is Sector A.
- Leave survivor in yard, drive to exit -> confirm departure blocked.
- Board all survivors, drive across exit -> confirm environment transitions to Sector B.
- Confirm persistent train and crew remain intact on Sector B entry track.
- Confirm Sector A cannot be revisited.

## Definition of Done
When all 30 automated acceptance checks pass, code is clean, documentation is reconciled, and git history has a focused commit for Sprint 6A.

## Next Possible Increment
Sprint 6B — Richer sector template composition and procedural track variety (if needed).
