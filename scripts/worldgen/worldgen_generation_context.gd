extends RefCounted
class_name WorldgenGenerationContext

const WorldgenGenerationTrace := preload("res://scripts/worldgen/worldgen_generation_trace.gd")
const WorldgenRandomStream := preload("res://scripts/worldgen/worldgen_random_stream.gd")
const WorldgenSeedDerivation := preload("res://scripts/worldgen/worldgen_seed_derivation.gd")

const STREAM_ARCHETYPE := "archetype"
const STREAM_TOPOLOGY := "topology"
const STREAM_SPATIAL := "spatial"
const STREAM_TERRAIN := "terrain"
const STREAM_WORLD_ENTITIES := "world_entities"
const STREAM_POIS := "pois"
const STREAM_ROLLING_STOCK := "rolling_stock"
const STREAM_GAMEPLAY_PROBLEM := "gameplay_problem"
const STREAM_DECAY := "decay"
const STREAM_DECORATION := "decoration"

const STREAM_NAMES := [
	STREAM_ARCHETYPE,
	STREAM_TOPOLOGY,
	STREAM_SPATIAL,
	STREAM_TERRAIN,
	STREAM_WORLD_ENTITIES,
	STREAM_POIS,
	STREAM_ROLLING_STOCK,
	STREAM_GAMEPLAY_PROBLEM,
	STREAM_DECAY,
	STREAM_DECORATION,
]

var _identity: Dictionary = {}
var _stream_subseeds: Dictionary = {}
var _diagnostics: Array[Dictionary] = []
var _trace: RefCounted


func _init(request: RefCounted = null) -> void:
	if request == null:
		_add_diagnostic("GENERATION_REQUEST_REQUIRED", "generation request is required")
		_trace = WorldgenGenerationTrace.new({})
		return
	if not request.has_method("is_valid") or not request.has_method("to_dictionary"):
		_add_diagnostic("GENERATION_REQUEST_INVALID", "generation request must expose is_valid and to_dictionary")
		_trace = WorldgenGenerationTrace.new({})
		return
	if not bool(request.is_valid()):
		_add_diagnostic("GENERATION_REQUEST_INVALID", "generation request is invalid")
		if request.has_method("get_diagnostics"):
			for diagnostic in request.get_diagnostics():
				_diagnostics.append((diagnostic as Dictionary).duplicate(true))
		_trace = WorldgenGenerationTrace.new({})
		return

	_identity = request.to_dictionary()
	_build_stream_subseeds()
	_trace = WorldgenGenerationTrace.new(_make_trace_dictionary())


func create(request: RefCounted) -> RefCounted:
	var script := get_script() as Script
	return script.new(request)


func is_valid() -> bool:
	return _diagnostics.is_empty()


func get_diagnostics() -> Array[Dictionary]:
	return _diagnostics.duplicate(true)


func get_identity() -> Dictionary:
	return _identity.duplicate(true)


func get_stream_names() -> Array[String]:
	var names: Array[String] = []
	for stream_name in STREAM_NAMES:
		names.append(str(stream_name))
	return names


func has_stream(stream_name: String) -> bool:
	return STREAM_NAMES.has(stream_name)


func get_stream_subseed(stream_name: String) -> int:
	return int(_stream_subseeds.get(stream_name, 0))


func make_rng(stream_name: String) -> RefCounted:
	var result := make_rng_result(stream_name)
	if not bool(result.get("valid", false)):
		return null
	return result.get("rng", null) as RefCounted


func make_rng_result(stream_name: String) -> Dictionary:
	if not has_stream(stream_name):
		return {
			"valid": false,
			"rng": null,
			"diagnostics": [_make_diagnostic("UNKNOWN_RNG_STREAM", "unknown RNG stream %s" % stream_name, {"stream_name": stream_name})],
		}
	if not is_valid():
		return {
			"valid": false,
			"rng": null,
			"diagnostics": get_diagnostics(),
		}
	return {
		"valid": true,
		"rng": WorldgenRandomStream.new(get_stream_subseed(stream_name)),
		"diagnostics": [],
	}


func get_generation_trace() -> RefCounted:
	return _trace


func to_trace_dictionary() -> Dictionary:
	if _trace == null:
		return {}
	return _trace.to_dictionary()


func _build_stream_subseeds() -> void:
	var derivation := WorldgenSeedDerivation.new()
	for stream_name in STREAM_NAMES:
		_stream_subseeds[str(stream_name)] = derivation.derive_subseed(_identity, str(stream_name))


func _make_trace_dictionary() -> Dictionary:
	return {
		"trace_version": WorldgenGenerationTrace.TRACE_VERSION,
		"run_seed": int(_identity.get("run_seed", 0)),
		"sector_index": int(_identity.get("sector_index", 0)),
		"route_profile": str(_identity.get("route_profile", "")),
		"region_pack": str(_identity.get("region_pack", "")),
		"grammar_version": str(_identity.get("grammar_version", "")),
		"generator_version": str(_identity.get("generator_version", "")),
		"stream_subseeds": _stream_subseeds.duplicate(true),
		"stage_decisions": [],
	}


func _add_diagnostic(code: String, message: String, context: Dictionary = {}) -> void:
	_diagnostics.append(_make_diagnostic(code, message, context))


func _make_diagnostic(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"message": message,
		"context": context.duplicate(true),
	}
