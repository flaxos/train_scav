extends RefCounted
class_name RailMovement

const SEGMENT_MAIN_WEST := "main_west"
const SEGMENT_MAIN_EAST := "main_east"
const SEGMENT_SIDING := "siding"

const POINTS_MAIN := "main"
const POINTS_SIDING := "siding"

const SWITCH_POSITION := Vector2(540.0, 360.0)
const COUPLER_GAP := 8.0
const COUPLING_RANGE := 24.0

const UNIT_LOCOMOTIVE := "locomotive"
const UNIT_FLATBED := "flatbed"
const UNIT_BOXCAR := "boxcar"
const UNIT_TANKER := "tanker"

const _UNIT_TYPES := {
	"L": UNIT_LOCOMOTIVE,
	"A": UNIT_FLATBED,
	"B": UNIT_BOXCAR,
	"C": UNIT_TANKER,
}

const _UNIT_LABELS := {
	"L": "Loco",
	"A": "Flatbed A",
	"B": "Boxcar B",
	"C": "Tanker C",
}

const _UNIT_LENGTHS := {
	"L": 64.0,
	"A": 56.0,
	"B": 56.0,
	"C": 52.0,
}

const _UNIT_MASSES := {
	"L": 90.0,
	"A": 35.0,
	"B": 42.0,
	"C": 50.0,
}

const _SIDING_C_CENTER_DISTANCE := 36.0

const _SEGMENT_POINTS := {
	SEGMENT_MAIN_WEST: [Vector2(160.0, 360.0), SWITCH_POSITION],
	SEGMENT_MAIN_EAST: [SWITCH_POSITION, Vector2(1120.0, 360.0)],
	SEGMENT_SIDING: [SWITCH_POSITION, Vector2(1040.0, 500.0)],
}

var current_segment: String = SEGMENT_MAIN_WEST
var distance: float = 336.0
var speed: float = 0.0
var throttle: float = 0.0
var direction: int = 1
var points_route: String = POINTS_MAIN
var brake_active: bool = false
var blocked_reason: String = ""
var active_units: Array[String] = ["L", "A", "B"]
var detached_consists: Array[Dictionary] = [
	{
		"units": ["C"],
		"segment": SEGMENT_SIDING,
		"distance": _SIDING_C_CENTER_DISTANCE,
	},
]

var max_speed: float = 150.0
var acceleration: float = 95.0
var brake_deceleration: float = 260.0
var coast_deceleration: float = 35.0
var max_coupling_speed: float = 14.0


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


func set_points_route(route: String) -> void:
	if route != POINTS_MAIN and route != POINTS_SIDING:
		return

	points_route = route


func toggle_points() -> void:
	if points_route == POINTS_MAIN:
		points_route = POINTS_SIDING
	else:
		points_route = POINTS_MAIN


func is_stopped() -> bool:
	return speed <= 0.05


func get_active_consist_ids() -> Array[String]:
	return active_units.duplicate()


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
		var unit_type := get_unit_type(unit_id)
		if unit_type == UNIT_LOCOMOTIVE:
			continue

		wagon_types[unit_type] = true

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


func get_total_mass() -> float:
	var total := 0.0
	for unit_id in active_units:
		total += get_unit_mass(unit_id)
	return total


func get_unit_type(unit_id: String) -> String:
	return str(_UNIT_TYPES.get(unit_id, "unknown"))


func get_unit_label(unit_id: String) -> String:
	return str(_UNIT_LABELS.get(unit_id, unit_id))


func get_unit_length(unit_id: String) -> float:
	return float(_UNIT_LENGTHS.get(unit_id, 48.0))


func get_unit_mass(unit_id: String) -> float:
	return float(_UNIT_MASSES.get(unit_id, 10.0))


func get_unit_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	var cursor := distance
	for index in active_units.size():
		var unit_id := active_units[index]
		var unit_length := get_unit_length(unit_id)
		var center_distance := cursor - unit_length * 0.5
		states.append({
			"id": unit_id,
			"type": get_unit_type(unit_id),
			"label": get_unit_label(unit_id),
			"segment": current_segment,
			"distance": center_distance,
			"position": get_world_position(current_segment, center_distance),
			"angle": get_segment_angle(current_segment),
			"active": true,
			"length": unit_length,
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
	if active_units.size() <= 1:
		blocked_reason = "No rear wagon to decouple"
		return false

	var rear_index := active_units.size() - 1
	var unit_id := active_units[rear_index]
	var center_distance := _get_active_unit_center_distance(rear_index)
	active_units.remove_at(rear_index)
	detached_consists.append({
		"units": [unit_id],
		"segment": current_segment,
		"distance": center_distance,
	})
	blocked_reason = "Decoupled %s" % unit_id
	return true


func can_couple_unit(unit_id: String) -> bool:
	return _find_nearest_coupling_target(unit_id) >= 0


func couple_nearest() -> bool:
	var target_index := _find_nearest_coupling_target()
	if target_index < 0:
		blocked_reason = "No coupler in range"
		return false
	if speed > max_coupling_speed:
		blocked_reason = "Too fast to couple"
		return false

	var consist := detached_consists[target_index]
	var units := _get_detached_units(consist)
	for unit_id in units:
		active_units.append(unit_id)
	detached_consists.remove_at(target_index)
	blocked_reason = "Coupled %s" % _format_consist_units(units)
	return true


func get_segment_length(segment_id: String = current_segment) -> float:
	var points: Array = _SEGMENT_POINTS[segment_id]
	return (points[1] as Vector2).distance_to(points[0] as Vector2)


func get_world_position(segment_id: String, segment_distance: float) -> Vector2:
	var points: Array = _SEGMENT_POINTS[segment_id]
	var start := points[0] as Vector2
	var end := points[1] as Vector2
	var ratio := segment_distance / maxf(get_segment_length(segment_id), 0.001)
	return start.lerp(end, ratio)


func get_segment_angle(segment_id: String) -> float:
	var points: Array = _SEGMENT_POINTS[segment_id]
	var start := points[0] as Vector2
	var end := points[1] as Vector2
	return (end - start).angle()


func get_position() -> Vector2:
	return get_world_position(current_segment, distance)


func get_heading_angle() -> float:
	var angle := get_segment_angle(current_segment)
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
	lines.append("Speed: %.1f" % speed)
	lines.append("Throttle: %d%%" % roundi(throttle * 100.0))
	lines.append("Direction: %s" % direction_label)
	lines.append("Brake: %s" % _format_bool(brake_active))
	lines.append("Points: %s" % points_route)
	lines.append("Mass: %.1f t" % get_total_mass())
	lines.append("Couplers: %s" % _format_coupler_summary())
	lines.append("Detached: %s" % get_detached_summary())
	if blocked_reason != "":
		lines.append("Blocked: %s" % blocked_reason)
	return lines


func get_track_segments() -> Dictionary:
	return _SEGMENT_POINTS


func _update_speed(delta: float, brake_active: bool) -> void:
	if brake_active:
		throttle = 0.0
		speed = maxf(speed - brake_deceleration * delta, 0.0)
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
	var travel := absf(amount)
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
	match current_segment:
		SEGMENT_MAIN_WEST:
			if points_route == POINTS_SIDING:
				current_segment = SEGMENT_SIDING
			else:
				current_segment = SEGMENT_MAIN_EAST
			distance = 0.0
			return true
		SEGMENT_MAIN_EAST:
			blocked_reason = "End of main line"
			return false
		SEGMENT_SIDING:
			blocked_reason = "End of siding"
			return false

	return false


func _leave_endpoint_a() -> bool:
	match current_segment:
		SEGMENT_MAIN_WEST:
			blocked_reason = "End of main line"
			return false
		SEGMENT_MAIN_EAST:
			current_segment = SEGMENT_MAIN_WEST
			distance = get_segment_length(SEGMENT_MAIN_WEST)
			return true
		SEGMENT_SIDING:
			current_segment = SEGMENT_MAIN_WEST
			distance = get_segment_length(SEGMENT_MAIN_WEST)
			return true

	return false


func _get_all_unit_ids() -> Array[String]:
	var ids := active_units.duplicate()
	for consist in detached_consists:
		for unit_id in _get_detached_units(consist):
			if ids.has(unit_id):
				continue
			ids.append(unit_id)
	return ids


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


func _get_active_rear_coupler_distance() -> float:
	var cursor := distance
	for index in active_units.size():
		cursor -= get_unit_length(active_units[index])
		if index < active_units.size() - 1:
			cursor -= COUPLER_GAP
	return cursor


func _find_nearest_coupling_target(unit_id: String = "") -> int:
	var rear_distance := _get_active_rear_coupler_distance()
	var best_index := -1
	var best_distance := INF
	for index in detached_consists.size():
		var consist := detached_consists[index]
		if _get_detached_segment(consist) != current_segment:
			continue

		var units := _get_detached_units(consist)
		if unit_id != "" and not units.has(unit_id):
			continue

		var target_front := _get_detached_front_coupler_distance(consist)
		var coupler_distance := absf(rear_distance - target_front)
		if coupler_distance > COUPLING_RANGE or coupler_distance >= best_distance:
			continue

		best_index = index
		best_distance = coupler_distance

	return best_index


func _get_detached_front_coupler_distance(consist: Dictionary) -> float:
	var units := _get_detached_units(consist)
	if units.is_empty():
		return float(consist.get("distance", 0.0))

	return float(consist.get("distance", 0.0)) + get_unit_length(units[0]) * 0.5


func _get_detached_draw_states(consist: Dictionary) -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	var segment_id := _get_detached_segment(consist)
	var cursor := float(consist.get("distance", 0.0))
	for unit_id in _get_detached_units(consist):
		var unit_length := get_unit_length(unit_id)
		states.append({
			"id": unit_id,
			"type": get_unit_type(unit_id),
			"label": get_unit_label(unit_id),
			"segment": segment_id,
			"distance": cursor,
			"position": get_world_position(segment_id, cursor),
			"angle": get_segment_angle(segment_id),
			"active": false,
			"length": unit_length,
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
