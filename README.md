# Train Scav

Top-down 2D Godot train-survival colony prototype.

## Active Sprint

Sprint 6B: Sector Clarity Stabilisation — complete after human UAT.

Sprint 6B stabilises the disposable-sector lifecycle before Sprint 7 scavenging/resources. Sector 0 still contains the current railway-operations yard, but crossing the exit boundary should now read clearly as entering Sector 1 rather than resetting the same scene.

The UAT scene keeps state/debug text in a right-side panel rather than over the railway playfield. Normal object operations are mouse-first: right-click the intended ground/object/anchor, then left-click a menu option to confirm. P2 is the workshop route point; P1 and damaged P3 remain available as diagnostics. P2 starts straight, which blocks the north workshop branch until a survivor operates it.

The playable scene includes an in-game Sprint 6B UAT guide in the side panel. Follow the checklist top to bottom while testing the demo slice. Interaction anchors use simple prototype icons: switch levers for points, a wrench for repair targets, a power bolt for the yard power connection and a coupler/joint icon for uncoupling. Visual yard branches connect to the modeled rail or end at buffer stops so the map reads as a railyard rather than loose decorative track strokes.

Sector lifecycle note: after all survivors are aboard, drive east past P2 onto the visible main-exit track. The scene now hard-brakes and asks for confirmation before disposing the sector, including a summary of rolling stock left behind and placeholders for future supplies. Choosing No stops before the boundary and keeps the current sector; choosing Yes disposes Sector 0 and enters Sector 1. Reversing left in Sector 1 must stop at the main-line end; it must not return to Sector 0. Disembarking in Sector 1 should place survivors beside the active Sector 1 train.

Shunter note: `S` starts damaged on the north workshop siding near the workshop wagon `W`. Repair `S`, board a survivor onto it, then explicitly select it as the controlled powered unit. Once repaired and crewed, it can move on that siding and can reverse back through the P2 connection toward the main line if the route is set.

## Play

Launch the project:

```bash
/home/flax/bin/godot --path .
```

Controls:

- left click survivor: select survivor
- right click ground/object/anchor: open options
- left click menu item: confirm the selected option
- `W` / `Up`: increase throttle
- `S` / `Down`: decrease throttle
- `Space`: brake and cut throttle
- `R`: reverse direction while stopped
- context options include move, board/disembark, operate points, uncouple exact joints, crew coupling at valid contact, repair shunter, repair yard control, connect power and explicit powered-unit control
- `1`-`5`: optional survivor selection shortcuts
- `C`: optional shortcut to assign crew coupling for the current contacted compatible endpoints at low speed
- Developer/debug shortcuts: `D` leave train, `B` board, `P/O` local point tasks, `U` exact A/B uncouple, `G/H/J/K` repair/power tasks, `Y/T` rejected remote point attempts, `X` crew-gated powered control, `E` crew P1 operation, `Q/F` guidance to use the exact right-click joint menu

For coupling approaches, keep the consist at shunting speed, then use the context menu so a survivor walks to the contact anchor and couples. The debug panel reports rail state, explicit powered control, driver availability, yard control/power state, point state and selected survivor/task state.

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
