extends SceneTree

const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TrainInterior := preload("res://scripts/colony/train_interior.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	# Scene tests drive _process() manually. Disable automatic frame processing before
	# entering the tree so an initialization failure cannot flood the log with a
	# secondary `crew.step()` nil error and hide the first useful error.
	scene.set_process(false)
	root.add_child(scene)

	await process_frame
	await process_frame

	_expect(scene.rail != null, "scene bootstrap creates rail model")
	_expect(scene.yard != null, "scene bootstrap creates yard model")
	_expect(scene.interior != null, "scene bootstrap creates train interior model")
	_expect(scene.crew != null, "scene bootstrap creates crew model")
	if scene.rail == null or scene.yard == null or scene.interior == null or scene.crew == null:
		printerr("Sprint 5A scene bootstrap failed; see the FIRST script error above this line")
		_finish()
		return

	_expect(scene.has_method("get_train_interior_draw_states"), "scene exposes train interior draw states")
	var states: Array[Dictionary] = scene.get_train_interior_draw_states()
	_expect(_interior_kind(states, "L") == TrainInterior.KIND_LOCOMOTIVE, "L renders a locomotive interior")
	_expect(_interior_kind(states, "A") == TrainInterior.KIND_BUNK, "A renders a bunk interior")
	_expect(_interior_kind(states, "B") == TrainInterior.KIND_STORAGE, "B renders a storage interior")
	_expect(_interior_kind(states, "W") == TrainInterior.KIND_WORKSHOP, "W renders a workshop interior")
	_expect(not _boardable(states, "C"), "C advertises no boardable interior")

	scene.crew.select_survivor("marta")
	var requested_local := Vector2(16.0, 5.0)
	await _right_click_unit_local(scene, "B", requested_local)
	_expect(_menu_has(scene, "Walk Marta to B STORAGE"), "right-clicking connected B offers an explicit interior movement order")
	await _left_click_context_option(scene, "Walk Marta to B STORAGE")
	var assigned: Dictionary = scene.crew.get_survivor_state("marta")
	_expect(str(assigned.get("task_type", "")) == CrewSimulation.TASK_MOVE_ABOARD, "interior context action assigns aboard movement rather than yard movement")
	var data := assigned.get("task_data", {}) as Dictionary
	var assigned_local := data.get("target_local", Vector2.ZERO) as Vector2
	_expect(assigned_local.distance_to(requested_local) <= 1.0, "right-click interior order targets the clicked local position rather than carriage centre")

	_step_scene(scene, 4.0)
	var marta: Dictionary = scene.crew.get_survivor_state("marta")
	_expect(str(marta.get("host_unit", "")) == "B", "scene UAT movement carries Marta through the connected train to B")
	_expect((marta.get("local_offset", Vector2.ZERO) as Vector2).distance_to(requested_local) <= 2.1, "Marta ends near the clicked position in B")

	_finish()


func _right_click_unit_local(scene: Node, unit_id: String, local_click: Vector2) -> void:
	var state := _find_unit_state(scene, unit_id)
	_expect(not state.is_empty(), "fixture finds unit %s" % unit_id)
	if state.is_empty():
		return
	var transform := Transform2D(float(state.get("angle", 0.0)), state.get("position", Vector2.ZERO) as Vector2)
	var carriage_click := transform * local_click
	await _click(scene, scene.world_to_screen_position(carriage_click), MOUSE_BUTTON_RIGHT)


func _left_click_context_option(scene: Node, label_fragment: String) -> void:
	var position: Vector2 = scene.get_context_menu_option_position(label_fragment)
	_expect(position != Vector2.INF, "menu exposes %s" % label_fragment)
	if position == Vector2.INF:
		return
	await _click(scene, position, MOUSE_BUTTON_LEFT)


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
		scene._process(0.05)
		elapsed += 0.05


func _find_unit_state(scene: Node, unit_id: String) -> Dictionary:
	for state in scene.rail.get_unit_draw_states():
		if str(state.get("id", "")) == unit_id:
			return state
	return {}


func _interior_kind(states: Array[Dictionary], unit_id: String) -> String:
	for state in states:
		if str(state.get("id", "")) == unit_id:
			return str(state.get("interior_kind", ""))
	return ""


func _boardable(states: Array[Dictionary], unit_id: String) -> bool:
	for state in states:
		if str(state.get("id", "")) == unit_id:
			return bool(state.get("boardable", false))
	return false


func _menu_has(scene: Node, fragment: String) -> bool:
	for label in scene.get_context_menu_labels():
		if str(label).contains(fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 5A scene interior check passed")
		quit(0)
		return
	printerr("Sprint 5A scene interior check failed with %d failure(s)" % _failures)
	quit(1)
