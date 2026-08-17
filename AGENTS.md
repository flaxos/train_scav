# AGENTS.md — Train Survival Project

## Mission
Build a top-down 2D Godot train-survival colony game whose defining experience is operating a physical, persistent train through disposable forward-only procedural railway sectors.

The current repository is an incremental game prototype. Prove gameplay before polish.

## Required reading order
Before making gameplay or architecture changes, read:
1. `docs/CURRENT_SPRINT.md`
2. `docs/GAME_DESIGN.md`
3. `docs/CORE_LOOP.md`
4. `docs/ARCHITECTURE.md`
5. `docs/DECISIONS.md`
6. `docs/PARKING_LOT.md`

For complex features or significant refactors, use an ExecPlan following `.agent/PLANS.md`.

## Scope guardrails
- `docs/CURRENT_SPRINT.md` is the active scope contract.
- Do not implement features in `docs/PARKING_LOT.md` unless the user explicitly promotes them into the current sprint.
- If you discover an attractive non-blocking improvement, record it in the parking lot instead of implementing it.
- Do not expand a sprint because a more general solution seems elegant.
- Prefer the smallest implementation that validates the current gameplay hypothesis.
- Do not refactor unrelated working systems while implementing a sprint item.
- Do not add production dependencies, plugins, addons, external services, or SDKs unless required by the current sprint.
- Do not build final art systems before the gameplay they represent has been validated with programmer art.

## Core design invariants
These require an explicit design decision to change:
- The train is the colony and physically exists in the world.
- Railway logistics are gameplay; wagons are not rearranged with drag-and-drop inventory operations.
- The train moves in real time.
- Sectors are forward-only. After the train exits a sector, that sector is discarded and cannot be revisited.
- Rolling stock must be physically coupled, uncoupled, pushed, pulled or shunted using available railway infrastructure.
- People are physical agents who move through carriages and, when stopped, can leave the train to perform work.
- Routine work should become automatable through jobs, roles and improved railway operations rather than requiring permanent micromanagement.
- Permadeath is allowed for survivors.
- Loss of the final viable locomotive / unrecoverable immobilisation is a valid run-ending state.
- Systems should create stories; avoid turning systemic opportunities into rigid scripted quest chains.

## Engineering rules
- Target Godot 4.x. Preserve compatibility with the version recorded in `docs/ARCHITECTURE.md` unless an upgrade is explicitly approved.
- Use typed GDScript for new gameplay code where practical.
- Prefer composition and small focused nodes/resources over deep inheritance hierarchies.
- Keep simulation state separate from presentation where practical.
- Avoid hard-coded references between unrelated systems; use signals/events or explicit service interfaces.
- Keep procedural generation deterministic from a seed once introduced.
- A disposable sector must not own persistent train or survivor state.
- Persistent state belongs to the run/train simulation, not the disposable sector scene.
- Debug tooling is a feature during prototyping. Add simple visible diagnostics when they materially shorten iteration.

## Validation
Every change must include the smallest reasonable validation for its scope.
Before declaring a task complete:
1. Run available automated checks.
2. Launch or headlessly validate the relevant Godot project/scene where possible.
3. Check for parser errors and obvious runtime errors.
4. Report exactly what was tested and what was not tested.
5. Leave the repository in a runnable state.

## Sprint completion rule
A sprint is complete only when its acceptance test in `docs/CURRENT_SPRINT.md` is demonstrably satisfied in a playable build.
Documentation or architecture alone does not complete a gameplay sprint.

## Git discipline
- Inspect `git status` before work.
- Do not overwrite unrelated user changes.
- Make focused changes.
- Prefer a clean checkpoint/commit at meaningful playable milestones.
- Never force-push, rewrite shared history, or delete branches without explicit instruction.

## Working style
- Start by restating the current sprint goal and the specific acceptance criterion you are targeting.
- Inspect existing code before proposing replacements.
- When blocked, identify the smallest blocker and solve only that blocker.
- When multiple approaches work, prefer the one that keeps the prototype easiest to replace later.
- Do not silently broaden scope.
- When you find future ideas, append concise entries to `docs/PARKING_LOT.md`.
