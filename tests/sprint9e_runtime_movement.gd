extends SceneTree

const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const RECONSTRUCTOR_PATH := "res://scripts/worldgen/worldgen_runtime_reconstructor.gd"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"
const HARNESS_SCENE := "res://scenes/worldgen/Sprint9EMultiArchetypeReconstruction.tscn"
const EMBEDDING_REGISTRY_PATH := "res://data/worldgen/embeddings/reference/reference_embeddings_v1.json"
const STATUS_DISPLAY_ONLY := "display_only"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9E Runtime Movement Tests ---")
	_all_reference_routes_drive_through_railmovement()
	_declining_branch_keeps_abandoned_track_non_routable()
	await _multi_archetype_harness_loads_and_cycles_layouts()
	_finish()


func _all_reference_routes_drive_through_railmovement() -> void:
	_expect_traverses_to("rural_through", "main", "rural_main", 900.0, "rural through drives across sparse zero-turnout layout")
	_expect_traverses_to("village_passing_station", "main", "main_east", 180.0, "village main route reaches east exit")
	_expect_traverses_to("village_passing_station", "loop", "main_east", 180.0, "village loop route reconnects to east exit")
	_expect_traverses_to("small_town_goods_station", "main", "main_east", 180.0, "small-town goods main route remains green")
	_expect_traverses_to("small_town_goods_station", "loop", "main_east", 180.0, "small-town goods loop route remains green")
	_expect_reaches_stub_and_reverses("small_town_goods_station", "goods_loading", "goods_loading", "main_west", "small-town goods loading track is reachable and reversible")
	_expect_traverses_to("agricultural_loading_point", "main", "main_east", 560.0, "agricultural main route reaches east exit")
	_expect_reaches_stub_and_reverses("agricultural_loading_point", "grain_loading", "grain_loading", "main_west", "agricultural loading spur is reachable and reversible")
	_expect_traverses_to("river_valley_constrained", "main", "valley_main_east", 180.0, "river-valley constrained main route reaches east exit")
	_expect_traverses_to("river_valley_constrained", "loop", "valley_main_east", 180.0, "river-valley constrained loop route reconnects")
	_expect_traverses_to("declining_abandoned_branch", "main", "main_east", 180.0, "declining branch active main reaches east exit")
	_expect_traverses_to("declining_abandoned_branch", "loop", "main_east", 180.0, "declining branch active loop reaches east exit")
	_expect_reaches_stub_and_reverses("declining_abandoned_branch", "old_storage", "overgrown_storage", "main_west", "declining branch active storage track is reachable and reversible")


func _declining_branch_keeps_abandoned_track_non_routable() -> void:
	var bundle := _make_configured_rail("declining_abandoned_branch")
	var rail: RefCounted = bundle.get("rail", null)
	var layout := bundle.get("layout", {}) as Dictionary
	if rail == null:
		return

	var display_segments: Array[String] = []
	for raw_segment_id in (layout.get("segments", {}) as Dictionary).keys():
		var segment_id := str(raw_segment_id)
		if rail.has_method("get_segment_runtime_status") and str(rail.get_segment_runtime_status(segment_id)) == STATUS_DISPLAY_ONLY:
			display_segments.append(segment_id)
	_expect(display_segments.has("abandoned_loading_track"), "declining branch maps abandoned loading track as display-only runtime geometry")
	_expect(display_segments.has("removed_branch_stub"), "declining branch maps removed branch stub as display-only runtime geometry")

	for preset in layout.get("route_presets", []) as Array:
		var preset_dict := preset as Dictionary
		_expect(not str(preset_dict.get("id", "")).contains("abandoned"), "declining branch has no active abandoned-track route preset")

	_apply_route_preset(rail, _find_route_preset(layout, "old_storage"))
	_prepare_single_loco(rail, layout)
	_step_until(rail, "overgrown_storage", 12.0)
	_expect(str(rail.current_segment) == "overgrown_storage", "declining branch yard route reaches active overgrown storage, not abandoned track")
	_expect(not display_segments.has(str(rail.current_segment)), "locomotive is not routed onto display-only abandoned geometry")


func _multi_archetype_harness_loads_and_cycles_layouts() -> void:
	var packed_scene := load(HARNESS_SCENE) as PackedScene
	_expect(packed_scene != null, "Sprint 9E multi-archetype harness scene loads")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.rail != null, "9E harness owns a live RailMovement instance")
	_expect((scene.reference_entries as Array).size() == 6, "9E harness loads six reference entries")
	var first_archetype := str(scene.current_archetype_id)
	_send_key(scene, KEY_BRACKETRIGHT)
	await process_frame
	_expect(str(scene.current_archetype_id) != first_archetype, "9E harness cycles to another archetype")
	_send_key(scene, KEY_SPACE)
	await process_frame
	_expect(float(scene.rail.throttle) > 0.0, "9E harness Space input sets ordinary RailMovement throttle")
	scene.queue_free()


func _expect_traverses_to(archetype_id: String, preset_id: String, target_segment: String, target_distance: float, message: String) -> void:
	var bundle := _make_configured_rail(archetype_id)
	var rail: RefCounted = bundle.get("rail", null)
	var layout := bundle.get("layout", {}) as Dictionary
	if rail == null:
		return
	_apply_route_preset(rail, _find_route_preset(layout, preset_id))
	_prepare_single_loco(rail, layout)
	_step_until_distance(rail, target_segment, target_distance, 18.0)
	_expect(str(rail.current_segment) == target_segment and float(rail.distance) >= target_distance, message)


func _expect_reaches_stub_and_reverses(archetype_id: String, preset_id: String, stub_segment: String, return_segment: String, message: String) -> void:
	var bundle := _make_configured_rail(archetype_id)
	var rail: RefCounted = bundle.get("rail", null)
	var layout := bundle.get("layout", {}) as Dictionary
	if rail == null:
		return
	_apply_route_preset(rail, _find_route_preset(layout, preset_id))
	_prepare_single_loco(rail, layout)
	_step_until(rail, stub_segment, 14.0)
	_expect(str(rail.current_segment) == stub_segment, "%s reaches %s" % [message, stub_segment])
	_step_until_stopped(rail, 14.0)
	_expect(str(rail.current_segment) == stub_segment and rail.is_stopped(), "%s stops at terminal buffer" % message)
	_expect(rail.reverse_direction(), "%s can reverse after stopping" % message)
	rail.speed = 70.0
	rail.throttle = 1.0
	_step_until(rail, return_segment, 18.0)
	_expect(str(rail.current_segment) == return_segment, "%s returns to %s" % [message, return_segment])


func _make_configured_rail(archetype_id: String) -> Dictionary:
	var loader := _load_script(LOADER_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	var reconstructor := _load_script(RECONSTRUCTOR_PATH)
	var rail_script := load(RAIL_PATH) as Script
	if loader == null or validator == null or reconstructor == null or rail_script == null:
		return {}
	var entry := _find_registry_entry(loader, archetype_id)
	_expect(not entry.is_empty(), "%s has 9E embedding registry entry" % archetype_id)
	if entry.is_empty():
		return {}

	var blueprint = loader.load_blueprint(str(entry.get("fixture_path", "")))
	var embedding: Dictionary = loader.load_json(str(entry.get("embedding_path", "")))
	var reconstruction: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	_expect(bool(reconstruction.get("valid", false)), "%s reconstructs for movement" % archetype_id)
	if not bool(reconstruction.get("valid", false)):
		printerr("%s reconstruction diagnostics: %s" % [archetype_id, str(reconstruction.get("diagnostics", []))])
		return {}

	var layout := reconstruction.get("layout", {}) as Dictionary
	var rail = rail_script.new()
	var configure_result: Dictionary = rail.configure_track_layout(layout)
	_expect(bool(configure_result.get("valid", false)), "%s configures RailMovement for movement" % archetype_id)
	if not bool(configure_result.get("valid", false)):
		printerr("%s RailMovement diagnostics: %s" % [archetype_id, str(configure_result.get("diagnostics", []))])
		return {}
	return {
		"rail": rail,
		"layout": layout,
	}


func _prepare_single_loco(rail: RefCounted, layout: Dictionary) -> void:
	var active: Array[String] = ["L"]
	var detached: Array[Dictionary] = []
	rail.active_units = active
	rail.detached_consists = detached
	rail.current_segment = str(layout.get("entry_segment", ""))
	rail.distance = float(layout.get("entry_distance", 24.0))
	rail.direction = 1
	rail.speed = 70.0
	rail.throttle = 1.0
	rail.max_speed = 70.0
	rail.acceleration = 0.0
	rail.coast_deceleration = 0.0
	rail.brake_deceleration = 140.0


func _apply_route_preset(rail: RefCounted, preset: Dictionary) -> void:
	_expect(not preset.is_empty(), "route preset exists")
	for point_id in (preset.get("routes", {}) as Dictionary).keys():
		_expect(rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id])), "sets route %s for preset %s" % [str(point_id), str(preset.get("id", ""))])


func _find_route_preset(layout: Dictionary, preset_id: String) -> Dictionary:
	for preset in layout.get("route_presets", []) as Array:
		var preset_dict := preset as Dictionary
		if str(preset_dict.get("id", "")) == preset_id:
			return preset_dict
	return {}


func _find_registry_entry(loader: RefCounted, archetype_id: String) -> Dictionary:
	var data: Dictionary = loader.load_json(EMBEDDING_REGISTRY_PATH)
	for entry in data.get("embeddings", []) as Array:
		var entry_dict := entry as Dictionary
		if str(entry_dict.get("archetype_id", "")) == archetype_id:
			return entry_dict
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


func _send_key(scene: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	scene._input(event)


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
		_expect(false, "%s exists" % path)
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		_expect(false, "%s loads and can instantiate" % path)
		return null
	return script.new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9E runtime movement acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9E runtime movement acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
