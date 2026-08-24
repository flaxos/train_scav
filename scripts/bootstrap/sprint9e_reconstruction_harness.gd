extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const WorldgenFixtureLoader := preload("res://scripts/worldgen/worldgen_fixture_loader.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")

const EMBEDDING_REGISTRY := "res://data/worldgen/embeddings/reference/reference_embeddings_v1.json"
const BACKGROUND_COLOR := Color(0.08, 0.095, 0.10, 1.0)
const TRACK_BED_COLOR := Color(0.18, 0.18, 0.17, 1.0)
const RAIL_COLOR := Color(0.58, 0.61, 0.60, 1.0)
const SLEEPER_COLOR := Color(0.26, 0.20, 0.15, 1.0)
const MAIN_COLOR := Color(0.48, 0.54, 0.54, 1.0)
const ACTIVE_TRACK_COLOR := Color(0.98, 0.80, 0.32, 1.0)
const LOOP_COLOR := Color(0.38, 0.68, 0.92, 1.0)
const YARD_COLOR := Color(0.70, 0.58, 0.42, 1.0)
const DISPLAY_ONLY_COLOR := Color(0.30, 0.32, 0.32, 1.0)
const POINT_COLOR := Color(0.96, 0.44, 0.26, 1.0)
const TEXT_COLOR := Color(0.86, 0.90, 0.88, 1.0)
const UNIT_TEXT_COLOR := Color(0.04, 0.05, 0.05, 1.0)
const UNIT_WIDTH := 30.0

var rail: RailMovement
var layout: Dictionary = {}
var reference_entries: Array = []
var current_index: int = 0
var current_archetype_id: String = ""
var status: String = ""
var brake_active: bool = false


func _ready() -> void:
	_load_reference_entries()
	_load_current_layout()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if rail == null:
		return
	rail.step(delta, brake_active)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_BRACKETLEFT:
			_cycle_layout(-1)
		KEY_BRACKETRIGHT:
			_cycle_layout(1)
		KEY_SPACE:
			if rail != null:
				if rail.throttle > 0.0:
					rail.set_throttle(0.0)
				else:
					rail.set_throttle(1.0)
		KEY_B:
			brake_active = not brake_active
		KEY_R:
			if rail != null and rail.reverse_direction():
				status = "Direction reversed"
			else:
				status = "Stop before reversing"
		KEY_0:
			_reset_locomotive()
		KEY_1:
			_apply_route_preset_index(0)
		KEY_2:
			_apply_route_preset_index(1)
		KEY_3:
			_apply_route_preset_index(2)
		KEY_4:
			_apply_route_preset_index(3)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	if rail == null:
		_draw_text(Vector2(24.0, 34.0), status, 16)
		return

	_draw_tracks()
	_draw_points()
	_draw_units()
	_draw_overlay()


func _load_reference_entries() -> void:
	var loader := WorldgenFixtureLoader.new()
	var data: Dictionary = loader.load_json(EMBEDDING_REGISTRY)
	reference_entries = (data.get("embeddings", []) as Array).duplicate(true)


func _cycle_layout(direction: int) -> void:
	if reference_entries.is_empty():
		return
	current_index = posmod(current_index + direction, reference_entries.size())
	_load_current_layout()


func _load_current_layout() -> void:
	if reference_entries.is_empty():
		status = "No Sprint 9E reference embeddings found"
		rail = null
		return

	var entry := reference_entries[current_index] as Dictionary
	current_archetype_id = str(entry.get("archetype_id", ""))
	var loader := WorldgenFixtureLoader.new()
	var validator := WorldgenSchemaValidator.new()
	var reconstructor := WorldgenRuntimeReconstructor.new()
	var blueprint := loader.load_blueprint(str(entry.get("fixture_path", "")))
	if blueprint == null:
		status = "Failed to load blueprint for %s" % current_archetype_id
		rail = null
		return

	var embedding := loader.load_json(str(entry.get("embedding_path", "")))
	var result := reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	if not bool(result.get("valid", false)):
		status = "Reconstruction failed: %s" % str(result.get("diagnostics", []))
		rail = null
		return

	layout = result.get("layout", {}) as Dictionary
	rail = RailMovement.new()
	var configure_result := rail.configure_track_layout(layout)
	if not bool(configure_result.get("valid", false)):
		status = "RailMovement rejected layout: %s" % str(configure_result.get("diagnostics", []))
		rail = null
		return

	_reset_locomotive()
	_apply_route_preset_index(0)
	status = "Loaded %s" % str(entry.get("label", current_archetype_id))


func _reset_locomotive() -> void:
	if rail == null:
		return
	var active: Array[String] = ["L"]
	var detached: Array[Dictionary] = []
	rail.active_units = active
	rail.detached_consists = detached
	rail.current_segment = str(layout.get("entry_segment", rail.current_segment))
	rail.distance = float(layout.get("entry_distance", 24.0))
	rail.direction = 1
	rail.speed = 0.0
	rail.throttle = 0.0
	rail.max_speed = 90.0
	rail.acceleration = 120.0
	rail.coast_deceleration = 55.0
	brake_active = false


func _apply_route_preset_index(index: int) -> void:
	if rail == null:
		return
	var presets := layout.get("route_presets", []) as Array
	if index < 0 or index >= presets.size():
		return
	var preset := presets[index] as Dictionary
	for point_id in (preset.get("routes", {}) as Dictionary).keys():
		rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id]))
	status = "Route: %s" % str(preset.get("label", preset.get("id", "")))


func _draw_tracks() -> void:
	var segments := rail.get_track_segments()
	for raw_segment_id in segments.keys():
		var segment_id := str(raw_segment_id)
		var points := segments[raw_segment_id] as Array
		var color := _track_color(segment_id)
		var highlighted := segment_id == rail.current_segment
		if highlighted:
			color = ACTIVE_TRACK_COLOR
		_draw_track_polyline(points, color, highlighted, rail.get_segment_runtime_status(segment_id) == RailMovement.SEGMENT_STATUS_DISPLAY_ONLY)
		var semantic_id := rail.get_segment_semantic_id(segment_id)
		if semantic_id != "":
			var label_position := points[maxi(points.size() / 2, 0)] as Vector2
			_draw_text(label_position + Vector2(-34.0, -10.0), semantic_id, 10)


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
		var position := state.get("position", Vector2.ZERO) as Vector2
		var angle := float(state.get("angle", 0.0))
		var unit_length := float(state.get("length", 48.0))
		var transform := Transform2D(angle, position)
		var body := _get_unit_polygon(unit_length)
		var transformed_body := PackedVector2Array()
		for point in body:
			transformed_body.append(transform * point)
		draw_colored_polygon(transformed_body, _get_unit_color(str(state.get("type", ""))))
		var outline := PackedVector2Array(transformed_body)
		outline.append(transformed_body[0])
		draw_polyline(outline, Color(0.08, 0.08, 0.08, 1.0), 2.5, true)
		_draw_text(position + Vector2(-7.0, 6.0), str(state.get("id", "?")), 16, UNIT_TEXT_COLOR)


func _draw_overlay() -> void:
	var entry := reference_entries[current_index] as Dictionary
	var lines: Array[String] = [
		"Sprint 9E multi-archetype reconstruction",
		"[%d/%d] %s" % [current_index + 1, reference_entries.size(), str(entry.get("label", current_archetype_id))],
		"Space throttle | B brake | R reverse | [ ] layout | 1-4 route | 0 reset",
		status,
	]
	var presets := layout.get("route_presets", []) as Array
	for index in range(mini(4, presets.size())):
		var preset := presets[index] as Dictionary
		lines.append("%d: %s" % [index + 1, str(preset.get("label", preset.get("id", "")))])
	for line in rail.get_debug_lines().slice(0, 7):
		lines.append(str(line))

	var y := 24.0
	for line in lines:
		_draw_text(Vector2(24.0, y), line, 14)
		y += 18.0


func _track_color(segment_id: String) -> Color:
	if rail.get_segment_runtime_status(segment_id) == RailMovement.SEGMENT_STATUS_DISPLAY_ONLY:
		return DISPLAY_ONLY_COLOR
	var role := rail.get_segment_semantic_role(segment_id)
	if role == "PASSING_LOOP":
		return LOOP_COLOR
	if role == "GOODS_YARD_TRACK" or role == "LOADING_TRACK" or role == "HEADSHUNT" or role == "STORAGE_TRACK" or role == "AGRICULTURAL_SPUR":
		return YARD_COLOR
	return MAIN_COLOR


func _draw_track_polyline(points: Array, route_color: Color, highlighted: bool, display_only: bool) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		draw_line(points[index] as Vector2, points[index + 1] as Vector2, TRACK_BED_COLOR, 15.0 if display_only else 21.0, true)
	if not display_only:
		_draw_track_sleepers(points)
		_draw_parallel_rails(points, highlighted)
	for index in range(points.size() - 1):
		draw_line(points[index] as Vector2, points[index + 1] as Vector2, route_color, 4.0 if highlighted else 2.0, true)


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
		if segment.length() <= 0.001:
			continue
		var normal := Vector2(-segment.y, segment.x).normalized()
		var width := 3.0 if highlighted else 2.2
		draw_line(start + normal * 5.2, end + normal * 5.2, RAIL_COLOR, width, true)
		draw_line(start - normal * 5.2, end - normal * 5.2, RAIL_COLOR, width, true)


func _get_unit_polygon(unit_length: float) -> PackedVector2Array:
	var half_length := unit_length * 0.5
	var half_width := UNIT_WIDTH * 0.5
	return PackedVector2Array([
		Vector2(-half_length, -half_width),
		Vector2(half_length - 12.0, -half_width),
		Vector2(half_length, 0.0),
		Vector2(half_length - 12.0, half_width),
		Vector2(-half_length, half_width),
	])


func _get_unit_color(unit_type: String) -> Color:
	if unit_type == RailMovement.UNIT_LOCOMOTIVE:
		return Color(0.82, 0.18, 0.16, 1.0)
	if unit_type == RailMovement.UNIT_SHUNTER:
		return Color(0.18, 0.42, 0.84, 1.0)
	return Color(0.78, 0.78, 0.78, 1.0)


func _draw_text(position: Vector2, text: String, font_size: int, color: Color = TEXT_COLOR) -> void:
	draw_string(get_theme_default_font(), position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
