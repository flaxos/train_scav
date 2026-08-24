extends RefCounted
class_name WorldgenGenerationRequest

const DEFAULT_ROUTE_PROFILE := "forward"
const DEFAULT_REGION_PACK := "central_eu_v1"
const DEFAULT_GRAMMAR_VERSION := "central_eu_small_town_station_v1"
const DEFAULT_GENERATOR_VERSION := "9f_deterministic_worldgen_infra_v1"

var _identity: Dictionary = {}
var _diagnostics: Array[Dictionary] = []


func _init(
	run_seed: int = 0,
	sector_index: int = 0,
	route_profile: String = DEFAULT_ROUTE_PROFILE,
	region_pack: String = DEFAULT_REGION_PACK,
	grammar_version: String = DEFAULT_GRAMMAR_VERSION,
	generator_version: String = DEFAULT_GENERATOR_VERSION
) -> void:
	_identity = {
		"run_seed": run_seed,
		"sector_index": sector_index,
		"route_profile": route_profile,
		"region_pack": region_pack,
		"grammar_version": grammar_version,
		"generator_version": generator_version,
	}
	_validate()


func create(
	run_seed: int,
	sector_index: int,
	route_profile: String = DEFAULT_ROUTE_PROFILE,
	region_pack: String = DEFAULT_REGION_PACK,
	grammar_version: String = DEFAULT_GRAMMAR_VERSION,
	generator_version: String = DEFAULT_GENERATOR_VERSION
) -> RefCounted:
	var script := get_script() as Script
	return script.new(
		run_seed,
		sector_index,
		route_profile,
		region_pack,
		grammar_version,
		generator_version
	)


func is_valid() -> bool:
	return _diagnostics.is_empty()


func get_diagnostics() -> Array[Dictionary]:
	return _diagnostics.duplicate(true)


func to_dictionary() -> Dictionary:
	return _identity.duplicate(true)


func get_run_seed() -> int:
	return int(_identity.get("run_seed", 0))


func get_sector_index() -> int:
	return int(_identity.get("sector_index", 0))


func get_route_profile() -> String:
	return str(_identity.get("route_profile", ""))


func get_region_pack() -> String:
	return str(_identity.get("region_pack", ""))


func get_grammar_version() -> String:
	return str(_identity.get("grammar_version", ""))


func get_generator_version() -> String:
	return str(_identity.get("generator_version", ""))


func _validate() -> void:
	_diagnostics.clear()
	if get_sector_index() < 0:
		_add_diagnostic("SECTOR_INDEX_INVALID", "sector_index must be zero or greater")
	if get_route_profile().is_empty():
		_add_diagnostic("ROUTE_PROFILE_REQUIRED", "route_profile is required")
	if get_region_pack().is_empty():
		_add_diagnostic("REGION_PACK_REQUIRED", "region_pack is required")
	if get_grammar_version().is_empty():
		_add_diagnostic("GRAMMAR_VERSION_REQUIRED", "grammar_version is required")
	if get_generator_version().is_empty():
		_add_diagnostic("GENERATOR_VERSION_REQUIRED", "generator_version is required")


func _add_diagnostic(code: String, message: String) -> void:
	_diagnostics.append({
		"code": code,
		"message": message,
		"context": _identity.duplicate(true),
	})
