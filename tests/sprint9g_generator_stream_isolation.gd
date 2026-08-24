extends SceneTree

const GENERATOR_PATH := "res://scripts/worldgen/worldgen_semantic_generator.gd"
const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const CONTEXT_PATH := "res://scripts/worldgen/worldgen_generation_context.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const GENERATOR_VERSION_9G := "9g_village_passing_station_semantic_v1"

var _failures: int = 0


class ContextWithPreexistingDecision:
	extends RefCounted

	var inner: RefCounted

	func _init(wrapped_context: RefCounted) -> void:
		inner = wrapped_context

	func is_valid() -> bool:
		return inner.is_valid()

	func get_diagnostics() -> Array[Dictionary]:
		return inner.get_diagnostics()

	func get_identity() -> Dictionary:
		return inner.get_identity()

	func make_rng(stream_name: String) -> RefCounted:
		return inner.make_rng(stream_name)

	func to_trace_dictionary() -> Dictionary:
		var trace: Dictionary = inner.to_trace_dictionary()
		trace["stage_decisions"] = [
			{
				"stage": "preexisting",
				"key": "upstream_decision",
				"value": "kept",
				"stream": "fixed",
			},
		]
		return trace


func _init() -> void:
	print("\n--- Starting Sprint 9G Generator Stream Isolation Tests ---")
	_required_files_exist()
	_external_stream_consumption_does_not_perturb_generation()
	_world_entity_stream_consumption_does_not_perturb_topology_owned_output()
	_existing_trace_decisions_are_appended_not_replaced()
	_semantic_generation_sweep_validates_and_varies()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(GENERATOR_PATH), "9G semantic generator exists")
	_expect(ResourceLoader.exists(REQUEST_PATH), "generation request exists")
	_expect(ResourceLoader.exists(CONTEXT_PATH), "generation context exists")
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "semantic validator exists")
	_expect(ResourceLoader.exists(CANONICAL_PATH), "canonical helper exists")


func _external_stream_consumption_does_not_perturb_generation() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var context := _make_context(200, 4)
	if generator == null or context == null:
		return

	var baseline: Dictionary = generator.generate_blueprint(context)
	var preconsumed_context := _make_context(200, 4)
	var decoration: RefCounted = preconsumed_context.make_rng("decoration")
	for _i in range(100):
		decoration.next_int()
	var after_decoration: Dictionary = generator.generate_blueprint(preconsumed_context)

	_expect(_blueprint_hash(baseline) == _blueprint_hash(after_decoration), "consuming decoration stream before generation does not alter generated blueprint")
	_expect(_trace_hash(baseline) == _trace_hash(after_decoration), "consuming decoration stream before generation does not alter generated trace")
	_expect(str(baseline.get("decisions", {})) == str(after_decoration.get("decisions", {})), "consuming decoration stream before generation does not alter decisions")


func _world_entity_stream_consumption_does_not_perturb_topology_owned_output() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var canonical := _load_script(CANONICAL_PATH)
	var context := _make_context(201, 3)
	if generator == null or canonical == null or context == null:
		return

	var baseline: Dictionary = generator.generate_blueprint(context)
	var preconsumed_context := _make_context(201, 3)
	var world_entities: RefCounted = preconsumed_context.make_rng("world_entities")
	for _i in range(100):
		world_entities.next_int()
	var after_world: Dictionary = generator.generate_blueprint(preconsumed_context)
	_expect(_rail_graph_hash(canonical, baseline) == _rail_graph_hash(canonical, after_world), "external world_entities consumption does not alter generated rail topology hash")
	_expect(str((baseline.get("decisions", {}) as Dictionary).get("platform_track", "")) == str((after_world.get("decisions", {}) as Dictionary).get("platform_track", "")), "external world_entities consumption does not alter topology-owned platform decision")


func _existing_trace_decisions_are_appended_not_replaced() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var context := _make_context(202, 5)
	if generator == null or context == null:
		return

	var wrapped := ContextWithPreexistingDecision.new(context)
	var result: Dictionary = generator.generate_blueprint_from_context(wrapped)
	_expect(bool(result.get("success", false)), "generation succeeds with context that already has trace decisions")
	if not bool(result.get("success", false)):
		printerr("Diagnostics: %s" % str(result.get("diagnostics", [])))
		return
	var trace: RefCounted = result.get("generation_trace", null)
	var stage_decisions := (trace.to_dictionary().get("stage_decisions", []) as Array)
	_expect(stage_decisions.size() >= 4, "9G appends decisions after preexisting trace decision")
	_expect(str((stage_decisions[0] as Dictionary).get("key", "")) == "upstream_decision", "preexisting trace decision is preserved first")
	_expect((context.to_trace_dictionary().get("stage_decisions", []) as Array).is_empty(), "generator does not mutate original context trace")


func _semantic_generation_sweep_validates_and_varies() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	if generator == null or request_script == null or validator == null:
		return

	var signatures: Dictionary = {}
	for seed in range(100, 250):
		var result: Dictionary = generator.generate_blueprint(_make_request(request_script, seed, 0))
		_expect(bool(result.get("success", false)), "seed %d generation succeeds" % seed)
		if not bool(result.get("success", false)):
			printerr("Seed %d diagnostics: %s" % [seed, str(result.get("diagnostics", []))])
			continue
		var blueprint: RefCounted = result.get("blueprint", null)
		var validation: Dictionary = validator.validate_blueprint(blueprint)
		_expect(bool(validation.get("valid", false)), "seed %d validates through 9C" % seed)
		_expect(blueprint.has_rail_path(), "seed %d has active entry-to-exit path" % seed)
		_expect(blueprint.get_tracks_by_role("PASSING_LOOP").size() == 1, "seed %d has one passing loop" % seed)
		_expect(not blueprint.get_station().is_empty(), "seed %d has station semantics" % seed)
		_expect(blueprint.get_entities_by_type("PLATFORM").size() == 1, "seed %d has platform semantics" % seed)
		var decisions := result.get("decisions", {}) as Dictionary
		var signature := "%s/%s" % [str(decisions.get("platform_track", "")), str(decisions.get("road_access", ""))]
		signatures[signature] = true
	_expect(signatures.size() >= 2, "known 150-seed semantic sweep shows restrained deterministic variation")


func _make_context(run_seed: int, sector_index: int) -> RefCounted:
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if request_script == null or context_script == null:
		return null
	return context_script.create(_make_request(request_script, run_seed, sector_index))


func _make_request(request_script: RefCounted, run_seed: int, sector_index: int) -> RefCounted:
	return request_script.create(
		run_seed,
		sector_index,
		"forward",
		"central_eu_v1",
		"central_eu_small_town_station_v1",
		GENERATOR_VERSION_9G
	)


func _blueprint_hash(result: Dictionary) -> String:
	var blueprint: RefCounted = result.get("blueprint", null)
	if blueprint == null:
		return ""
	return str(blueprint.get_canonical_hash())


func _trace_hash(result: Dictionary) -> String:
	var trace: RefCounted = result.get("generation_trace", null)
	if trace == null:
		return ""
	return str(trace.get_canonical_hash())


func _rail_graph_hash(canonical: RefCounted, result: Dictionary) -> String:
	var blueprint: RefCounted = result.get("blueprint", null)
	if blueprint == null:
		return ""
	return canonical.hash_dictionary((blueprint.to_dictionary().get("rail_graph", {}) as Dictionary))


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
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
		print("\nSprint 9G generator stream isolation acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9G generator stream isolation acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
