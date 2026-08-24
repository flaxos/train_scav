extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	for method_name in [
		"get_anchor_icon_states",
		"get_uat_tutorial_lines",
		"get_current_uat_step_index",
		"get_world_bounds",
		"get_task_target_draw_states",
		"get_yard_track_connection_report",
		"get_track_visual_style",
		"get_switch_route_visual_states",
	]:
		_expect(scene.has_method(method_name), "scene exposes visual guidance method %s" % method_name)
	if _failures > 0:
		_finish()
		return

	var icons: Array[Dictionary] = scene.get_anchor_icon_states()
	_expect(_has_icon(icons, "P2", "switch"), "P2 uses a switch icon instead of an anonymous colored circle")
	_expect(_has_icon(icons, "yard_power", "power"), "yard power uses a power icon")
	_expect(not _has_icon(icons, "shunter", "repair"), "opening sector hides shunter repair icon until S exists")
	_expect(_has_icon(icons, "A/B", "joint"), "coupled A/B joint uses an uncoupling/joint icon")
	var p2_point_state: Dictionary = scene.yard.get_point_state(YardOperations.POINT_P2)
	var p2_anchor: Vector2 = scene.yard.get_point_anchor(YardOperations.POINT_P2)
	var p2_branch_position := p2_point_state.get("track_position", Vector2.ZERO) as Vector2
	_expect(p2_anchor.distance_to(p2_branch_position) <= 40.0, "P2 operator anchor is visibly next to the P2 workshop branch it controls")

	var track_style: Dictionary = scene.get_track_visual_style()
	_expect(bool(track_style.get("draws_sleepers", false)), "rail renderer draws sleepers instead of only colored route lines")
	_expect(bool(track_style.get("draws_parallel_rails", false)), "rail renderer draws two rails so tracks read as railway")
	_expect(bool(track_style.get("straight_branch_labels", false)), "rail renderer labels straight and branch turnout choices")

	var route_states: Array[Dictionary] = scene.get_switch_route_visual_states()
	_expect(_route_has_option(route_states, "P1", "straight", RailMovement.SEGMENT_MAIN_EAST), "P1 exposes straight route to main")
	_expect(_route_has_option(route_states, "P1", "branch", RailMovement.SEGMENT_SIDING), "P1 exposes branch route to siding A")
	_expect(_route_has_option(route_states, "P2", "straight", RailMovement.SEGMENT_MAIN_EXIT), "P2 exposes straight route along main exit")
	_expect(_route_has_option(route_states, "P2", "branch", RailMovement.SEGMENT_SIDING_B), "P2 exposes branch route to workshop siding")
	_expect(_route_control_label_contains(route_states, "P2", "controls"), "P2 visual state explains which turnout it controls")
	_expect(_active_route_kind(route_states, "P2") == "straight", "P2 starts with straight route highlighted")
	_expect(_p2_branch_guide_points_with_track(route_states, p2_branch_position), "P2 branch guide points toward the actual north/east workshop branch")
	_expect(scene.yard.manual_operate_point(YardOperations.POINT_P2), "fixture can operate P2 for visual route-state check")
	route_states = scene.get_switch_route_visual_states()
	_expect(_active_route_kind(route_states, "P2") == "branch", "P2 branch route is highlighted after operation")

	var lines: Array[String] = scene.get_uat_tutorial_lines()
	var tutorial_text := "\n".join(lines)
	_expect(tutorial_text.contains("UAT Guide"), "scene has an in-game UAT guide")
	_expect(tutorial_text.contains("Train Scav - Sprint 8 UAT Guide"), "UAT guide names Sprint 8")
	_expect(tutorial_text.contains("vertical slice"), "UAT guide explains the vertical-slice goal")
	_expect(tutorial_text.contains("Discover != owned"), "UAT guide explains search versus deposit")
	_expect(tutorial_text.contains("Departure requires all crew aboard and diesel"), "UAT guide explains crew return and diesel before departure")
	_expect(tutorial_text.contains("Coupled W != online"), "UAT guide explains workshop activation after coupling")
	_expect(not tutorial_text.contains("Remote P2"), "UAT guide does not present remote switching as the normal play path")
	_expect(scene.get_current_uat_step_index() == 0, "fresh UAT guide starts with obstruction stop")

	scene.lifecycle.transition_blocked_reason = "Departure blocked: opening obstruction still blocks the route"
	var survivor_screen: Vector2 = scene.world_to_screen_position(_survivor_position(scene, "marta"))
	await _click(scene, survivor_screen, MOUSE_BUTTON_LEFT)
	_expect(scene.get_current_uat_step_index() == 1, "after blocked departure and survivor selection, UAT guide advances to obstruction work")

	var route_segment: Array = scene.rail.get_track_segments()[RailMovement.SEGMENT_SIDING_B]
	_expect(route_segment.size() >= 6, "workshop siding uses enough rail points for a readable bend")
	_expect(_max_turn_delta(route_segment) <= 0.55, "workshop siding avoids abrupt unrealistic angle changes")
	var main_segment: Array = scene.rail.get_track_segments()[RailMovement.SEGMENT_MAIN_EAST]
	var main_tangent := ((main_segment[main_segment.size() - 1] as Vector2) - (main_segment[main_segment.size() - 2] as Vector2)).normalized()
	var branch_tangent := ((route_segment[1] as Vector2) - (route_segment[0] as Vector2)).normalized()
	_expect(absf(angle_difference(main_tangent.angle(), branch_tangent.angle())) <= 0.35, "P2 branch leaves the main as a plausible facing turnout instead of bending back on itself")
	_expect((route_segment[1] as Vector2).x > (route_segment[0] as Vector2).x, "P2 north branch initially continues east before curving north")
	_expect((route_segment[0] as Vector2).distance_to(p2_branch_position) <= 1.0, "P2 controlled branch begins at the P2 turnout")
	_expect(_points_bounds(route_segment).position.y < p2_branch_position.y - 20.0, "P2 controlled branch is the visible north branch")
	var bounds: Rect2 = scene.get_world_bounds()
	_expect(bounds.size.x >= 1300.0, "playfield world bounds are widened for a clearer yard")
	_expect(bounds.encloses(_points_bounds(route_segment)), "world bounds include redesigned workshop siding")

	var connections: Array[Dictionary] = scene.get_yard_track_connection_report()
	_expect(connections.size() >= 2, "yard has several visible branch tracks")
	_expect(not _connection_has_id(connections, "upper_storage_siding"), "north branch is modeled by P2 rather than duplicated as decorative scenery")
	for connection in connections:
		_expect(bool(connection.get("connected_to_model", false)), "yard branch %s visually connects to modeled rail" % str(connection.get("id", "")))
		_expect(bool(connection.get("has_buffer_or_join", false)), "yard branch %s has a readable end condition" % str(connection.get("id", "")))

	scene.crew.force_survivor_yard_position("marta", Vector2(640.0, 540.0))
	_expect(scene.crew.assign_move("marta", Vector2(700.0, 540.0)), "fixture assigns a short movement task")
	_step_scene(scene, 2.0)
	_expect(str(scene.crew.get_survivor_state("marta").get("task_status", "")) == "completed", "fixture movement task completes")
	_expect(scene.get_task_target_draw_states().is_empty(), "completed or idle tasks do not leave long target connector lines across the yard")

	_finish()


func _survivor_position(scene: Node, survivor_id: String) -> Vector2:
	for state in scene.crew.get_survivor_draw_states():
		if str(state.get("id", "")) == survivor_id:
			return state.get("position", Vector2.ZERO) as Vector2
	return Vector2.ZERO


func _click(scene: Node, position: Vector2, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = true
	scene._gui_input(event)
	scene._process(1.0 / 60.0)
	await process_frame


func _step_scene(scene: Node, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		scene._process(0.1)
		elapsed += 0.1


func _has_icon(icons: Array[Dictionary], target_id: String, icon_kind: String) -> bool:
	for icon in icons:
		if str(icon.get("id", "")) == target_id and str(icon.get("icon", "")) == icon_kind:
			return true
	return false


func _route_has_option(routes: Array[Dictionary], point_id: String, option_kind: String, target_segment: String) -> bool:
	var state := _route_state(routes, point_id)
	var options: Array = state.get("options", [])
	for option in options:
		var option_state := option as Dictionary
		if str(option_state.get("kind", "")) == option_kind \
				and str(option_state.get("target_segment", "")) == target_segment:
			return true
	return false


func _p2_branch_guide_points_with_track(routes: Array[Dictionary], p2_position: Vector2) -> bool:
	var state := _route_state(routes, "P2")
	var options: Array = state.get("options", [])
	for option in options:
		var option_state := option as Dictionary
		if str(option_state.get("kind", "")) != "branch":
			continue
		var guide_end := option_state.get("guide_end", p2_position) as Vector2
		return guide_end.x > p2_position.x and guide_end.y < p2_position.y
	return false


func _route_control_label_contains(routes: Array[Dictionary], point_id: String, text: String) -> bool:
	var state := _route_state(routes, point_id)
	return str(state.get("control_label", "")).to_lower().contains(text.to_lower())


func _active_route_kind(routes: Array[Dictionary], point_id: String) -> String:
	return str(_route_state(routes, point_id).get("active_kind", ""))


func _route_state(routes: Array[Dictionary], point_id: String) -> Dictionary:
	for route in routes:
		if str(route.get("point_id", "")) == point_id:
			return route
	return {}


func _max_turn_delta(points: Array) -> float:
	var max_delta := 0.0
	for index in range(points.size() - 2):
		var first := points[index] as Vector2
		var middle := points[index + 1] as Vector2
		var last := points[index + 2] as Vector2
		var first_angle := (middle - first).angle()
		var second_angle := (last - middle).angle()
		max_delta = maxf(max_delta, absf(angle_difference(first_angle, second_angle)))
	return max_delta


func _points_bounds(points: Array) -> Rect2:
	if points.is_empty():
		return Rect2()

	var first_point := points[0] as Vector2
	var min_position := first_point
	var max_position := first_point
	for point in points:
		var vector := point as Vector2
		min_position.x = minf(min_position.x, vector.x)
		min_position.y = minf(min_position.y, vector.y)
		max_position.x = maxf(max_position.x, vector.x)
		max_position.y = maxf(max_position.y, vector.y)
	return Rect2(min_position, max_position - min_position)


func _connection_has_id(connections: Array[Dictionary], connection_id: String) -> bool:
	for connection in connections:
		if str(connection.get("id", "")) == connection_id:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 visual guidance check passed")
		quit(0)
		return

	printerr("Sprint 4 visual guidance check failed with %d failure(s)" % _failures)
	quit(1)
