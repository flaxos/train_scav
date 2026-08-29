extends RefCounted
class_name TrainInterior

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")

const KIND_LOCOMOTIVE := "locomotive"
const KIND_BUNK := "bunk"
const KIND_STORAGE := "storage"
const KIND_WORKSHOP := "workshop"
const KIND_SHUNTER := "shunter"
const KIND_EXTERNAL := "external"

const AISLE_HALF_WIDTH := 7.0
const BODY_INSET := 6.0
const DOOR_INSET := 7.0

var rail: RefCounted


func _init(rail_model: RefCounted) -> void:
	rail = rail_model


func dispose() -> void:
	rail = null


func get_unit_metadata(unit_id: String) -> Dictionary:
	if rail != null and rail.has_method("get_unit_definition"):
		var definition: Dictionary = rail.get_unit_definition(unit_id)
		if not definition.is_empty():
			return _metadata(
				str(definition.get("interior_kind", KIND_EXTERNAL)),
				str(definition.get("interior_label", "NO INTERIOR")),
				bool(definition.get("boardable", false)),
				bool(definition.get("gangway_front", false)),
				bool(definition.get("gangway_rear", false))
			)
	# Unknown future stock remains non-boardable/non-gangway until it receives
	# explicit catalogue metadata.
	return _metadata(KIND_EXTERNAL, "NO INTERIOR", false, false, false)


func _metadata(kind: String, label: String, boardable: bool, gangway_front: bool, gangway_rear: bool) -> Dictionary:
	return {
		"kind": kind,
		"label": label,
		"boardable": boardable,
		"gangway_front": gangway_front,
		"gangway_rear": gangway_rear,
	}


func get_unit_interior_kind(unit_id: String) -> String:
	return str(get_unit_metadata(unit_id).get("kind", KIND_EXTERNAL))


func get_unit_interior_label(unit_id: String) -> String:
	return str(get_unit_metadata(unit_id).get("label", "NO INTERIOR"))


func is_boardable_unit(unit_id: String) -> bool:
	return bool(get_unit_metadata(unit_id).get("boardable", false))


func has_front_gangway(unit_id: String) -> bool:
	return bool(get_unit_metadata(unit_id).get("gangway_front", false))


func has_rear_gangway(unit_id: String) -> bool:
	return bool(get_unit_metadata(unit_id).get("gangway_rear", false))


func is_walkable_unit(unit_id: String) -> bool:
	return is_boardable_unit(unit_id)


func get_walk_bounds(unit_id: String) -> Rect2:
	var length: float = float(rail.get_unit_length(unit_id))
	return Rect2(
		Vector2(-length * 0.5 + BODY_INSET, -AISLE_HALF_WIDTH),
		Vector2(maxf(length - BODY_INSET * 2.0, 1.0), AISLE_HALF_WIDTH * 2.0)
	)


func clamp_local_position(unit_id: String, local_position: Vector2) -> Vector2:
	var bounds := get_walk_bounds(unit_id)
	return Vector2(
		clampf(local_position.x, bounds.position.x, bounds.end.x),
		clampf(local_position.y, bounds.position.y, bounds.end.y)
	)


func get_front_door_local(unit_id: String) -> Vector2:
	return Vector2(rail.get_unit_length(unit_id) * 0.5 - DOOR_INSET, 0.0)


func get_rear_door_local(unit_id: String) -> Vector2:
	return Vector2(-rail.get_unit_length(unit_id) * 0.5 + DOOR_INSET, 0.0)


func get_consist_units_for(unit_id: String) -> Array[String]:
	if rail.has_method("get_consist_unit_ids_for"):
		return rail.get_consist_unit_ids_for(unit_id)
	return []


func can_walk_joint(front_unit: String, rear_unit: String) -> bool:
	# Rail consist order is physical front -> rear. Crossing this joint therefore
	# requires the front vehicle's rear gangway and the rear vehicle's front gangway.
	return has_rear_gangway(front_unit) and has_front_gangway(rear_unit)


func can_walk_between(from_unit: String, to_unit: String) -> bool:
	if from_unit == "" or to_unit == "":
		return false
	if not is_boardable_unit(from_unit) or not is_boardable_unit(to_unit):
		return false

	var units := get_consist_units_for(from_unit)
	var from_index := units.find(from_unit)
	var to_index := units.find(to_unit)
	if from_index < 0 or to_index < 0:
		return false
	if from_index == to_index:
		return true

	var start := mini(from_index, to_index)
	var finish := maxi(from_index, to_index)
	for index in range(start, finish):
		if not can_walk_joint(units[index], units[index + 1]):
			return false
	return true


func get_walk_path(from_unit: String, to_unit: String) -> Array[String]:
	var result: Array[String] = []
	if not can_walk_between(from_unit, to_unit):
		return result

	var units := get_consist_units_for(from_unit)
	var from_index := units.find(from_unit)
	var to_index := units.find(to_unit)
	var step := 1 if to_index >= from_index else -1
	var index := from_index
	while true:
		result.append(units[index])
		if index == to_index:
			break
		index += step
	return result


func get_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for unit_state in rail.get_unit_draw_states():
		var unit_id := str(unit_state.get("id", ""))
		var next_state: Dictionary = unit_state.duplicate(true)
		var metadata := get_unit_metadata(unit_id)
		next_state["interior_kind"] = str(metadata.get("kind", KIND_EXTERNAL))
		next_state["interior_label"] = str(metadata.get("label", "NO INTERIOR"))
		next_state["walkable"] = is_walkable_unit(unit_id)
		next_state["boardable"] = is_boardable_unit(unit_id)
		next_state["gangway_front"] = has_front_gangway(unit_id)
		next_state["gangway_rear"] = has_rear_gangway(unit_id)
		next_state["walk_bounds"] = get_walk_bounds(unit_id)
		states.append(next_state)
	return states
