extends SceneTree

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"
const ROUTE_PROFILE := "industrial"
const STATUS_DISPLAY_ONLY := "display_only"

var _failures: int = 0
var _previous_env: Dictionary = {}


func _init() -> void:
	print("\n--- Starting Sprint 11 Scripted UAT Rehearsal ---")
	_previous_env = _capture_env([ENV_RUN_SEED, ENV_START_SECTOR, ENV_START_ROUTE])
	await _agricultural_loading_point_uat()
	await _river_valley_uat()
	await _declining_branch_uat()
	_restore_env(_previous_env)
	_finish()


func _agricultural_loading_point_uat() -> void:
	var scene := await _start_debug_scene(6005, "agricultural_loading_point")
	if scene == null:
		return
	_expect(_debug_contains(scene, "Features:"), "agricultural UAT debug panel exposes generated feature summary")
	_expect(_debug_contains(scene, "agricultural loading"), "agricultural UAT debug panel names loading feature")
	_expect(_route_reaches_exit(scene, "main"), "agricultural UAT main route reaches exit in normal Main scene")
	_expect(_route_reaches_stub_and_reverses(scene, "grain_loading", "grain_loading", "main_west"), "agricultural UAT grain loading route is reachable and reversible")
	_expect(_route_reaches_stub_and_reverses(scene, "headshunt", "short_runaround", "main_west"), "agricultural UAT headshunt route is reachable and reversible")
	_cleanup_scene(scene)


func _river_valley_uat() -> void:
	var scene := await _start_debug_scene(6004, "river_valley_constrained")
	if scene == null:
		return
	_expect(_debug_contains(scene, "Features:"), "river UAT debug panel exposes generated feature summary")
	_expect(_debug_contains(scene, "bridge/water"), "river UAT debug panel names bridge/water feature")
	_expect(_route_reaches_exit(scene, "main"), "river UAT main route reaches exit in normal Main scene")
	_expect(_route_reaches_exit(scene, "loop"), "river UAT loop route reconnects to exit in normal Main scene")
	_cleanup_scene(scene)


func _declining_branch_uat() -> void:
	var scene := await _start_debug_scene(6008, "declining_abandoned_branch")
	if scene == null:
		return
	_expect(_debug_contains(scene, "Features:"), "declining UAT debug panel exposes generated feature summary")
	_expect(_debug_contains(scene, "display-only abandoned track"), "declining UAT debug panel names display-only abandoned track")
	_expect(_route_reaches_exit(scene, "main"), "declining UAT main route reaches exit in normal Main scene")
	_expect(_route_reaches_exit(scene, "loop"), "declining UAT loop route reconnects to exit in normal Main scene")
	_expect(_route_reaches_stub_and_reverses(scene, "old_storage", "overgrown_storage", "main_west"), "declining UAT overgrown storage route is reachable and reversible")
	_expect(str(scene.rail.get_segment_runtime_status("abandoned_loading_track")) == STATUS_DISPLAY_ONLY, "declining UAT abandoned loading track is display-only")
	_expect(str(scene.rail.get_segment_runtime_status("removed_branch_stub")) == STATUS_DISPLAY_ONLY, "declining UAT removed branch stub is display-only")
	for raw_preset in scene.lifecycle.current_sector.definition.route_presets:
		var preset := raw_preset as Dictionary
		_expect(not str(preset.get("id", "")).contains("abandoned"), "declining UAT exposes no abandoned route preset")
	_cleanup_scene(scene)


func _start_debug_scene(seed: int, expected_archetype: String) -> Node:
	OS.set_environment(ENV_RUN_SEED, str(seed))
	OS.set_environment(ENV_START_SECTOR, "2")
	OS.set_environment(ENV_START_ROUTE, ROUTE_PROFILE)
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads for %s UAT" % expected_archetype)
	if packed_scene == null:
		return null
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var visual_state: Dictionary = scene.get_sector_visual_state()
	_expect(str(visual_state.get("source_type", "")) == "PROCEDURAL", "%s UAT starts in generated sector" % expected_archetype)
	_expect(str(visual_state.get("archetype_id", "")) == expected_archetype, "%s UAT reaches expected seed fixture" % expected_archetype)
	_expect(scene.lifecycle.can_depart(), "%s UAT debug start can depart without authored blockers" % expected_archetype)
	return scene


func _route_reaches_exit(scene: Node, preset_id: String) -> bool:
	var layout := scene.lifecycle.current_sector.definition.runtime_layout as Dictionary
	_apply_route_preset(scene.rail, _find_route_preset(layout, preset_id))
	_prepare_train_at_entry(scene)
	_step_until_distance(scene.rail, str(layout.get("exit_segment", "")), float(layout.get("exit_distance", 0.0)), 26.0)
	return str(scene.rail.current_segment) == str(layout.get("exit_segment", "")) \
			and float(scene.rail.distance) >= float(layout.get("exit_distance", 0.0))


func _route_reaches_stub_and_reverses(scene: Node, preset_id: String, stub_segment: String, return_segment: String) -> bool:
	var layout := scene.lifecycle.current_sector.definition.runtime_layout as Dictionary
	_apply_route_preset(scene.rail, _find_route_preset(layout, preset_id))
	_prepare_train_at_entry(scene)
	_step_until(scene.rail, stub_segment, 18.0)
	if str(scene.rail.current_segment) != stub_segment:
		return false
	_step_until_stopped(scene.rail, 18.0)
	if not scene.rail.is_stopped():
		return false
	if not scene.rail.reverse_direction():
		return false
	scene.rail.speed = 70.0
	scene.rail.throttle = 1.0
	_step_until(scene.rail, return_segment, 22.0)
	return str(scene.rail.current_segment) == return_segment


func _prepare_train_at_entry(scene: Node) -> void:
	var definition = scene.lifecycle.current_sector.definition
	scene.rail.current_segment = str(definition.entry_segment)
	scene.rail.distance = float(definition.entry_distance)
	scene.rail.direction = 1
	scene.rail.speed = 70.0
	scene.rail.throttle = 1.0
	scene.rail.max_speed = 70.0
	scene.rail.acceleration = 0.0
	scene.rail.coast_deceleration = 0.0
	scene.rail.brake_deceleration = 140.0


func _apply_route_preset(rail: RefCounted, preset: Dictionary) -> void:
	_expect(not preset.is_empty(), "route preset exists")
	for point_id in (preset.get("routes", {}) as Dictionary).keys():
		_expect(rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id])), "sets point %s for preset %s" % [str(point_id), str(preset.get("id", ""))])


func _find_route_preset(layout: Dictionary, preset_id: String) -> Dictionary:
	for raw_preset in layout.get("route_presets", []) as Array:
		var preset := raw_preset as Dictionary
		if str(preset.get("id", "")) == preset_id:
			return preset
	return {}


func _step_until(rail: RefCounted, target_segment: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and str(rail.current_segment) != target_segment:
		rail.step(0.25, false)
		elapsed += 0.25


func _step_until_distance(rail: RefCounted, target_segment: String, target_distance: float, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds:
		if str(rail.current_segment) == target_segment and float(rail.distance) >= target_distance:
			return
		rail.step(0.25, false)
		elapsed += 0.25


func _step_until_stopped(rail: RefCounted, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and float(rail.speed) > 0.05:
		rail.step(0.25, false)
		elapsed += 0.25


func _debug_contains(scene: Node, needle: String) -> bool:
	var lines: Array[String] = scene.get_compact_debug_lines()
	for line in lines:
		if line.contains(needle):
			return true
	return false


func _cleanup_scene(scene: Node) -> void:
	if scene == null:
		return
	scene.queue_free()


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
		print("\nSprint 11 scripted UAT rehearsal passed")
		quit(0)
	else:
		printerr("\nSprint 11 scripted UAT rehearsal FAILED with %d failure(s)" % _failures)
		quit(1)
