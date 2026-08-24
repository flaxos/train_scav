# Current Sprint — Sprint 8: First Vertical Slice

**Status:** AUTOMATED IMPLEMENTATION READY — HUMAN PLAYTEST PENDING

## Hypothesis
The systems built in Sprints 1-7 become an actual game when they create one understandable chain of problems, decisions and physical consequences.

Core loop to prove:

DRIVE -> OBSTRUCTION -> STOP -> EXPEDITION -> SEARCH / RETRIEVE -> RETURN -> ONBOARD RESPONSE -> IRREVERSIBLE DEPARTURE -> INDUSTRIAL YARD -> DISCOVER WORKSHOP WAGON -> SHUNT -> PHYSICAL RECOVERY -> ACTIVATE WORKSHOP -> MAKE DECISION -> DEPART WITH UPGRADED TRAIN

Roadmap acceptance:
> A fresh player can complete one meaningful travel -> stop -> explore -> shunt -> upgrade -> depart cycle and understand why the train and its physical configuration matter.

## Baseline Dependencies
Sprint 8 builds on the completed Sprint 1-7 systems:
- deterministic rail-space train movement, points, coupling, uncoupling and contact;
- persistent rolling-stock identity and explicit powered-unit control;
- crew as physical agents with aboard/yard state and task execution;
- carriage interiors and onboard survivor movement;
- survivor needs, roles, skills and simple task assignment;
- sector lifecycle with irreversible departure and persistent train transfer;
- resources, POIs, searching, physical hauling and deposit ownership.

Do not replace these systems with a new mission, quest, train, crew, inventory or sector framework.

## Scenario Structure
The active build should provide one deterministic first-session slice:
1. Start with approximately `[L][A][B]`, crew aboard, limited train resources and no workshop wagon.
2. Drive forward and encounter a clear obstruction/problem.
3. Stop, send crew physically outside, search local POIs and haul useful supplies back to storage.
4. Resolve a small onboard maintenance fault through physical crew work.
5. Depart Sector 0 using the existing irreversible sector lifecycle.
6. Enter an industrial railway sector containing a separate workshop wagon `W`.
7. Use real yard operations, points, crew and shunting to physically recover `W`.
8. Activate `W` through a short crew/work/resource step.
9. Read the route intel and choose the next route by physically driving onto one of three marked exit branches.
10. Depart with the upgraded train, preserving the physically coupled workshop wagon.

## Authority Rules
- **Rail owns** physical movement, topology, rolling stock, consist order, contact, coupling, uncoupling and powered control.
- **Crew owns** survivor position, movement, tasks and carried cargo.
- **Train/colony owns** deposited diesel, food, parts, survivor persistent state and carriage interiors.
- **Sector owns** disposable POIs, obstruction/fault world context and local yard objects.
- **Sector lifecycle owns** irreversible departure, old-sector disposal and persistent transfer.
- **Scenario coordinator may observe and author setup** but must not become a competing gameplay authority.

Critical invariants:
- discovered resource != train-owned resource;
- crew outside = cannot depart;
- discovered wagon != owned wagon;
- owned wagon is not meaningful until physically coupled into the train;
- workshop coupled != workshop online;
- final route decision is physical rail state: the train must occupy a marked exit branch, not select a menu option;
- final consist order must emerge from physical shunting, not UI reordering.

## Explicit Exclusions
Do NOT implement in Sprint 8:
- combat, enemies, weapons, stealth or factions;
- strategic world map or deep recruitment;
- procedural city/yard overhaul;
- detailed inventory, encumbrance, crafting, recipes or workshop production queues;
- technology tree or upgrade tree;
- signalling/dispatch simulation;
- multiple independent player trains;
- major railway physics rewrites;
- weather survival, save/load, final art, audio production or polished onboarding.

## Automated Acceptance
- [x] First-session scenario initialises with the expected train, crew, resources and opening sector problem.
- [x] Workshop wagon `W` is not initially part of the player's train.
- [x] Opening obstruction blocks departure/progress until resolved by a physical crew interaction.
- [x] Sprint 7 scavenging semantics remain intact: search discovers, hauling/deposit transfers ownership.
- [x] Onboard fault creates valid physical work and clears only after task completion.
- [x] Sector 0 departure obeys existing diesel/crew/blocker rules and disposes the old sector.
- [x] Industrial sector loads with a physically separate workshop wagon.
- [x] Only real endpoint coupling makes `W` part of the train consist.
- [x] Workshop activation requires the wagon to be attached, consumes the designed resource cost and completes through crew work.
- [x] Final route branch choice changes real run/next-sector state.
- [x] Workshop wagon persists across the next sector transition.
- [x] All Sprint 1-7 regression tests remain green.
- [x] Headless launch has no parse/compile/runtime script errors.

## Human Playtest Gate
Sprint 8 is not complete until the following is verified in the Godot GUI:
1. Drive the starting train.
2. Encounter the obstruction and stop.
3. Send crew out physically.
4. Search/retrieve/deposit useful supplies.
5. Return crew to the train.
6. Resolve the onboard fault through physical crew work.
7. Depart Sector 0 irreversibly.
8. Enter the industrial sector.
9. Discover workshop wagon `W` as a physical yard vehicle.
10. Use yard operations and shunting to physically couple `W`.
11. Activate the workshop through crew work.
12. Use route intel and drive onto a marked exit branch to make the final route/resource/recruitment-style decision.
13. Depart with `W` still attached and persistent.

## Definition of Done
Sprint 8 is complete only after automated validation passes and the human playtest gate above is accepted by the user.

## Next Possible Increment
Post-vertical-slice features only after Sprint 8 human UAT passes.
