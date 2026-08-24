extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const WorldgenFixtureLoader := preload("res://scripts/worldgen/worldgen_fixture_loader.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")

const GOODS_FIXTURE := "res://data/worldgen/archetypes/reference/small_town_goods_station_v1.json"
const GOODS_EMBEDDING := "res://data/worldgen/embeddings/reference/small_town_goods_station_embedding_v1.json"

const BACKGROUND_COLOR := Color(0.08, 0.095, 0.10, 1.0)
const TRACK_BED_COLOR := Color(0.18, 0.18, 0.17, 1.0)
const RAIL_COLOR := Color(0.58, 0.61, 0.60, 1.0)
const SLEEPER_COLOR := Color(0.26, 0.20, 0.15, 1.0)
const TRACK_COLOR := Color(0.48, 0.54, 0.54, 1.0)
const ACTIVE_TRACK_COLOR := Color(0.98, 0.80, 0.32, 1.0)
const LOOP_COLOR := Color(0.38, 0.68, 0.92, 1.0)
const YARD_COLOR := Color(0.70, 0.58, 0.42, 1.0)
const POINT_COLOR := Color(0.96, 0.44, 0.26, 1.0)
const UNIT_LABEL_COLOR := Color(0.04, 0.05, 0.05, 1.0)
const LOCOMOTIVE_CAB_COLOR := Color(0.16, 0.13, 0.11, 1.0)
const LOCOMOTIVE_HEADLIGHT_COLOR := Color(1.0, 0.86, 0.28, 1.0)
const TEXT_COLOR := Color(0.86, 0.90, 0.88, 1.0)
const UNIT_WIDTH := 30.0

var rail: RailMovement
var layout: Dictionary = {}
var status: String = ""
var brake_active: bool = false


func _ready() -> void:
	_load_reconstructed_fixture()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if rail == null:
		return
	rail.step(delta, brake_active)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if rail == null or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_SPACE:
			if rail.throttle > 0.0:
				rail.set_throttle(0.0)
			else:
				rail.set_throttle(1.0)
		KEY_B:
			brake_active = not brake_active
		KEY_R:
			if rail.reverse_direction():
				status = "Direction reversed"
			else:
				status = "Stop before reversing"
		KEY_1:
			_set_routes({
				"west_yard_switch": "main",
				"west_loop_switch": "platform",
				"east_loop_switch": "platform",
			}, "Route: platform main")
		KEY_2:
			_set_routes({
				"west_yard_switch": "main",
				"west_loop_switch": "loop",
				"east_loop_switch": "loop",
			}, "Route: passing loop")
		KEY_3:
			_set_routes({
				"west_yard_switch": "yard",
				"yard_switch": "loading",
			}, "Route: goods loading")
		KEY_4:
			_set_routes({
				"west_yard_switch": "yard",
				"yard_switch": "headshunt",
			}, "Route: yard headshunt")
		KEY_0:
			_reset_locomotive()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	if rail == null:
		_draw_text(Vector2(24.0, 34.0), status, 16)
		return

	_draw_tracks()
	_draw_points()
	_draw_units()
	_draw_overlay()


func _load_reconstructed_fixture() -> void:
	var loader := WorldgenFixtureLoader.new()
	var validator := WorldgenSchemaValidator.new()
	var reconstructor := WorldgenRuntimeReconstructor.new()
	var blueprint := loader.load_blueprint(GOODS_FIXTURE)
	if blueprint == null:
		status = "Failed to load small-town goods blueprint"
		return

	var embedding := loader.load_json(GOODS_EMBEDDING)
	var result := reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	if not bool(result.get("valid", false)):
		status = "Reconstruction failed: %s" % str(result.get("diagnostics", []))
		return

	layout = result.get("layout", {}) as Dictionary
	rail = RailMovement.new()
	var configure_result := rail.configure_track_layout(layout)
	if not bool(configure_result.get("valid", false)):
		status = "RailMovement rejected layout: %s" % str(configure_result.get("diagnostics", []))
		rail = null
		return

	_reset_locomotive()
	status = "Small-town goods station reconstructed from SectorBlueprint"


func _reset_locomotive() -> void:
	var active: Array[String] = ["L"]
	var detached: Array[Dictionary] = []
	rail.active_units = active
	rail.detached_consists = detached
	rail.current_segment = "main_west"
	rail.distance = 24.0
	rail.direction = 1
	rail.speed = 0.0
	rail.throttle = 0.0
	rail.max_speed = 90.0
	rail.acceleration = 120.0
	rail.coast_deceleration = 55.0
	brake_active = false


func _set_routes(routes: Dictionary, message: String) -> void:
	for point_id in routes.keys():
		rail.set_point_route(str(point_id), str(routes[point_id]))
	status = message


func _draw_tracks() -> void:
	var segments := rail.get_track_segments()
	for segment_id in segments.keys():
		var points := segments[segment_id] as Array
		var color := _track_color(str(segment_id))
		var highlighted := false
		if str(segment_id) == rail.current_segment:
			color = ACTIVE_TRACK_COLOR
			highlighted = true
		_draw_track_polyline(points, color, highlighted)
		if rail.get_segment_semantic_id(str(segment_id)) != "":
			var label_position := points[maxi(points.size() / 2, 0)] as Vector2
			_draw_text(label_position + Vector2(-34.0, -10.0), rail.get_segment_semantic_id(str(segment_id)), 10)


func _draw_points() -> void:
	var snapshot := rail.get_runtime_topology_snapshot()
	var points := snapshot.get("points", {}) as Dictionary
	for point_id in points.keys():
		var point := points[point_id] as Dictionary
		var raw_position := point.get("position", []) as Array
		if raw_position.size() < 2:
			continue
		var position := Vector2(float(raw_position[0]), float(raw_position[1]))
		draw_circle(position, 9.0, POINT_COLOR)
		_draw_text(position + Vector2(12.0, -10.0), "%s:%s" % [str(point_id), str(point.get("route", ""))], 11)


func _draw_units() -> void:
	for state in rail.get_unit_draw_states():
		_draw_unit(state)


func _draw_overlay() -> void:
	var lines: Array[String] = [
		"Sprint 9D semantic blueprint runtime reconstruction",
		"Space throttle | B brake | R reverse | 1 main | 2 loop | 3 goods loading | 4 headshunt | 0 reset",
		status,
	]
	for line in rail.get_debug_lines().slice(0, 8):
		lines.append(str(line))

	var y := 24.0
	for line in lines:
		_draw_text(Vector2(24.0, y), line, 14)
		y += 18.0


func _track_color(segment_id: String) -> Color:
	var role := rail.get_segment_semantic_role(segment_id)
	if role == "PASSING_LOOP":
		return LOOP_COLOR
	if role == "GOODS_YARD_TRACK" or role == "LOADING_TRACK" or role == "HEADSHUNT":
		return YARD_COLOR
	return TRACK_COLOR


func _draw_track_polyline(points: Array, route_color: Color, highlighted: bool) -> void:
	if points.size() < 2:
		return

	for index in range(points.size() - 1):
		draw_line(points[index] as Vector2, points[index + 1] as Vector2, TRACK_BED_COLOR, 21.0, true)

	_draw_track_sleepers(points)
	_draw_parallel_rails(points, highlighted)
	for index in range(points.size() - 1):
		draw_line(points[index] as Vector2, points[index + 1] as Vector2, route_color, 3.5 if highlighted else 2.0, true)


func _draw_track_sleepers(points: Array) -> void:
	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		var segment := end - start
		var length := segment.length()
		if length <= 0.001:
			continue
		var tangent := segment / length
		var normal := Vector2(-tangent.y, tangent.x)
		var sleeper_distance := 0.0
		while sleeper_distance <= length:
			var center := start + tangent * sleeper_distance
			draw_line(center - normal * 12.0, center + normal * 12.0, SLEEPER_COLOR, 2.0, true)
			sleeper_distance += 28.0


func _draw_parallel_rails(points: Array, highlighted: bool) -> void:
	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		var segment := end - start
		var length := segment.length()
		if length <= 0.001:
			continue
		var normal := Vector2(-segment.y, segment.x).normalized()
		var width := 3.0 if highlighted else 2.2
		draw_line(start + normal * 5.2, end + normal * 5.2, RAIL_COLOR, width, true)
		draw_line(start - normal * 5.2, end - normal * 5.2, RAIL_COLOR, width, true)


func _draw_unit(state: Dictionary) -> void:
	var position := state.get("position", Vector2.ZERO) as Vector2
	var angle := float(state.get("angle", 0.0))
	var unit_length := float(state.get("length", 48.0))
	var transform := Transform2D(angle, position)
	var body := _get_unit_polygon(str(state.get("type", "")), unit_length)
	var transformed_body := PackedVector2Array()
	for point in body:
		transformed_body.append(transform * point)

	draw_colored_polygon(transformed_body, _get_unit_color(str(state.get("type", "")), bool(state.get("active", false))))
	var outline := PackedVector2Array(transformed_body)
	outline.append(transformed_body[0])
	draw_polyline(outline, Color(0.08, 0.08, 0.08, 1.0), 2.5, true)
	if str(state.get("type", "")) == RailMovement.UNIT_LOCOMOTIVE or str(state.get("type", "")) == RailMovement.UNIT_SHUNTER:
		_draw_locomotive_indicator(state)
	_draw_unit_label(state)


func _draw_locomotive_indicator(state: Dictionary) -> void:
	var endpoints := _get_unit_endpoints(state)
	var position := state.get("position", Vector2.ZERO) as Vector2
	var angle := float(state.get("angle", 0.0))
	var tangent := Vector2.RIGHT.rotated(angle)
	var normal := Vector2.UP.rotated(angle)
	var cab_center := position - tangent * 12.0
	var cab_half_length := 10.0
	var cab_half_width := 9.0
	var cab := PackedVector2Array([
		cab_center - tangent * cab_half_length - normal * cab_half_width,
		cab_center + tangent * cab_half_length - normal * cab_half_width,
		cab_center + tangent * cab_half_length + normal * cab_half_width,
		cab_center - tangent * cab_half_length + normal * cab_half_width,
	])
	draw_colored_polygon(cab, LOCOMOTIVE_CAB_COLOR)
	draw_circle(endpoints.get("front", position) as Vector2, 6.5, LOCOMOTIVE_HEADLIGHT_COLOR)


func _draw_unit_label(state: Dictionary) -> void:
	var position := state.get("position", Vector2.ZERO) as Vector2
	draw_string(get_theme_default_font(), position + Vector2(-7.0, 6.0), str(state.get("id", "?")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, UNIT_LABEL_COLOR)


func _get_unit_polygon(unit_type: String, unit_length: float) -> PackedVector2Array:
	var half_length := unit_length * 0.5
	var half_width := UNIT_WIDTH * 0.5
	if unit_type == RailMovement.UNIT_LOCOMOTIVE or unit_type == RailMovement.UNIT_SHUNTER:
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
		RailMovement.UNIT_SHUNTER:
			color = Color(0.18, 0.42, 0.84, 1.0)
		RailMovement.UNIT_FLATBED:
			color = Color(0.58, 0.62, 0.68, 1.0)
		RailMovement.UNIT_BOXCAR:
			color = Color(0.38, 0.72, 0.40, 1.0)
		RailMovement.UNIT_TANKER:
			color = Color(0.78, 0.68, 0.28, 1.0)
		RailMovement.UNIT_WORKSHOP:
			color = Color(0.66, 0.36, 0.78, 1.0)
	if not active:
		color = color.darkened(0.35)
	return color


func _get_unit_endpoints(state: Dictionary) -> Dictionary:
	var position := state.get("position", Vector2.ZERO) as Vector2
	var angle := float(state.get("angle", 0.0))
	var tangent := Vector2.RIGHT.rotated(angle)
	var half_length := float(state.get("length", 48.0)) * 0.5
	return {
		"front": position + tangent * half_length,
		"rear": position - tangent * half_length,
	}


func _draw_text(position: Vector2, text: String, font_size: int) -> void:
	draw_string(get_theme_default_font(), position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, TEXT_COLOR)
