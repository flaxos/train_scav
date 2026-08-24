extends SceneTree

const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const CONTEXT_PATH := "res://scripts/worldgen/worldgen_generation_context.gd"
const SEMANTIC_GENERATOR_PATH := "res://scripts/worldgen/worldgen_semantic_generator.gd"
const SPATIAL_GENERATOR_PATH := "res://scripts/worldgen/worldgen_village_passing_spatial_embedding.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const RECONSTRUCTOR_PATH := "res://scripts/worldgen/worldgen_runtime_reconstructor.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"

const GENERATOR_VERSION_9G := "9g_village_passing_station_semantic_v1"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9 Closeout Generated Runtime Tests ---")
	_required_files_exist()
	_known_request_reaches_runtime_rail()
	_same_request_is_end_to_end_deterministic()
	_known_seed_sample_reconstructs_and_varies_spatially()
	_representative_generated_seeds_physically_move()
	_decoration_stream_consumption_does_not_perturb_output()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(REQUEST_PATH), "generation request exists")
	_expect(ResourceLoader.exists(CONTEXT_PATH), "generation context exists")
	_expect(ResourceLoader.exists(SEMANTIC_GENERATOR_PATH), "9G semantic generator exists")
	_expect(ResourceLoader.exists(SPATIAL_GENERATOR_PATH), "village passing spatial embedding generator exists")
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "semantic validator exists")
	_expect(ResourceLoader.exists(RECONSTRUCTOR_PATH), "runtime reconstructor exists")
	_expect(ResourceLoader.exists(CANONICAL_PATH), "canonical helper exists")
	_expect(ResourceLoader.exists(RAIL_PATH), "RailMovement exists")


func _known_request_reaches_runtime_rail() -> void:
	var result := _build_generated_runtime(9001, 3)
	if result.is_empty():
		return

	var blueprint: RefCounted = result.get("blueprint", null)
	var embedding := result.get("embedding", {}) as Dictionary
	var layout := result.get("layout", {}) as Dictionary
	var rail: RefCounted = result.get("rail", null)
	var final_trace: RefCounted = result.get("spatial_trace", null)

	_expect(blueprint != null, "generated pipeline exposes SectorBlueprint")
	_expect(not embedding.is_empty(), "generated pipeline exposes spatial embedding")
	_expect(not layout.is_empty(), "generated pipeline exposes reconstructed runtime layout")
	_expect(rail != null, "generated pipeline configures RailMovement")
	_expect(final_trace != null, "generated pipeline exposes final trace")
	if blueprint == null or rail == null or final_trace == null:
		return

	_expect(str(blueprint.get_archetype_id()) == "village_passing_station", "closeout still generates only village_passing_station")
	_expect((layout.get("points", {}) as Dictionary).size() == 2, "generated village runtime layout uses two ordinary turnouts")
	_expect((layout.get("route_presets", []) as Array).size() == 2, "generated runtime layout exposes main and loop route presets")
	_expect(str(layout.get("entry_segment", "")) == "approach_main", "generated runtime entry maps to semantic approach")
	_expect(str(layout.get("exit_segment", "")) == "exit_main", "generated runtime exit maps to semantic exit")
	_expect((layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary).has("station_main"), "station_main semantic edge maps to runtime")
	_expect((layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary).has("passing_loop"), "passing_loop semantic edge maps to runtime")
	_expect(_trace_has_stage(final_trace.to_dictionary(), "semantic_topology"), "final trace preserves semantic topology decisions")
	_expect(_trace_has_stage(final_trace.to_dictionary(), "spatial_embedding"), "final trace appends spatial embedding decisions")
	_expect(_trace_decision_stream(final_trace.to_dictionary(), "loop_side") == "spatial", "loop_side is owned by spatial stream")
	_print_sample_summary(9001, result)


func _same_request_is_end_to_end_deterministic() -> void:
	var first := _build_generated_runtime(9010, 2)
	var second := _build_generated_runtime(9010, 2)
	if first.is_empty() or second.is_empty():
		return

	_expect(str((first.get("blueprint", null) as RefCounted).get_canonical_hash()) == str((second.get("blueprint", null) as RefCounted).get_canonical_hash()), "same request keeps blueprint hash stable")
	_expect(str((first.get("spatial_trace", null) as RefCounted).get_canonical_hash()) == str((second.get("spatial_trace", null) as RefCounted).get_canonical_hash()), "same request keeps final trace hash stable")
	_expect(str(first.get("embedding_hash", "")) == str(second.get("embedding_hash", "")), "same request keeps spatial embedding hash stable")
	_expect(str(first.get("runtime_topology_hash", "")) == str(second.get("runtime_topology_hash", "")), "same request keeps runtime topology snapshot stable")


func _known_seed_sample_reconstructs_and_varies_spatially() -> void:
	var signatures: Dictionary = {}
	for seed in range(100, 140):
		var result := _build_generated_runtime(seed, 0)
		_expect(not result.is_empty(), "seed %d generates, embeds, reconstructs and configures" % seed)
		if result.is_empty():
			continue
		var blueprint: RefCounted = result.get("blueprint", null)
		var validator := _load_script(VALIDATOR_PATH)
		var validation: Dictionary = validator.validate_blueprint(blueprint)
		_expect(bool(validation.get("valid", false)), "seed %d generated semantic blueprint validates" % seed)
		signatures[str((result.get("spatial_decisions", {}) as Dictionary).get("signature", ""))] = true
		if seed == 100 or seed == 101:
			_print_sample_summary(seed, result)
	_expect(signatures.size() >= 2, "known generated seed sample produces at least two restrained spatial signatures")


func _representative_generated_seeds_physically_move() -> void:
	for seed in [100, 101]:
		var main_result := _build_generated_runtime(seed, 0)
		_expect(not main_result.is_empty(), "seed %d builds main-route runtime" % seed)
		if not main_result.is_empty():
			var main_rail: RefCounted = main_result.get("rail", null)
			var main_layout := main_result.get("layout", {}) as Dictionary
			_apply_route_preset(main_rail, _find_route_preset(main_layout, "main"))
			_prepare_single_loco(main_rail, main_layout)
			_drive_until_distance_no_teleport(main_rail, "exit_main", 120.0, 20.0, "seed %d main route" % seed)
			_expect(str(main_rail.current_segment) == "exit_main", "seed %d locomotive reaches generated east exit on main" % seed)

		var loop_result := _build_generated_runtime(seed, 0)
		_expect(not loop_result.is_empty(), "seed %d builds loop-route runtime" % seed)
		if loop_result.is_empty():
			continue
		var loop_rail: RefCounted = loop_result.get("rail", null)
		var loop_layout := loop_result.get("layout", {}) as Dictionary
		_apply_route_preset(loop_rail, _find_route_preset(loop_layout, "loop"))
		_prepare_single_loco(loop_rail, loop_layout)
		_drive_until_segment_no_teleport(loop_rail, "passing_loop", 12.0, "seed %d loop entry" % seed)
		_expect(str(loop_rail.current_segment) == "passing_loop", "seed %d turnout route sends locomotive through passing loop" % seed)
		_drive_until_distance_no_teleport(loop_rail, "exit_main", 120.0, 16.0, "seed %d loop exit" % seed)
		_expect(str(loop_rail.current_segment) == "exit_main", "seed %d passing loop reconnects to east exit" % seed)
		loop_rail.speed = 0.0
		loop_rail.throttle = 0.0
		_expect(loop_rail.reverse_direction(), "seed %d can reverse after stopping on generated runtime layout" % seed)
		loop_rail.speed = 60.0
		loop_rail.throttle = 1.0
		_drive_until_segment_no_teleport(loop_rail, "passing_loop", 16.0, "seed %d reverse loop return" % seed)
		_expect(str(loop_rail.current_segment) == "passing_loop", "seed %d reverse movement remains valid through loop" % seed)


func _decoration_stream_consumption_does_not_perturb_output() -> void:
	var baseline := _build_generated_runtime(9020, 4)
	var preconsumed := _build_generated_runtime(9020, 4, true)
	if baseline.is_empty() or preconsumed.is_empty():
		return
	_expect(str((baseline.get("blueprint", null) as RefCounted).get_canonical_hash()) == str((preconsumed.get("blueprint", null) as RefCounted).get_canonical_hash()), "decoration pre-consumption does not alter semantic blueprint hash")
	_expect(str(baseline.get("embedding_hash", "")) == str(preconsumed.get("embedding_hash", "")), "decoration pre-consumption does not alter spatial embedding")
	_expect(str(baseline.get("runtime_topology_hash", "")) == str(preconsumed.get("runtime_topology_hash", "")), "decoration pre-consumption does not alter runtime topology")


func _build_generated_runtime(run_seed: int, sector_index: int, consume_decoration_first: bool = false) -> Dictionary:
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	var semantic_generator := _load_script(SEMANTIC_GENERATOR_PATH)
	var spatial_generator := _load_script(SPATIAL_GENERATOR_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	var reconstructor := _load_script(RECONSTRUCTOR_PATH)
	var canonical := _load_script(CANONICAL_PATH)
	var rail_script := load(RAIL_PATH) as Script
	if request_script == null or context_script == null or semantic_generator == null or spatial_generator == null or validator == null or reconstructor == null or canonical == null or rail_script == null:
		return {}

	var request: RefCounted = request_script.create(
		run_seed,
		sector_index,
		"forward",
		"central_eu_v1",
		"central_eu_small_town_station_v1",
		GENERATOR_VERSION_9G
	)
	var context: RefCounted = context_script.create(request)
	if consume_decoration_first:
		var decoration_rng: RefCounted = context.make_rng("decoration")
		for _i in range(200):
			decoration_rng.next_int()

	var semantic_result: Dictionary = semantic_generator.generate_blueprint(context)
	_expect(bool(semantic_result.get("success", false)), "semantic generation succeeds for seed %d" % run_seed)
	if not bool(semantic_result.get("success", false)):
		printerr("Semantic diagnostics: %s" % str(semantic_result.get("diagnostics", [])))
		return {}
	var blueprint: RefCounted = semantic_result.get("blueprint", null)
	var semantic_trace: RefCounted = semantic_result.get("generation_trace", null)
	var validation: Dictionary = validator.validate_blueprint(blueprint)
	_expect(bool(validation.get("valid", false)), "semantic validation runs before spatial generation for seed %d" % run_seed)
	if not bool(validation.get("valid", false)):
		printerr("Semantic validation diagnostics: %s" % str(validation.get("diagnostics", [])))
		return {}

	var spatial_result: Dictionary = spatial_generator.generate_embedding(blueprint, context, semantic_trace)
	_expect(bool(spatial_result.get("success", false)), "spatial embedding generation succeeds for seed %d" % run_seed)
	if not bool(spatial_result.get("success", false)):
		printerr("Spatial diagnostics: %s" % str(spatial_result.get("diagnostics", [])))
		return {}
	var embedding := spatial_result.get("embedding", {}) as Dictionary
	var reconstruction: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	_expect(bool(reconstruction.get("valid", false)), "runtime reconstruction succeeds for generated seed %d" % run_seed)
	if not bool(reconstruction.get("valid", false)):
		printerr("Reconstruction diagnostics: %s" % str(reconstruction.get("diagnostics", [])))
		return {}

	var layout := reconstruction.get("layout", {}) as Dictionary
	var rail = rail_script.new()
	var configure_result: Dictionary = rail.configure_track_layout(layout)
	_expect(bool(configure_result.get("valid", false)), "RailMovement configures generated seed %d" % run_seed)
	if not bool(configure_result.get("valid", false)):
		printerr("RailMovement diagnostics: %s" % str(configure_result.get("diagnostics", [])))
		return {}

	return {
		"blueprint": blueprint,
		"semantic_trace": semantic_trace,
		"spatial_trace": spatial_result.get("generation_trace", null),
		"embedding": embedding,
		"embedding_hash": canonical.hash_dictionary(embedding),
		"spatial_decisions": (spatial_result.get("decisions", {}) as Dictionary).duplicate(true),
		"layout": layout,
		"rail": rail,
		"runtime_topology_hash": canonical.hash_dictionary(rail.get_runtime_topology_snapshot()),
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


func _drive_until_segment_no_teleport(rail: RefCounted, target_segment: String, max_seconds: float, label: String) -> void:
	var elapsed := 0.0
	var previous_position: Vector2 = rail.get_position()
	while elapsed < max_seconds and str(rail.current_segment) != target_segment:
		rail.step(0.1, false)
		var current_position: Vector2 = rail.get_position()
		_expect(previous_position.distance_to(current_position) <= 80.0, "%s has no visible teleport while driving" % label)
		previous_position = current_position
		elapsed += 0.1


func _drive_until_distance_no_teleport(rail: RefCounted, target_segment: String, target_distance: float, max_seconds: float, label: String) -> void:
	var elapsed := 0.0
	var previous_position: Vector2 = rail.get_position()
	while elapsed < max_seconds:
		if str(rail.current_segment) == target_segment and float(rail.distance) >= target_distance:
			return
		rail.step(0.1, false)
		var current_position: Vector2 = rail.get_position()
		_expect(previous_position.distance_to(current_position) <= 80.0, "%s has no visible teleport while driving" % label)
		previous_position = current_position
		elapsed += 0.1


func _trace_has_stage(trace_data: Dictionary, stage_name: String) -> bool:
	for raw_decision in trace_data.get("stage_decisions", []) as Array:
		if str((raw_decision as Dictionary).get("stage", "")) == stage_name:
			return true
	return false


func _trace_decision_stream(trace_data: Dictionary, key: String) -> String:
	for raw_decision in trace_data.get("stage_decisions", []) as Array:
		var decision := raw_decision as Dictionary
		if str(decision.get("key", "")) == key:
			return str(decision.get("stream", ""))
	return ""


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		_expect(false, "%s loads and can instantiate" % path)
		return null
	return script.new()


func _print_sample_summary(seed: int, result: Dictionary) -> void:
	var blueprint: RefCounted = result.get("blueprint", null)
	var trace: RefCounted = result.get("spatial_trace", null)
	var semantic_decisions := ((result.get("semantic_trace", null) as RefCounted).to_dictionary().get("stage_decisions", []) as Array)
	print("Sprint 9 closeout sample seed %d: blueprint=%s trace=%s embedding=%s spatial=%s semantic_decisions=%d" % [
		seed,
		str(blueprint.get_canonical_hash()),
		str(trace.get_canonical_hash()),
		str(result.get("embedding_hash", "")),
		str(result.get("spatial_decisions", {})),
		semantic_decisions.size(),
	])


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9 closeout generated runtime acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9 closeout generated runtime acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
