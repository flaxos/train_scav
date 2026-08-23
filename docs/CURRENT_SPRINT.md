# Current Sprint — Sprint 6B: Sector Clarity Stabilisation

**Status:** COMPLETE — ALL AUTOMATED TESTS PASSING (30/30) — HUMAN PLAYTEST PASSED

## Hypothesis
If Sector 1 is visibly and mechanically distinct from Sector 0, then human testers can trust the disposable-sector lifecycle before Sprint 7 adds scavenging and resources.

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
1. Preserve the Sprint 6A disposable-sector lifecycle exactly.
2. Remove stale Sprint 4 / Sprint 5A labels from the README and playable guide.
3. Make Sector B / Sector 1 visibly distinct from Sector A / Sector 0 through clear presentation metadata and entry marker text.
4. Preserve the no-backtracking rule when reversing left after entering Sector 1.
5. Confirm disembarking after the Sector 1 transition leaves survivors in the active sector, not at an old-sector origin.
6. Clarify that P2 starts straight and therefore blocks the north workshop branch until a survivor operates it.
7. Place the sector exit on a visible eastbound main-exit track beyond P2 so departure reads as leaving the yard rather than hitting an invisible trigger.
8. Require forward train movement to cross the sector exit; reversing or sitting on an exit coordinate must not transition sectors.
9. Add an explicit departure confirmation UI that lists left-behind rolling stock and future supply placeholders before sector disposal.
10. If the player cancels departure, hard-brake the train before the boundary and keep the current sector active.
11. Keep Sector 6B as deterministic hand-authored stabilisation, not procedural generation.

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

Sector disposal is deliberate. The playable scene must stop at the forward exit boundary and ask for confirmation before calling the sector lifecycle transition. Cancelling departure stops the train before the boundary and must not dispose the current sector.

## Explicit Exclusions
Do NOT implement in 6B:
- disk save/load or full serialisation;
- random terrain generation or procedural rail networks;
- POIs, scavenging, expeditions, resources (diesel, food, parts);
- combat, threats, factions, weather;
- multiple simultaneously loaded sectors or backtracking;
- minimap, loading screens, or endless sector generation.

## Automated Acceptance
- [x] Existing Sprint 1–6A regression suite remains green.
- [x] README names Sprint 6B as the active stabilisation increment.
- [x] In-game guide names Sprint 6B and explains the Sector 0 -> Sector 1 UAT.
- [x] Sector A and Sector B expose distinct display names, entry labels and accent colors.
- [x] Sector B entry marker visibly names Sector 1.
- [x] P2/north workshop branch guidance is explicit.
- [x] Exit boundary is on a visible eastbound `main_exit` track beyond P2.
- [x] Reversing or idling on the exit boundary cannot transition sectors.
- [x] Forward exit opens a confirmation UI instead of immediately disposing the sector.
- [x] Confirmation lists left-behind rolling stock and future supply placeholders.
- [x] Cancelling departure hard-brakes before the exit and keeps the current sector.
- [x] Disembarking after entering Sector 1 places the survivor near the Sector 1 train.
- [x] Reversing left in Sector 1 cannot decrement the sector index or resurrect Sector A.
- [x] Full regression suite (Sprint 1–6B) passes 100%.

## Human Playtest Gate
- [x] Launch project, confirm starting sector is Sector A.
- [x] Leave survivor in yard, drive to exit -> confirm departure blocked.
- [x] Board all survivors, drive east past P2 onto the visible main-exit track.
- [x] Confirm the departure dialog lists detached rolling stock and future supply placeholders.
- [x] Choose No -> confirm the train hard-brakes and remains in Sector 0.
- [x] Drive east again and choose Yes -> confirm environment transitions to Sector B.
- [x] Confirm persistent train and crew remain intact on Sector B entry track.
- [x] Confirm the UI clearly reads as Sector 1 rather than a reset of Sector 0.
- [x] Stop and disembark in Sector 1; survivor should appear near the active train.
- [x] Reverse left in Sector 1; the train should stop at the main-line end rather than returning to Sector 0.
- [x] Confirm P2 straight/branch explanation makes the north workshop route understandable.
- [x] Confirm Sector A cannot be revisited.

## Definition of Done
When all 30 automated test scripts pass, Sector 6B UAT guidance is clear, documentation is reconciled, and git history has a focused commit for Sprint 6B.

## Next Possible Increment
Sprint 7 — Scavenging/resources.
