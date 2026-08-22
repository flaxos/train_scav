extends RefCounted
class_name YardOperations

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

const POINT_P1 := "P1"
const POINT_P2 := "P2"
const POINT_P3 := "P3"

const MECHANICAL_OPERATIONAL := "operational"
const MECHANICAL_DAMAGED := "damaged"

const CONTROL_DAMAGED := "damaged"
const CONTROL_REPAIRED := "repaired"

const ROUTE_MAIN := "main"
const ROUTE_DIVERGING := "diverging"

const POINT_P1_ANCHOR := Vector2(512.0, 302.0)
const POINT_P2_TRACK_POSITION := Vector2(1320.0, 360.0)
const POINT_P2_ANCHOR := Vector2(1300.0, 332.0)
const POINT_P3_TRACK_POSITION := Vector2(1080.0, 515.0)
const POINT_P3_ANCHOR := Vector2(1045.0, 555.0)
const YARD_CONTROL_REPAIR_ANCHOR := Vector2(365.0, 585.0)
const YARD_POWER_ANCHOR := Vector2(420.0, 585.0)
const SHUNTER_REPAIR_ANCHOR := Vector2(1550.0, 252.0)

var rail: RefCounted
var yard_control_condition: String = CONTROL_DAMAGED
var yard_power_connected: bool = false
var last_status: String = "Yard control offline"

var points: Dictionary = {
	POINT_P1: {
		"id": POINT_P1,
		"name": "Points A",
		"mechanical_state": MECHANICAL_OPERATIONAL,
		"remote_capable": false,
		"route": RailMovement.POINTS_SIDING,
		"anchor": POINT_P1_ANCHOR,
		"rail_authority": true,
	},
	POINT_P2: {
		"id": POINT_P2,
		"name": "Points B",
		"mechanical_state": MECHANICAL_OPERATIONAL,
		"remote_capable": false,
		"route": RailMovement.POINTS_MAIN,
		"anchor": POINT_P2_ANCHOR,
		"track_position": POINT_P2_TRACK_POSITION,
		"rail_authority": true,
	},
	POINT_P3: {
		"id": POINT_P3,
		"name": "Yard Ladder P3",
		"mechanical_state": MECHANICAL_DAMAGED,
		"remote_capable": false,
		"route": RailMovement.POINTS_SIDING,
		"anchor": POINT_P3_ANCHOR,
		"track_position": POINT_P3_TRACK_POSITION,
		"rail_authority": true,
	},
}


func _init(rail_model: RefCounted = null) -> void:
	if rail_model == null:
		rail = RailMovement.new()
	else:
		rail = rail_model

	_sync_p1_from_rail()
	_sync_p2_from_rail()
	_sync_p3_from_rail()


func get_point_ids() -> Array[String]:
	var ids: Array[String] = []
	for point_id in points.keys():
		ids.append(str(point_id))
	return ids


func get_point_state(point_id: String) -> Dictionary:
	if not points.has(point_id):
		return {}

	if point_id == POINT_P1:
		_sync_p1_from_rail()
	elif point_id == POINT_P2:
		_sync_p2_from_rail()
	elif point_id == POINT_P3:
		_sync_p3_from_rail()

	var state: Dictionary = points[point_id].duplicate(true)
	state["occupied"] = is_point_occupied(point_id)
	state["manual_available"] = str(state.get("mechanical_state", "")) == MECHANICAL_OPERATIONAL
	state["remote_available"] = can_remote_operate_point(point_id)
	return state


func get_point_anchor(point_id: String) -> Vector2:
	var state := get_point_state(point_id)
	if state.is_empty():
		return Vector2.ZERO
	return state.get("anchor", Vector2.ZERO) as Vector2


func manual_operate_point(point_id: String) -> bool:
	if not _validate_point_can_move(point_id):
		return false

	if point_id == POINT_P1:
		if not rail.request_points_toggle():
			last_status = rail.blocked_reason
			return false
		_sync_p1_from_rail()
		last_status = "Manually operated %s to %s" % [point_id, str(points[point_id]["route"])]
		return true
	if point_id == POINT_P2 or point_id == POINT_P3:
		if not rail.request_yard_point_toggle(point_id):
			last_status = rail.blocked_reason
			return false
		if point_id == POINT_P2:
			_sync_p2_from_rail()
		else:
			_sync_p3_from_rail()
		last_status = "Manually operated %s to %s" % [point_id, str(points[point_id]["route"])]
		return true

	_toggle_stored_point_route(point_id)
	last_status = "Manually operated %s to %s" % [point_id, str(points[point_id]["route"])]
	return true


func remote_operate_point(point_id: String) -> bool:
	if not points.has(point_id):
		last_status = "Unknown point"
		return false
	last_status = "Remote switch control unavailable in this UAT"
	return false


func repair_point(point_id: String) -> bool:
	if not points.has(point_id):
		last_status = "Unknown point"
		return false

	points[point_id]["mechanical_state"] = MECHANICAL_OPERATIONAL
	last_status = "%s repaired" % point_id
	return true


func is_point_occupied(point_id: String) -> bool:
	if point_id == POINT_P1 and rail.has_method("is_switch_occupied"):
		return rail.is_switch_occupied()
	if (point_id == POINT_P2 or point_id == POINT_P3) and rail.has_method("is_yard_point_occupied"):
		return rail.is_yard_point_occupied(point_id)
	return false


func can_remote_operate_point(point_id: String) -> bool:
	if not points.has(point_id):
		return false
	return false


func repair_yard_control() -> bool:
	yard_control_condition = CONTROL_REPAIRED
	last_status = "Yard control repaired"
	return true


func connect_power() -> bool:
	yard_power_connected = true
	last_status = "Yard auxiliary power connected"
	return true


func disconnect_power() -> bool:
	yard_power_connected = false
	last_status = "Yard auxiliary power disconnected"
	return true


func is_remote_control_available() -> bool:
	return false


func get_yard_control_state() -> Dictionary:
	return {
		"condition": yard_control_condition,
		"powered": yard_power_connected,
		"remote_control": is_remote_control_available(),
		"repair_anchor": YARD_CONTROL_REPAIR_ANCHOR,
		"power_anchor": YARD_POWER_ANCHOR,
	}


func get_shunter_state() -> Dictionary:
	return {
		"id": "S",
		"condition": rail.get_powered_unit_condition("S"),
		"powered_unit": rail.is_powered_unit("S"),
		"controllable": rail.get_powered_unit_condition("S") == RailMovement.CONDITION_OPERATIONAL,
		"repair_anchor": SHUNTER_REPAIR_ANCHOR,
	}


func repair_shunter() -> bool:
	if not rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL):
		last_status = "Shunter missing"
		return false

	last_status = "Shunter repaired"
	return true


func get_repair_anchor(target_type: String, target_id: String = "") -> Vector2:
	match target_type:
		"shunter":
			return SHUNTER_REPAIR_ANCHOR
		"yard_control":
			return YARD_CONTROL_REPAIR_ANCHOR
		"power":
			return YARD_POWER_ANCHOR
		"point":
			return get_point_anchor(target_id)
	return Vector2.ZERO


func get_interaction_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for point_id in get_point_ids():
		var point_state := get_point_state(point_id)
		states.append({
			"id": point_id,
			"type": "yard_point",
			"position": point_state.get("anchor", Vector2.ZERO),
			"mechanical_state": str(point_state.get("mechanical_state", "")),
			"remote_capable": bool(point_state.get("remote_capable", false)),
			"remote_available": bool(point_state.get("remote_available", false)),
			"occupied": bool(point_state.get("occupied", false)),
		})

	states.append({
		"id": "yard_control",
		"type": "repair_yard_control",
		"position": YARD_CONTROL_REPAIR_ANCHOR,
		"condition": yard_control_condition,
	})
	states.append({
		"id": "yard_power",
		"type": "connect_power",
		"position": YARD_POWER_ANCHOR,
		"powered": yard_power_connected,
	})
	states.append({
		"id": "shunter",
		"type": "repair_shunter",
		"position": SHUNTER_REPAIR_ANCHOR,
		"condition": rail.get_powered_unit_condition("S"),
	})
	return states


func get_yard_track_draw_segments() -> Array[Dictionary]:
	# These short overrun/apron pieces continue the two modeled P3 routes to clear
	# buffered ends. The actual route choice and train movement are authoritative
	# RailMovement segments; these are presentation-only continuations.
	return [
		{
			"id": "storage_overrun",
			"points": [Vector2(1560.0, 545.0), Vector2(1640.0, 540.0)],
			"label": "Storage headshunt",
			"end_condition": "buffer",
		},
		{
			"id": "repair_apron",
			"points": [Vector2(1500.0, 580.0), Vector2(1600.0, 580.0)],
			"label": "Repair apron",
			"end_condition": "buffer",
		},
	]


func get_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Yard control: %s power %s remote %s" % [
		yard_control_condition,
		_format_bool(yard_power_connected),
		_format_bool(is_remote_control_available()),
	])
	var shunter := get_shunter_state()
	lines.append("Shunter S: %s controllable %s" % [
		str(shunter.get("condition", "")),
		_format_bool(bool(shunter.get("controllable", false))),
	])
	for point_id in get_point_ids():
		var state := get_point_state(point_id)
		lines.append("%s mech %s route %s remote %s occupied %s" % [
			point_id,
			str(state.get("mechanical_state", "")),
			str(state.get("route", "")),
			_format_bool(bool(state.get("remote_available", false))),
			_format_bool(bool(state.get("occupied", false))),
		])
	lines.append("Yard status: %s" % last_status)
	return lines


func _validate_point_can_move(point_id: String) -> bool:
	if not points.has(point_id):
		last_status = "Unknown point"
		return false
	if str(points[point_id].get("mechanical_state", "")) != MECHANICAL_OPERATIONAL:
		last_status = "%s damaged" % point_id
		return false
	if is_point_occupied(point_id):
		last_status = "%s occupied" % point_id
		return false
	return true


func _toggle_stored_point_route(point_id: String) -> void:
	if str(points[point_id].get("route", ROUTE_MAIN)) == ROUTE_MAIN:
		points[point_id]["route"] = ROUTE_DIVERGING
	else:
		points[point_id]["route"] = ROUTE_MAIN


func _sync_p1_from_rail() -> void:
	if not points.has(POINT_P1):
		return
	points[POINT_P1]["route"] = rail.points_route


func _sync_p2_from_rail() -> void:
	if not points.has(POINT_P2):
		return
	if not rail.has_method("get_yard_point_route"):
		return
	points[POINT_P2]["route"] = rail.get_yard_point_route(POINT_P2)


func _sync_p3_from_rail() -> void:
	if not points.has(POINT_P3):
		return
	if not rail.has_method("get_yard_point_route"):
		return
	points[POINT_P3]["route"] = rail.get_yard_point_route(POINT_P3)


func _format_bool(value: bool) -> String:
	if value:
		return "yes"
	return "no"
