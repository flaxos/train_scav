extends RefCounted
class_name SectorDefinition

# Sprint 6A — Disposable sector definition / metadata model.
# Holds deterministic configuration for disposable sector templates.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

const SOURCE_AUTHORED := "AUTHORED"
const SOURCE_PROCEDURAL := "PROCEDURAL"

var sector_id: String = ""
var template_name: String = ""
var seed_value: int = 0
var sector_index: int = 0
var display_name: String = ""
var entry_label: String = ""
var accent_color: Color = Color(0.35, 0.95, 0.85, 0.9)

var entry_segment: String = RailMovement.SEGMENT_MAIN_WEST
var entry_distance: float = 100.0
var exit_segment: String = RailMovement.SEGMENT_MAIN_EXIT
var exit_distance: float = 260.0
var route_exits: Array[Dictionary] = []

var source_type: String = SOURCE_AUTHORED
var archetype_id: String = ""
var generator_version: String = ""
var grammar_version: String = ""
var route_profile: String = ""
var region_pack: String = ""
var blueprint_hash: String = ""
var generation_trace_hash: String = ""
var spatial_embedding_hash: String = ""
var runtime_topology_hash: String = ""
var poi_signature: String = ""
var rolling_stock_signature: String = ""
var runtime_layout: Dictionary = {}
var route_presets: Array[Dictionary] = []
var poi_definitions: Array[Dictionary] = []
var detached_consists: Array[Dictionary] = []
var rolling_stock_units: Dictionary = {}
var hazard_definitions: Array[Dictionary] = []
var worldgen_summary: Dictionary = {}


static func create_for_index(run_seed: int, index: int) -> SectorDefinition:
	var def := new()
	def.sector_index = index
	if index == 0:
		def.template_name = "Sector A"
		def.display_name = "Sector 0: Departure Yard"
		def.entry_label = "Sector 0 start"
		def.accent_color = Color(0.35, 0.95, 0.85, 0.9)
		def.seed_value = run_seed
		def.sector_id = "sector_a_%d" % run_seed
	else:
		def.template_name = "Sector B"
		def.display_name = "Sector %d: Forward Industrial Yard" % index
		def.entry_label = "Sector %d entry - no return" % index
		def.accent_color = Color(0.96, 0.67, 0.24, 0.92)
		def.seed_value = run_seed + index * 1000 + 7
		def.sector_id = "sector_b_%d_%d" % [index, def.seed_value]

	def.entry_segment = RailMovement.SEGMENT_MAIN_WEST
	def.entry_distance = 100.0
	def.exit_segment = RailMovement.SEGMENT_MAIN_EXIT
	def.exit_distance = 260.0
	def.source_type = SOURCE_AUTHORED
	if index == 1:
		def.route_exits = _create_industrial_route_exits()
	else:
		def.route_exits = _create_default_route_exits()
	return def


static func from_procedural_result(result: Dictionary) -> SectorDefinition:
	var def := new()
	def.source_type = SOURCE_PROCEDURAL
	def.sector_index = int(result.get("sector_index", 0))
	def.seed_value = int(result.get("sector_seed", 0))
	def.archetype_id = str(result.get("archetype_id", ""))
	def.generator_version = str(result.get("generator_version", ""))
	def.grammar_version = str(result.get("grammar_version", ""))
	def.route_profile = str(result.get("route_profile", ""))
	def.region_pack = str(result.get("region_pack", ""))
	def.blueprint_hash = str(result.get("blueprint_hash", ""))
	def.generation_trace_hash = str(result.get("generation_trace_hash", ""))
	def.spatial_embedding_hash = str(result.get("spatial_embedding_hash", ""))
	def.runtime_topology_hash = str(result.get("runtime_topology_hash", ""))
	def.poi_signature = str(result.get("poi_signature", ""))
	def.rolling_stock_signature = str(result.get("rolling_stock_signature", ""))
	def.runtime_layout = (result.get("layout", {}) as Dictionary).duplicate(true)
	def.route_presets.assign((def.runtime_layout.get("route_presets", []) as Array).duplicate(true))
	def.poi_definitions.assign((result.get("poi_definitions", []) as Array).duplicate(true))
	def.detached_consists.assign((result.get("detached_consists", []) as Array).duplicate(true))
	def.rolling_stock_units = (result.get("rolling_stock_units", {}) as Dictionary).duplicate(true)
	def.hazard_definitions.assign((result.get("hazard_definitions", []) as Array).duplicate(true))
	def.worldgen_summary = (result.get("summary", {}) as Dictionary).duplicate(true)
	def.entry_segment = str(def.runtime_layout.get("entry_segment", ""))
	def.entry_distance = float(def.runtime_layout.get("entry_distance", 0.0))
	def.exit_segment = str(def.runtime_layout.get("exit_segment", ""))
	def.exit_distance = float(def.runtime_layout.get("exit_distance", 0.0))
	var custom_exits := result.get("route_exits", []) as Array
	if not custom_exits.is_empty():
		def.route_exits.assign(custom_exits.duplicate(true))
	else:
		def.route_exits = _create_generated_route_exits(def.exit_segment, def.exit_distance)
	def.template_name = _template_name_for_archetype(def.archetype_id)
	def.display_name = "Sector %d: %s" % [def.sector_index, _display_name_for_archetype(def.archetype_id)]
	def.entry_label = "Sector %d procedural entry" % def.sector_index
	def.accent_color = _accent_color_for_archetype(def.archetype_id)
	def.sector_id = "procedural_%s_%d_%s" % [
		def.archetype_id,
		def.sector_index,
		def.blueprint_hash.substr(0, 10),
	]
	return def


func is_procedural() -> bool:
	return source_type == SOURCE_PROCEDURAL


func get_worldgen_debug_state() -> Dictionary:
	return {
		"source_type": source_type,
		"archetype_id": archetype_id,
		"generator_version": generator_version,
		"grammar_version": grammar_version,
		"route_profile": route_profile,
		"region_pack": region_pack,
		"blueprint_hash": blueprint_hash,
		"generation_trace_hash": generation_trace_hash,
		"spatial_embedding_hash": spatial_embedding_hash,
		"runtime_topology_hash": runtime_topology_hash,
		"poi_signature": poi_signature,
		"rolling_stock_signature": rolling_stock_signature,
		"rolling_stock_units": rolling_stock_units.duplicate(true),
		"hazard_definitions": hazard_definitions.duplicate(true),
	}


func get_route_exit(exit_id: String) -> Dictionary:
	for exit_def in route_exits:
		if str(exit_def.get("id", "")) == exit_id or str(exit_def.get("route_id", "")) == exit_id:
			return exit_def.duplicate(true)
	return {}


func get_route_exit_for_segment(segment_id: String) -> Dictionary:
	for exit_def in route_exits:
		if str(exit_def.get("segment", "")) == segment_id:
			return exit_def.duplicate(true)
	return {}


func get_route_exit_requirements(exit_id: String) -> Dictionary:
	var exit_def := get_route_exit(exit_id)
	return (exit_def.get("requirements", {}) as Dictionary).duplicate(true)


static func _create_default_route_exits() -> Array[Dictionary]:
	return [
		{
			"id": "forward_exit",
			"route_id": "forward",
			"label": "Forward exit",
			"summary": "Continue to the next sector.",
			"profile": "forward",
			"segment": RailMovement.SEGMENT_MAIN_EXIT,
			"distance": 260.0,
			"requirements": {
				"require_traction": true,
			},
		},
	]


static func _create_industrial_route_exits() -> Array[Dictionary]:
	return [
		{
			"id": "direct_exit",
			"route_id": "direct",
			"label": "Direct route",
			"summary": "Cheaper and faster; fewer opportunities.",
			"profile": "direct",
			"segment": RailMovement.SEGMENT_MAIN_EXIT,
			"distance": 260.0,
			"requirements": {
				"max_mass": 250.0,
				"require_traction": true,
			},
		},
		{
			"id": "industrial_exit",
			"route_id": "industrial",
			"label": "Industrial route",
			"summary": "More parts opportunity; higher operational risk later.",
			"profile": "industrial",
			"segment": RailMovement.SEGMENT_INDUSTRIAL_EXIT,
			"distance": 220.0,
			"requirements": {
				"max_mass": 320.0,
				"require_traction": true,
				"required_capabilities": ["workshop"],
			},
		},
		{
			"id": "settlement_exit",
			"route_id": "settlement",
			"label": "Settlement route",
			"summary": "Possible recruit lead; safer supplies later.",
			"profile": "settlement",
			"segment": RailMovement.SEGMENT_SETTLEMENT_EXIT,
			"distance": 220.0,
			"requirements": {
				"max_length": 300.0,
				"require_traction": true,
				"required_capabilities": ["crew_accommodation"],
			},
		},
	]


static func _create_generated_route_exits(exit_segment_id: String, exit_at_distance: float) -> Array[Dictionary]:
	return [
		{
			"id": "forward_exit",
			"route_id": "forward",
			"label": "Procedural forward exit",
			"summary": "Continue to the next procedural sector.",
			"profile": "forward",
			"segment": exit_segment_id,
			"distance": exit_at_distance,
			"requirements": {
				"require_traction": true,
			},
		},
	]


static func _template_name_for_archetype(archetype: String) -> String:
	match archetype:
		"rural_through":
			return "Procedural Rural Through"
		"village_passing_station":
			return "Procedural Village Passing"
		"small_town_goods":
			return "Procedural Small-Town Goods"
		"agricultural_loading_point":
			return "Procedural Agricultural Loading"
		"river_valley_constrained":
			return "Procedural River Valley"
		"declining_abandoned_branch":
			return "Procedural Declining Branch"
	return "Procedural Sector"


static func _display_name_for_archetype(archetype: String) -> String:
	match archetype:
		"rural_through":
			return "Rural Through"
		"village_passing_station":
			return "Village Passing Station"
		"small_town_goods":
			return "Small-Town Goods Sector"
		"agricultural_loading_point":
			return "Agricultural Loading Point"
		"river_valley_constrained":
			return "River-Valley Constrained Sector"
		"declining_abandoned_branch":
			return "Declining Abandoned Branch"
	return "Procedural Sector"


static func _accent_color_for_archetype(archetype: String) -> Color:
	match archetype:
		"rural_through":
			return Color(0.55, 0.72, 0.50, 0.92)
		"village_passing_station":
			return Color(0.42, 0.70, 0.95, 0.92)
		"small_town_goods":
			return Color(0.96, 0.67, 0.24, 0.92)
		"agricultural_loading_point":
			return Color(0.64, 0.82, 0.36, 0.92)
		"river_valley_constrained":
			return Color(0.32, 0.76, 0.82, 0.92)
		"declining_abandoned_branch":
			return Color(0.78, 0.62, 0.46, 0.92)
	return Color(0.35, 0.95, 0.85, 0.9)
