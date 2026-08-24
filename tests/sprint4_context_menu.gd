extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	for method_name in [
		"is_context_menu_open",
		"get_context_menu_labels",
		"get_context_menu_option_position",
		"world_to_screen_position",
	]:
		_expect(scene.has_method(method_name), "scene exposes context menu method %s" % method_name)
	_expect(scene.crew.has_method("force_survivor_aboard_unit"), "crew test API can place a survivor aboard a specific engine")
	if _failures > 0:
		_finish()
		return

	_right_click_ground_offers_selected_survivor_move(scene)
	await _left_click_context_option(scene, "Move Marta here")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == CrewSimulation.TASK_MOVE, "ground menu assigns movement to selected survivor")
	_expect(not scene.is_context_menu_open(), "confirming a menu option closes the context menu")
	scene.crew.cancel_task("marta")

	var p2_screen: Vector2 = scene.world_to_screen_position(scene.yard.get_point_anchor(YardOperations.POINT_P2))
	await _right_click(scene, p2_screen)
	_expect(_menu_has(scene, "Operate P2"), "right-clicking P2 exposes crew-operated points option")
	await _left_click_context_option(scene, "Operate P2")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == CrewSimulation.TASK_OPERATE_YARD_POINT, "P2 menu action assigns yard point task")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_target", "")) == YardOperations.POINT_P2, "P2 menu action targets P2")
	scene.crew.cancel_task("marta")

	var route_before: String = scene.rail.get_yard_point_route(YardOperations.POINT_P2)
	scene.yard.repair_yard_control()
	scene.yard.connect_power()
	await _right_click(scene, p2_screen)
	_expect(not _menu_has(scene, "Remote P2"), "normal point context menu does not expose remote switching")
	_expect(scene.rail.get_yard_point_route(YardOperations.POINT_P2) == route_before, "opening normal P2 menu does not remotely change route")

	_transition_scene_to_industrial(scene)

	var shunter_screen: Vector2 = scene.world_to_screen_position(scene.yard.get_repair_anchor("shunter"))
	await _right_click(scene, shunter_screen)
	_expect(_menu_has(scene, "Repair shunter S"), "damaged shunter exposes repair menu action")
	_expect(not _menu_has(scene, "Control shunter S"), "damaged shunter cannot be selected for powered control from menu")
	await _left_click_context_option(scene, "Repair shunter S")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == CrewSimulation.TASK_REPAIR_SHUNTER, "repair shunter menu action assigns crew repair")
	scene.crew.cancel_task("marta")

	scene.yard.repair_shunter()
	scene.crew.force_survivor_yard_position("marta", scene.yard.get_repair_anchor("shunter"))
	await _right_click(scene, shunter_screen)
	_expect(_menu_has(scene, "Board shunter S"), "repaired shunter offers boarding when no crew is aboard S")
	_expect(not _menu_has(scene, "Control shunter S"), "repaired shunter cannot be controlled from menu without a crew member aboard")
	await _left_click_context_option(scene, "Board shunter S")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == CrewSimulation.TASK_BOARD, "board shunter menu action assigns a boarding task")
	scene.crew.cancel_task("marta")
	scene.crew.force_survivor_aboard_unit("marta", "S")
	await _right_click(scene, shunter_screen)
	_expect(_menu_has(scene, "Control shunter S"), "repaired shunter exposes powered control after a survivor boards S")
	await _left_click_context_option(scene, "Control shunter S")
	_expect(scene.rail.get_controlled_power_unit_id() == "S", "shunter control menu action explicitly selects S")
	_expect(scene.rail.set_direction(-1), "fixture reverses S toward W for rear coupling menu check")
	_drive_scene_until_can_couple(scene, "W", 80.0)
	_expect(scene.rail.can_couple_unit("W"), "fixture creates valid S/W contact for context menu")
	await _right_click_unit(scene, "W")
	_expect(_menu_has(scene, "Couple S rear / W front"), "right-click menu identifies S/W rear contact as a coupling action")
	await _left_click_context_option(scene, "Couple S rear / W front")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == "couple", "coupling menu assigns a crew coupling task")
	_expect(not scene.rail.get_active_consist_ids().has("W"), "coupling does not execute before crew reaches the contact anchor")
	_step_scene_until_task_done(scene, "marta", 8.0)
	_expect(scene.rail.get_active_consist_ids().has("W"), "crew coupling task performs the authoritative coupling after arrival")

	_configure_shunter_front_contact_fixture(scene)
	scene.crew.force_survivor_aboard_unit("marta", "S")
	_drive_scene_until_can_couple(scene, "W", 20.0)
	_expect(scene.rail.can_couple_unit("W"), "fixture creates valid S/W front contact for context menu")
	await _right_click_unit(scene, "W")
	_expect(_menu_has(scene, "Couple S front / W rear"), "right-click menu identifies S/W front contact as a coupling action")

	scene.rail.select_powered_control("L")
	var joint: Dictionary = scene.rail.get_joint_anchor("A", "B")
	var joint_screen: Vector2 = scene.world_to_screen_position(joint.get("anchor", Vector2.ZERO) as Vector2)
	await _right_click(scene, joint_screen)
	_expect(_menu_has(scene, "Uncouple A/B"), "right-clicking exact A/B joint exposes exact uncoupling action")
	await _left_click_context_option(scene, "Uncouple A/B")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == CrewSimulation.TASK_UNCOUPLE, "joint menu action assigns uncoupling task")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_target", "")) == "A/B", "joint menu action targets the exact A/B joint")

	await _right_click(scene, Vector2(8.0, 8.0))
	_expect(not scene.is_context_menu_open(), "right-clicking outside the playfield closes the context menu")

	_finish()


func _right_click_ground_offers_selected_survivor_move(scene: Node) -> void:
	var destination: Vector2 = scene.world_to_screen_position(Vector2(720.0, 520.0))
	var labels: Array[String] = []
	scene.crew.select_survivor("marta")
	_send_mouse(scene, destination, MOUSE_BUTTON_RIGHT, true)
	labels = scene.get_context_menu_labels()
	_expect(scene.is_context_menu_open(), "right-clicking playable ground opens the context menu")
	_expect(labels.has("Move Marta here"), "ground context menu offers movement for selected survivor")


func _left_click_context_option(scene: Node, label_fragment: String) -> void:
	var option_position: Vector2 = scene.get_context_menu_option_position(label_fragment)
	_expect(option_position != Vector2.INF, "context menu has option matching %s" % label_fragment)
	if option_position == Vector2.INF:
		return
	await _click(scene, option_position, MOUSE_BUTTON_LEFT)


func _right_click(scene: Node, position: Vector2) -> void:
	await _click(scene, position, MOUSE_BUTTON_RIGHT)


func _right_click_unit(scene: Node, unit_id: String) -> void:
	var state := _find_unit_state(scene, unit_id)
	_expect(not state.is_empty(), "fixture found unit %s for right-click" % unit_id)
	if state.is_empty():
		return
	await _right_click(scene, scene.world_to_screen_position(state.get("position", Vector2.ZERO) as Vector2))


func _click(scene: Node, position: Vector2, button: MouseButton) -> void:
	_send_mouse(scene, position, button, true)
	scene._process(1.0 / 60.0)
	await process_frame
	_send_mouse(scene, position, button, false)
	scene._process(1.0 / 60.0)
	await process_frame


func _send_mouse(scene: Node, position: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = pressed
	scene._gui_input(event)


func _menu_has(scene: Node, label_fragment: String) -> bool:
	for label in scene.get_context_menu_labels():
		if str(label).contains(label_fragment):
			return true
	return false


func _drive_scene_until_can_couple(scene: Node, unit_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	scene.rail.max_speed = 8.0
	scene.rail.acceleration = 22.0
	scene.rail.coast_deceleration = 5.0
	scene.rail.set_throttle(1.0)
	while elapsed < max_seconds and not scene.rail.can_couple_unit(unit_id):
		scene._process(0.1)
		elapsed += 0.1
	scene.rail.set_throttle(0.0)
	scene._process(0.1)


func _step_scene_until_task_done(scene: Node, survivor_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds:
		var status := str(scene.crew.get_survivor_state(survivor_id).get("task_status", ""))
		if status != CrewSimulation.STATUS_ASSIGNED \
				and status != CrewSimulation.STATUS_MOVING \
				and status != CrewSimulation.STATUS_INTERACTING:
			return
		scene._process(0.1)
		elapsed += 0.1


func _configure_shunter_front_contact_fixture(scene: Node) -> void:
	var active_units: Array[String] = ["S"]
	var detached_consists: Array[Dictionary] = [
		{
			"units": ["W"],
			"segment": RailMovement.SEGMENT_SIDING_B,
			"distance": 150.0,
		},
		{
			"units": ["L", "A", "B"],
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": 336.0,
		},
	]
	scene.rail.active_units = active_units
	scene.rail.detached_consists = detached_consists
	scene.rail.current_segment = RailMovement.SEGMENT_SIDING_B
	scene.rail.distance = 100.0
	scene.rail.direction = 1
	scene.rail.speed = 0.0
	scene.rail.throttle = 0.0
	scene.rail.controlled_power_unit_id = "S"
	scene.rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	scene.rail.last_contact.clear()


func _transition_scene_to_industrial(scene: Node) -> void:
	if scene.has_method("get_vertical_slice_state") and scene.scenario != null:
		scene.scenario.execute_scenario_interaction("clear_obstruction", "opening_obstruction", "olek")
		scene.scenario.execute_scenario_interaction("repair_onboard_fault", "locomotive_fault", "marta")
	scene.train_resources.set_amount("diesel", 24.0)
	_expect(scene.lifecycle.request_transition(), "fixture enters the industrial sector for S/W menu checks")
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.interior = scene.crew.interior


func _find_unit_state(scene: Node, unit_id: String) -> Dictionary:
	for state in scene.rail.get_unit_draw_states():
		if str(state.get("id", "")) == unit_id:
			return state
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 context menu check passed")
		quit(0)
		return

	printerr("Sprint 4 context menu check failed with %d failure(s)" % _failures)
	quit(1)
