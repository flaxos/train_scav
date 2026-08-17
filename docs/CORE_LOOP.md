# Core Gameplay Loop

## Primary loop

```text
TRAVEL
  ↓
DISCOVER
  ↓
DECIDE: PASS OR STOP
  ↓
SECURE / REPAIR / EXPLORE
  ↓
SALVAGE RESOURCES / PEOPLE / ROLLING STOCK
  ↓
SHUNT / RECONFIGURE / REPAIR TRAIN
  ↓
ASSIGN CREW / RECOVER COMMUNITY
  ↓
DEPART
  ↓
PERMANENTLY DISCARD SECTOR
  ↓
NEXT SECTOR
```

The loop succeeds when every layer reinforces the others:
- resource pressure creates reasons to stop;
- stopping creates exposure and labour cost;
- exploration reveals resources, information and rolling stock;
- recovered rolling stock alters train capability;
- added mass/length creates new railway constraints;
- better people and equipment increase automation;
- forward-only sectors make every departure consequential.

## Moment-to-moment train loop

While moving:
1. Observe train and route.
2. Monitor fuel, condition and crew.
3. Allow job system to resolve routine tasks.
4. Respond to faults/events.
5. Inspect upcoming rail/sector opportunities.
6. Decide whether to continue or stop.

## Stop/exploration loop

1. Stop and secure train.
2. Inspect local rail layout and points of interest.
3. Assign expedition/engineering personnel.
4. Search, repair, negotiate or later fight.
5. Haul useful resources back to the train.
6. Decide whether remaining opportunities justify more time/risk.

## Shunting loop

1. Identify desired train configuration or salvage target.
2. Inspect physical track constraints.
3. Decide movement method: main locomotive, shunter, human push, restored yard controls, other.
4. Prepare crew and infrastructure.
5. Decouple only where physically possible.
6. Operate points.
7. Move consists at low speed.
8. Couple/reconnect.
9. Verify train integrity.
10. Abandon unwanted rolling stock if necessary.

## Progression loop

Progression should be tangible:
- acquire a better wagon;
- recover a second locomotive;
- restore workshop capacity;
- add radios;
- improve automation;
- recruit a specialist;
- replace inefficient rolling stock;
- become capable of taking routes previously too dangerous/heavy/damaged.

Avoid progression that is only abstract percentage increases when a physical capability can represent it.

## POC hypothesis

> Physically operating a small train through a rail yard, manipulating points and couplers, and recovering/repositioning wagons is satisfying enough to support a larger colony-survival game.

The first POC exists to answer this before procedural generation, deep colony simulation, combat or final art.

## POC playable loop

```text
START WITH [LOCO][A][B]
       ↓
DRIVE TO YARD
       ↓
INSPECT SIDING WITH [C]
       ↓
OPERATE POINTS
       ↓
UNCOUPLE / REVERSE / SHUNT
       ↓
RECOVER [C]
       ↓
REASSEMBLE [LOCO][A][C][B]
       ↓
DRIVE TO EXIT
```

If this is not enjoyable with programmer art, do not add content to hide the problem. Improve or rethink the rail interaction.
