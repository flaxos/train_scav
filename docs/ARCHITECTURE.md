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

## Coupler model — POC

A coupler needs enough state to determine:
- owning rolling-stock unit;
- front/rear endpoint;
- connected coupler or none;
- coupling range/alignment threshold;
- whether coupling is permitted;
- whether a crew action is required.

For Sprint 2, physical interaction may be simplified to automatic coupling when compatible couplers are slowly aligned and the player confirms/commands coupling.

## Train consist model

A consist is an ordered connected chain of rolling stock.

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
