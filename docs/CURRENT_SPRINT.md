# Current Sprint — Sprint 5A: Physical Train Interiors

**Status:** IMPLEMENTED — AUTOMATED TEST + HUMAN PLAYTEST PENDING

## Why 5A is separate
Sprint 5 is intentionally split into small playable increments. Sprint 5A proves the spatial foundation first: survivors must physically belong to carriages and move through the connected train before needs, skills, jobs or automatic work are added.

## Hypothesis
If survivors visibly occupy rolling stock and can walk through physically connected carriages while the train moves, the train starts to read as a mobile colony rather than only a railway consist.

## In scope
- Add a read-only railway topology API exposing which rolling-stock units belong to the same physical consist.
- Add a dedicated train-interior model layered on top of rail authority.
- Prototype carriage identities:
  - `L` — locomotive interior;
  - `A` — bunk/passenger prototype interior;
  - `B` — storage prototype interior;
  - `W` — workshop interior;
  - `S` — boardable shunter cab, but not a through gangway vehicle;
  - `C` — tanker/external vehicle with no boardable interior or walk-through gangway;
  - unknown future stock defaults to non-boardable/non-gangway until explicitly configured.
- Render simple cutaway/programmer-art interiors inside rolling stock.
- Keep survivors hosted by an explicit carriage ID and local carriage-space position.
- Allow survivors to walk longitudinally inside a carriage and cross connected gangway doors into adjacent carriages.
- Model front/rear gangway capability per vehicle end; a coupled joint is walkable only when both facing gangway ends are compatible.
- Render gangway crossing continuously between the two moving carriage door anchors rather than snapping host carriage in one frame.
- Preserve the actual clicked local position inside a carriage as the movement destination.
- Allow onboard movement while the train is moving.
- Revalidate physical consist connectivity every simulation step.
- If a joint is uncoupled during an onboard movement task, the survivor remains in the carriage already reached and the impossible remainder of the task becomes blocked.
- Right-click a connected carriage to issue an explicit `Walk <crew> to <carriage> <interior>` order.
- Preserve Sprint 4.5 captured-actor context-menu semantics.

## Explicitly out of scope
Do NOT add in 5A:
- hunger, rest or health simulation;
- food, parts, diesel or inventory economy;
- skills, roles or professions;
- automatic job assignment;
- maintenance faults;
- hauling/crafting;
- room construction;
- pathfinding through arbitrary 2D rooms;
- save/load;
- final carriage art;
- changes to turnout, collision, coupling or traction mechanics unless a genuine blocker is discovered.

## Automated acceptance
- [ ] Existing Sprint 1–4.5 regression suite remains green.
- [ ] Railway exposes consist membership without colony code mutating rail arrays.
- [ ] `L -> A -> B` is recognised as one connected interior route at the default start.
- [ ] A survivor can walk from `L` through `A` into `B`.
- [ ] The movement remains valid while the train is moving.
- [ ] A/B/W expose locomotive/bunk/storage/workshop prototype interior identities as intended.
- [ ] Tanker `C` cannot be boarded and is not treated as a walk-through passenger gangway.
- [ ] Unknown future rolling stock defaults to non-boardable/non-gangway.
- [ ] Per-end gangway rules allow `L -> A -> B` but prevent fictitious through-corridors through `S`/`C`.
- [ ] Gangway transition movement is spatially continuous without a one-frame door-to-door teleport.
- [ ] Right-clicking a position inside a carriage preserves that local position as the destination.
- [ ] Uncoupling `A/B` prevents a new `L -> B` interior movement order.
- [ ] If A/B is uncoupled after a survivor reaches `A`, that survivor stays in `A` and the route to `B` blocks.
- [ ] Scene exposes visible interior draw states.
- [ ] Right-clicking connected `B` while Marta is aboard the default train offers `Walk Marta to B STORAGE`.
- [ ] The context action assigns onboard movement rather than a yard/disembark movement.

## Human playtest gate
Sprint 5A is complete only when a human confirms in Godot:

- [ ] Rolling stock visibly reads as having a simple interior/cutaway layer rather than survivors floating on coloured rectangles.
- [ ] `L`, `A BUNK`, `B STORAGE`, and `W WORKSHOP` are visually distinguishable enough for prototype UAT.
- [ ] Select/right-click behaviour from Sprint 4.5 remains clear.
- [ ] Selecting a survivor aboard `L`, right-clicking `B`, and choosing `Walk ... to B STORAGE` visibly moves that survivor through `L -> A -> B`.
- [ ] The survivor stays attached to the moving/curving carriage rather than drifting in world space.
- [ ] Movement between cars feels continuous enough for a prototype; no teleport to the destination carriage.
- [ ] Splitting the train at A/B makes B physically inaccessible from L/A.
- [ ] A survivor already on the L/A side of a split does not cross the disconnected joint.
- [ ] Existing yard driving, shunting, points and coupling remain usable.

## Definition of done
When automated tests and the human gate pass, commit/tag Sprint 5A. Sprint 5B may then add minimal needs without changing the railway movement layer or replacing the physical interior topology.

## Next increment
Sprint 5B — **Minimal needs: health, hunger and rest**.
