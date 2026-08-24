extends RefCounted
class_name SectorDefinition

# Sprint 6A — Disposable sector definition / metadata model.
# Holds deterministic configuration for disposable sector templates.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

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
	if index == 1:
		def.route_exits = _create_industrial_route_exits()
	else:
		def.route_exits = _create_default_route_exits()
	return def


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
		},
		{
			"id": "industrial_exit",
			"route_id": "industrial",
			"label": "Industrial route",
			"summary": "More parts opportunity; higher operational risk later.",
			"profile": "industrial",
			"segment": RailMovement.SEGMENT_INDUSTRIAL_EXIT,
			"distance": 220.0,
		},
		{
			"id": "settlement_exit",
			"route_id": "settlement",
			"label": "Settlement route",
			"summary": "Possible recruit lead; safer supplies later.",
			"profile": "settlement",
			"segment": RailMovement.SEGMENT_SETTLEMENT_EXIT,
			"distance": 220.0,
		},
	]
