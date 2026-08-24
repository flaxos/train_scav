extends SceneTree

const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const CONTEXT_PATH := "res://scripts/worldgen/worldgen_generation_context.gd"
const TRACE_PATH := "res://scripts/worldgen/worldgen_generation_trace.gd"
const SEED_DERIVATION_PATH := "res://scripts/worldgen/worldgen_seed_derivation.gd"
const RANDOM_STREAM_PATH := "res://scripts/worldgen/worldgen_random_stream.gd"

const GOLDEN_TRACE_HASH := "c29825cacac716621dacb2a8cf7a5450eddb7645fbe49382d304df05bcb117a6"
const GOLDEN_SUBSEEDS := {
	"archetype": 238576771,
	"topology": 2064870995,
	"spatial": 2091214199,
	"terrain": 661731090,
	"world_entities": 1947510623,
	"pois": 789851001,
	"rolling_stock": 1781333302,
	"gameplay_problem": 1381368502,
	"decay": 855139671,
	"decoration": 250620168,
}

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9F Generation Context Tests ---")
	_required_files_exist()
	_generation_request_is_defensive_and_validated()
	_golden_trace_is_stable()
	_generation_identity_changes_subseeds_deliberately()
	_unknown_stream_fails_loudly()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(REQUEST_PATH), "generation request class exists")
	_expect(ResourceLoader.exists(CONTEXT_PATH), "generation context class exists")
	_expect(ResourceLoader.exists(TRACE_PATH), "generation trace class exists")
	_expect(ResourceLoader.exists(SEED_DERIVATION_PATH), "stable seed derivation class exists")
	_expect(ResourceLoader.exists(RANDOM_STREAM_PATH), "worldgen random stream class exists")


func _generation_request_is_defensive_and_validated() -> void:
	var request_script := _load_script(REQUEST_PATH)
	if request_script == null:
		return

	var request: RefCounted = request_script.create(12345, 7, "industrial", "central_eu_v1")
	_expect(request.is_valid(), "valid request accepts required generation identity")
	var identity: Dictionary = request.to_dictionary()
	identity["route_profile"] = "mutated"
	_expect(str(request.get_route_profile()) == "industrial", "request exposes defensive-copy identity data")

	var invalid_request: RefCounted = request_script.create(12345, -1, "", "", "", "")
	_expect(not invalid_request.is_valid(), "invalid request reports validation failure")
	_expect((invalid_request.get_diagnostics() as Array).size() >= 1, "invalid request carries diagnostics")


func _golden_trace_is_stable() -> void:
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if request_script == null or context_script == null:
		return

	var request: RefCounted = request_script.create(12345, 7, "industrial", "central_eu_v1")
	var first_context: RefCounted = context_script.create(request)
	var second_context: RefCounted = context_script.create(request)
	_expect(first_context.is_valid(), "golden context is valid")
	_expect(second_context.is_valid(), "recreated golden context is valid")

	for stream_name in GOLDEN_SUBSEEDS.keys():
		var expected := int(GOLDEN_SUBSEEDS[stream_name])
		_expect(first_context.get_stream_subseed(str(stream_name)) == expected, "%s subseed matches golden vector" % str(stream_name))
		_expect(second_context.get_stream_subseed(str(stream_name)) == expected, "%s subseed is stable across context recreation" % str(stream_name))

	var trace: RefCounted = first_context.get_generation_trace()
	_expect(str(trace.get_canonical_hash()) == GOLDEN_TRACE_HASH, "generation trace hash matches golden vector")
	_expect(str(second_context.get_generation_trace().get_canonical_hash()) == GOLDEN_TRACE_HASH, "recreated trace hash matches golden vector")

	var trace_dict: Dictionary = trace.to_dictionary()
	(trace_dict.get("stream_subseeds", {}) as Dictionary)["topology"] = 1
	_expect(trace.get_stream_subseed("topology") == int(GOLDEN_SUBSEEDS["topology"]), "trace exposes defensive-copy subseed data")
	_expect((trace.to_dictionary().get("stage_decisions", []) as Array).is_empty(), "9F trace contains no procedural stage decisions")

	print("Sprint 9F golden trace: %s" % str(trace.to_dictionary()))


func _generation_identity_changes_subseeds_deliberately() -> void:
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if request_script == null or context_script == null:
		return

	var base: RefCounted = context_script.create(request_script.create(12345, 7, "industrial", "central_eu_v1"))
	var different_sector: RefCounted = context_script.create(request_script.create(12345, 8, "industrial", "central_eu_v1"))
	var different_seed: RefCounted = context_script.create(request_script.create(54321, 7, "industrial", "central_eu_v1"))
	var different_version: RefCounted = context_script.create(request_script.create(
		12345,
		7,
		"industrial",
		"central_eu_v1",
		"central_eu_small_town_station_v1",
		"9f_deterministic_worldgen_infra_v2"
	))

	_expect(base.get_stream_subseed("topology") != different_sector.get_stream_subseed("topology"), "sector_index changes topology subseed")
	_expect(base.get_stream_subseed("topology") != different_seed.get_stream_subseed("topology"), "run_seed changes topology subseed")
	_expect(base.get_stream_subseed("topology") != different_version.get_stream_subseed("topology"), "generator_version changes topology subseed")
	_expect(str(base.get_generation_trace().get_canonical_hash()) != str(different_version.get_generation_trace().get_canonical_hash()), "generator_version changes trace identity")


func _unknown_stream_fails_loudly() -> void:
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if request_script == null or context_script == null:
		return

	var context: RefCounted = context_script.create(request_script.create(12345, 7, "industrial", "central_eu_v1"))
	_expect(not context.has_stream("not_a_stream"), "unknown stream name is not accepted")
	var result: Dictionary = context.make_rng_result("not_a_stream")
	_expect(not bool(result.get("valid", true)), "unknown stream make_rng_result fails")
	_expect(_has_diagnostic_code(result, "UNKNOWN_RNG_STREAM"), "unknown stream reports diagnostic code")
	_expect(context.make_rng("not_a_stream") == null, "unknown stream make_rng returns null")


func _has_diagnostic_code(result: Dictionary, code: String) -> bool:
	for diagnostic in result.get("diagnostics", []) as Array:
		if str((diagnostic as Dictionary).get("code", "")) == code:
			return true
	return false


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
		print("\nSprint 9F generation context acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9F generation context acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
