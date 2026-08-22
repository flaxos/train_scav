extends RefCounted
class_name SectorDefinition

# Sprint 6A — Disposable sector definition / metadata model.
# Holds deterministic configuration for disposable sector templates.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var sector_id: String = ""
var template_name: String = ""
var seed_value: int = 0
var sector_index: int = 0

var entry_segment: String = RailMovement.SEGMENT_MAIN_WEST
var entry_distance: float = 100.0
var exit_segment: String = RailMovement.SEGMENT_MAIN_EAST
var exit_distance: float = 750.0


static func create_for_index(run_seed: int, index: int) -> SectorDefinition:
	var def := new()
	def.sector_index = index
	if index == 0:
		def.template_name = "Sector A"
		def.seed_value = run_seed
		def.sector_id = "sector_a_%d" % run_seed
	else:
		def.template_name = "Sector B"
		def.seed_value = run_seed + index * 1000 + 7
		def.sector_id = "sector_b_%d_%d" % [index, def.seed_value]

	def.entry_segment = RailMovement.SEGMENT_MAIN_WEST
	def.entry_distance = 100.0
	def.exit_segment = RailMovement.SEGMENT_MAIN_EAST
	def.exit_distance = 750.0
	return def
