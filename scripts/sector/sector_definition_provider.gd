extends RefCounted
class_name SectorDefinitionProvider

const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")

const FIRST_PROCEDURAL_SECTOR_INDEX := 2

var last_diagnostics: Array[Dictionary] = []


func create_definition(run_seed: int, sector_index: int, route_profile: String = "") -> SectorDefinition:
	last_diagnostics.clear()
	if has_authored_definition(sector_index):
		return SectorDefinition.create_for_index(run_seed, sector_index)

	var profile := route_profile
	if profile.is_empty():
		profile = WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE
	var result := WorldgenProductionSectorGenerator.new().generate_sector(
		run_seed,
		sector_index,
		profile,
		WorldgenGenerationRequest.DEFAULT_REGION_PACK,
		WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION
	)
	if bool(result.get("success", false)):
		return result.get("sector_definition", null) as SectorDefinition

	last_diagnostics = (result.get("diagnostics", []) as Array).duplicate(true)
	push_error("Procedural sector generation failed for sector %d: %s" % [sector_index, str(last_diagnostics)])
	return null


func has_authored_definition(sector_index: int) -> bool:
	return sector_index < FIRST_PROCEDURAL_SECTOR_INDEX


func get_handoff_index() -> int:
	return FIRST_PROCEDURAL_SECTOR_INDEX
