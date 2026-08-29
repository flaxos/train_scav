extends SceneTree

const GENERATOR_PATH := "res://scripts/worldgen/worldgen_production_sector_generator.gd"
const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const CONTEXT_PATH := "res://scripts/worldgen/worldgen_generation_context.gd"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"
const TrainResources := preload("res://scripts/train/train_resources.gd")

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"
const GENERATOR_VERSION := "9_production_procedural_sectors_v1"
const EXPECTED_ARCHETYPES := [
	"rural_through",
	"village_passing_station",
	"small_town_goods",
	"agricultural_loading_point",
	"river_valley_constrained",
	"declining_abandoned_branch",
]
const PROMOTED_ARCHETYPES := [
	"agricultural_loading_point",
	"river_valley_constrained",
	"declining_abandoned_branch",
]
const UAT_ARCHETYPE_SAMPLES := [
	{"seed": 6003, "archetype_id": "rural_through"},
	{"seed": 6012, "archetype_id": "village_passing_station"},
	{"seed": 6001, "archetype_id": "small_town_goods"},
	{"seed": 6005, "archetype_id": "agricultural_loading_point"},
	{"seed": 6004, "archetype_id": "river_valley_constrained"},
	{"seed": 6008, "archetype_id": "declining_abandoned_branch"},
]
const STATUS_DISPLAY_ONLY := "display_only"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 11 Procgen Variety Tests ---")
	_production_generator_exposes_six_archetypes()
	_promoted_archetypes_are_generated_not_loaded_from_fixtures()
	_known_sample_produces_all_six_archetypes()
	_known_uat_seed_fixtures_are_stable()
	await _normal_scene_exposes_sprint11_load_check()
	_promoted_archetypes_are_deterministic()
	_promoted_archetypes_have_safe_resources_and_routes()
	await _normal_main_debug_start_reaches_all_supported_archetypes()
	_finish()


func _production_generator_exposes_six_archetypes() -> void:
	var generator := _load_script(GENERATOR_PATH)
	if generator == null:
		return
	var supported := generator.SUPPORTED_ARCHETYPES as Array
	_expect(supported.size() == EXPECTED_ARCHETYPES.size(), "production generator exposes six supported archetypes")
	for archetype_id in EXPECTED_ARCHETYPES:
		_expect(supported.has(archetype_id), "production generator supports %s" % archetype_id)


func _promoted_archetypes_are_generated_not_loaded_from_fixtures() -> void:
	var semantic_source := FileAccess.get_file_as_string("res://scripts/worldgen/worldgen_semantic_generator.gd")
	var production_source := FileAccess.get_file_as_string("res://scripts/worldgen/worldgen_production_sector_generator.gd")
	for archetype_id in PROMOTED_ARCHETYPES:
		_expect(not semantic_source.contains("%s_v1.json" % archetype_id), "semantic generation for %s does not load reference fixture JSON" % archetype_id)
		_expect(not production_source.contains("%s_v1.json" % archetype_id), "production generation for %s does not load reference fixture JSON" % archetype_id)


func _known_sample_produces_all_six_archetypes() -> void:
	var seen: Dictionary = {}
	for index in range(2, 242):
		var result := _generate(74001, index, "industrial")
		if result.is_empty():
			continue
		seen[str(result.get("archetype_id", ""))] = true

	for archetype_id in EXPECTED_ARCHETYPES:
		_expect(seen.has(archetype_id), "known Sprint 11 sample includes %s" % archetype_id)


func _known_uat_seed_fixtures_are_stable() -> void:
	for raw_sample in UAT_ARCHETYPE_SAMPLES:
		var sample := raw_sample as Dictionary
		var seed := int(sample.get("seed", 0))
		var expected_archetype := str(sample.get("archetype_id", ""))
		var result := _generate(seed, 2, "industrial")
		_expect(str(result.get("archetype_id", "")) == expected_archetype, "UAT seed %d reaches %s" % [seed, expected_archetype])


func _normal_scene_exposes_sprint11_load_check() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads for Sprint 11 load check")
	if packed_scene == null:
		return
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("get_sprint11_preflight_state"), "normal scene exposes Sprint 11 preflight state")
	_expect(scene.has_method("get_sprint11_preflight_lines"), "normal scene exposes Sprint 11 preflight lines")
	if scene.has_method("get_sprint11_preflight_state"):
		var state: Dictionary = scene.get_sprint11_preflight_state()
		var supported := state.get("supported_archetypes", []) as Array
		_expect(supported.size() == EXPECTED_ARCHETYPES.size(), "Sprint 11 load check exposes six production archetypes")
		var samples := state.get("seed_samples", []) as Array
		_expect(samples.size() == UAT_ARCHETYPE_SAMPLES.size(), "Sprint 11 load check exposes six UAT seed samples")
		for raw_sample in samples:
			var sample := raw_sample as Dictionary
			_expect(bool(sample.get("seeded", false)), "Sprint 11 load check seed %d is seeded" % int(sample.get("seed", 0)))
	if scene.has_method("get_sprint11_preflight_lines"):
		var joined := "\n".join(scene.get_sprint11_preflight_lines())
		_expect(joined.contains("Sprint 11 Procgen Check"), "Sprint 11 load check lines have visible title")
		_expect(joined.contains("6005"), "Sprint 11 load check mentions agricultural fixture seed")
		_expect(joined.contains("river_valley_constrained"), "Sprint 11 load check mentions river-valley fixture")
	var guide := "\n".join(scene.get_uat_tutorial_lines())
	_expect(guide.contains("Train Scav - Sprint 11 UAT"), "normal startup guide names Sprint 11")
	_expect(guide.contains("Sprint 11 Procgen Check"), "normal startup guide includes Sprint 11 load check")

	scene.queue_free()
	await process_frame
	await process_frame


func _promoted_archetypes_are_deterministic() -> void:
	for archetype_id in PROMOTED_ARCHETYPES:
		var sample := _find_archetype(archetype_id, 76000, 1200)
		_expect(not sample.is_empty(), "known sample can generate %s" % archetype_id)
		if sample.is_empty():
			continue
		var seed := int(sample.get("run_seed", 0))
		var index := int(sample.get("sector_index", 0))
		var repeat := _generate(seed, index, str(sample.get("route_profile", "industrial")))
		_expect(str(sample.get("blueprint_hash", "")) == str(repeat.get("blueprint_hash", "")), "%s blueprint hash is deterministic" % archetype_id)
		_expect(str(sample.get("spatial_embedding_hash", "")) == str(repeat.get("spatial_embedding_hash", "")), "%s spatial hash is deterministic" % archetype_id)
		_expect(str(sample.get("runtime_topology_hash", "")) == str(repeat.get("runtime_topology_hash", "")), "%s runtime topology hash is deterministic" % archetype_id)
		_expect(str(sample.get("poi_signature", "")) == str(repeat.get("poi_signature", "")), "%s POI signature is deterministic" % archetype_id)


func _promoted_archetypes_have_safe_resources_and_routes() -> void:
	for archetype_id in EXPECTED_ARCHETYPES:
		var result := _find_archetype(archetype_id, 77000, 1200)
		_expect(not result.is_empty(), "known sample can generate %s" % archetype_id)
		if result.is_empty():
			continue
		_expect(_has_departure_diesel_poi(result), "%s includes enough obtainable diesel for departure" % archetype_id)
		_expect(_route_reaches_exit(result, "main"), "%s main route reaches exit" % archetype_id)

	var agricultural := _find_archetype("agricultural_loading_point", 78000, 1200)
	if not agricultural.is_empty():
		_expect(_route_reaches_stub_and_reverses(agricultural, "grain_loading", "grain_loading", "main_west"), "agricultural loading route is reachable and reversible")
		_expect(_route_reaches_stub_and_reverses(agricultural, "headshunt", "short_runaround", "main_west"), "agricultural headshunt route is reachable and reversible")

	var river := _find_archetype("river_valley_constrained", 79000, 1200)
	if not river.is_empty():
		_expect(_route_reaches_exit(river, "loop"), "river-valley loop route reconnects to exit")
		_expect(_blueprint_has_relation(river, "WATER_CROSSED_BY_TRACK"), "river-valley blueprint records water crossing")
		_expect(_blueprint_has_relation(river, "BRIDGE_CARRIES_TRACK"), "river-valley blueprint records bridge relation")

	var declining := _find_archetype("declining_abandoned_branch", 80000, 1200)
	if not declining.is_empty():
		_expect(_route_reaches_exit(declining, "loop"), "declining branch loop route reconnects to exit")
		_expect(_route_reaches_stub_and_reverses(declining, "old_storage", "overgrown_storage", "main_west"), "declining storage route is reachable and reversible")
		_expect(_display_only_segments(declining).has("abandoned_loading_track"), "declining branch keeps abandoned loading track display-only")
		_expect(_display_only_segments(declining).has("removed_branch_stub"), "declining branch keeps removed branch stub display-only")
		for preset in (declining.get("layout", {}) as Dictionary).get("route_presets", []) as Array:
			var preset_dict := preset as Dictionary
			_expect(not str(preset_dict.get("id", "")).contains("abandoned"), "declining branch exposes no abandoned route preset")


func _normal_main_debug_start_reaches_all_supported_archetypes() -> void:
	var previous_env := _capture_env([ENV_RUN_SEED, ENV_START_SECTOR, ENV_START_ROUTE])
	for raw_sample in UAT_ARCHETYPE_SAMPLES:
		var sample := raw_sample as Dictionary
		var seed := int(sample.get("seed", 0))
		var expected_archetype := str(sample.get("archetype_id", ""))
		OS.set_environment(ENV_RUN_SEED, str(seed))
		OS.set_environment(ENV_START_SECTOR, "2")
		OS.set_environment(ENV_START_ROUTE, "industrial")

		var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
		_expect(packed_scene != null, "normal Main scene loads for %s debug start" % expected_archetype)
		if packed_scene == null:
			continue
		var scene := packed_scene.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame

		var visual_state: Dictionary = scene.get_sector_visual_state()
		_expect(str(visual_state.get("source_type", "")) == "PROCEDURAL", "debug start enters a procedural sector for %s" % expected_archetype)
		_expect(str(visual_state.get("archetype_id", "")) == expected_archetype, "debug start reaches %s" % expected_archetype)
		_expect(scene.lifecycle.can_depart(), "%s debug start has no authored opening blockers" % expected_archetype)

		scene.queue_free()
		await process_frame
		await process_frame
	_restore_env(previous_env)


func _generate(run_seed: int, sector_index: int, route_profile: String) -> Dictionary:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if generator == null or request_script == null or context_script == null:
		return {}

	var request: RefCounted = request_script.create(
		run_seed,
		sector_index,
		route_profile,
		"central_eu_v1",
		"central_eu_small_town_station_v1",
		GENERATOR_VERSION
	)
	var context: RefCounted = context_script.create(request)
	var result: Dictionary = generator.generate_sector_from_context(context)
	_expect(bool(result.get("success", false)), "production generation succeeds for seed %d index %d" % [run_seed, sector_index])
	if not bool(result.get("success", false)):
		printerr("Generation diagnostics: %s" % str(result.get("diagnostics", [])))
		return {}
	return result


func _find_archetype(archetype_id: String, seed_start: int, count: int) -> Dictionary:
	for seed in range(seed_start, seed_start + count):
		var result := _generate(seed, 2, "industrial")
		if str(result.get("archetype_id", "")) == archetype_id:
			return result
	return {}


func _has_departure_diesel_poi(result: Dictionary) -> bool:
	var diesel_total := 0.0
	for raw_poi in result.get("poi_definitions", []) as Array:
		var poi := raw_poi as Dictionary
		if str(poi.get("yield_type", "")) == TrainResources.RESOURCE_DIESEL:
			diesel_total += float(poi.get("yield_amount", 0.0))
	return diesel_total >= TrainResources.DEPARTURE_DIESEL_COST


func _route_reaches_exit(result: Dictionary, preset_id: String) -> bool:
	var configured := _make_configured_rail(result)
	if configured.is_empty():
		return false
	var rail: RefCounted = configured.get("rail", null)
	var layout := configured.get("layout", {}) as Dictionary
	_apply_route_preset(rail, _find_route_preset(layout, preset_id))
	_prepare_single_loco(rail, layout)
	_step_until_distance(rail, str(layout.get("exit_segment", "")), float(layout.get("exit_distance", 0.0)), 26.0)
	return str(rail.current_segment) == str(layout.get("exit_segment", "")) \
			and float(rail.distance) >= float(layout.get("exit_distance", 0.0))


func _route_reaches_stub_and_reverses(result: Dictionary, preset_id: String, stub_segment: String, return_segment: String) -> bool:
	var configured := _make_configured_rail(result)
	if configured.is_empty():
		return false
	var rail: RefCounted = configured.get("rail", null)
	var layout := configured.get("layout", {}) as Dictionary
	_apply_route_preset(rail, _find_route_preset(layout, preset_id))
	_prepare_single_loco(rail, layout)
	_step_until(rail, stub_segment, 18.0)
	if str(rail.current_segment) != stub_segment:
		return false
	_step_until_stopped(rail, 18.0)
	if not rail.is_stopped():
		return false
	if not rail.reverse_direction():
		return false
	rail.speed = 70.0
	rail.throttle = 1.0
	_step_until(rail, return_segment, 22.0)
	return str(rail.current_segment) == return_segment


func _display_only_segments(result: Dictionary) -> Array[String]:
	var configured := _make_configured_rail(result)
	var rail: RefCounted = configured.get("rail", null)
	var layout := configured.get("layout", {}) as Dictionary
	var display_segments: Array[String] = []
	if rail == null:
		return display_segments
	for raw_segment_id in (layout.get("segments", {}) as Dictionary).keys():
		var segment_id := str(raw_segment_id)
		if rail.has_method("get_segment_runtime_status") and str(rail.get_segment_runtime_status(segment_id)) == STATUS_DISPLAY_ONLY:
			display_segments.append(segment_id)
	return display_segments


func _blueprint_has_relation(result: Dictionary, relation_type: String) -> bool:
	var blueprint: RefCounted = result.get("blueprint", null)
	if blueprint == null or not blueprint.has_method("to_dictionary"):
		return false
	var data: Dictionary = blueprint.to_dictionary()
	var world_graph := data.get("world_graph", {}) as Dictionary
	for raw_relation in world_graph.get("relations", []) as Array:
		var relation := raw_relation as Dictionary
		if str(relation.get("type", "")) == relation_type:
			return true
	return false


func _make_configured_rail(result: Dictionary) -> Dictionary:
	var rail_script := load(RAIL_PATH) as Script
	if rail_script == null or not rail_script.can_instantiate():
		_expect(false, "RailMovement script loads")
		return {}
	var rail = rail_script.new()
	var layout := result.get("layout", {}) as Dictionary
	var configured: Dictionary = rail.configure_track_layout(layout)
	_expect(bool(configured.get("valid", false)), "generated layout configures RailMovement")
	if not bool(configured.get("valid", false)):
		printerr("Rail diagnostics: %s" % str(configured.get("diagnostics", [])))
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
		_expect(rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id])), "sets point %s for preset %s" % [str(point_id), str(preset.get("id", ""))])


func _find_route_preset(layout: Dictionary, preset_id: String) -> Dictionary:
	for preset in layout.get("route_presets", []) as Array:
		var preset_dict := preset as Dictionary
		if str(preset_dict.get("id", "")) == preset_id:
			return preset_dict
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
		print("\nSprint 11 procgen variety acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 11 procgen variety FAILED with %d failure(s)" % _failures)
		quit(1)
