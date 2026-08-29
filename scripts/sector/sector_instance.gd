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
	if definition != null and definition.is_procedural() and not definition.runtime_layout.is_empty():
		var configure_result: Dictionary = rail.configure_track_layout(definition.runtime_layout)
		if not bool(configure_result.get("valid", false)):
			push_error("Generated sector runtime layout rejected: %s" % str(configure_result.get("diagnostics", [])))
		if rail.has_method("set_unit_type_map"):
			rail.set_unit_type_map(definition.rolling_stock_units)
		rail.detached_consists = definition.detached_consists.duplicate(true)
		if not definition.hazard_definitions.is_empty():
			for hazard in definition.hazard_definitions:
				var h_type := str(hazard.get("type", ""))
				var h_target := str(hazard.get("target_id", ""))
				var h_cond := str(hazard.get("condition", "damaged"))
				match h_type:
					"point", "turnout", "switch":
						if rail.has_method("set_point_condition"):
							rail.set_point_condition(h_target, h_cond)
					"track", "segment", "bridge":
						if rail.has_method("set_track_condition"):
							rail.set_track_condition(h_target, h_cond)
		if yard != null and yard.has_method("sync_points_from_rail_layout"):
			yard.sync_points_from_rail_layout()
	if definition != null and not definition.poi_definitions.is_empty():
		pois = SectorPOIs.new(definition.seed_value, definition.poi_definitions)
	else:
		pois = SectorPOIs.new(definition.seed_value)


func is_exit_crossed() -> bool:
	return not get_crossed_exit().is_empty()


func get_crossed_exit() -> Dictionary:
	if disposed or definition == null or rail == null:
		return {}
	if int(rail.direction) <= 0:
		return {}
	if float(rail.speed) <= 0.05:
		return {}

	for exit_state in _get_effective_route_exits():
		if str(rail.current_segment) == str(exit_state.get("segment", "")) \
				and float(rail.distance) >= float(exit_state.get("distance", 0.0)):
			return exit_state.duplicate(true)
	return {}


func get_route_exit_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	if definition == null or rail == null:
		return states
	for exit_state in _get_effective_route_exits():
		var segment_id := str(exit_state.get("segment", ""))
		var exit_distance := float(exit_state.get("distance", 0.0))
		var draw_state := exit_state.duplicate(true)
		draw_state["position"] = rail.get_point_on_segment(segment_id, exit_distance)
		draw_state["crossed"] = str(rail.current_segment) == segment_id and float(rail.distance) >= exit_distance
		states.append(draw_state)
	return states


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


func _get_effective_route_exits() -> Array[Dictionary]:
	var exits: Array[Dictionary] = []
	if definition == null:
		return exits
	for exit_state in definition.route_exits:
		exits.append(exit_state.duplicate(true))
	if not exits.is_empty():
		return exits
	exits.append({
		"id": "forward_exit",
		"route_id": "forward",
		"label": "Forward exit",
		"segment": definition.exit_segment,
		"distance": definition.exit_distance,
		"profile": "forward",
	})
	return exits
