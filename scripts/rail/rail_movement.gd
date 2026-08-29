extends RefCounted
class_name RailMovement

const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")

const SEGMENT_MAIN_WEST := "main_west"
const SEGMENT_MAIN_EAST := "main_east"
const SEGMENT_MAIN_EXIT := "main_exit"
const SEGMENT_SIDING := "siding"
const SEGMENT_SIDING_B := "siding_b"
const SEGMENT_YARD_STORAGE := "yard_storage"
const SEGMENT_YARD_REPAIR := "yard_repair"
const SEGMENT_INDUSTRIAL_EXIT := "industrial_exit"
const SEGMENT_SETTLEMENT_EXIT := "settlement_exit"

const POINTS_MAIN := "main"
const POINTS_SIDING := "siding"

const SWITCH_POSITION := Vector2(540.0, 360.0)
const COUPLER_GAP := 8.0
const COUPLING_RANGE := 24.0
const DEFAULT_SAFE_CONTACT_SPEED := 14.0
const SWITCH_OCCUPANCY_CLEARANCE := 42.0
const TRAILING_ROUTE_STOP_CLEARANCE := SWITCH_OCCUPANCY_CLEARANCE + 2.0
const SWITCH_OPERATOR_ANCHOR_OFFSET := Vector2(-28.0, -58.0)
const JOINT_OPERATOR_ANCHOR_OFFSET := 42.0
const CONTACT_NONE := "none"
const CONTACT_CONTROLLED := "controlled"
const CONTACT_IMPACT := "impact"
const CONDITION_OPERATIONAL := "operational"
const CONDITION_DAMAGED := "damaged"
const CONTACT_EPSILON := 0.01
const COUPLER_FRONT := "front"
const COUPLER_REAR := "rear"
const SEGMENT_STATUS_ACTIVE := "active"
const SEGMENT_STATUS_DISPLAY_ONLY := "display_only"

const UNIT_LOCOMOTIVE := "locomotive"
const UNIT_SHUNTER := "shunter"
const UNIT_FLATBED := "flatbed"
const UNIT_BOXCAR := "boxcar"
const UNIT_TANKER := "tanker"
const UNIT_WORKSHOP := "workshop"

const _UNIT_TYPES := {
	"L": UNIT_LOCOMOTIVE,
	"S": UNIT_SHUNTER,
	"A": UNIT_FLATBED,
	"B": UNIT_BOXCAR,
	"C": UNIT_TANKER,
	"W": UNIT_WORKSHOP,
}

const _UNIT_LABELS := {
	"L": "Loco",
	"S": "Yard Shunter",
	"A": "Flatbed A",
	"B": "Boxcar B",
	"C": "Tanker C",
	"W": "Workshop Wagon",
}

const _UNIT_LENGTHS := {
	"L": 64.0,
	"S": 54.0,
	"A": 56.0,
	"B": 56.0,
	"C": 52.0,
	"W": 60.0,
}

const _UNIT_MASSES := {
	"L": 90.0,
	"S": 62.0,
	"A": 35.0,
	"B": 42.0,
	"C": 50.0,
	"W": 48.0,
}

const _SIDING_C_CENTER_DISTANCE := 220.0
const _SIDING_WORKSHOP_CENTER_DISTANCE := 150.0
const _SHUNTER_CENTER_DISTANCE := 240.0

const _SEGMENT_POINTS := {
	SEGMENT_MAIN_WEST: [Vector2(160.0, 360.0), SWITCH_POSITION],
	SEGMENT_MAIN_EAST: [SWITCH_POSITION, Vector2(1320.0, 360.0)],
	SEGMENT_MAIN_EXIT: [Vector2(1320.0, 360.0), Vector2(1480.0, 360.0), Vector2(1760.0, 360.0)],
	SEGMENT_SIDING_B: [
		# P2 is a facing turnout from the eastbound main. The branch must
		# continue generally east as it diverges north; a branch that turns
		# immediately back west produces an impossible hairpin turnout.
		Vector2(1320.0, 360.0),
		Vector2(1360.0, 358.0),
		Vector2(1405.0, 352.0),
		Vector2(1450.0, 340.0),
		Vector2(1495.0, 324.0),
		Vector2(1540.0, 304.0),
		Vector2(1590.0, 282.0),
		Vector2(1640.0, 260.0),
	],
	SEGMENT_INDUSTRIAL_EXIT: [
		Vector2(1640.0, 260.0),
		Vector2(1740.0, 236.0),
		Vector2(1880.0, 224.0),
		Vector2(2020.0, 224.0),
	],
	SEGMENT_SIDING: [
		SWITCH_POSITION,
		Vector2(620.0, 368.0),
		Vector2(720.0, 398.0),
		Vector2(850.0, 455.0),
		Vector2(1080.0, 515.0),
	],
	# Sprint 4.5: P3 is now a real second-stage yard turnout. The P1 siding is
	# the yard lead; P3 fans that lead into two long, roughly parallel sidings.
	# This gives the prototype a recognisable railway-yard grammar and proves
	# switch -> switch topology without changing the accepted P2 workshop route.
	SEGMENT_YARD_STORAGE: [
		Vector2(1080.0, 515.0),
		Vector2(1180.0, 540.0),
		Vector2(1300.0, 552.0),
		Vector2(1430.0, 552.0),
		Vector2(1560.0, 545.0),
	],
	SEGMENT_SETTLEMENT_EXIT: [
		Vector2(1560.0, 545.0),
		Vector2(1680.0, 548.0),
		Vector2(1810.0, 570.0),
		Vector2(1950.0, 570.0),
	],
	SEGMENT_YARD_REPAIR: [
		Vector2(1080.0, 515.0),
		Vector2(1160.0, 555.0),
		Vector2(1260.0, 580.0),
		Vector2(1380.0, 585.0),
		Vector2(1500.0, 580.0),
	],
}

var current_segment: String = SEGMENT_MAIN_WEST
var distance: float = 336.0
var speed: float = 0.0
var throttle: float = 0.0
var direction: int = 1
var points_route: String = POINTS_MAIN
var yard_point_routes: Dictionary = {
	"P2": POINTS_MAIN,
	"P3": POINTS_SIDING,
}
var _runtime_layout_id: String = "default_authored_yard"
var _layout_primary_point_id: String = "P1"
var _layout_segment_points: Dictionary = {}
var _layout_segment_semantics: Dictionary = {}
var _layout_point_definitions: Dictionary = {}
var _layout_next_connections: Dictionary = {}
var _layout_previous_connections: Dictionary = {}
var _layout_endpoint_b_block_reasons: Dictionary = {}
# Track routing is directional: facing moves from a common leg consult the
# switch setting, while reverse/trailing moves follow the segment's structural
# connection back to its common leg. A live switch setting must never rewrite
# the path already occupied by rolling stock.
var brake_active: bool = false
var blocked_reason: String = ""
var condition_state: String = CONDITION_OPERATIONAL
var last_contact: Dictionary = {}
var controlled_locomotive_id: String = "L"
var controlled_power_unit_id: String = "L"
var powered_unit_conditions: Dictionary = {
	"L": CONDITION_OPERATIONAL,
	"S": CONDITION_DAMAGED,
}
var unit_type_overrides: Dictionary = {}
var active_units: Array[String] = ["L", "A", "B"]
var detached_consists: Array[Dictionary] = [
	{
		"units": ["C"],
		"segment": SEGMENT_SIDING,
		"distance": _SIDING_C_CENTER_DISTANCE,
	},
	{
		"units": ["W"],
		"segment": SEGMENT_SIDING_B,
		"distance": _SIDING_WORKSHOP_CENTER_DISTANCE,
	},
	{
		"units": ["S"],
		"segment": SEGMENT_SIDING_B,
		"distance": _SHUNTER_CENTER_DISTANCE,
	},
]

var max_speed: float = 150.0
var acceleration: float = 95.0
var brake_deceleration: float = 260.0
var coast_deceleration: float = 35.0
var safe_contact_speed: float = DEFAULT_SAFE_CONTACT_SPEED
var max_coupling_speed: float = DEFAULT_SAFE_CONTACT_SPEED


func _init() -> void:
	_apply_track_layout(_make_default_track_layout())


func step(delta: float, brake_active: bool) -> void:
	self.brake_active = brake_active
	blocked_reason = ""
	_update_speed(delta, brake_active)
	_advance(speed * float(direction) * delta)


func set_throttle(value: float) -> void:
	throttle = clampf(value, 0.0, 1.0)


func adjust_throttle(amount: float) -> void:
	set_throttle(throttle + amount)


func set_direction(value: int) -> bool:
	var next_direction := signi(value)
	if next_direction == 0:
		return false
	if not is_stopped():
		return false

	direction = next_direction
	return true


func reverse_direction() -> bool:
	return set_direction(-direction)


func configure_track_layout(layout: Dictionary) -> Dictionary:
	var diagnostics: Array[Dictionary] = []
	_validate_track_layout(layout, diagnostics)
	if not diagnostics.is_empty():
		return {
			"valid": false,
			"diagnostics": diagnostics,
		}

	_apply_track_layout(layout)
	current_segment = str(layout.get("entry_segment", current_segment))
	distance = float(layout.get("entry_distance", distance))
	speed = 0.0
	throttle = 0.0
	direction = 1
	blocked_reason = ""
	last_contact.clear()
	return {
		"valid": true,
		"diagnostics": [],
	}


func get_runtime_topology_snapshot() -> Dictionary:
	var segments: Dictionary = {}
	for raw_segment_id in _layout_segment_points.keys():
		var segment_id := str(raw_segment_id)
		var semantics := _layout_segment_semantics.get(segment_id, {}) as Dictionary
		segments[segment_id] = {
			"points": _vector_points_to_pairs(_get_segment_points(segment_id)),
			"semantic_edge_id": str(semantics.get("semantic_edge_id", "")),
			"semantic_role": str(semantics.get("semantic_role", "")),
			"runtime_status": str(semantics.get("runtime_status", SEGMENT_STATUS_ACTIVE)),
		}

	var points: Dictionary = {}
	for raw_point_id in _layout_point_definitions.keys():
		var point_id := str(raw_point_id)
		var definition := _layout_point_definitions[point_id] as Dictionary
		var position := definition.get("position", Vector2.ZERO) as Vector2
		points[point_id] = {
			"semantic_node_id": str(definition.get("semantic_node_id", "")),
			"position": [position.x, position.y],
			"routes": (definition.get("routes", []) as Array).duplicate(true),
			"route": get_point_route(point_id),
		}

	return {
		"layout_id": _runtime_layout_id,
		"segments": segments,
		"points": points,
		"next_connections": _layout_next_connections.duplicate(true),
		"previous_connections": _layout_previous_connections.duplicate(true),
	}


func get_segment_semantic_id(segment_id: String) -> String:
	var semantics := _layout_segment_semantics.get(segment_id, {}) as Dictionary
	return str(semantics.get("semantic_edge_id", ""))


func get_segment_semantic_role(segment_id: String) -> String:
	var semantics := _layout_segment_semantics.get(segment_id, {}) as Dictionary
	return str(semantics.get("semantic_role", ""))


func get_segment_runtime_status(segment_id: String) -> String:
	var semantics := _layout_segment_semantics.get(segment_id, {}) as Dictionary
	return str(semantics.get("runtime_status", SEGMENT_STATUS_ACTIVE))


func get_point_ids() -> Array[String]:
	var ids: Array[String] = []
	for raw_point_id in _layout_point_definitions.keys():
		ids.append(str(raw_point_id))
	ids.sort()
	return ids


func get_point_route(point_id: String) -> String:
	if point_id == _layout_primary_point_id:
		return points_route
	var definition := _layout_point_definitions.get(point_id, {}) as Dictionary
	return str(yard_point_routes.get(point_id, definition.get("initial_route", POINTS_MAIN)))


func set_point_route(point_id: String, route: String) -> bool:
	if not _layout_point_definitions.has(point_id):
		return false
	var definition := _layout_point_definitions[point_id] as Dictionary
	var routes := definition.get("routes", []) as Array
	if not routes.has(route):
		return false
	_store_point_route(point_id, route)
	return true


func request_point_toggle(point_id: String) -> bool:
	if not _layout_point_definitions.has(point_id):
		blocked_reason = "Unknown point"
		return false
	if not is_stopped():
		blocked_reason = "Stop before changing points"
		return false
	if is_point_occupied(point_id):
		blocked_reason = "%s occupied" % point_id
		return false

	_toggle_point_route(point_id)
	blocked_reason = "%s changed to %s" % [point_id, get_point_route(point_id)]
	return true


func is_point_occupied(point_id: String) -> bool:
	if not _layout_point_definitions.has(point_id):
		return false
	var definition := _layout_point_definitions[point_id] as Dictionary
	var point_position := definition.get("position", Vector2.ZERO) as Vector2
	for state in get_unit_draw_states():
		var half_length := float(state.get("length", 0.0)) * 0.5
		var clearance := SWITCH_OCCUPANCY_CLEARANCE + half_length
		var unit_position := state.get("position", Vector2.ZERO) as Vector2
		if unit_position.distance_to(point_position) <= clearance:
			return true
	return false


func set_points_route(route: String) -> void:
	set_point_route(_layout_primary_point_id, route)


func toggle_points() -> void:
	_toggle_point_route(_layout_primary_point_id)


func set_yard_point_route(point_id: String, route: String) -> bool:
	return set_point_route(point_id, route)


func get_yard_point_route(point_id: String) -> String:
	return get_point_route(point_id)


func toggle_yard_point(point_id: String) -> bool:
	if not _layout_point_definitions.has(point_id):
		return false
	_toggle_point_route(point_id)
	return true


func request_points_toggle() -> bool:
	var changed := request_point_toggle(_layout_primary_point_id)
	if changed:
		blocked_reason = "Points changed to %s" % points_route
	elif blocked_reason == "%s occupied" % _layout_primary_point_id:
		blocked_reason = "Points occupied"
	return changed


func request_yard_point_toggle(point_id: String) -> bool:
	if not _layout_point_definitions.has(point_id):
		blocked_reason = "Unknown yard point"
		return false
	return request_point_toggle(point_id)


func get_points_operator_anchor() -> Vector2:
	var definition := _layout_point_definitions.get(_layout_primary_point_id, {}) as Dictionary
	var position := definition.get("position", SWITCH_POSITION) as Vector2
	return position + SWITCH_OPERATOR_ANCHOR_OFFSET


func is_switch_occupied() -> bool:
	return is_point_occupied(_layout_primary_point_id)


func is_yard_point_occupied(point_id: String) -> bool:
	return is_point_occupied(point_id)


func is_stopped() -> bool:
	return speed <= 0.05


func get_active_consist_ids() -> Array[String]:
	return active_units.duplicate()


func get_consist_unit_ids_for(unit_id: String) -> Array[String]:
	# Read-only topology API for colony/interior systems. The railway remains the
	# authority for physical consist membership; consumers must not rebuild or
	# mutate consist arrays themselves.
	if active_units.has(unit_id):
		return active_units.duplicate()

	for consist in detached_consists:
		var units := _get_detached_units(consist)
		if units.has(unit_id):
			return units.duplicate()
	return []


func are_units_in_same_consist(first_unit: String, second_unit: String) -> bool:
	var units := get_consist_unit_ids_for(first_unit)
	return not units.is_empty() and units.has(second_unit)


func get_active_occupied_interval() -> Dictionary:
	return _get_active_interval()


func get_detached_occupied_interval(unit_id: String) -> Dictionary:
	for consist in detached_consists:
		if not _get_detached_units(consist).has(unit_id):
			continue

		return _get_detached_interval(consist)

	return {}


func has_any_overlap() -> bool:
	var active_interval := _get_active_interval()
	for consist in detached_consists:
		var detached_interval := _get_detached_interval(consist)
		if str(active_interval["segment"]) != str(detached_interval["segment"]):
			continue
		if _intervals_overlap(active_interval, detached_interval):
			return true

	return false


func get_last_contact() -> Dictionary:
	return last_contact.duplicate(true)


func get_condition_state() -> String:
	return condition_state


func get_controlled_locomotive_id() -> String:
	return controlled_locomotive_id


func get_controlled_power_unit_id() -> String:
	return controlled_power_unit_id


func is_powered_unit(unit_id: String) -> bool:
	return bool(get_unit_definition(unit_id).get("powered", false))


func get_powered_unit_condition(unit_id: String) -> String:
	if not is_powered_unit(unit_id):
		return ""
	return str(powered_unit_conditions.get(unit_id, CONDITION_OPERATIONAL))


func set_powered_unit_condition(unit_id: String, condition: String) -> bool:
	if not is_powered_unit(unit_id):
		return false
	if condition != CONDITION_OPERATIONAL and condition != CONDITION_DAMAGED:
		return false

	powered_unit_conditions[unit_id] = condition
	return true


func get_powered_unit_ids() -> Array[String]:
	var ids: Array[String] = []
	for unit_id in active_units:
		if unit_id != controlled_power_unit_id:
			continue
		if not is_powered_unit(unit_id):
			continue
		if get_powered_unit_condition(unit_id) != CONDITION_OPERATIONAL:
			continue
		ids.append(unit_id)
	return ids


func has_traction_authority() -> bool:
	return not get_powered_unit_ids().is_empty()


func select_powered_control(unit_id: String) -> bool:
	if not is_powered_unit(unit_id):
		blocked_reason = "%s is not a powered unit" % unit_id
		return false
	if get_powered_unit_condition(unit_id) != CONDITION_OPERATIONAL:
		blocked_reason = "%s is not operational" % unit_id
		return false

	if active_units.has(unit_id):
		controlled_power_unit_id = unit_id
		speed = 0.0
		throttle = 0.0
		blocked_reason = "Control selected: %s" % unit_id
		return true

	var target_index := _find_detached_consist_index(unit_id)
	if target_index < 0:
		blocked_reason = "%s is not present in any consist" % unit_id
		return false

	var target_consist := detached_consists[target_index].duplicate(true)
	detached_consists.remove_at(target_index)
	if not active_units.is_empty():
		var active_front_center := _get_active_unit_center_distance(0)
		var active_position := _resolve_path_distance(current_segment, active_front_center)
		detached_consists.append({
			"units": active_units.duplicate(),
			"segment": str(active_position["segment"]),
			"distance": float(active_position["distance"]),
		})

	var target_units := _get_detached_units(target_consist)
	active_units = target_units
	current_segment = _get_detached_segment(target_consist)
	var target_front_distance := _get_detached_front_coupler_distance(target_consist)
	distance = target_front_distance
	controlled_power_unit_id = unit_id
	speed = 0.0
	throttle = 0.0
	last_contact.clear()
	blocked_reason = "Control selected: %s" % unit_id
	return true


func get_consist_containing_unit(unit_id: String) -> Dictionary:
	if active_units.has(unit_id):
		return {
			"units": active_units.duplicate(),
			"segment": current_segment,
			"distance": _get_active_unit_center_distance(0),
			"active": true,
		}

	for consist in detached_consists:
		var units := _get_detached_units(consist)
		if not units.has(unit_id):
			continue

		return {
			"units": units,
			"segment": _get_detached_segment(consist),
			"distance": float(consist.get("distance", 0.0)),
			"active": false,
		}

	return {}


func get_consist_summary() -> String:
	return _format_consist_units(active_units)


func has_detached_consist(units: Array[String], segment_id: String) -> bool:
	for consist in detached_consists:
		if _get_detached_segment(consist) != segment_id:
			continue
		if _same_units(_get_detached_units(consist), units):
			return true

	return false


func get_wagon_type_count() -> int:
	var wagon_types := {}
	for unit_id in _get_all_unit_ids():
		var type_id := get_unit_type_id(unit_id)
		if type_id == RollingStockCatalog.TYPE_LOCOMOTIVE_DIESEL:
			continue

		wagon_types[type_id] = true

	return wagon_types.size()


func get_coupler_status_lines() -> Array[String]:
	var lines: Array[String] = []
	if active_units.size() > 0:
		lines.append("%s front: free" % active_units[0])
		for index in active_units.size() - 1:
			lines.append("%s rear -> %s front" % [active_units[index], active_units[index + 1]])
		lines.append("%s rear: free" % active_units[active_units.size() - 1])

	for consist in detached_consists:
		var units := _get_detached_units(consist)
		if units.is_empty():
			continue

		lines.append("%s front: free" % units[0])
		lines.append("%s rear: free" % units[units.size() - 1])

	return lines


func get_coupled_joints() -> Array[Dictionary]:
	var joints: Array[Dictionary] = []
	if active_units.size() <= 1:
		return joints

	for index in range(active_units.size() - 1):
		joints.append(_get_active_joint_info(index))

	return joints


func has_coupled_joint(front_unit: String, rear_unit: String) -> bool:
	return _find_active_joint_index(front_unit, rear_unit) >= 0


func get_joint_anchor(front_unit: String, rear_unit: String) -> Dictionary:
	var index := _find_active_joint_index(front_unit, rear_unit)
	if index < 0:
		return {}

	return _get_active_joint_info(index)


func get_total_mass() -> float:
	var total := 0.0
	for unit_id in active_units:
		total += get_unit_mass(unit_id)
	return total


func get_total_length() -> float:
	return _get_active_consist_length()


func get_mobility_summary() -> Dictionary:
	return {
		"total_mass": get_total_mass(),
		"total_length": get_total_length(),
		"unit_count": active_units.size(),
		"has_traction": has_traction_authority(),
		"powered_unit_id": str(controlled_power_unit_id),
		"capabilities": get_train_capabilities(),
	}


func set_unit_type(unit_id: String, type_id: String) -> bool:
	if unit_id == "" or not RollingStockCatalog.has_type(type_id):
		return false
	unit_type_overrides[unit_id] = type_id
	if bool(RollingStockCatalog.get_definition(type_id).get("powered", false)) \
			and not powered_unit_conditions.has(unit_id):
		powered_unit_conditions[unit_id] = CONDITION_OPERATIONAL
	return true


func set_unit_type_map(type_map: Dictionary) -> void:
	for raw_unit_id in type_map.keys():
		set_unit_type(str(raw_unit_id), str(type_map[raw_unit_id]))


func get_unit_type_id(unit_id: String) -> String:
	if unit_type_overrides.has(unit_id):
		return str(unit_type_overrides.get(unit_id, ""))
	return RollingStockCatalog.infer_legacy_type_id(unit_id)


func get_unit_type_map(unit_ids: Array[String] = []) -> Dictionary:
	var ids: Array[String] = []
	if unit_ids.is_empty():
		ids = _get_all_unit_ids()
	else:
		ids.assign(unit_ids)
	var result: Dictionary = {}
	for unit_id in ids:
		var type_id := get_unit_type_id(unit_id)
		if type_id == "":
			continue
		result[unit_id] = type_id
	return result


func get_unit_definition(unit_id: String) -> Dictionary:
	return RollingStockCatalog.get_definition_for_unit(unit_id, unit_type_overrides)


func get_unit_capability_summary(unit_id: String) -> String:
	return str(get_unit_definition(unit_id).get("summary", ""))


func get_unit_capabilities(unit_id: String) -> Array[String]:
	return RollingStockCatalog.get_capabilities_for_unit(unit_id, unit_type_overrides)


func get_train_capabilities() -> Array[String]:
	return RollingStockCatalog.get_capabilities_for_units(active_units, unit_type_overrides)


func has_train_capability(capability: String) -> bool:
	return capability != "" and get_train_capabilities().has(capability)


func get_train_resource_capacities() -> Dictionary:
	return RollingStockCatalog.get_resource_capacity_for_units(active_units, unit_type_overrides)


func get_unit_type(unit_id: String) -> String:
	return str(get_unit_definition(unit_id).get("physical_type", "unknown"))


func get_unit_label(unit_id: String) -> String:
	if _UNIT_LABELS.has(unit_id):
		return str(_UNIT_LABELS.get(unit_id, unit_id))
	var definition := get_unit_definition(unit_id)
	var display_name := str(definition.get("display_name", ""))
	if display_name != "":
		return "%s %s" % [display_name, unit_id]
	return unit_id


func get_unit_length(unit_id: String) -> float:
	if _UNIT_LENGTHS.has(unit_id):
		return float(_UNIT_LENGTHS.get(unit_id, 48.0))
	var definition := get_unit_definition(unit_id)
	if not definition.is_empty():
		return float(definition.get("length", 48.0))
	return 48.0


func get_unit_mass(unit_id: String) -> float:
	if _UNIT_MASSES.has(unit_id):
		return float(_UNIT_MASSES.get(unit_id, 10.0))
	var definition := get_unit_definition(unit_id)
	if not definition.is_empty():
		return float(definition.get("mass", 10.0))
	return 10.0


func get_unit_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	var cursor := distance
	for index in active_units.size():
		var unit_id := active_units[index]
		var unit_length := get_unit_length(unit_id)
		var center_distance := cursor - unit_length * 0.5
		var rail_position := _resolve_path_distance(current_segment, center_distance)
		var segment_id := str(rail_position["segment"])
		var segment_distance := float(rail_position["distance"])
		states.append({
			"id": unit_id,
			"type_id": get_unit_type_id(unit_id),
			"type": get_unit_type(unit_id),
			"label": get_unit_label(unit_id),
			"capability_summary": get_unit_capability_summary(unit_id),
			"segment": segment_id,
			"distance": segment_distance,
			"position": get_position_at_distance(segment_id, segment_distance),
			"angle": get_tangent_at_distance(segment_id, segment_distance).angle(),
			"active": true,
			"length": unit_length,
			"controlled": unit_id == controlled_power_unit_id,
			"powered": get_powered_unit_ids().has(unit_id),
			"condition": get_powered_unit_condition(unit_id),
		})
		cursor -= unit_length + COUPLER_GAP

	for consist in detached_consists:
		for state in _get_detached_draw_states(consist):
			states.append(state)

	return states


func get_detached_summary() -> String:
	if detached_consists.is_empty():
		return "none"

	var pieces: Array[String] = []
	for consist in detached_consists:
		var segment_id := _get_detached_segment(consist)
		pieces.append("%s on %s" % [_format_consist_units(_get_detached_units(consist)), segment_id])

	return "; ".join(pieces)


func decouple_rear() -> bool:
	if not is_stopped():
		blocked_reason = "Stop before decoupling"
		return false
	if not active_units.has(controlled_power_unit_id):
		blocked_reason = "No controlled powered unit in active consist"
		return false
	if active_units.size() <= 1:
		blocked_reason = "No rear wagon to decouple"
		return false

	var rear_index := active_units.size() - 1
	var unit_id := active_units[rear_index]
	if unit_id == controlled_power_unit_id or is_powered_unit(unit_id):
		blocked_reason = "No detachable wagon at controlled consist rear"
		return false

	var center_distance := _get_active_unit_center_distance(rear_index)
	var rail_position := _resolve_path_distance(current_segment, center_distance)
	active_units.remove_at(rear_index)
	detached_consists.append({
		"units": [unit_id],
		"segment": str(rail_position["segment"]),
		"distance": float(rail_position["distance"]),
	})
	blocked_reason = "Decoupled %s" % unit_id
	return true


func decouple_front() -> bool:
	if not is_stopped():
		blocked_reason = "Stop before decoupling"
		return false
	if not active_units.has(controlled_power_unit_id):
		blocked_reason = "No controlled powered unit in active consist"
		return false
	if active_units.size() <= 1:
		blocked_reason = "No front wagon to decouple"
		return false

	var unit_id := active_units[0]
	if unit_id == controlled_power_unit_id or is_powered_unit(unit_id):
		blocked_reason = "No detachable wagon at controlled consist front"
		return false

	var front_unit_length := get_unit_length(unit_id)
	var center_distance := distance - front_unit_length * 0.5
	var detached_position := _resolve_path_distance(current_segment, center_distance)
	var next_front_position := _resolve_path_distance(current_segment, distance - front_unit_length - COUPLER_GAP)

	active_units.remove_at(0)
	current_segment = str(next_front_position["segment"])
	distance = float(next_front_position["distance"])
	detached_consists.append({
		"units": [unit_id],
		"segment": str(detached_position["segment"]),
		"distance": float(detached_position["distance"]),
	})
	blocked_reason = "Decoupled front %s" % unit_id
	return true


func decouple_joint(front_unit: String, rear_unit: String) -> bool:
	if not is_stopped():
		blocked_reason = "Stop before uncoupling"
		return false
	if not active_units.has(controlled_power_unit_id):
		blocked_reason = "No controlled powered unit in active consist"
		return false

	var joint_index := _find_active_joint_index(front_unit, rear_unit)
	if joint_index < 0:
		blocked_reason = "Joint no longer coupled"
		return false

	var front_slice := _slice_active_units(0, joint_index + 1)
	var rear_slice := _slice_active_units(joint_index + 1, active_units.size())
	var detached_units: Array[String] = []
	var next_active_units: Array[String] = []
	var detached_center_index := -1
	var next_segment := current_segment
	var next_distance := distance

	if front_slice.has(controlled_power_unit_id):
		next_active_units = front_slice
		detached_units = rear_slice
		detached_center_index = joint_index + 1
	elif rear_slice.has(controlled_power_unit_id):
		next_active_units = rear_slice
		detached_units = front_slice
		detached_center_index = 0
		var next_active_front_unit := rear_slice[0]
		var next_active_front_center := _get_active_unit_center_distance(joint_index + 1)
		var next_active_front := _resolve_path_distance(current_segment, next_active_front_center + get_unit_length(next_active_front_unit) * 0.5)
		next_segment = str(next_active_front["segment"])
		next_distance = float(next_active_front["distance"])
	else:
		blocked_reason = "No controlled powered unit after uncoupling"
		return false

	if detached_units.is_empty() or detached_center_index < 0:
		blocked_reason = "No rolling stock to detach"
		return false

	var detached_center := _get_active_unit_center_distance(detached_center_index)
	var detached_position := _resolve_path_distance(current_segment, detached_center)
	active_units = next_active_units
	current_segment = next_segment
	distance = next_distance
	detached_consists.append({
		"units": detached_units,
		"segment": str(detached_position["segment"]),
		"distance": float(detached_position["distance"]),
	})
	blocked_reason = "Uncoupled joint %s/%s" % [front_unit, rear_unit]
	return true


func can_couple_unit(unit_id: String) -> bool:
	var info := _find_contact_coupling_target_info(unit_id)
	if info.is_empty():
		return false

	return speed <= max_coupling_speed


func get_last_contact_anchor() -> Dictionary:
	var target_info := _find_contact_coupling_target_info()
	if target_info.is_empty():
		return {}

	var target_index := int(target_info["index"])
	var consist := detached_consists[target_index]
	var active_end := str(target_info["active_end"])
	var detached_end := str(target_info["detached_end"])
	# `contact_distance` is already projected into the active segment's path
	# coordinates. Using the detached consist's raw local distance here breaks
	# crew coupling when the two exposed couplers meet exactly across a turnout.
	var contact_distance := float(target_info["contact_distance"])
	var rail_position := _resolve_path_distance(current_segment, contact_distance)
	var segment_id := str(rail_position["segment"])
	var segment_distance := float(rail_position["distance"])
	var position := get_position_at_distance(segment_id, segment_distance)
	var tangent := get_tangent_at_distance(segment_id, segment_distance)
	var normal := Vector2(-tangent.y, tangent.x).normalized()
	var active_unit := str(target_info["active_unit"])
	var detached_unit := str(target_info["unit"])

	return {
		"id": "%s/%s" % [active_unit, detached_unit],
		"active_unit": active_unit,
		"detached_unit": detached_unit,
		"active_end": active_end,
		"detached_end": detached_end,
		"segment": segment_id,
		"distance": segment_distance,
		"position": position,
		"anchor": position + normal * JOINT_OPERATOR_ANCHOR_OFFSET,
		"angle": tangent.angle(),
		"relative_speed": float(last_contact.get("relative_speed", 0.0)),
		"coupling_permitted": true,
	}


func couple_nearest() -> bool:
	var target_info := _find_contact_coupling_target_info()
	if target_info.is_empty():
		if str(last_contact.get("type", CONTACT_NONE)) == CONTACT_IMPACT:
			blocked_reason = "Impact contact must be reset before coupling"
		else:
			blocked_reason = "No compatible couplers in contact"
		return false
	if speed > max_coupling_speed:
		blocked_reason = "Too fast to couple"
		return false

	var target_index := int(target_info["index"])
	var consist := detached_consists[target_index]
	var units := _get_detached_units(consist)
	var active_end := str(target_info["active_end"])
	var detached_end := str(target_info["detached_end"])
	var next_units: Array[String] = []
	if active_end == COUPLER_REAR and detached_end == COUPLER_FRONT:
		next_units.assign(active_units)
		for unit_id in units:
			next_units.append(unit_id)
	elif active_end == COUPLER_FRONT and detached_end == COUPLER_REAR:
		# The contacted consist becomes the new physical front. If the contact
		# occurred across a turnout, its front coupler is expressed in the target
		# segment's local coordinates, so transfer the active reference segment as
		# well as the distance. Previously only `distance` changed, which made
		# cross-segment front coupling either unavailable or geometrically invalid.
		var next_front_segment := _get_detached_segment(consist)
		var next_front_distance := _get_detached_front_coupler_distance(consist)
		next_units.assign(units)
		for unit_id in active_units:
			next_units.append(unit_id)
		current_segment = next_front_segment
		distance = next_front_distance
	else:
		blocked_reason = "Coupler endpoints are not compatible"
		return false

	active_units = next_units
	detached_consists.remove_at(target_index)
	var resulting_consist := get_consist_summary()
	last_contact["coupled"] = true
	last_contact["resulting_consist"] = resulting_consist
	last_contact["result"] = "coupled %s" % resulting_consist
	blocked_reason = "Coupled %s via %s %s <-> %s %s" % [
		_format_consist_units(units),
		str(target_info["active_unit"]),
		active_end,
		str(target_info["unit"]),
		detached_end,
	]
	return true


func get_segment_length(segment_id: String = current_segment) -> float:
	var points: Array = _get_segment_points(segment_id)
	var total := 0.0
	for index in range(points.size() - 1):
		total += (points[index + 1] as Vector2).distance_to(points[index] as Vector2)
	return total


func get_position_at_distance(segment_id: String, segment_distance: float) -> Vector2:
	var points: Array = _get_segment_points(segment_id)
	if points.is_empty():
		return Vector2.ZERO
	var remaining := clampf(segment_distance, 0.0, get_segment_length(segment_id))
	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		var length := end.distance_to(start)
		if remaining <= length or index == points.size() - 2:
			var ratio := remaining / maxf(length, 0.001)
			return start.lerp(end, ratio)
		remaining -= length

	return points[points.size() - 1] as Vector2


func get_tangent_at_distance(segment_id: String, segment_distance: float) -> Vector2:
	var points: Array = _get_segment_points(segment_id)
	if points.size() < 2:
		return Vector2.RIGHT
	var remaining := clampf(segment_distance, 0.0, get_segment_length(segment_id))
	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		var length := end.distance_to(start)
		if remaining <= length or index == points.size() - 2:
			return (end - start).normalized()
		remaining -= length

	return Vector2.RIGHT


func get_world_position(segment_id: String, segment_distance: float) -> Vector2:
	return get_position_at_distance(segment_id, segment_distance)


func get_point_on_segment(segment_id: String, segment_distance: float) -> Vector2:
	return get_world_position(segment_id, segment_distance)


func get_segment_angle(segment_id: String) -> float:
	return get_tangent_at_distance(segment_id, 0.0).angle()


func get_position() -> Vector2:
	return get_world_position(current_segment, distance)


func get_heading_angle() -> float:
	var angle := get_tangent_at_distance(current_segment, distance).angle()
	if direction < 0:
		angle += PI
	return angle


func get_debug_lines() -> Array[String]:
	var direction_label := "Forward"
	if direction < 0:
		direction_label = "Reverse"

	var lines: Array[String] = []
	lines.append("Track: %s" % current_segment)
	lines.append("Distance: %.1f / %.1f" % [distance, get_segment_length()])
	lines.append("Consist: %s" % get_consist_summary())
	lines.append("Controlled locomotive: %s" % controlled_locomotive_id)
	lines.append("Controlled power: %s" % controlled_power_unit_id)
	lines.append("Powered units: %s" % _format_consist_units(get_powered_unit_ids()))
	lines.append("Traction: %s" % _format_yes_no(has_traction_authority()))
	lines.append("Speed: %.1f" % speed)
	lines.append("Throttle: %d%%" % roundi(throttle * 100.0))
	lines.append("Direction: %s" % direction_label)
	lines.append("Brake: %s" % _format_bool(brake_active))
	lines.append("Points: %s" % points_route)
	lines.append("Yard P2: %s" % get_yard_point_route("P2"))
	lines.append("Yard P3: %s" % get_yard_point_route("P3"))
	lines.append("Mass: %.1f t" % get_total_mass())
	lines.append("Condition: %s" % condition_state)
	lines.append("Couplers: %s" % _format_coupler_summary())
	lines.append("Detached: %s" % get_detached_summary())
	if not last_contact.is_empty():
		lines.append("Contact: %s %s %s <-> %s %s on %s at %.1f" % [
			str(last_contact.get("type", CONTACT_NONE)),
			str(last_contact.get("active_unit", "?")),
			str(last_contact.get("active_end", "?")),
			str(last_contact.get("detached_unit", "?")),
			str(last_contact.get("detached_end", "?")),
			str(last_contact.get("segment", "?")),
			float(last_contact.get("relative_speed", 0.0)),
		])
		lines.append("Coupling permitted: %s" % _format_yes_no(bool(last_contact.get("coupling_permitted", false))))
		lines.append("Contact result: %s" % str(last_contact.get("result", "none")))
		if last_contact.has("resulting_consist"):
			lines.append("Resulting consist: %s" % str(last_contact["resulting_consist"]))
	if blocked_reason != "":
		lines.append("Blocked: %s" % blocked_reason)
	return lines


func get_track_segments() -> Dictionary:
	return _layout_segment_points


func _update_speed(delta: float, brake_active: bool) -> void:
	if brake_active:
		throttle = 0.0
		speed = maxf(speed - brake_deceleration * delta, 0.0)
		return
	if not has_traction_authority():
		if throttle > 0.0:
			blocked_reason = "No operational controlled powered unit in active consist"
		speed = move_toward(speed, 0.0, coast_deceleration * delta)
		return

	var mass_factor := clampf(150.0 / maxf(get_total_mass(), 1.0), 0.45, 1.1)
	var target_speed := throttle * max_speed * mass_factor
	var rate := acceleration * mass_factor
	if target_speed < speed:
		rate = coast_deceleration

	speed = move_toward(speed, target_speed, rate * delta)


func _format_bool(value: bool) -> String:
	if value:
		return "on"
	return "off"


func _format_yes_no(value: bool) -> String:
	if value:
		return "yes"
	return "no"


func _advance(amount: float) -> void:
	var remaining := amount
	var guard := 0
	while absf(remaining) > 0.001 and guard < 8:
		guard += 1
		if remaining > 0.0:
			remaining = _advance_toward_segment_end(remaining)
		else:
			remaining = _advance_toward_segment_start(remaining)


func _advance_toward_segment_end(amount: float) -> float:
	var contact := _find_contact_for_amount(amount)
	if not contact.is_empty():
		distance += float(contact["travel"])
		_register_contact(contact)
		return 0.0

	var room := get_segment_length() - distance
	if amount <= room:
		distance += amount
		return 0.0

	distance = get_segment_length()
	var leftover := amount - room
	if _leave_endpoint_b():
		return leftover

	speed = 0.0
	return 0.0


func _advance_toward_segment_start(amount: float) -> float:
	# A trailing/reverse move must still have the turnout aligned for the branch
	# the consist is physically leaving. The old reverse fix treated every branch
	# as structurally passable regardless of point state, which removed the visual
	# teleport but broke Sprint 4's yard rule: P2 straight must block a shunter
	# from trailing out of the workshop siding.
	#
	# Stop when the ACTIVE REAR coupler reaches the turnout. This is important:
	# waiting until the front reference reaches segment distance 0 would allow a
	# long consist to render through the wrong branch before the route is rejected.
	var travel := absf(amount)
	var rear_distance := _get_active_rear_coupler_distance()
	if _has_structural_previous_segment(current_segment) and not _is_trailing_route_aligned(current_segment):
		# Stop slightly CLEAR of the turnout rather than directly on the switch.
		# That keeps the occupancy interlock free so the player can throw the points
		# after receiving the route-block message instead of having to move away first.
		var travel_to_route_stop := rear_distance - TRAILING_ROUTE_STOP_CLEARANCE
		if travel_to_route_stop <= CONTACT_EPSILON:
			speed = 0.0
			blocked_reason = _get_trailing_route_block_reason(current_segment)
			return 0.0

		if travel >= travel_to_route_stop - CONTACT_EPSILON:
			# Same-segment rolling stock may be closer than the turnout barrier, so let
			# normal contact resolution win when appropriate. Cross-boundary contact
			# projection is disabled while the turnout is misaligned.
			var contact_before_points := _find_contact_for_amount(-travel_to_route_stop)
			if not contact_before_points.is_empty():
				distance += float(contact_before_points["travel"])
				_register_contact(contact_before_points)
				return 0.0

			distance -= travel_to_route_stop
			speed = 0.0
			blocked_reason = _get_trailing_route_block_reason(current_segment)
			return 0.0

	var contact := _find_contact_for_amount(amount)
	if not contact.is_empty():
		distance += float(contact["travel"])
		_register_contact(contact)
		return 0.0

	if travel <= distance:
		distance -= travel
		return 0.0

	var leftover := -(travel - distance)
	distance = 0.0
	if _leave_endpoint_a():
		return leftover

	speed = 0.0
	return 0.0


func _leave_endpoint_b() -> bool:
	# Forward travel from a common leg follows the stored traversed branch while
	# the consist is still straddling a turnout. Otherwise the live points route
	# decides the next segment for a new facing move.
	var next_segment := _get_next_segment(current_segment)
	if next_segment != "":
		current_segment = next_segment
		distance = 0.0
		return true

	blocked_reason = _get_endpoint_b_block_reason(current_segment)
	return false


func _leave_endpoint_a() -> bool:
	var source_segment := current_segment
	var previous_segment := _get_previous_segment(source_segment)
	if previous_segment == "":
		match source_segment:
			SEGMENT_MAIN_WEST:
				blocked_reason = "End of main line"
			_:
				blocked_reason = "No route through points"
		return false

	# `distance` is the active consist FRONT coupler measured along
	# `current_segment`. During reverse travel the rear of the consist crosses
	# endpoint A first; `_resolve_path_distance()` already places those negative
	# offsets onto the structurally connected previous segment. By the time the
	# front coupler itself reaches endpoint A the ENTIRE consist has cleared the
	# source segment. Therefore the equivalent coordinate on the previous segment
	# is exactly its endpoint B -- do not add consist length here. Adding consist
	# length re-projects the train back onto the branch and causes the visible
	# reverse-turnout teleport.
	current_segment = previous_segment
	distance = get_segment_length(previous_segment)
	return true


func _resolve_path_distance(segment_id: String, segment_distance: float) -> Dictionary:
	var resolved_segment := segment_id
	var resolved_distance := segment_distance
	var guard := 0
	while resolved_distance < 0.0 and guard < 8:
		guard += 1
		var previous_segment := _get_previous_segment(resolved_segment)
		if previous_segment == "":
			resolved_distance = 0.0
			break
		resolved_segment = previous_segment
		resolved_distance += get_segment_length(resolved_segment)

	guard = 0
	while resolved_distance > get_segment_length(resolved_segment) and guard < 8:
		guard += 1
		var next_segment := _get_next_segment(resolved_segment)
		if next_segment == "":
			resolved_distance = get_segment_length(resolved_segment)
			break
		resolved_distance -= get_segment_length(resolved_segment)
		resolved_segment = next_segment

	return {
		"segment": resolved_segment,
		"distance": resolved_distance,
	}


func _has_structural_previous_segment(segment_id: String) -> bool:
	return _layout_previous_connections.has(segment_id) or _get_previous_segment(segment_id) != ""


func _is_trailing_route_aligned(segment_id: String) -> bool:
	# Facing and trailing moves use the same physical point alignment. A branch
	# already occupied by a train does not magically become the selected branch;
	# if the points are against the movement, the train stops at the turnout.
	if _layout_previous_connections.has(segment_id):
		var connection := _layout_previous_connections[segment_id] as Dictionary
		if connection.has("requires_point"):
			return get_point_route(str(connection.get("requires_point", ""))) == str(connection.get("requires_route", ""))
		if connection.has("point"):
			return _get_previous_segment(segment_id) != ""
	return true


func _get_trailing_route_block_reason(segment_id: String) -> String:
	if _layout_previous_connections.has(segment_id):
		var connection := _layout_previous_connections[segment_id] as Dictionary
		if connection.has("blocked_reason"):
			return str(connection.get("blocked_reason", "No route through points"))
		if connection.has("requires_point"):
			return "%s route blocks %s" % [str(connection.get("requires_point", "point")), segment_id]
	return "No route through points"


func _get_previous_segment(segment_id: String) -> String:
	# Structural topology only. Route alignment is deliberately checked by the
	# movement layer at the moment the trailing/rear coupler reaches the turnout.
	# Keeping topology separate avoids using the live switch setting to redraw a
	# consist that is already straddling an aligned turnout.
	if _layout_previous_connections.has(segment_id):
		return _resolve_previous_connection_target(_layout_previous_connections[segment_id] as Dictionary)
	return ""


func _get_next_segment(segment_id: String) -> String:
	# Facing movement from a common leg is the only place where the live switch
	# route chooses a branch. Reverse/trailing continuity is handled by
	# `_get_previous_segment()`.
	if _layout_next_connections.has(segment_id):
		return _resolve_connection_target(_layout_next_connections[segment_id] as Dictionary)
	return ""


func _make_default_track_layout() -> Dictionary:
	var segments: Dictionary = {}
	for raw_segment_id in _SEGMENT_POINTS.keys():
		var segment_id := str(raw_segment_id)
		segments[segment_id] = (_SEGMENT_POINTS[raw_segment_id] as Array).duplicate(true)

	var segment_semantics: Dictionary = {}
	for raw_segment_id in segments.keys():
		segment_semantics[str(raw_segment_id)] = {
			"semantic_edge_id": "",
			"semantic_role": "",
		}

	return {
		"layout_id": "default_authored_yard",
		"primary_point_id": "P1",
		"entry_segment": SEGMENT_MAIN_WEST,
		"entry_distance": distance,
		"segments": segments,
		"segment_semantics": segment_semantics,
		"points": {
			"P1": {
				"id": "P1",
				"position": SWITCH_POSITION,
				"routes": [POINTS_MAIN, POINTS_SIDING],
				"initial_route": POINTS_MAIN,
			},
			"P2": {
				"id": "P2",
				"position": Vector2(1320.0, 360.0),
				"routes": [POINTS_MAIN, POINTS_SIDING],
				"initial_route": POINTS_MAIN,
			},
			"P3": {
				"id": "P3",
				"position": Vector2(1080.0, 515.0),
				"routes": [POINTS_MAIN, POINTS_SIDING],
				"initial_route": POINTS_SIDING,
			},
		},
		"next_connections": {
			SEGMENT_MAIN_WEST: {
				"point": "P1",
				"routes": {
					POINTS_MAIN: SEGMENT_MAIN_EAST,
					POINTS_SIDING: SEGMENT_SIDING,
				},
			},
			SEGMENT_MAIN_EAST: {
				"point": "P2",
				"routes": {
					POINTS_MAIN: SEGMENT_MAIN_EXIT,
					POINTS_SIDING: SEGMENT_SIDING_B,
				},
			},
			SEGMENT_SIDING: {
				"point": "P3",
				"routes": {
					POINTS_MAIN: SEGMENT_YARD_STORAGE,
					POINTS_SIDING: SEGMENT_YARD_REPAIR,
				},
			},
			SEGMENT_SIDING_B: {
				"segment": SEGMENT_INDUSTRIAL_EXIT,
			},
			SEGMENT_YARD_STORAGE: {
				"segment": SEGMENT_SETTLEMENT_EXIT,
			},
		},
		"previous_connections": {
			SEGMENT_MAIN_EAST: {
				"segment": SEGMENT_MAIN_WEST,
				"requires_point": "P1",
				"requires_route": POINTS_MAIN,
				"blocked_reason": "P1 route blocks main line",
			},
			SEGMENT_SIDING: {
				"segment": SEGMENT_MAIN_WEST,
				"requires_point": "P1",
				"requires_route": POINTS_SIDING,
				"blocked_reason": "P1 route blocks siding",
			},
			SEGMENT_MAIN_EXIT: {
				"segment": SEGMENT_MAIN_EAST,
				"requires_point": "P2",
				"requires_route": POINTS_MAIN,
				"blocked_reason": "P2 route blocks main line",
			},
			SEGMENT_SIDING_B: {
				"segment": SEGMENT_MAIN_EAST,
				"requires_point": "P2",
				"requires_route": POINTS_SIDING,
				"blocked_reason": "P2 route blocks workshop siding",
			},
			SEGMENT_YARD_STORAGE: {
				"segment": SEGMENT_SIDING,
				"requires_point": "P3",
				"requires_route": POINTS_MAIN,
				"blocked_reason": "P3 route blocks storage siding",
			},
			SEGMENT_YARD_REPAIR: {
				"segment": SEGMENT_SIDING,
				"requires_point": "P3",
				"requires_route": POINTS_SIDING,
				"blocked_reason": "P3 route blocks repair siding",
			},
			SEGMENT_INDUSTRIAL_EXIT: {
				"segment": SEGMENT_SIDING_B,
			},
			SEGMENT_SETTLEMENT_EXIT: {
				"segment": SEGMENT_YARD_STORAGE,
			},
		},
		"endpoint_b_block_reasons": {
			SEGMENT_MAIN_WEST: "No route through points",
			SEGMENT_MAIN_EAST: "End of main line",
			SEGMENT_MAIN_EXIT: "End of main line",
			SEGMENT_SIDING: "No route through P3",
			SEGMENT_SIDING_B: "End of workshop siding",
			SEGMENT_YARD_STORAGE: "End of storage siding",
			SEGMENT_YARD_REPAIR: "End of repair siding",
			SEGMENT_INDUSTRIAL_EXIT: "End of industrial route",
			SEGMENT_SETTLEMENT_EXIT: "End of settlement route",
		},
	}


func _validate_track_layout(layout: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if not layout.has("segments") or typeof(layout.get("segments")) != TYPE_DICTIONARY:
		_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_SEGMENTS_REQUIRED", "track layout requires segments")
		return
	if not layout.has("points") or typeof(layout.get("points")) != TYPE_DICTIONARY:
		_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_POINTS_REQUIRED", "track layout requires points")
		return

	var segments := layout.get("segments", {}) as Dictionary
	for raw_segment_id in segments.keys():
		var segment_id := str(raw_segment_id)
		var points := _coerce_segment_points(segments[raw_segment_id])
		if points.size() < 2:
			_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_SEGMENT_POINTS_INVALID", "segment %s requires at least two points" % segment_id, segment_id)

	var entry_segment := str(layout.get("entry_segment", ""))
	if not entry_segment.is_empty() and not segments.has(entry_segment):
		_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_ENTRY_SEGMENT_INVALID", "entry segment %s is not in layout" % entry_segment, entry_segment)
	if not entry_segment.is_empty() and _is_layout_display_only_segment(layout, entry_segment):
		_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_ENTRY_SEGMENT_DISPLAY_ONLY", "entry segment %s is display-only" % entry_segment, entry_segment)

	var exit_segment := str(layout.get("exit_segment", ""))
	if not exit_segment.is_empty() and not segments.has(exit_segment):
		_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_EXIT_SEGMENT_INVALID", "exit segment %s is not in layout" % exit_segment, exit_segment)
	if not exit_segment.is_empty() and _is_layout_display_only_segment(layout, exit_segment):
		_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_EXIT_SEGMENT_DISPLAY_ONLY", "exit segment %s is display-only" % exit_segment, exit_segment)

	_validate_runtime_connections(layout.get("next_connections", {}) as Dictionary, segments, layout.get("points", {}) as Dictionary, layout.get("segment_semantics", {}) as Dictionary, diagnostics)
	_validate_runtime_connections(layout.get("previous_connections", {}) as Dictionary, segments, layout.get("points", {}) as Dictionary, layout.get("segment_semantics", {}) as Dictionary, diagnostics)


func _validate_runtime_connections(
	connections: Dictionary,
	segments: Dictionary,
	points: Dictionary,
	segment_semantics: Dictionary,
	diagnostics: Array[Dictionary]
) -> void:
	for raw_segment_id in connections.keys():
		var segment_id := str(raw_segment_id)
		if not segments.has(segment_id):
			_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_CONNECTION_SEGMENT_INVALID", "connection references unknown segment %s" % segment_id, segment_id)
			continue
		if _is_display_only_segment(segment_semantics, segment_id):
			_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_DISPLAY_ONLY_SEGMENT_ROUTED", "connection starts from display-only segment %s" % segment_id, segment_id)
			continue
		var connection := connections[raw_segment_id] as Dictionary
		if connection.has("point") and not points.has(str(connection.get("point", ""))):
			_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_CONNECTION_POINT_INVALID", "connection %s references unknown point" % segment_id, segment_id)
		if connection.has("requires_point") and not points.has(str(connection.get("requires_point", ""))):
			_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_CONNECTION_POINT_INVALID", "connection %s references unknown required point" % segment_id, segment_id)
		if connection.has("segment"):
			var target_segment := str(connection.get("segment", ""))
			if not segments.has(target_segment):
				_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_CONNECTION_TARGET_INVALID", "connection %s references unknown target segment" % segment_id, segment_id)
			elif _is_display_only_segment(segment_semantics, target_segment):
				_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_DISPLAY_ONLY_SEGMENT_ROUTED", "connection %s targets display-only segment %s" % [segment_id, target_segment], target_segment)
		var routes := connection.get("routes", {}) as Dictionary
		for raw_route in routes.keys():
			var target_segment := str(routes[raw_route])
			if not segments.has(target_segment):
				_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_CONNECTION_TARGET_INVALID", "route %s from %s references unknown target segment" % [str(raw_route), segment_id], segment_id)
			elif _is_display_only_segment(segment_semantics, target_segment):
				_add_layout_diagnostic(diagnostics, "RUNTIME_LAYOUT_DISPLAY_ONLY_SEGMENT_ROUTED", "route %s from %s targets display-only segment %s" % [str(raw_route), segment_id, target_segment], target_segment)


func _is_layout_display_only_segment(layout: Dictionary, segment_id: String) -> bool:
	return _is_display_only_segment(layout.get("segment_semantics", {}) as Dictionary, segment_id)


func _is_display_only_segment(segment_semantics: Dictionary, segment_id: String) -> bool:
	var semantics := segment_semantics.get(segment_id, {}) as Dictionary
	return str(semantics.get("runtime_status", SEGMENT_STATUS_ACTIVE)) == SEGMENT_STATUS_DISPLAY_ONLY


func _apply_track_layout(layout: Dictionary) -> void:
	_runtime_layout_id = str(layout.get("layout_id", "runtime_layout"))

	_layout_segment_points.clear()
	var raw_segments := layout.get("segments", {}) as Dictionary
	for raw_segment_id in raw_segments.keys():
		var segment_id := str(raw_segment_id)
		_layout_segment_points[segment_id] = _coerce_segment_points(raw_segments[raw_segment_id])

	_layout_segment_semantics.clear()
	var raw_semantics := layout.get("segment_semantics", {}) as Dictionary
	for raw_segment_id in _layout_segment_points.keys():
		var segment_id := str(raw_segment_id)
		_layout_segment_semantics[segment_id] = (raw_semantics.get(segment_id, {}) as Dictionary).duplicate(true)

	_layout_point_definitions.clear()
	var raw_points := layout.get("points", {}) as Dictionary
	for raw_point_id in raw_points.keys():
		var point_id := str(raw_point_id)
		var raw_definition := raw_points[raw_point_id] as Dictionary
		_layout_point_definitions[point_id] = {
			"id": point_id,
			"semantic_node_id": str(raw_definition.get("semantic_node_id", "")),
			"position": raw_definition.get("position", Vector2.ZERO) as Vector2,
			"routes": (raw_definition.get("routes", []) as Array).duplicate(true),
			"initial_route": str(raw_definition.get("initial_route", POINTS_MAIN)),
		}

	_layout_primary_point_id = str(layout.get("primary_point_id", ""))
	if _layout_primary_point_id.is_empty():
		if _layout_point_definitions.has("P1"):
			_layout_primary_point_id = "P1"
		else:
			var point_ids := get_point_ids()
			if not point_ids.is_empty():
				_layout_primary_point_id = point_ids[0]

	_layout_next_connections = (layout.get("next_connections", {}) as Dictionary).duplicate(true)
	_layout_previous_connections = (layout.get("previous_connections", {}) as Dictionary).duplicate(true)
	_layout_endpoint_b_block_reasons = (layout.get("endpoint_b_block_reasons", {}) as Dictionary).duplicate(true)

	yard_point_routes.clear()
	for raw_point_id in _layout_point_definitions.keys():
		var point_id := str(raw_point_id)
		var definition := _layout_point_definitions[point_id] as Dictionary
		_store_point_route(point_id, str(definition.get("initial_route", POINTS_MAIN)))


func _coerce_segment_points(raw_points: Variant) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if typeof(raw_points) != TYPE_ARRAY:
		return points
	for raw_point in raw_points as Array:
		if typeof(raw_point) == TYPE_VECTOR2:
			points.append(raw_point as Vector2)
		elif typeof(raw_point) == TYPE_ARRAY:
			var pair := raw_point as Array
			if pair.size() >= 2:
				points.append(Vector2(float(pair[0]), float(pair[1])))
	return points


func _get_segment_points(segment_id: String) -> Array:
	return _layout_segment_points.get(segment_id, []) as Array


func _resolve_connection_target(connection: Dictionary) -> String:
	if connection.has("point"):
		var point_id := str(connection.get("point", ""))
		var route := get_point_route(point_id)
		var routes := connection.get("routes", {}) as Dictionary
		return str(routes.get(route, ""))
	if connection.has("segment"):
		if connection.has("requires_point"):
			var required_point := str(connection.get("requires_point", ""))
			var required_route := str(connection.get("requires_route", ""))
			if get_point_route(required_point) != required_route:
				return ""
		return str(connection.get("segment", ""))
	return ""


func _resolve_previous_connection_target(connection: Dictionary) -> String:
	if connection.has("point"):
		var point_id := str(connection.get("point", ""))
		var route := get_point_route(point_id)
		var routes := connection.get("routes", {}) as Dictionary
		return str(routes.get(route, ""))
	if connection.has("segment"):
		return str(connection.get("segment", ""))
	return ""


func _get_endpoint_b_block_reason(segment_id: String) -> String:
	return str(_layout_endpoint_b_block_reasons.get(segment_id, "End of track"))


func _store_point_route(point_id: String, route: String) -> void:
	if point_id == _layout_primary_point_id:
		points_route = route
	else:
		yard_point_routes[point_id] = route


func _toggle_point_route(point_id: String) -> void:
	var definition := _layout_point_definitions.get(point_id, {}) as Dictionary
	var routes := definition.get("routes", []) as Array
	if routes.is_empty():
		return
	var current_route := get_point_route(point_id)
	var current_index := routes.find(current_route)
	if current_index < 0:
		current_index = 0
	var next_index := (current_index + 1) % routes.size()
	_store_point_route(point_id, str(routes[next_index]))


func _vector_points_to_pairs(points: Array) -> Array:
	var pairs: Array = []
	for point in points:
		var vector := point as Vector2
		pairs.append([vector.x, vector.y])
	return pairs


func _add_layout_diagnostic(diagnostics: Array[Dictionary], code: String, message: String, segment_id: String = "") -> void:
	diagnostics.append({
		"code": code,
		"message": message,
		"segment_id": segment_id,
	})


func _get_all_unit_ids() -> Array[String]:
	var ids := active_units.duplicate()
	for consist in detached_consists:
		for unit_id in _get_detached_units(consist):
			if ids.has(unit_id):
				continue
			ids.append(unit_id)
	return ids


func _get_unit_type_for_id(unit_id: String) -> String:
	return get_unit_type(unit_id)


func _find_detached_consist_index(unit_id: String) -> int:
	for index in detached_consists.size():
		if _get_detached_units(detached_consists[index]).has(unit_id):
			return index
	return -1


func _get_active_unit_center_distance(index: int) -> float:
	var cursor := distance
	for unit_index in active_units.size():
		var unit_id := active_units[unit_index]
		var unit_length := get_unit_length(unit_id)
		var center_distance := cursor - unit_length * 0.5
		if unit_index == index:
			return center_distance
		cursor -= unit_length + COUPLER_GAP

	return distance


func _find_active_joint_index(front_unit: String, rear_unit: String) -> int:
	if active_units.size() <= 1:
		return -1

	for index in range(active_units.size() - 1):
		if active_units[index] == front_unit and active_units[index + 1] == rear_unit:
			return index

	return -1


func _get_active_joint_info(index: int) -> Dictionary:
	if index < 0 or index >= active_units.size() - 1:
		return {}

	var front_unit := active_units[index]
	var rear_unit := active_units[index + 1]
	var front_center_distance := _get_active_unit_center_distance(index)
	var front_rear_coupler_distance := front_center_distance - get_unit_length(front_unit) * 0.5
	var joint_distance := front_rear_coupler_distance - COUPLER_GAP * 0.5
	var rail_position := _resolve_path_distance(current_segment, joint_distance)
	var segment_id := str(rail_position["segment"])
	var segment_distance := float(rail_position["distance"])
	var position := get_position_at_distance(segment_id, segment_distance)
	var tangent := get_tangent_at_distance(segment_id, segment_distance)
	var normal := Vector2(-tangent.y, tangent.x).normalized()

	return {
		"id": "%s/%s" % [front_unit, rear_unit],
		"front_unit": front_unit,
		"rear_unit": rear_unit,
		"index": index,
		"segment": segment_id,
		"distance": segment_distance,
		"position": position,
		"anchor": position + normal * JOINT_OPERATOR_ANCHOR_OFFSET,
		"angle": tangent.angle(),
	}


func _slice_active_units(start_index: int, end_index: int) -> Array[String]:
	var result: Array[String] = []
	var start := clampi(start_index, 0, active_units.size())
	var end := clampi(end_index, start, active_units.size())
	for index in range(start, end):
		result.append(active_units[index])
	return result


func _get_active_rear_coupler_distance() -> float:
	return distance - _get_active_consist_length()


func _get_active_consist_length() -> float:
	var total := 0.0
	for index in active_units.size():
		total += get_unit_length(active_units[index])
		if index < active_units.size() - 1:
			total += COUPLER_GAP
	return total


func _get_active_interval() -> Dictionary:
	return {
		"segment": current_segment,
		"rear": _get_active_rear_coupler_distance(),
		"front": distance,
	}


func _get_detached_interval(consist: Dictionary) -> Dictionary:
	var units := _get_detached_units(consist)
	var segment_id := _get_detached_segment(consist)
	if units.is_empty():
		var fallback_distance := float(consist.get("distance", 0.0))
		return {
			"segment": segment_id,
			"rear": fallback_distance,
			"front": fallback_distance,
		}

	var front := _get_detached_front_coupler_distance(consist)
	var rear := _get_detached_rear_coupler_distance(consist)
	return {
		"segment": segment_id,
		"rear": rear,
		"front": front,
	}


func _find_contact_for_amount(amount: float) -> Dictionary:
	if is_zero_approx(amount) or active_units.is_empty():
		return {}

	var active_interval := _get_active_interval()
	var nearest: Dictionary = {}
	var nearest_distance := INF
	if amount > 0.0:
		var current_front := float(active_interval["front"])
		var desired_front := current_front + amount
		for index in detached_consists.size():
			var consist := detached_consists[index]
			var detached_interval := _project_detached_interval_for_motion(_get_detached_interval(consist), amount)
			if detached_interval.is_empty():
				continue

			var target_rear := float(detached_interval["rear"])
			if target_rear < current_front - CONTACT_EPSILON:
				continue
			if target_rear > desired_front + CONTACT_EPSILON:
				continue

			var travel := maxf(target_rear - current_front, 0.0)
			if travel >= nearest_distance:
				continue

			nearest_distance = travel
			var units := _get_detached_units(consist)
			nearest = _make_contact_candidate(index, travel, COUPLER_FRONT, active_units[0], COUPLER_REAR, units[units.size() - 1])
	else:
		var current_rear := float(active_interval["rear"])
		var desired_rear := current_rear + amount
		for index in detached_consists.size():
			var consist := detached_consists[index]
			var detached_interval := _project_detached_interval_for_motion(_get_detached_interval(consist), amount)
			if detached_interval.is_empty():
				continue

			var target_front := float(detached_interval["front"])
			if target_front > current_rear + CONTACT_EPSILON:
				continue
			if target_front < desired_rear - CONTACT_EPSILON:
				continue

			var travel := minf(target_front - current_rear, 0.0)
			var travel_distance := absf(travel)
			if travel_distance >= nearest_distance:
				continue

			nearest_distance = travel_distance
			var units := _get_detached_units(consist)
			nearest = _make_contact_candidate(index, travel, COUPLER_REAR, active_units[active_units.size() - 1], COUPLER_FRONT, units[0])

	return nearest


func _project_detached_interval_for_motion(detached_interval: Dictionary, amount: float) -> Dictionary:
	# Contact distances are compared in the active segment's local coordinate
	# system. Adjacent connected segments are projected across the turnout so a
	# leading coupler can detect rolling stock BEFORE the active reference point
	# itself changes segments. This is essential in reverse because the rear
	# coupler leads and may cross endpoint A while the front coupler is still on
	# the source segment.
	var detached_segment := str(detached_interval.get("segment", ""))
	if detached_segment == current_segment:
		return detached_interval.duplicate(true)

	if amount < 0.0:
		# Do not detect rolling stock through a turnout that is physically aligned
		# against this trailing movement. The route barrier is resolved before the
		# active rear coupler enters the adjacent segment.
		if _get_active_rear_coupler_distance() >= -CONTACT_EPSILON and not _is_trailing_route_aligned(current_segment):
			return {}

		var previous_segment := _get_previous_segment(current_segment)
		if previous_segment == "" or detached_segment != previous_segment:
			return {}

		var previous_length := get_segment_length(previous_segment)
		return {
			"segment": detached_segment,
			"rear": float(detached_interval["rear"]) - previous_length,
			"front": float(detached_interval["front"]) - previous_length,
		}

	if amount > 0.0:
		var next_segment := _get_next_segment(current_segment)
		if next_segment == "" or detached_segment != next_segment:
			return {}

		var current_length := get_segment_length(current_segment)
		return {
			"segment": detached_segment,
			"rear": current_length + float(detached_interval["rear"]),
			"front": current_length + float(detached_interval["front"]),
		}

	return {}


func _make_contact_candidate(index: int, travel: float, active_end: String, active_unit: String, detached_end: String, detached_unit: String) -> Dictionary:
	return {
		"index": index,
		"travel": travel,
		"active_end": active_end,
		"active_unit": active_unit,
		"detached_end": detached_end,
		"detached_unit": detached_unit,
	}


func _register_contact(contact: Dictionary) -> void:
	var relative_speed := absf(speed)
	var contact_type := CONTACT_CONTROLLED
	var coupling_permitted := _are_coupler_ends_compatible(str(contact["active_end"]), str(contact["detached_end"]))
	var result := "stopped"
	if relative_speed > safe_contact_speed:
		contact_type = CONTACT_IMPACT
		coupling_permitted = false
		condition_state = CONDITION_DAMAGED
		result = CONDITION_DAMAGED

	last_contact = {
		"index": int(contact["index"]),
		"type": contact_type,
		"active_unit": str(contact["active_unit"]),
		"detached_unit": str(contact["detached_unit"]),
		"active_end": str(contact["active_end"]),
		"detached_end": str(contact["detached_end"]),
		"relative_speed": relative_speed,
		"safe_contact_speed": safe_contact_speed,
		"coupling_permitted": coupling_permitted,
		"condition": condition_state,
		"result": result,
		"segment": current_segment,
		"distance": distance,
		"target_consist": _format_consist_units(_get_detached_units(detached_consists[int(contact["index"])])),
	}
	speed = 0.0
	throttle = 0.0
	blocked_reason = "%s contact with %s" % [contact_type.capitalize(), str(contact["detached_unit"])]


func _find_contact_coupling_target_info(unit_id: String = "") -> Dictionary:
	if last_contact.is_empty():
		return {}
	if str(last_contact.get("type", CONTACT_NONE)) != CONTACT_CONTROLLED:
		return {}
	if not bool(last_contact.get("coupling_permitted", false)):
		return {}

	var target_index := int(last_contact.get("index", -1))
	if target_index < 0 or target_index >= detached_consists.size():
		return {}

	var consist := detached_consists[target_index]
	var units := _get_detached_units(consist)
	if units.is_empty():
		return {}
	if unit_id != "" and not units.has(unit_id):
		return {}

	var active_end := str(last_contact.get("active_end", ""))
	var detached_end := str(last_contact.get("detached_end", ""))
	if not _are_coupler_ends_compatible(active_end, detached_end):
		return {}

	var active_unit := _get_active_endpoint_unit(active_end)
	var detached_unit := _get_detached_endpoint_unit(consist, detached_end)
	if active_unit == "" or detached_unit == "":
		return {}
	if active_unit != str(last_contact.get("active_unit", "")):
		return {}
	if detached_unit != str(last_contact.get("detached_unit", "")):
		return {}
	if str(last_contact.get("segment", "")) != current_segment:
		return {}

	# Contact detection already supports an exposed coupler meeting rolling stock
	# on the structurally adjacent segment across an aligned turnout. Coupling must
	# validate in the SAME projected path coordinate system; comparing the raw
	# segment-local distances incorrectly rejects legitimate cross-turnout contacts.
	var motion_sign := 1.0
	if active_end == COUPLER_REAR:
		motion_sign = -1.0

	var projected_interval := _project_detached_interval_for_motion(
		_get_detached_interval(consist),
		motion_sign
	)
	if projected_interval.is_empty():
		return {}

	var active_coupler := _get_active_coupler_distance(active_end)
	var target_coupler := 0.0
	if detached_end == COUPLER_FRONT:
		target_coupler = float(projected_interval["front"])
	elif detached_end == COUPLER_REAR:
		target_coupler = float(projected_interval["rear"])
	else:
		return {}

	var coupler_distance := absf(active_coupler - target_coupler)
	if coupler_distance > CONTACT_EPSILON:
		return {}

	return {
		"index": target_index,
		"active_end": active_end,
		"detached_end": detached_end,
		"active_unit": active_unit,
		"unit": detached_unit,
		"distance": coupler_distance,
		"segment": current_segment,
		"target_segment": _get_detached_segment(consist),
		"contact_distance": (active_coupler + target_coupler) * 0.5,
	}


func _are_coupler_ends_compatible(active_end: String, detached_end: String) -> bool:
	return (active_end == COUPLER_FRONT and detached_end == COUPLER_REAR) \
		or (active_end == COUPLER_REAR and detached_end == COUPLER_FRONT)


func _get_active_endpoint_unit(endpoint: String) -> String:
	if active_units.is_empty():
		return ""
	if endpoint == COUPLER_FRONT:
		return active_units[0]
	if endpoint == COUPLER_REAR:
		return active_units[active_units.size() - 1]
	return ""


func _get_detached_endpoint_unit(consist: Dictionary, endpoint: String) -> String:
	var units := _get_detached_units(consist)
	if units.is_empty():
		return ""
	if endpoint == COUPLER_FRONT:
		return units[0]
	if endpoint == COUPLER_REAR:
		return units[units.size() - 1]
	return ""


func _get_active_coupler_distance(endpoint: String) -> float:
	if endpoint == COUPLER_FRONT:
		return distance
	if endpoint == COUPLER_REAR:
		return _get_active_rear_coupler_distance()
	return distance


func _get_detached_coupler_distance(consist: Dictionary, endpoint: String) -> float:
	if endpoint == COUPLER_FRONT:
		return _get_detached_front_coupler_distance(consist)
	if endpoint == COUPLER_REAR:
		return _get_detached_rear_coupler_distance(consist)
	return float(consist.get("distance", 0.0))


func _get_detached_front_coupler_distance(consist: Dictionary) -> float:
	var units := _get_detached_units(consist)
	if units.is_empty():
		return float(consist.get("distance", 0.0))

	return float(consist.get("distance", 0.0)) + get_unit_length(units[0]) * 0.5


func _get_detached_rear_coupler_distance(consist: Dictionary) -> float:
	var units := _get_detached_units(consist)
	if units.is_empty():
		return float(consist.get("distance", 0.0))

	var cursor := float(consist.get("distance", 0.0))
	var rear := cursor - get_unit_length(units[0]) * 0.5
	for index in range(1, units.size()):
		cursor -= get_unit_length(units[index - 1]) * 0.5
		cursor -= COUPLER_GAP
		cursor -= get_unit_length(units[index]) * 0.5
		rear = cursor - get_unit_length(units[index]) * 0.5
	return rear


func _intervals_overlap(left: Dictionary, right: Dictionary) -> bool:
	return float(left["rear"]) < float(right["front"]) - CONTACT_EPSILON \
		and float(left["front"]) > float(right["rear"]) + CONTACT_EPSILON


func _get_detached_draw_states(consist: Dictionary) -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	var segment_id := _get_detached_segment(consist)
	var cursor := float(consist.get("distance", 0.0))
	for unit_id in _get_detached_units(consist):
		var unit_length := get_unit_length(unit_id)
		var rail_position := _resolve_path_distance(segment_id, cursor)
		var resolved_segment := str(rail_position["segment"])
		var resolved_distance := float(rail_position["distance"])
		states.append({
			"id": unit_id,
			"type_id": get_unit_type_id(unit_id),
			"type": get_unit_type(unit_id),
			"label": get_unit_label(unit_id),
			"capability_summary": get_unit_capability_summary(unit_id),
			"segment": resolved_segment,
			"distance": resolved_distance,
			"position": get_position_at_distance(resolved_segment, resolved_distance),
			"angle": get_tangent_at_distance(resolved_segment, resolved_distance).angle(),
			"active": false,
			"length": unit_length,
			"controlled": unit_id == controlled_power_unit_id,
			"powered": is_powered_unit(unit_id) and get_powered_unit_condition(unit_id) == CONDITION_OPERATIONAL,
			"condition": get_powered_unit_condition(unit_id),
		})
		cursor -= unit_length + COUPLER_GAP

	return states


func _get_detached_units(consist: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for unit_id in consist.get("units", []):
		result.append(str(unit_id))
	return result


func _get_detached_segment(consist: Dictionary) -> String:
	return str(consist.get("segment", ""))


func _same_units(left: Array[String], right: Array[String]) -> bool:
	if left.size() != right.size():
		return false

	for index in left.size():
		if left[index] != right[index]:
			return false

	return true


func _format_consist_units(units: Array[String]) -> String:
	var text := ""
	for unit_id in units:
		text += "[%s]" % unit_id
	return text


func _format_coupler_summary() -> String:
	var coupled_links: int = maxi(active_units.size() - 1, 0)
	var free_ends: int = 2 + detached_consists.size() * 2
	return "%d coupled, %d free" % [coupled_links, free_ends]
