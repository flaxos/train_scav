# Train Scav

Top-down 2D Godot train-survival colony prototype.

## Active Sprint

Sprint 4: Railway Operations Systems.

Sprint 4 validates whether one yard can support multiple systemic salvage solutions. The same workshop wagon `W` can be recovered with manual crew-operated points or by repairing, boarding and using the local shunter `S`. Yard control and train-supplied power are present as repairable infrastructure, but remote point throwing is parked and rejected in the current UAT. Sprint 4 remains human-playtest pending until the GUI scenario is verified.

The UAT scene keeps state/debug text in a right-side panel rather than over the railway playfield. Normal object operations are mouse-first: right-click the intended ground/object/anchor, then left-click a menu option to confirm. P2 is the workshop route point; P1 and damaged P3 remain available as diagnostics.

The playable scene includes an in-game UAT guide in the side panel. Follow the checklist top to bottom while testing the demo slice. Interaction anchors now use simple prototype icons: switch levers for points, a wrench for repair targets, a power bolt for the yard power connection and a coupler/joint icon for uncoupling. Visual yard branches connect to the modeled rail or end at buffer stops so the map reads as a railyard rather than loose decorative track strokes.

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
