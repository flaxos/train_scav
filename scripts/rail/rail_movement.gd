extends RefCounted
class_name RailMovement

const SEGMENT_MAIN_WEST := "main_west"
const SEGMENT_MAIN_EAST := "main_east"
const SEGMENT_SIDING := "siding"

const POINTS_MAIN := "main"
const POINTS_SIDING := "siding"

const SWITCH_POSITION := Vector2(540.0, 360.0)

const _SEGMENT_POINTS := {
	SEGMENT_MAIN_WEST: [Vector2(160.0, 360.0), SWITCH_POSITION],
	SEGMENT_MAIN_EAST: [SWITCH_POSITION, Vector2(1120.0, 360.0)],
	SEGMENT_SIDING: [SWITCH_POSITION, Vector2(1040.0, 500.0)],
}

var current_segment: String = SEGMENT_MAIN_WEST
var distance: float = 80.0
var speed: float = 0.0
var throttle: float = 0.0
var direction: int = 1
var points_route: String = POINTS_MAIN
var blocked_reason: String = ""

var max_speed: float = 150.0
var acceleration: float = 95.0
var brake_deceleration: float = 260.0
var coast_deceleration: float = 35.0


func step(delta: float, brake_active: bool) -> void:
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


func get_segment_length(segment_id: String = current_segment) -> float:
	var points: Array = _SEGMENT_POINTS[segment_id]
	return (points[1] as Vector2).distance_to(points[0] as Vector2)


func get_position() -> Vector2:
	var points: Array = _SEGMENT_POINTS[current_segment]
	var start := points[0] as Vector2
	var end := points[1] as Vector2
	var ratio := distance / maxf(get_segment_length(), 0.001)
	return start.lerp(end, ratio)


func get_heading_angle() -> float:
	var points: Array = _SEGMENT_POINTS[current_segment]
	var start := points[0] as Vector2
	var end := points[1] as Vector2
	var angle := (end - start).angle()
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
	lines.append("Speed: %.1f" % speed)
	lines.append("Throttle: %d%%" % roundi(throttle * 100.0))
	lines.append("Direction: %s" % direction_label)
	lines.append("Points: %s" % points_route)
	if blocked_reason != "":
		lines.append("Blocked: %s" % blocked_reason)
	return lines


func get_track_segments() -> Dictionary:
	return _SEGMENT_POINTS


func _update_speed(delta: float, brake_active: bool) -> void:
	if brake_active:
		speed = maxf(speed - brake_deceleration * delta, 0.0)
		return

	var target_speed := throttle * max_speed
	var rate := acceleration
	if target_speed < speed:
		rate = coast_deceleration

	speed = move_toward(speed, target_speed, rate * delta)


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
