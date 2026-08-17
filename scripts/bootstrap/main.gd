extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

const BACKGROUND_COLOR := Color(0.055, 0.062, 0.071, 1.0)
const ROUTE_MAIN_COLOR := Color(0.30, 0.75, 0.95, 1.0)
const ROUTE_SIDING_COLOR := Color(0.95, 0.58, 0.20, 1.0)
const ROUTE_INACTIVE_COLOR := Color(0.42, 0.45, 0.48, 1.0)
const ROUTE_CURRENT_COLOR := Color(0.92, 0.80, 0.32, 1.0)

@onready var instruction_label: Label = %InstructionLabel
@onready var debug_label: Label = %DebugLabel

var rail: RailMovement
var _throttle_up_held: bool = false
var _throttle_down_held: bool = false
var _brake_held: bool = false


func _ready() -> void:
	rail = RailMovement.new()
	instruction_label.text = "Train Scav - Sprint 1\nW/S: throttle   Space: brake   R: reverse while stopped   E: points"
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR, true)
	_draw_track()
	_draw_switch()
	_draw_locomotive()


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
	var pos := rail.get_position()
	var angle := rail.get_heading_angle()
	var transform := Transform2D(angle, pos)
	var body := PackedVector2Array([
		Vector2(-34.0, -14.0),
		Vector2(24.0, -14.0),
		Vector2(36.0, 0.0),
		Vector2(24.0, 14.0),
		Vector2(-34.0, 14.0),
	])
	var transformed_body := PackedVector2Array()
	for point in body:
		transformed_body.append(transform * point)

	draw_colored_polygon(transformed_body, Color(0.82, 0.18, 0.16, 1.0))
	var outline := PackedVector2Array(transformed_body)
	outline.append(transformed_body[0])
	draw_polyline(outline, Color(0.08, 0.08, 0.08, 1.0), 3.0, true)


func _get_track_color(segment_id: String) -> Color:
	if segment_id == rail.current_segment:
		return ROUTE_CURRENT_COLOR
	if segment_id == RailMovement.SEGMENT_MAIN_EAST and rail.points_route == RailMovement.POINTS_MAIN:
		return ROUTE_MAIN_COLOR
	if segment_id == RailMovement.SEGMENT_SIDING and rail.points_route == RailMovement.POINTS_SIDING:
		return ROUTE_SIDING_COLOR
	return ROUTE_INACTIVE_COLOR
