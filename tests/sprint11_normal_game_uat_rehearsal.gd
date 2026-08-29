extends SceneTree

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

const ROUTE_PROFILE := "industrial"
const STATUS_DISPLAY_ONLY := "display_only"
const PROMOTED_UAT_SAMPLES := [
	{
		"seed": 6005,
		"archetype_id": "agricultural_loading_point",
		"feature": "agricultural loading",
	},
	{
		"seed": 6004,
		"archetype_id": "river_valley_constrained",
		"feature": "bridge/water",
	},
	{
		"seed": 6008,
		"archetype_id": "declining_abandoned_branch",
		"feature": "display-only abandoned track",
	},
]

var _failures: int = 0
var _previous_env: Dictionary = {}


func _init() -> void:
	print("\n--- Starting Sprint 11 Normal-Game UAT Rehearsal ---")
	_previous_env = _capture_env([ENV_RUN_SEED, ENV_START_SECTOR, ENV_START_ROUTE])
	for raw_sample in PROMOTED_UAT_SAMPLES:
		var sample := raw_sample as Dictionary
		await _run_promoted_archetype_from_authored_opening(sample)
	_restore_env(_previous_env)
	_finish()


func _run_promoted_archetype_from_authored_opening(sample: Dictionary) -> void:
	var seed := int(sample.get("seed", 0))
	var expected_archetype := str(sample.get("archetype_id", ""))
	var scene := await _run_normal_main_to_sector2(seed, expected_archetype)
	if scene == null:
		return

	_expect(_debug_contains(scene, "Features:"), "%s normal-game UAT exposes generated feature summary" % expected_archetype)
	_expect(_debug_contains(scene, str(sample.get("feature", ""))), "%s normal-game UAT names promoted feature" % expected_archetype)

	match expected_archetype:
		"agricultural_loading_point":
			_expect(_route_reaches_exit(scene, "main"), "agricultural normal-game UAT main route reaches exit")
			_expect(_route_reaches_stub_and_reverses(scene, "grain_loading", "grain_loading", "main_west"), "agricultural normal-game UAT grain loading route is reachable and reversible")
			_expect(_agricultural_headshunt_valid_or_cleanly_skipped(scene), "agricultural normal-game UAT headshunt route is valid when present or absent when skipped")
		"river_valley_constrained":
			_expect(_route_reaches_exit(scene, "main"), "river normal-game UAT main route reaches exit")
			_expect(_route_reaches_exit(scene, "loop"), "river normal-game UAT loop route reconnects to exit")
		"declining_abandoned_branch":
			_expect(_route_reaches_exit(scene, "main"), "declining normal-game UAT main route reaches exit")
			_expect(_route_reaches_exit(scene, "loop"), "declining normal-game UAT loop route reconnects to exit")
			_expect(_route_reaches_stub_and_reverses(scene, "old_storage", "overgrown_storage", "main_west"), "declining normal-game UAT storage route is reachable and reversible")
			_expect(str(scene.rail.get_segment_runtime_status("abandoned_loading_track")) == STATUS_DISPLAY_ONLY, "declining normal-game UAT abandoned loading track is display-only")
			_expect(str(scene.rail.get_segment_runtime_status("removed_branch_stub")) == STATUS_DISPLAY_ONLY, "declining normal-game UAT removed branch stub is display-only")
			for raw_preset in scene.lifecycle.current_sector.definition.route_presets:
				var preset := raw_preset as Dictionary
				_expect(not str(preset.get("id", "")).contains("abandoned"), "declining normal-game UAT exposes no abandoned route preset")

	_cleanup_scene(scene)


func _run_normal_main_to_sector2(seed: int, expected_archetype: String) -> Node:
	OS.set_environment(ENV_RUN_SEED, str(seed))
	OS.unset_environment(ENV_START_SECTOR)
	OS.unset_environment(ENV_START_ROUTE)

	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads for %s seed %d" % [expected_archetype, seed])
	if packed_scene == null:
		return null
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var visual0: Dictionary = scene.get_sector_visual_state()
	_expect(int(visual0.get("run_seed", 0)) == seed, "%s normal-game UAT uses known run seed" % expected_archetype)
	_expect(int(visual0.get("sector_index", -1)) == 0, "%s normal-game UAT starts in authored sector 0" % expected_archetype)
	_expect(str(visual0.get("source_type", "")) == SectorDefinition.SOURCE_AUTHORED, "%s normal-game UAT sector 0 is authored" % expected_archetype)
	_expect(scene.scenario.obstruction_state == FirstRunScenario.STATE_ACTIVE, "%s normal-game UAT keeps opening obstruction active at start" % expected_archetype)
	_expect(not scene.lifecycle.can_depart(), "%s normal-game UAT authored sector 0 blocks departure before setup" % expected_archetype)
	var initial_consist: Array = scene.rail.get_active_consist_ids()

	scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 120.0)
	scene.train_resources.set_amount(TrainResources.RESOURCE_FOOD, 24.0)
	scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 12.0)
	scene.scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scene.scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	_cross_forward_exit(scene.lifecycle.current_sector)
	_expect(scene.lifecycle.request_transition(), "%s normal-game UAT departs authored sector 0 through lifecycle" % expected_archetype)
	_sync_scene_to_lifecycle(scene)

	var sector1 = scene.lifecycle.current_sector
	_expect(int(sector1.definition.sector_index) == 1, "%s normal-game UAT reaches authored sector 1" % expected_archetype)
	_expect(str(sector1.definition.source_type) == SectorDefinition.SOURCE_AUTHORED, "%s normal-game UAT sector 1 is authored" % expected_archetype)
	_expect(scene.rail.get_active_consist_ids() == initial_consist, "%s normal-game UAT train persists into authored sector 1" % expected_archetype)
	_expect(scene.lifecycle.previous_sector != null and scene.lifecycle.previous_sector.disposed, "%s normal-game UAT disposes authored sector 0" % expected_archetype)

	if not scene.rail.active_units.has(FirstRunScenario.WORKSHOP_ID):
		scene.rail.active_units.append(FirstRunScenario.WORKSHOP_ID)
	scene.scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	var sector1_consist: Array = scene.rail.get_active_consist_ids()
	_cross_route_exit(sector1, ROUTE_PROFILE)
	_expect(scene.lifecycle.request_transition(), "%s normal-game UAT departs authored sector 1 through %s route" % [expected_archetype, ROUTE_PROFILE])
	_sync_scene_to_lifecycle(scene)

	var procedural = scene.lifecycle.current_sector
	var visual2: Dictionary = scene.get_sector_visual_state()
	_expect(int(procedural.definition.sector_index) == 2, "%s normal-game UAT reaches generated sector 2" % expected_archetype)
	_expect(str(procedural.definition.source_type) == SectorDefinition.SOURCE_PROCEDURAL, "%s normal-game UAT sector 2 is procedural" % expected_archetype)
	_expect(str(procedural.definition.archetype_id) == expected_archetype, "%s normal-game UAT reaches expected promoted archetype" % expected_archetype)
	_expect(str(visual2.get("archetype_id", "")) == expected_archetype, "%s normal-game UAT visual state records promoted archetype" % expected_archetype)
	_expect(scene.rail.get_active_consist_ids() == sector1_consist, "%s normal-game UAT consist persists into generated sector 2" % expected_archetype)
	_expect(scene.lifecycle.previous_sector != null and scene.lifecycle.previous_sector.disposed, "%s normal-game UAT disposes authored sector 1" % expected_archetype)
	_expect(_debug_contains(scene, "PROCEDURAL"), "%s normal-game UAT debug panel exposes procedural source" % expected_archetype)
	_expect(_debug_contains(scene, "Run:%d" % seed), "%s normal-game UAT debug panel exposes run seed" % expected_archetype)
	_expect(_debug_contains(scene, "Idx:2"), "%s normal-game UAT debug panel exposes generated sector index" % expected_archetype)
	_expect(_debug_contains(scene, "Archetype:%s" % expected_archetype), "%s normal-game UAT debug panel exposes promoted archetype" % expected_archetype)
	_expect(_debug_contains(scene, "Hash:"), "%s normal-game UAT debug panel exposes generated blueprint hash" % expected_archetype)
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


func _agricultural_headshunt_valid_or_cleanly_skipped(scene: Node) -> bool:
	var layout := scene.lifecycle.current_sector.definition.runtime_layout as Dictionary
	if not _find_route_preset(layout, "headshunt").is_empty():
		return _route_reaches_stub_and_reverses(scene, "headshunt", "short_runaround", "main_west")
	return not (layout.get("segments", {}) as Dictionary).has("short_runaround")


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


func _cross_forward_exit(sector: RefCounted) -> void:
	sector.rail.current_segment = sector.definition.exit_segment
	sector.rail.distance = sector.definition.exit_distance + 8.0
	sector.rail.direction = 1
	sector.rail.speed = 25.0


func _cross_route_exit(sector: RefCounted, route_id: String) -> void:
	for route_exit in sector.definition.route_exits:
		var exit := route_exit as Dictionary
		if str(exit.get("route_id", "")) != route_id:
			continue
		sector.rail.current_segment = str(exit.get("segment", ""))
		sector.rail.distance = float(exit.get("distance", 0.0)) + 8.0
		sector.rail.direction = 1
		sector.rail.speed = 25.0
		return
	_cross_forward_exit(sector)


func _sync_scene_to_lifecycle(scene: Node) -> void:
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.train_resources = scene.lifecycle.get_train_resources()
	scene.interior = scene.crew.interior


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
		print("\nSprint 11 normal-game UAT rehearsal passed")
		quit(0)
	else:
		printerr("\nSprint 11 normal-game UAT rehearsal FAILED with %d failure(s)" % _failures)
		quit(1)
