extends RefCounted
class_name SectorInstance

# Sprint 6A — Disposable sector instance model.
# Owns sector-local rail movement and yard operations state.
# Is marked disposed when transition out occurs.

const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")

var definition: SectorDefinition
var rail: RefCounted
var yard: RefCounted
var disposed: bool = false


func _init(sec_def: SectorDefinition, rail_model: RefCounted = null, yard_model: RefCounted = null) -> void:
	definition = sec_def
	if rail_model == null:
		rail = RailMovement.new()
	else:
		rail = rail_model

	if yard_model == null:
		yard = YardOperations.new(rail)
	else:
		yard = yard_model


func is_exit_crossed() -> bool:
	if disposed or definition == null or rail == null:
		return false
	return str(rail.current_segment) == definition.exit_segment and float(rail.distance) >= definition.exit_distance


func dispose() -> void:
	if disposed:
		return
	disposed = true
	rail = null
	yard = null
