# Current Sprint - Sprint 4: Railway Operations Systems

**Status:** IMPLEMENTED - HUMAN PLAYTEST PENDING

## UAT Stabilisation Notes
Human feedback showed the Sprint 4 systems are promising but the demo needed more readable UAT presentation and stricter physical-operation rules: full debug text covered the playfield, P1/P2 controls made the primary scenario harder to parse than necessary, shunter repair/control was not clear enough, colored-circle anchors were too abstract, the right-side workshop route did not match the intended P2/north-branch puzzle, and some operations still bypassed crew presence.

The playable UAT flow now uses a focused side panel, a simpler primary route, semantic prototype icons, a gentler workshop siding and a mouse-first interaction menu:
- right-click ground/object/anchor to open available actions;
- left-click a menu item to confirm;
- P2 is the primary workshop route point;
- `S` starts damaged on the workshop siding and must be repaired before explicit powered control can select it;
- interaction anchors use basic icons for switches, repair, power and coupled joints instead of anonymous colored circles;
- tracks render as prototype railway, with sleepers and two rails rather than relying only on colored route strokes;
- P1 and P2 show explicit labels for the controlling switch, straight path, branch path and active route;
- P2's operator anchor sits beside the actual workshop turnout and controls access to that siding in both directions;
- P2 now controls the visible north workshop branch; the confusing duplicate north scenery track was removed;
- valid shunter/wagon contact exposes a mouse menu action naming the contacted units and coupler endpoints;
- coupling and uncoupling in the playable scene are crew tasks at physical anchors, not instant consist-array shortcuts;
- powered control requires a survivor aboard the selected locomotive/shunter;
- remote point switching is parked for later and rejected in the current UAT;
- the workshop siding has been widened and smoothed so the track path reads as a railway turnout rather than an abrupt bend;
- visual-only yard branches now connect to modeled rail and end with buffer stops rather than floating as loose disconnected strokes;
- task target connector lines are shown only for active tasks, so completed/idle survivors do not leave confusing lines across the yard;
- a step-by-step UAT guide is visible in the game and advances from live scene state;
- P1 and P3 remain available as secondary diagnostics so every system is still testable without making the main recovery route more complicated.

## Sprint Objective
Build a hand-authored railway yard where the same workshop/salvage wagon can be recovered through materially different systemic railway operations rather than scripted strategy branches.

## Hypothesis
Multiple interacting railway systems make yards interesting rather than repetitive when the player can combine:
- physical rail infrastructure;
- crew labour;
- a repaired local shunter;
- train-supplied yard power;
- manual point operation and repaired yard infrastructure state.

## In Scope
- One hand-authored Sprint 4 yard layered on the existing prototype scene.
- Player train `[L][A][B]`.
- Workshop salvage wagon `W`.
- Damaged local shunter `S`.
- Multiple visible points and sidings.
- P1 and P2 as route-relevant point systems.
- P3 as a damaged repairable point for infrastructure-state validation.
- Yard-control facility with repaired/powered infrastructure state; remote point throwing is deliberately unavailable in this UAT.
- Abstract train auxiliary power connection.
- Crew tasks for shunter repair, yard-control repair, power connection, damaged-point repair, local point operation and contact-based coupling/uncoupling.
- Explicit powered-unit control selection between `L` and repaired `S`.
- Automated tests proving manual and shunter paths recover the same salvage target through rail movement and coupling.

## Out of Scope
Do NOT implement:
- survivor skills, roles, progression or automatic work assignment;
- repair-part inventory, fuel economy or resource costs;
- detailed electrical simulation, cable physics or power-grid load;
- multiple locomotives powering one consist, MU control or distributed traction;
- signals, realistic signalling rules or automatic shunting;
- derailment physics, detailed crash animation or destruction;
- procedural yards/sectors;
- colony needs, hauling, crafting, combat, save/load, final art or audio.

## Acceptance Test
Sprint 4 is complete only when automated checks pass and the human playtest gate below is confirmed in the Godot window.

- [x] The playable scene contains the main train.
- [x] The playable scene contains workshop/salvage wagon `W`.
- [x] The playable scene contains damaged powered shunter `S`.
- [x] Multiple points are represented: P1, P2 and P3.
- [x] Multiple sidings/yard tracks are visible, including the workshop siding.
- [x] Point mechanical state and remote-control availability are separate; current UAT points remain local-only.
- [x] A mechanically operational point can be operated manually while yard control is offline.
- [x] A damaged point cannot move until repaired.
- [x] Occupied points reject unsafe manual changes; remote commands reject without mutating routes.
- [x] Yard control can be repaired and powered, but remote switch operation remains unavailable in this UAT.
- [x] Power connection/loss does not directly mutate physical point routes.
- [x] Shunter `S` has persistent powered rolling-stock identity.
- [x] Wagon `W` cannot become a locomotive or powered control target.
- [x] Control can explicitly transfer `L -> S -> L` after shunter repair.
- [x] Only the selected powered consist responds to throttle.
- [x] The selected powered consist responds to throttle only when a survivor is aboard that powered unit.
- [x] Parked powered/passive consists remain stationary.
- [x] Crew repair tasks do not execute before survivor arrival and interaction.
- [x] Crew repair tasks reserve targets and reject conflicting duplicate assignments.
- [x] Manual path can recover `W` with the main locomotive and locally operated points.
- [x] Shunter path can repair/select `S` and recover the same `W`.
- [x] Yard-control repair/power is stateful infrastructure and does not script or remotely complete recovery.
- [x] The tested strategies use shared rail, yard, crew and rolling-stock state rather than strategy flags.
- [x] Debug/state text is contained in a side UI panel instead of covering the playfield.
- [x] The playable UAT route presents P2 as the primary workshop point while preserving P1/P3 diagnostic coverage.
- [x] Normal Sprint 4 object operations are exposed through a right-click context menu instead of requiring a long list of letter keys.
- [x] The shunter setup explains that `S` starts damaged on the workshop siding and must be repaired before powered control.
- [x] Interaction anchors have readable prototype icons for point operation, repair, power and uncoupling.
- [x] Track rendering uses sleepers and paired rails so each route reads as physical railway.
- [x] P1/P2 route labels make the straight path, branch path and active route explicit.
- [x] P2's visible switch/operator anchor is placed at the workshop branch it controls.
- [x] P2 branch state gates train and shunter movement between the main and workshop siding.
- [x] P2 controls the visible north workshop branch and the duplicate decorative north branch has been removed.
- [x] Mouse coupling actions identify the contacted units/endpoints, including shunter-to-workshop-wagon contact.
- [x] Mouse coupling actions assign a survivor task and execute only after the survivor reaches the contact anchor.
- [x] The workshop siding uses a wider, gentler hand-authored rail path.
- [x] Decorative yard sidings connect to modeled rail or visibly terminate at buffer stops.
- [x] Completed/idle crew tasks no longer draw stale target connector lines across the playfield.
- [x] The playable scene contains an in-game step-by-step UAT guide wired to live scene state.
- [x] Existing Sprint 1 movement behavior remains covered.
- [x] Existing Sprint 2 contact, coupling, orientation and locomotive-authority behavior remains covered.
- [x] Existing Sprint 3 crew movement, task lifecycle, reservations and uncoupling behavior remains covered.

## Human Playtest Gate
Sprint 4 remains pending until a human confirms in the Godot GUI:

- [ ] The yard is understandable at a glance.
- [ ] Debug/state text fits cleanly in the side panel and does not obscure the railway.
- [ ] Right-click menus make point, repair, power, uncouple, coupling and powered-control actions discoverable.
- [ ] The shunter starting state/path is understandable without guessing keyboard shortcuts.
- [ ] Shunter/main-locomotive movement cannot pass through the other powered unit.
- [ ] A survivor must be aboard `L` or `S` before that powered unit can be driven.
- [ ] Coupling and uncoupling require a survivor task at the physical contact/joint anchor.
- [ ] Prototype icons make switches, power, repairs and coupled joints identifiable without reading source code.
- [ ] Track visuals read as rail tracks with sleepers and paired rails, not just colored debug lines.
- [ ] P1/P2 labels make it obvious which switch controls which straight/branch route.
- [ ] P2 is visually located at the workshop turnout and clearly controls access to that branch.
- [ ] Right-click coupling after S/W contact exposes the shunter/workshop-wagon endpoint pair without needing the `C` shortcut.
- [ ] The redesigned workshop siding reads as plausible railway geometry.
- [ ] Visual yard branches read as connected sidings or buffered track ends, not disconnected decorative strokes.
- [ ] Task target lines do not distract from the railyard once the task is complete.
- [ ] The in-game UAT guide gives enough step-by-step direction to test the demo slice without separate notes.
- [ ] The main train, shunter `S`, salvage wagon `W`, track and points are visibly distinct.
- [ ] Manual point operation still requires a survivor task and physical movement.
- [ ] Repair tasks visibly require a survivor to walk to the target anchor.
- [ ] Shunter `S` is visibly and semantically a powered unit after repair.
- [ ] Switching control between `L` and `S` is explicit and deterministic.
- [ ] Wagons never become locomotives.
- [ ] Yard control can be repaired.
- [ ] Train-supplied power activates yard control only after connection.
- [ ] Remote P1/P2 operation is unavailable/rejected in this UAT and does not mutate track routes.
- [ ] Occupied points remain protected.
- [ ] At least two different strategies recover the same `W` salvage wagon.
- [ ] The strategies do not rely on a scripted mission branch.
- [ ] Crew interaction improves the operation rather than creating excessive waiting.

## Human Test Sequences

### Strategy A - Manual Main-Locomotive Recovery
1. Start fresh.
2. Ignore shunter repair and yard control.
3. Select a survivor.
4. Right-click ground near the train or use the survivor menu to move/disembark if needed.
5. Right-click P2 and choose `Operate P2`.
6. Drive the main locomotive slowly through the selected route.
7. Contact the same workshop wagon `W` at shunting speed.
8. Right-click `W`/the coupling anchor and choose the `Couple ...` endpoint action so a survivor performs the coupling task.
9. Reposition `W` into the intended departing consist.

### Strategy B - Repaired Shunter Recovery
1. Start fresh.
2. Select a survivor.
3. Right-click the shunter/repair anchor and choose `Repair shunter S`.
4. Wait for the survivor to reach the shunter repair anchor and complete repair.
5. Move a survivor to `S` and choose `Board shunter S`.
6. Right-click repaired `S` and choose `Control shunter S`.
7. Drive `S` at shunting speed toward `W`; reverse through the P2 connection if taking it back toward the main line.
8. Contact `W` and choose the `Couple S ... / W ...` endpoint action from the context menu.
9. Verify `L` remained a locomotive and no wagon became powered control.

### Yard-Control/Power Diagnostic
1. Start fresh.
2. Select a survivor and right-click the yard-control cabinet, then choose `Repair yard control`.
3. Select a survivor and right-click the power anchor, then choose `Connect train power`.
4. Verify repaired/powered yard control is represented as infrastructure state.
5. Verify remote P1/P2 commands are unavailable/rejected and do not change routes.

### Secondary Diagnostics
These actions are retained in the right-click menu and keyboard shortcuts to test each element without making the primary demo route heavier:
- crew-operated P1;
- repair damaged P3;
- crew uncouples the exact `A/B` joint.

## Developer Shortcuts
Keyboard shortcuts remain only as diagnostics around the mouse-first flow:
- `E`: assigns the selected survivor to operate P1;
- `Q`/`F`: show guidance to use the exact right-click joint menu instead of mutating consist order;
- `C`: assigns the selected survivor to couple the current valid contact, if any.

Normal Sprint 4 human testing should use the right-click menu for crew tasks, local point operation, repairs, exact uncoupling, crew coupling and explicit powered-control selection.

## Definition of Done
Do not mark Sprint 4 complete from automated tests alone. The sprint is complete only after the human playtest gate confirms the yard is understandable and at least two materially different strategies recover the same salvage target.

## Next Sprint
Do not begin Sprint 5 until Sprint 4 passes the human playtest gate.
