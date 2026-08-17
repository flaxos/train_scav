# Train Scav

Top-down 2D Godot train-survival colony prototype.

## Active Sprint

Sprint 0: Project Skeleton.

This sprint establishes a runnable Godot project and repeatable validation workflow before gameplay systems are implemented.

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

If resource imports need to be refreshed explicitly, run:

```bash
XDG_CONFIG_HOME=/tmp/train_scav_godot/config \
XDG_DATA_HOME=/tmp/train_scav_godot/data \
XDG_CACHE_HOME=/tmp/train_scav_godot/cache \
/home/flax/bin/godot --headless --path . --import
```
