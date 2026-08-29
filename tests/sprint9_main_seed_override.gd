extends SceneTree

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9 Main Seed Override Tests ---")
	await _main_scene_uses_uat_seed_environment_override()
	_finish()


func _main_scene_uses_uat_seed_environment_override() -> void:
	var previous_value := OS.get_environment(ENV_RUN_SEED)
	OS.set_environment(ENV_RUN_SEED, "6001")

	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads")
	if packed_scene == null:
		_restore_env(previous_value)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.lifecycle != null, "normal Main scene creates sector lifecycle")
	if scene.lifecycle != null:
		_expect(int(scene.lifecycle.run_state.run_seed) == 6001, "Main scene honours TRAIN_SCAV_RUN_SEED for UAT fresh runs")
		var visual_state: Dictionary = scene.get_sector_visual_state()
		_expect(int(visual_state.get("run_seed", 0)) == 6001, "sector debug state reports overridden run seed")

	scene.queue_free()
	await process_frame
	await process_frame
	_restore_env(previous_value)


func _restore_env(previous_value: String) -> void:
	if previous_value.is_empty():
		OS.unset_environment(ENV_RUN_SEED)
	else:
		OS.set_environment(ENV_RUN_SEED, previous_value)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9 Main seed override acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9 Main seed override acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
