extends SceneTree

const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Procedural UAT Start Tests ---")
	await _normal_main_scene_can_start_directly_in_generated_goods_sector()
	_finish()


func _normal_main_scene_can_start_directly_in_generated_goods_sector() -> void:
	var previous_env := _capture_env([ENV_RUN_SEED, ENV_START_SECTOR, ENV_START_ROUTE])
	OS.set_environment(ENV_RUN_SEED, "6006")
	OS.set_environment(ENV_START_SECTOR, "2")
	OS.set_environment(ENV_START_ROUTE, "industrial")

	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads")
	if packed_scene == null:
		_restore_env(previous_env)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.lifecycle != null, "normal Main scene creates sector lifecycle")
	if scene.lifecycle != null:
		_expect(int(scene.lifecycle.run_state.run_seed) == 6006, "debug start preserves requested run seed")
		_expect(int(scene.lifecycle.run_state.sector_index) == 2, "debug start enters requested generated sector index")
		_expect(scene.lifecycle.can_depart(), "generated-sector debug start has no authored opening blockers")

	var visual_state: Dictionary = scene.get_sector_visual_state()
	_expect(str(visual_state.get("source_type", "")) == SectorDefinition.SOURCE_PROCEDURAL, "debug start uses a procedural sector")
	_expect(str(visual_state.get("archetype_id", "")) == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, "debug start reaches the known goods-sector UAT sample")

	var unit_id := "sector_002_salvage_01"
	_expect(str(scene.rail.get_unit_type_id(unit_id)) == "parts_flatbed", "seed 6006 debug start exposes parts flatbed salvage")
	_expect(not scene.rail.get_active_consist_ids().has(unit_id), "debug-start salvage is discovered but not owned")
	_expect(_detached_consists_include(scene.rail.detached_consists as Array, unit_id), "debug-start salvage starts detached and physically recoverable")

	var joined_debug := "\n".join(scene.get_compact_debug_lines())
	_expect(joined_debug.contains("Generated stock:"), "debug panel reports generated stock after debug start")
	_expect(joined_debug.contains(unit_id), "debug panel reports generated stock unit ID after debug start")
	_expect(joined_debug.contains("parts_flatbed"), "debug panel reports generated stock type after debug start")

	scene.queue_free()
	await process_frame
	await process_frame
	_restore_env(previous_env)


func _detached_consists_include(detached_consists: Array, unit_id: String) -> bool:
	for raw_consist in detached_consists:
		var consist := raw_consist as Dictionary
		var units := consist.get("units", []) as Array
		if units.has(unit_id):
			return true
	return false


func _capture_env(names: Array[String]) -> Dictionary:
	var captured: Dictionary = {}
	for env_name in names:
		captured[env_name] = OS.get_environment(env_name)
	return captured


func _restore_env(previous_env: Dictionary) -> void:
	for raw_env_name in previous_env.keys():
		var env_name := str(raw_env_name)
		var previous_value := str(previous_env[env_name])
		if previous_value.is_empty():
			OS.unset_environment(env_name)
		else:
			OS.set_environment(env_name, previous_value)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 procedural UAT start acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 procedural UAT start FAILED with %d failure(s)" % _failures)
		quit(1)
