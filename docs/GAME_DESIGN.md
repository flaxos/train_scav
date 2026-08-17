# Game Design — Train Survival Project

**Status:** Living design document  
**Working title:** TBD  
**Engine:** Godot 4.x  
**Format:** Top-down 2D colony / railway operations / survival game  
**Primary setting:** Slightly future, post-collapse Europe  

## 1. High concept

The player leads a community that survives aboard a moving train after a civilisation-scale collapse. The train is simultaneously the settlement, shelter, transport system, storage, industrial base and most important survival asset.

The player travels through a large procedurally generated railway world, but the world is experienced as a sequence of **forward-only sectors**. Railway lines cross towns, cities, farms, rivers, industrial districts, stations, depots, bridges and tunnels. The player may stop to explore, scavenge, repair infrastructure, recruit survivors, defend the community, salvage rolling stock and physically reconfigure the train.

The core fantasy is:

> Build and operate a mobile civilisation that must physically navigate a collapsing railway world.

The game should repeatedly make the player ask:
- What is ahead?
- Is it worth stopping?
- Can the train survive the route?
- What does the community need?
- Is this wagon worth carrying?
- How do I physically recover or reposition it?

## 2. Design pillars

### 2.1 The train is the colony
The train is not an abstract base-management screen. It exists physically in the world. Carriages contain rooms, equipment, survivors and resources. Survivors physically move through connected rolling stock.

### 2.2 Railway logistics are gameplay
Rolling stock cannot be rearranged by dragging cards in a menu. Carriages are physically coupled and decoupled. Reconfiguration requires appropriate track geometry, points/switches, siding capacity, locomotive access, crew and sometimes repaired infrastructure.

### 2.3 Forward only
When the train exits a sector, that sector is gone permanently. The player cannot reverse into previous sectors or return later.

This creates:
- meaningful stop/leave decisions;
- urgency around unexplored opportunities;
- clean procedural scaling;
- minimal world persistence requirements;
- a strong thematic feeling that the community is always moving forward.

### 2.4 People matter
Survivors have persistent identities, skills, health, needs, roles and eventually lightweight relationships and traits. Losing a skilled survivor should matter mechanically and narratively.

### 2.5 Systems create stories
Prefer systemic situations over scripted quest chains.

Example:
> The engineer is injured, the local points are jammed, diesel is low, and a usable tanker is trapped behind a scrap wagon.

The game should give the player tools and let a story emerge from the solution.

## 3. Player activity layers

### 3.1 Railway / sector layer
The train physically moves through a top-down world in real time. The sector contains rail geometry and surrounding areas worth exploring.

Typical sector content:
- main line;
- junctions;
- stations;
- sidings;
- freight yards;
- depots;
- abandoned rolling stock;
- towns and suburbs;
- farms;
- factories and warehouses;
- rivers and bridges;
- tunnels;
- damaged infrastructure;
- human activity or threats.

### 3.2 Train / colony layer
The player can zoom into carriages while the train is moving or stopped.

Survivors:
- sleep;
- eat;
- work;
- repair;
- haul;
- treat injuries;
- operate equipment;
- move between connected cars.

Example carriage roles:
- locomotive;
- bunk/passenger;
- storage;
- kitchen;
- workshop;
- medical;
- generator/power;
- fuel tanker;
- greenhouse;
- armour/defence;
- utility/maintenance.

Only a small initial set is required for the prototype.

### 3.3 Expedition layer
When stopped, survivors may leave the train and explore local areas.

Early expedition interactions should favour click-to-command behaviour rather than direct-action shooter controls:
- move;
- search;
- repair;
- haul;
- interact;
- engage hostile target;
- take cover / retreat later if combat warrants it.

Routine expeditions may become increasingly automated later. Important or dangerous encounters may remain directly commanded.

## 4. Core train operation

### 4.1 Movement
The train travels in real time.

Normal travel should be command-oriented rather than a full cab simulator. Shunting should expose more precise low-speed controls.

Potential controls:
- forward / neutral / reverse;
- throttle;
- brake;
- emergency stop;
- points/switch interaction;
- coupling/uncoupling commands.

### 4.2 Consist
The order of rolling stock matters physically and strategically.

Potential consequences of wagon order:
- crew travel time;
- access to critical equipment;
- defence exposure;
- dangerous cargo placement;
- power/utility routing;
- shunting difficulty;
- operational convenience.

### 4.3 Locomotives
The initial game uses one locomotive. Later, players may acquire additional locomotives for:
- double-heading;
- push-pull operation;
- redundancy;
- heavy consists;
- gradients;
- shunting.

A run may end if the community becomes irrecoverably immobilised with no viable locomotive or survival path.

## 5. Shunting — defining mechanic

The player should see abandoned rolling stock and think:

> I want that. How do I physically get it onto my train?

Shunting should be a systemic logistics problem, not a scripted puzzle with one solution.

### 5.1 Required physical actions
Depending on the yard and solution:
- stop and secure the train;
- inspect track layout;
- operate or repair points;
- walk crew to manual infrastructure;
- decouple a portion of the consist;
- move the locomotive or a shunter;
- push/pull wagons;
- reposition blocking rolling stock;
- recover desired wagon;
- reconnect the consist;
- abandon unwanted or damaged stock;
- depart before conditions worsen.

### 5.2 Ways to move rolling stock
Planned systemic options:
1. Main locomotive.
2. Secondary locomotive or local shunter.
3. Human-powered movement for suitably light/empty stock over short distances.
4. Restored powered yard infrastructure.
5. Gravity movement as a possible later mechanic.

### 5.3 Manual and powered points
Post-collapse automatic signalling/control systems are commonly offline.

Early game:
- a survivor walks to a points lever;
- operates it manually;
- may need to repair a jammed mechanism.

Improved operation:
- provide power with a portable/train generator;
- electrically repair or bypass the local control system;
- restore remote points control;
- later coordinate via radios/cameras/rail-operations teams.

Progression should often reduce operational friction rather than merely adding percentage bonuses.

### 5.4 Crew coordination
Coupling, uncoupling and manual points require physical personnel at the location.

Early coordination may rely on:
- hand signals;
- whistles;
- visual contact.

Later capability may include:
- handheld radios;
- train intercom;
- remote cameras;
- dedicated rail operations roles;
- partially automated shunting orders.

### 5.5 Train size has natural costs
Avoid arbitrary wagon-slot limits where possible.

Longer/heavier trains incur:
- worse acceleration;
- longer stopping distance;
- higher fuel use;
- more difficult shunting;
- siding/platform length constraints;
- larger crew travel distances;
- bridge/route constraints;
- higher locomotive power requirements.

The player should routinely ask whether a wagon is worth hauling.

### 5.6 Abandonment
A wagon may be abandoned because it is:
- damaged;
- obsolete;
- too heavy;
- low capacity;
- badly insulated;
- tactically dangerous;
- preventing escape.

Emergency abandonment is desirable emergent gameplay: the player may need to leave part of the train behind to survive.

## 6. Colony simulation

### 6.1 Survivor data
Likely survivor properties:
- name;
- health;
- hunger;
- rest;
- warmth/temperature comfort if justified;
- morale;
- current task;
- role/job;
- skills;
- traits later;
- relationships later.

### 6.2 Initial skill families
Potential skills:
- mechanical;
- electrical;
- railway operations;
- medical;
- cooking;
- scavenging;
- combat;
- research/crafting later.

Keep the first implementation much smaller.

### 6.3 Jobs and automation
The player assigns people to roles/stations rather than issuing every routine action.

Example engineering priority:
1. Critical locomotive repair.
2. Restore essential power.
3. Repair critical carriage systems.
4. Routine maintenance.
5. Craft components.

Characters physically perform their assigned work.

Early game is intimate and hands-on. Late game should move toward organisation and automation rather than increased clicking.

## 7. Resource loop

Core candidate resources:
- diesel/fuel;
- food;
- water;
- medical supplies;
- spare parts/materials.

Not all need to exist in the first POC.

Stopping should have opportunity cost so the optimal strategy is not to loot every location. Potential pressures include:
- food consumption;
- generator/fuel use;
- crew fatigue;
- deteriorating weather;
- approaching threats;
- infrastructure condition;
- time-sensitive opportunities.

## 8. Sector model

### 8.1 Disposable procedural sectors
Conceptual lifecycle:

1. Generate/load sector ahead.
2. Train enters physically.
3. Player travels/stops/interacts.
4. Train reaches the exit boundary.
5. Store only run-level/journal information worth keeping.
6. Destroy the sector and its local simulation.
7. Generate/load the next sector.

The persistent train and survivors must survive sector destruction unchanged.

### 8.2 Sector transition presentation
Transitions should feel continuous rather than like selecting a level.

Possible masking environments:
- long tunnel;
- dense forest;
- mountain cutting;
- darkness/weather;
- long rural track.

The exact streaming/loading approach is an implementation detail to validate later.

### 8.3 Sector themes
Possible regional sector types:
- rural;
- urban;
- industrial;
- mountain;
- river;
- severe winter.

Each should ultimately change railway operation, not only visuals.

## 9. Threat and combat direction

Combat is deliberately not part of the initial POC.

Current design direction:
- click-to-engage / lightweight tactical real-time commands;
- possibly tactical pause;
- skills and equipment influence results;
- the strategic decision of whom to risk matters more than aiming skill;
- the train remains physically present during attacks;
- fleeing by getting people aboard and moving the train should be possible.

Combat design remains open and must not delay proving train/railway gameplay.

## 10. Difficulty / world configuration

Rather than only Easy/Medium/Hard, later expose world parameters such as:
- hostility;
- resource abundance;
- infrastructure degradation;
- environmental severity;
- population density.

This should allow experiences ranging from peaceful railway-colony builder to hostile survival scenario.

## 11. Run structure and failure

Survivors may die permanently.

A locomotive being temporarily disabled is a recoverable emergency if repairs, towing or another locomotive remain possible.

A run-ending state should represent loss of a viable survival path, commonly:
- final locomotive destroyed beyond recovery;
- train permanently immobilised;
- community unable to sustain itself with no plausible recovery option.

Avoid arbitrary instant game-over where an interesting recovery scenario exists.

## 12. First 30-minute target experience

The intended opening experience has been defined as:
1. Begin aboard a small train already moving.
2. Inspect physical carriage interiors and survivors.
3. Encounter a simple track obstruction.
4. Stop and send survivors out to clear/inspect it.
5. Search a small station for supplies/information.
6. Learn that leaving the sector is permanent.
7. Depart and manage a basic onboard need/fault.
8. Enter a second industrial/freight sector.
9. Discover a valuable workshop wagon.
10. Repair/operate yard infrastructure.
11. Physically shunt and recover the wagon.
12. Assign a survivor and activate the workshop.
13. Face a route/recruitment/resource decision before departure.

This is a vertical-slice target, not Sprint 1 scope.

## 13. Tone and visual direction

Grounded, slightly future, post-apocalyptic Europe.

Visual goals:
- readable top-down 2D / 3-quarter presentation;
- physical trains and rail geometry;
- carriage cutaways or interiors;
- cold, worn European industrial environment;
- warm inhabited train interiors contrasted with hostile exterior;
- survival engineering rather than fantasy technology.

Programmer art is preferred until mechanics are proven.
