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
	return def
