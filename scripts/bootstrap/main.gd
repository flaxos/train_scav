extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

@onready var instruction_label: Label = %InstructionLabel
@onready var debug_label: Label = %DebugLabel

var rail: RailMovement


func _ready() -> void:
	rail = RailMovement.new()
	instruction_label.text = "Train Scav - Sprint 1\nW/S: throttle   Space: brake   R: reverse while stopped   E: points"
	queue_redraw()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		rail.adjust_throttle(delta * 0.65)
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		rail.adjust_throttle(-delta * 0.9)

	var braking := Input.is_key_pressed(KEY_SPACE)
	rail.step(delta, braking)
	debug_label.text = "\n".join(rail.get_debug_lines())
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_E:
			rail.toggle_points()
		KEY_R:
			rail.reverse_direction()


func _draw() -> void:
	_draw_track()
	_draw_switch()
	_draw_locomotive()


func _draw_track() -> void:
	var segments := rail.get_track_segments()
	for segment_id: String in segments:
		var points: Array = segments[segment_id]
		var color := Color(0.52, 0.55, 0.58, 1.0)
		if segment_id == rail.current_segment:
			color = Color(0.90, 0.78, 0.35, 1.0)

		var start := points[0] as Vector2
		var end := points[1] as Vector2
		draw_line(start, end, Color(0.15, 0.15, 0.15, 1.0), 18.0, true)
		draw_line(start, end, color, 8.0, true)


func _draw_switch() -> void:
	var switch_color := Color(0.30, 0.75, 0.95, 1.0)
	if rail.points_route == RailMovement.POINTS_SIDING:
		switch_color = Color(0.90, 0.62, 0.25, 1.0)

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
