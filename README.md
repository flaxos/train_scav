# Train Scav

Top-down 2D Godot train-survival colony prototype.

## Active Sprint

Sprint 1: Train Moves on Rails.

This sprint validates a single locomotive moving on hand-authored rail geometry with one siding and one switch.

## Play

Launch the project:

```bash
/home/flax/bin/godot --path .
```

Controls:

- `W` / `Up`: increase throttle
- `S` / `Down`: decrease throttle
- `Space`: brake
- `R`: reverse direction while stopped
- `E`: change points/switch

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

If resource imports need to be refreshed explicitly, run:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --import
```
