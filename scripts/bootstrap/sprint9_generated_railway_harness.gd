extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")
const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")
const WorldgenVillagePassingSpatialEmbedding := preload("res://scripts/worldgen/worldgen_village_passing_spatial_embedding.gd")

const BACKGROUND_COLOR := Color(0.08, 0.095, 0.10, 1.0)
const TRACK_BED_COLOR := Color(0.18, 0.18, 0.17, 1.0)
const RAIL_COLOR := Color(0.58, 0.61, 0.60, 1.0)
const SLEEPER_COLOR := Color(0.26, 0.20, 0.15, 1.0)
const MAIN_COLOR := Color(0.48, 0.54, 0.54, 1.0)
const ACTIVE_TRACK_COLOR := Color(0.98, 0.80, 0.32, 1.0)
const LOOP_COLOR := Color(0.38, 0.68, 0.92, 1.0)
const POINT_COLOR := Color(0.96, 0.44, 0.26, 1.0)
const TEXT_COLOR := Color(0.86, 0.90, 0.88, 1.0)
const UNIT_TEXT_COLOR := Color(0.04, 0.05, 0.05, 1.0)
const LOCOMOTIVE_CAB_COLOR := Color(0.16, 0.13, 0.11, 1.0)
const LOCOMOTIVE_HEADLIGHT_COLOR := Color(1.0, 0.86, 0.28, 1.0)
const UNIT_WIDTH := 30.0

var rail: RailMovement
var layout: Dictionary = {}
var embedding: Dictionary = {}
var semantic_decisions: Dictionary = {}
var spatial_decisions: Dictionary = {}
var blueprint_hash: String = ""
var generation_trace_hash: String = ""
var semantic_trace_hash: String = ""
var spatial_embedding_hash: String = ""
var current_runtime_segment: String = ""
var current_seed: int = 100
var sector_index: int = 0
var selected_route_id: String = "main"
var status: String = ""
var brake_active: bool = false


func _ready() -> void:
	_regenerate_current_seed()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if rail == null:
		return
	rail.step(delta, brake_active)
	current_runtime_segment = str(rail.current_segment)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_BRACKETLEFT:
			current_seed -= 1
			_regenerate_current_seed()
		KEY_BRACKETRIGHT:
			current_seed += 1
			_regenerate_current_seed()
		KEY_G:
			_regenerate_current_seed()
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
			_apply_route_preset_id("main")
		KEY_2:
			_apply_route_preset_id("loop")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	if rail == null:
		_draw_text(Vector2(24.0, 34.0), status, 16)
		return

	_draw_tracks()
	_draw_points()
	_draw_units()
	_draw_overlay()


func _regenerate_current_seed() -> void:
	rail = null
	layout.clear()
	embedding.clear()
	semantic_decisions.clear()
	spatial_decisions.clear()
	blueprint_hash = ""
	generation_trace_hash = ""
	semantic_trace_hash = ""
	spatial_embedding_hash = ""
	current_runtime_segment = ""
	selected_route_id = "main"
	brake_active = false

	var request := WorldgenGenerationRequest.new(
		current_seed,
		sector_index,
		WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE,
		WorldgenGenerationRequest.DEFAULT_REGION_PACK,
		WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION,
		WorldgenSemanticGenerator.GENERATOR_VERSION
	)
	var context := WorldgenGenerationContext.new(request)
	var semantic_generator := WorldgenSemanticGenerator.new()
	var semantic_result := semantic_generator.generate_blueprint(context)
	if not bool(semantic_result.get("success", false)):
		status = "Semantic generation failed: %s" % str(semantic_result.get("diagnostics", []))
		return

	var blueprint: RefCounted = semantic_result.get("blueprint", null)
	semantic_decisions = (semantic_result.get("decisions", {}) as Dictionary).duplicate(true)
	blueprint_hash = str(blueprint.get_canonical_hash())
	var semantic_trace: RefCounted = semantic_result.get("generation_trace", null)
	semantic_trace_hash = str(semantic_trace.get_canonical_hash())

	var validator := WorldgenSchemaValidator.new()
	var validation := validator.validate_blueprint(blueprint)
	if not bool(validation.get("valid", false)):
		status = "Semantic validation failed: %s" % str(validation.get("diagnostics", []))
		return

	var spatial_generator := WorldgenVillagePassingSpatialEmbedding.new()
	var spatial_result := spatial_generator.generate_embedding(blueprint, context, semantic_trace)
	if not bool(spatial_result.get("success", false)):
		status = "Spatial embedding failed: %s" % str(spatial_result.get("diagnostics", []))
		return
	embedding = (spatial_result.get("embedding", {}) as Dictionary).duplicate(true)
	spatial_decisions = (spatial_result.get("decisions", {}) as Dictionary).duplicate(true)
	spatial_embedding_hash = WorldgenCanonical.new().hash_dictionary(embedding)
	var final_trace: RefCounted = spatial_result.get("generation_trace", null)
	generation_trace_hash = str(final_trace.get_canonical_hash())

	var reconstruction := WorldgenRuntimeReconstructor.new().reconstruct_runtime_layout(blueprint, embedding, validator)
	if not bool(reconstruction.get("valid", false)):
		status = "Runtime reconstruction failed: %s" % str(reconstruction.get("diagnostics", []))
		return
	layout = reconstruction.get("layout", {}) as Dictionary

	rail = RailMovement.new()
	var configure_result := rail.configure_track_layout(layout)
	if not bool(configure_result.get("valid", false)):
		status = "RailMovement rejected generated layout: %s" % str(configure_result.get("diagnostics", []))
		rail = null
		return

	_reset_locomotive()
	_apply_route_preset_id("main")
	status = "Generated seed %d" % current_seed


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
	current_runtime_segment = str(rail.current_segment)


func _apply_route_preset_id(preset_id: String) -> void:
	if rail == null:
		return
	var preset := _find_route_preset(preset_id)
	if preset.is_empty():
		return
	for point_id in (preset.get("routes", {}) as Dictionary).keys():
		rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id]))
	selected_route_id = preset_id
	status = "Route: %s" % str(preset.get("label", preset_id))


func _find_route_preset(preset_id: String) -> Dictionary:
	for preset in layout.get("route_presets", []) as Array:
		var preset_dict := preset as Dictionary
		if str(preset_dict.get("id", "")) == preset_id:
			return preset_dict
	return {}


func _draw_tracks() -> void:
	var segments := rail.get_track_segments()
	for raw_segment_id in segments.keys():
		var segment_id := str(raw_segment_id)
		var points := segments[raw_segment_id] as Array
		var color := _track_color(segment_id)
		var highlighted := segment_id == rail.current_segment
		if highlighted:
			color = ACTIVE_TRACK_COLOR
		_draw_track_polyline(points, color, highlighted)
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
		_draw_unit(state)


func _draw_overlay() -> void:
	var lines: Array[String] = [
		"Sprint 9 generated railway closeout",
		"Seed: %d | Sector: %d | Route: %s" % [current_seed, sector_index, selected_route_id],
		"Space throttle | B brake | R reverse | [ ] seed | G regen | 1 main | 2 loop | 0 reset",
		"Blueprint: %s" % _short_hash(blueprint_hash),
		"Trace: %s | Embedding: %s" % [_short_hash(generation_trace_hash), _short_hash(spatial_embedding_hash)],
		"Semantic: platform_track=%s road_access=%s" % [
			str(semantic_decisions.get("platform_track", "")),
			str(semantic_decisions.get("road_access", "")),
		],
		"Spatial: side=%s approach=%s station=%s offset=%s" % [
			str(spatial_decisions.get("loop_side", "")),
			str(spatial_decisions.get("approach_length_class", "")),
			str(spatial_decisions.get("station_length_class", "")),
			str(spatial_decisions.get("loop_offset_class", "")),
		],
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
	return MAIN_COLOR


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
	var body := _get_unit_polygon(unit_length)
	var transformed_body := PackedVector2Array()
	for point in body:
		transformed_body.append(transform * point)

	draw_colored_polygon(transformed_body, _get_unit_color(str(state.get("type", ""))))
	var outline := PackedVector2Array(transformed_body)
	outline.append(transformed_body[0])
	draw_polyline(outline, Color(0.08, 0.08, 0.08, 1.0), 2.5, true)
	if str(state.get("type", "")) == RailMovement.UNIT_LOCOMOTIVE or str(state.get("type", "")) == RailMovement.UNIT_SHUNTER:
		_draw_locomotive_indicator(state)
	_draw_text(position + Vector2(-7.0, 6.0), str(state.get("id", "?")), 16, UNIT_TEXT_COLOR)


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


func _get_unit_endpoints(state: Dictionary) -> Dictionary:
	var position := state.get("position", Vector2.ZERO) as Vector2
	var angle := float(state.get("angle", 0.0))
	var tangent := Vector2.RIGHT.rotated(angle)
	var half_length := float(state.get("length", 48.0)) * 0.5
	return {
		"front": position + tangent * half_length,
		"rear": position - tangent * half_length,
	}


func _short_hash(value: String) -> String:
	if value.length() <= 12:
		return value
	return value.substr(0, 12)


func _draw_text(position: Vector2, text: String, font_size: int, color: Color = TEXT_COLOR) -> void:
	draw_string(get_theme_default_font(), position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
