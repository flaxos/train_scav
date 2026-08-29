# Train Scav

Top-down 2D Godot train-survival colony prototype.

## Active Sprint

Sprint 12: Mobility, Burden & Route Requirements — Planning phase.

(Sprint 10 Rolling-Stock Ecosystem and Sprint 11 Procgen Variety Pass are complete and passed human UAT).

Known Sprint 11 generated-sector UAT seeds for sector 2 on the `industrial` route:

- `TRAIN_SCAV_RUN_SEED=6003`: `rural_through`
- `TRAIN_SCAV_RUN_SEED=6012`: `village_passing_station`
- `TRAIN_SCAV_RUN_SEED=6001`: `small_town_goods`
- `TRAIN_SCAV_RUN_SEED=6005`: `agricultural_loading_point`
- `TRAIN_SCAV_RUN_SEED=6004`: `river_valley_constrained`
- `TRAIN_SCAV_RUN_SEED=6008`: `declining_abandoned_branch`

Known Sprint 10 UAT seeds:

- `TRAIN_SCAV_RUN_SEED=6001`, choose the `industrial` route exit: sector 2 is `small_town_goods` with `fuel_tanker` salvage.
- `TRAIN_SCAV_RUN_SEED=6006`, choose the `industrial` route exit: sector 2 is `small_town_goods` with `parts_flatbed` salvage.
- `TRAIN_SCAV_RUN_SEED=6061`, choose the `industrial` route exit: sector 2 is `small_town_goods` with `boxcar_storage` salvage.

The UAT scene keeps state/debug text in a right-side panel rather than over the railway playfield. Normal object operations are mouse-first: right-click the intended ground/object/anchor/POI, then left-click a menu option to confirm. POIs use programmer-art icons and labels; generated procedural POIs use the same search, carry and deposit rules as authored POIs.

On launch, the right-side guide starts with a Sprint 11 Procgen Check that lists the six seeded sector-2 archetype samples. The Sprint 10 rolling-stock preflight remains available through debug/test helpers.

In procedural sectors, the debug panel also prints a `Features:` line for the current archetype, such as bridge/water crossing or display-only abandoned track, so human UAT can confirm why the generated form matters.

In procedural sectors, the debug panel prints `Generated stock:` lines for current-sector generated wagons, including the unit ID, type ID, ownership state and capability summary.

Sector lifecycle note: after all survivors are aboard and the train has enough diesel, drive east past P2 onto the visible main-exit track. The scene hard-brakes and asks for confirmation before disposing the sector, including diesel cost, detached rolling stock and uncollected POI supplies. Choosing No stops before the boundary and keeps the current sector; choosing Yes consumes diesel, disposes Sector 0 and enters Sector 1.

Shunter note: `S` starts damaged on the north workshop siding near the workshop wagon `W`. Repair `S`, board a survivor onto it, then explicitly select it as the controlled powered unit. Once repaired and crewed, it can move on that siding and can reverse back through the P2 connection toward the main line if the route is set.

## Play

Launch the project:

```bash
/home/flax/bin/godot --path .
```

Launch with a specific UAT run seed:

```bash
TRAIN_SCAV_RUN_SEED=6001 /home/flax/bin/godot --path .
```

Skip the authored opening and start normal `Main.tscn` directly in a generated Sprint 11 UAT sector:

```bash
TRAIN_SCAV_RUN_SEED=6005 TRAIN_SCAV_START_SECTOR=2 TRAIN_SCAV_START_ROUTE=industrial /home/flax/bin/godot --path .
```

This debug shortcut is for faster generated-sector inspection, route checks and generated-wagon recovery testing. Omit `TRAIN_SCAV_START_SECTOR` for the full normal-game UAT through the crafted opening.

Controls:

- left click survivor: select survivor
- right click ground/object/anchor: open options
- left click menu item: confirm the selected option
- right click Fuel Depot / Maintenance Shed / Supply Store: search or haul discovered supplies
- `W` / `Up`: increase throttle
- `S` / `Down`: decrease throttle
- `Space`: brake and cut throttle
- `R`: reverse direction while stopped
- context options include move, board/disembark, search POIs, haul supplies, operate points, uncouple exact joints, crew coupling at valid contact, repair shunter, repair yard control, connect power and explicit powered-unit control
- `1`-`5`: optional survivor selection shortcuts
- `C`: optional shortcut to assign crew coupling for the current contacted compatible endpoints at low speed
- Developer/debug shortcuts: `D` leave train, `B` board, `P/O` local point tasks, `U` exact A/B uncouple, `G/H/J/K` repair/power tasks, `Y/T` rejected remote point attempts, `X` crew-gated powered control, `E` crew P1 operation, `Q/F` guidance to use the exact right-click joint menu

For Sprint 11 UAT, use the debug-start command above to inspect the six known sector-2 archetype seeds quickly, then complete at least one normal run through the authored opening into a generated sector. For the Sprint 10 rolling-stock path, seed `6001`, `6006` or `6061` still reaches `small_town_goods` with salvage after the `industrial` route exit.

## Verified Local Toolchain

Checked on 2026-08-17:

- Codex: `/home/flax/.local/bin/codex` (`codex-cli 0.147.0`)
- Git: `/usr/bin/git` (`git version 2.43.0`)
- Godot: `/home/flax/bin/godot` (`4.4.1.stable.official.49a5bc7b6`)

## Validation

Use isolated Godot user/cache directories so validation does not depend on writable home-directory editor settings.

Run the full current suite:

```bash
set -e
for test_file in $(find tests -maxdepth 1 -name '*.gd' | sort); do
  XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
  XDG_DATA_HOME=/tmp/train_scav_godot/data \
  XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
  /home/flax/bin/godot --headless --path . --script "$test_file"
done
```

Validate the project skeleton and launch the configured main scene headlessly:

```bash
test -f project.godot && test -f scenes/bootstrap/Main.tscn && \
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --quit-after 2
```

Run the Sprint 9 scripted UAT rehearsal before human playtest:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint9_scripted_uat_rehearsal.gd
```

This does not replace the required normal-game human UAT.

Run the Sprint 10 rolling-stock acceptance tests:

```bash
for test_file in tests/sprint10_*.gd; do
  XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
  XDG_DATA_HOME=/tmp/train_scav_godot/data \
  XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
  /home/flax/bin/godot --headless --path . --script "$test_file"
done
```

Run the Sprint 11 procgen-variety acceptance test:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint11_procgen_variety.gd
```

Run the Sprint 11 debug-start normal-`Main.tscn` scripted UAT rehearsal:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint11_scripted_uat_rehearsal.gd
```

Run the Sprint 11 normal-game handoff rehearsal from authored Sector 0 into generated Sector 2:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint11_normal_game_uat_rehearsal.gd
```

Run the Sprint 1 acceptance simulation:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint1_acceptance.gd
```

Run the Sprint 1 scene visibility and control checks:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint1_visual_scene.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint1_scene_controls.gd
```

Run the Sprint 2 acceptance simulation:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint2_acceptance.gd
```

Run the Sprint 2 scene control check:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint2_scene_controls.gd
```

Run the Sprint 2 rail contact/collision check:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint2_contact_acceptance.gd
```

Run the Sprint 2 endpoint coupling/topology check:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint2_endpoint_coupling.gd
```

Run the Sprint 2 per-unit orientation and locomotive-authority checks:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint2_orientation_acceptance.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint2_locomotive_authority.gd
```

Run the Sprint 3 rail and crew checks:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint3_rail_interactions.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint3_crew_acceptance.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint3_scene_controls.gd
```

Run the Sprint 4 yard operations checks:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_yard_infrastructure.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_powered_control.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_crew_repair_acceptance.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_strategy_acceptance.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_scene_controls.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_uat_layout.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_context_menu.gd

XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --script tests/sprint4_visual_guidance.gd
```

If resource imports need to be refreshed explicitly, run:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --import
```
