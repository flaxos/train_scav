# Technical Architecture

## Status
Initial architecture intent. Keep replaceable until the POC proves the mechanics.

## Baseline
- Engine: Godot 4.x.
- Known local baseline at project planning time: Godot 4.4.1 stable.
- Language: GDScript unless a measured reason emerges for another language.
- Rendering: 2D.
- Target initially: desktop development build.

Do not upgrade the engine during a sprint unless the upgrade is explicitly made part of that sprint.

## Architecture goals
1. Persistent train/run state must survive disposable sector replacement.
2. Railway movement must be deterministic and debuggable enough for shunting gameplay.
3. Train consist operations must not depend on UI state.
4. People and carriage simulation should be separable from world generation.
5. Procedural sector generation should be introduced only after hand-authored railway operation works.
6. Systems should remain replaceable while prototyping.

## Proposed domain boundaries

```text
RUN / GAME STATE
├── current seed / progress
├── persistent train
├── persistent survivors
├── inventory/resources
└── run journal

TRAIN
├── consist
├── locomotive(s)
├── wagons
├── couplers
├── movement command state
└── train-level utilities later

RAIL
├── track segments
├── junctions / points
├── route connectivity
├── occupancy
└── yard infrastructure

COLONY
├── survivors
├── skills
├── needs
├── jobs/tasks
└── pathing through train/local sector

SECTOR
├── local railway layout
├── terrain
├── points of interest
├── local objects
├── local threats later
└── entry / exit boundaries

UI
├── selection
├── train controls
├── status overlays
├── debug information
└── commands
```

## Important ownership rule

**Sector state is disposable. Train/run state is persistent.**

A sector may reference the active train while it is present, but it must not be the authoritative owner of:
- wagon identity;
- survivor identity;
- persistent inventory;
- locomotive condition;
- run progression.

When a sector is destroyed, the train must remain valid.

## Suggested Godot organisation

Exact names may change after implementation learning.

```text
res://
├── scenes/
│   ├── bootstrap/
│   ├── rail/
│   ├── train/
│   ├── colony/
│   ├── sector/
│   └── ui/
├── scripts/
│   ├── rail/
│   ├── train/
│   ├── colony/
│   ├── sector/
│   ├── run/
│   └── debug/
├── resources/
│   ├── rolling_stock/
│   ├── survivors/
│   └── sectors/
├── assets/
│   ├── prototype/
│   ├── generated/
│   └── authored/
└── tests/
```

Do not create every directory up front if unused. Structure should follow working code.

## Rail representation — initial direction

The first POC should prioritise reliable track-following over realistic wheel/rail physics.

Likely representation:
- explicit track graph;
- track segments with ordered geometry/curves;
- junction/points nodes connecting valid segment exits;
- vehicles track a rail position plus direction;
- movement advances along the graph;
- points determine which outgoing path is active;
- consists derive wagon placement from coupler distances along connected rail paths.

Avoid unconstrained rigid-body train physics as the authoritative movement model in the first POC. It is likely to create instability and consume the project.

Visual/secondary physics effects can be added later if needed.

Rail rendering must consume rail-space transform data from the rail model. Each rolling-stock unit derives its visual position and rotation from its own segment/distance and the local tangent sampled at that point. A consist spanning a switch may therefore render different vehicles at different angles; it must not apply one global consist or locomotive rotation to every vehicle.

## Coupler model — POC

A coupler needs enough state to determine:
- owning rolling-stock unit;
- front/rear endpoint;
- connected coupler or none;
- coupling range/alignment threshold;
- whether coupling is permitted;
- whether a crew action is required.

For Sprint 2, physical interaction may be simplified to automatic coupling when compatible couplers are slowly aligned and the player confirms/commands coupling.

Sprint 2 coupling candidates are created only by deterministic rail-space contact between exposed coupler endpoints. The contact event records the active consist endpoint, the target consist endpoint, rail segment/path, relative speed and whether coupling is permitted. Coupling must use that endpoint pair to derive the new physical consist order. It must not scan for any nearby detached wagon and append it to the active consist.

Rolling stock contact is based on occupied intervals along the current rail segment/path. Vehicles on different switch branches or parallel/crossing rendered geometry are not considered in contact merely because their 2D drawings are close or overlapping.

## Train consist model

A consist is an ordered connected chain of rolling stock.

Physical consist order, rolling-stock identity and traction/control authority are separate concepts. A wagon at the front of the physical order remains a wagon, and the controlled locomotive remains the locomotive entity identified by the simulation. Sprint 2 uses one controlled locomotive, `L`; later multi-locomotive gameplay must extend this explicitly rather than inferring authority from `consist[0]`, `consist.back()` or travel direction.

Sprint 2 exposes simple rear and front outer-end decoupling commands. A split keeps the active controlled consist as the physical segment containing `controlled_locomotive_id`; commands that would detach the controlled locomotive or leave a wagon as the active powered unit are rejected.

Required operations eventually include:
- inspect ordered units;
- split at a coupler;
- join two compatible consists;
- determine active locomotive(s);
- calculate basic total mass;
- identify direction/front/rear.

Do not assume the locomotive is always the first physical unit forever.

## Character movement

Later prototype requirement:
- navigate inside a carriage;
- pass through valid inter-car doors between connected wagons;
- leave/board train when stopped and an access point is usable;
- navigate to local rail infrastructure.

Do not build deep character AI before rail operation is proven.

Sprint 3 introduces a deliberately small crew simulation. Survivors have persistent identity, a spatial state of aboard or yard, a current position, selection state and one active task. Aboard survivor transforms are derived from the host rolling-stock draw transform, so a person aboard a moving or rotating wagon follows that wagon instead of floating in world space.

Crew tasks are an orchestration layer over authoritative domain systems. A survivor task validates and reserves a physical target, moves the survivor to an explicit interaction anchor, waits through a short interaction and then calls the rail-domain API. Crew code must not splice consist arrays, change switch visuals independently or infer locomotive/control authority.

Railway interactions expose physical anchors: the points operator anchor and exact coupled-joint anchors. Uncoupling tasks target an existing ordered joint such as `A/B`; the rail model performs the split and keeps the active controlled consist on the segment containing `controlled_locomotive_id`.

## Railway operations systems

Sprint 4 adds a small yard-operations domain around the existing rail and crew domains.

Mechanical railway state and remote-control state are independent:
- a point may be mechanically operational but local-only while yard control is offline;
- remote commands require repaired yard control, connected power, remote-capable point hardware and an unoccupied switch zone when that feature is promoted;
- power connection/loss changes remote capability but does not directly mutate physical routes.

Current Sprint 4 UAT keeps P1/P2 local-only. Yard control and auxiliary power can be repaired/connected as infrastructure state, but remote point route changes are rejected and do not mutate rail routes. Future restored automation must still call the rail-domain point authority and retain occupancy safety.

Multiple powered units may exist in one sector. Sprint 4 still supports only one independently controlled powered consist at a time. Control selection is explicit through `controlled_power_unit_id`; switching control between the main locomotive `L` and repaired shunter `S` never changes rolling-stock identity or physical consist order. Wagon-only consists remain passive and cannot become powered through array position.

Playable powered control also requires crew presence. The selected powered unit can receive player throttle only when at least one survivor is aboard that locomotive/shunter; repairing a shunter is not enough by itself to make it drivable.

Yard repair, power, coupling and uncoupling tasks remain crew orchestration. A survivor reserves an explicit anchor, walks there, interacts briefly and then calls the relevant yard or rail operation. Crew code does not splice consists, couple by visual proximity, repair rolling stock by visual proximity or change point graphics independently.

Sprint 4 strategy success is state-based. The workshop wagon `W` is recovered only when it is physically reached and coupled through the existing rail/contact system; there are no strategy flags such as manual/shunter success.

## Task/job model

Use a distinction between:
- **job/role:** persistent priority assignment such as Engineer;
- **task:** concrete action such as Operate Points 03 or Repair Cooling Pump.

An automation layer can create tasks from world conditions and roles.

## Procedural generation

Deferred until sector lifecycle sprint.

When introduced:
- deterministic seed;
- generate rail topology first;
- decorate with environment/POIs second;
- validate connected entry→exit route;
- validate physically usable railway geometry;
- preserve safe minimums for train dimensions.

The procedural generator must never create a sector with no legal continuation unless intentionally representing a run-ending/event scenario.

## Save model

Do not implement full save/load during the earliest POC unless needed for iteration.

Long-term save should primarily serialise:
- run seed/history;
- train rolling stock and state;
- survivors and state;
- inventory/resources;
- progression/settings;
- current sector seed/state only if saving mid-sector is supported.

Previous sectors do not require simulation persistence.

## Debug tooling

Useful prototype debug surfaces:
- current track segment and distance;
- movement direction;
- active points state;
- consist unit order;
- coupler connections;
- total consist mass;
- selected vehicle/crew;
- current tasks;
- sector entry/exit state.

Readable debug overlays are preferable to guessing at invisible simulation state.
