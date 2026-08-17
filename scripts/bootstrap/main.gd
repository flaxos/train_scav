extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

const BACKGROUND_COLOR := Color(0.055, 0.062, 0.071, 1.0)
const ROUTE_MAIN_COLOR := Color(0.30, 0.75, 0.95, 1.0)
const ROUTE_SIDING_COLOR := Color(0.95, 0.58, 0.20, 1.0)
const ROUTE_INACTIVE_COLOR := Color(0.42, 0.45, 0.48, 1.0)
const ROUTE_CURRENT_COLOR := Color(0.92, 0.80, 0.32, 1.0)
const COUPLER_COLOR := Color(0.05, 0.05, 0.05, 1.0)
const ACTIVE_COUPLING_ZONE_COLOR := Color(0.35, 0.82, 0.95, 0.18)
const DETACHED_COUPLING_ZONE_COLOR := Color(0.95, 0.68, 0.28, 0.18)
const UNIT_WIDTH := 30.0

@onready var instruction_label: Label = %InstructionLabel
@onready var debug_label: Label = %DebugLabel

var rail: RailMovement
var _throttle_up_held: bool = false
var _throttle_down_held: bool = false
var _brake_held: bool = false


func _ready() -> void:
	rail = RailMovement.new()
	instruction_label.text = "Train Scav - Sprint 2\nW/S: throttle   Space: brake   R: reverse while stopped   E: points\nQ: decouple rear wagon   C: couple aligned wagon at low speed"
	queue_redraw()


func _process(delta: float) -> void:
	if _throttle_up_held:
		rail.adjust_throttle(delta * 0.65)
	if _throttle_down_held:
		rail.adjust_throttle(-delta * 0.9)

	rail.step(delta, _brake_held)
	debug_label.text = "\n".join(rail.get_debug_lines())
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.echo:
		return

	match key_event.keycode:
		KEY_W, KEY_UP:
			_throttle_up_held = key_event.pressed
		KEY_S, KEY_DOWN:
			_throttle_down_held = key_event.pressed
		KEY_SPACE:
			_brake_held = key_event.pressed
		KEY_E:
			if key_event.pressed:
				rail.toggle_points()
		KEY_R:
			if key_event.pressed:
				rail.reverse_direction()
		KEY_Q:
			if key_event.pressed:
				rail.decouple_rear()
		KEY_C:
			if key_event.pressed:
				rail.couple_nearest()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR, true)
	_draw_track()
	_draw_switch()
	_draw_coupling_zones()
	_draw_rolling_stock()
	_draw_couplers()


func _draw_track() -> void:
	var segments := rail.get_track_segments()
	for segment_id: String in segments:
		var points: Array = segments[segment_id]
		var color := _get_track_color(segment_id)

		var start := points[0] as Vector2
		var end := points[1] as Vector2
		draw_line(start, end, Color(0.15, 0.15, 0.15, 1.0), 18.0, true)
		draw_line(start, end, color, 8.0, true)


func _draw_switch() -> void:
	var switch_color := ROUTE_MAIN_COLOR
	if rail.points_route == RailMovement.POINTS_SIDING:
		switch_color = ROUTE_SIDING_COLOR

	draw_circle(RailMovement.SWITCH_POSITION, 14.0, switch_color)


func _draw_locomotive() -> void:
	_draw_rolling_stock()


func _draw_rolling_stock() -> void:
	for state in rail.get_unit_draw_states():
		_draw_unit(state)


func _draw_couplers() -> void:
	var active_states: Array[Dictionary] = []
	for state in rail.get_unit_draw_states():
		var ends := _get_unit_endpoints(state)
		draw_circle(ends["front"], 5.0, COUPLER_COLOR)
		draw_circle(ends["rear"], 5.0, COUPLER_COLOR)
		if bool(state["active"]):
			active_states.append(state)

	for index in active_states.size() - 1:
		var left_ends := _get_unit_endpoints(active_states[index])
		var right_ends := _get_unit_endpoints(active_states[index + 1])
		draw_line(left_ends["rear"], right_ends["front"], COUPLER_COLOR, 3.0, true)


func _draw_coupling_zones() -> void:
	var active_states: Array[Dictionary] = []
	var detached_states: Array[Dictionary] = []
	for state in rail.get_unit_draw_states():
		if bool(state["active"]):
			active_states.append(state)
		else:
			detached_states.append(state)

	if not active_states.is_empty():
		var active_rear := _get_unit_endpoints(active_states[active_states.size() - 1])["rear"] as Vector2
		draw_circle(active_rear, RailMovement.COUPLING_RANGE, ACTIVE_COUPLING_ZONE_COLOR)

	for state in detached_states:
		var detached_front := _get_unit_endpoints(state)["front"] as Vector2
		draw_circle(detached_front, RailMovement.COUPLING_RANGE, DETACHED_COUPLING_ZONE_COLOR)


func _draw_unit(state: Dictionary) -> void:
	var pos := state["position"] as Vector2
	var angle := float(state["angle"])
	var unit_length := float(state["length"])
	var transform := Transform2D(angle, pos)
	var body := _get_unit_polygon(str(state["type"]), unit_length)
	var transformed_body := PackedVector2Array()
	for point in body:
		transformed_body.append(transform * point)

	draw_colored_polygon(transformed_body, _get_unit_color(str(state["type"]), bool(state["active"])))
	var outline := PackedVector2Array(transformed_body)
	outline.append(transformed_body[0])
	draw_polyline(outline, Color(0.08, 0.08, 0.08, 1.0), 2.5, true)


func _get_unit_polygon(unit_type: String, unit_length: float) -> PackedVector2Array:
	var half_length := unit_length * 0.5
	var half_width := UNIT_WIDTH * 0.5
	if unit_type == RailMovement.UNIT_LOCOMOTIVE:
		return PackedVector2Array([
			Vector2(-half_length, -half_width),
			Vector2(half_length - 12.0, -half_width),
			Vector2(half_length, 0.0),
			Vector2(half_length - 12.0, half_width),
			Vector2(-half_length, half_width),
		])

	return PackedVector2Array([
		Vector2(-half_length, -half_width),
		Vector2(half_length, -half_width),
		Vector2(half_length, half_width),
		Vector2(-half_length, half_width),
	])


func _get_unit_color(unit_type: String, active: bool) -> Color:
	var color := Color(0.78, 0.78, 0.78, 1.0)
	match unit_type:
		RailMovement.UNIT_LOCOMOTIVE:
			color = Color(0.82, 0.18, 0.16, 1.0)
		RailMovement.UNIT_FLATBED:
			color = Color(0.58, 0.62, 0.68, 1.0)
		RailMovement.UNIT_BOXCAR:
			color = Color(0.38, 0.72, 0.40, 1.0)
		RailMovement.UNIT_TANKER:
			color = Color(0.78, 0.68, 0.28, 1.0)

	if not active:
		color = color.darkened(0.35)
	return color


func _get_unit_endpoints(state: Dictionary) -> Dictionary:
	var pos := state["position"] as Vector2
	var angle := float(state["angle"])
	var tangent := Vector2.RIGHT.rotated(angle)
	var half_length := float(state["length"]) * 0.5
	return {
		"front": pos + tangent * half_length,
		"rear": pos - tangent * half_length,
	}


func _get_track_color(segment_id: String) -> Color:
	if segment_id == rail.current_segment:
		return ROUTE_CURRENT_COLOR
	if segment_id == RailMovement.SEGMENT_MAIN_EAST and rail.points_route == RailMovement.POINTS_MAIN:
		return ROUTE_MAIN_COLOR
	if segment_id == RailMovement.SEGMENT_SIDING and rail.points_route == RailMovement.POINTS_SIDING:
		return ROUTE_SIDING_COLOR
	return ROUTE_INACTIVE_COLOR
