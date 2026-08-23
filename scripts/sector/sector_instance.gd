extends RefCounted
class_name SectorInstance

# Sprint 6A — Disposable sector instance model.
# Owns sector-local rail movement and yard operations state.
# Is marked disposed when transition out occurs.

const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const SectorPOIs := preload("res://scripts/sector/sector_pois.gd")

var definition: SectorDefinition
var rail: RefCounted
var yard: RefCounted
var pois: RefCounted
var elapsed_time: float = 0.0
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
	pois = SectorPOIs.new(definition.seed_value)


func is_exit_crossed() -> bool:
	if disposed or definition == null or rail == null:
		return false
	if int(rail.direction) <= 0:
		return false
	if float(rail.speed) <= 0.05:
		return false
	return str(rail.current_segment) == definition.exit_segment and float(rail.distance) >= definition.exit_distance


func step(delta: float) -> void:
	if disposed:
		return
	elapsed_time += maxf(delta, 0.0)


func get_elapsed_time() -> float:
	return elapsed_time


func get_poi_states() -> Array[Dictionary]:
	if pois == null:
		return []
	return pois.get_poi_states()


func get_poi_state(poi_id: String) -> Dictionary:
	if pois == null:
		return {}
	return pois.get_poi_state(poi_id)


func search_poi(poi_id: String) -> bool:
	if pois == null:
		return false
	return pois.search_poi(poi_id)


func dispose() -> void:
	if disposed:
		return
	disposed = true
	rail = null
	yard = null
	pois = null
