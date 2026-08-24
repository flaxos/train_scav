extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	_expect(scene.yard != null, "main scene owns Sprint 4 yard operations")
	_expect(scene.has_method("_draw_yard_auxiliary_tracks"), "main scene draws Sprint 4 yard tracks")
	_expect(scene.crew.has_method("force_survivor_aboard_unit"), "scene crew can place test survivor aboard a specific powered unit")
	_expect(scene.rail.get_unit_type("S") == RailMovement.UNIT_SHUNTER, "scene shunter has shunter identity")
	_expect(scene.rail.get_unit_type("W") == RailMovement.UNIT_WORKSHOP, "scene salvage wagon has workshop identity")
	if _failures > 0:
		printerr("Sprint 4 scene controls check failed with %d failure(s)" % _failures)
		quit(1)
		return

	var instruction_label := scene.get_node("%InstructionLabel") as Label
	_expect(instruction_label.text.contains("Sprint"), "instructions identify the active playable sprint")
	_expect(instruction_label.text.contains("Mouse-first"), "instructions present mouse-first UAT operations")
	_expect(instruction_label.text.contains("Right click"), "instructions explain right-click option menus")
	_expect(instruction_label.text.contains("Left click menu item"), "instructions explain menu confirmation")
	_expect(instruction_label.text.contains("Coupled W != online"), "instructions explain workshop activation after coupling")
	_expect(instruction_label.text.contains("Drive remains keyboard"), "instructions keep keyboard driving separate from object actions")
	_expect(not instruction_label.text.contains("P/O"), "primary instructions no longer present P1/P2 as equal-complexity controls")
	_expect(not instruction_label.text.contains("Y/T"), "primary instructions no longer present P1/P2 remote controls as equal-complexity controls")
	_expect(not instruction_label.text.contains("G:"), "primary instructions no longer expose repair as a keyboard-letter flow")
	_expect(not instruction_label.text.contains("H:"), "primary instructions no longer expose yard control as a keyboard-letter flow")
	_expect(not instruction_label.text.contains("J:"), "primary instructions no longer expose power connection as a keyboard-letter flow")
	_expect(not instruction_label.text.contains("X:"), "primary instructions no longer expose powered control as a keyboard-letter flow")

	await _tap_key(scene, KEY_P)
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == "operate_yard_point", "P assigns selected survivor to operate the workshop route point")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_target", "")) == "P2", "P targets P2 as the primary workshop point")
	scene.crew.cancel_task("marta")

	await _tap_key(scene, KEY_O)
	_expect(str(scene.crew.get_survivor_state("marta").get("task_target", "")) == "P1", "O remains available as the secondary P1 diagnostic control")
	scene.crew.cancel_task("marta")

	var before_route: String = scene.rail.points_route
	await _tap_key(scene, KEY_Y)
	_expect(scene.rail.get_yard_point_route("P2") == RailMovement.POINTS_MAIN, "remote workshop command does nothing while yard control is offline")
	scene.yard.repair_yard_control()
	scene.yard.connect_power()
	await _tap_key(scene, KEY_Y)
	_expect(scene.rail.get_yard_point_route("P2") == RailMovement.POINTS_MAIN, "remote workshop key remains disabled in the normal UAT flow")
	await _tap_key(scene, KEY_T)
	_expect(scene.rail.points_route == before_route, "remote P1 key remains disabled in the normal UAT flow")

	_transition_scene_to_industrial(scene)

	await _tap_key(scene, KEY_X)
	_expect(scene.rail.get_controlled_power_unit_id() == "L", "X cannot select damaged shunter before repair")

	await _tap_key(scene, KEY_G)
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == "repair_shunter", "G assigns selected survivor to repair shunter")
	scene.crew.cancel_task("marta")

	scene.yard.repair_shunter()
	await _tap_key(scene, KEY_X)
	_expect(scene.rail.get_controlled_power_unit_id() == "L", "X cannot select repaired shunter until a survivor is aboard S")
	scene.crew.force_survivor_aboard_unit("marta", "S")
	await _tap_key(scene, KEY_X)
	_expect(scene.rail.get_controlled_power_unit_id() == "S", "X explicitly switches control to repaired shunter with crew aboard")
	await _tap_key(scene, KEY_X)
	_expect(scene.rail.get_controlled_power_unit_id() == "L", "X explicitly switches control back to main locomotive")

	scene.rail.select_powered_control("S")
	scene.crew.force_survivor_yard_position("marta", Vector2(1120.0, 300.0))
	await _hold_key(scene, KEY_W, 0.7)
	_expect(scene.rail.speed <= 0.05, "controlled shunter cannot move without crew aboard its engine")
	_expect(scene.rail.blocked_reason.contains("No crew aboard S"), "blocked shunter throttle reports missing engine crew")
	scene.crew.force_survivor_aboard_unit("marta", "S")
	await _hold_key(scene, KEY_W, 0.7)
	_expect(scene.rail.speed > 0.05, "controlled shunter moves once a survivor is aboard S")

	scene._process(1.0 / 60.0)
	await process_frame
	var debug_label := scene.get_node("%DebugLabel") as Label
	var debug_text := debug_label.text
	_expect(debug_text.contains("Control:"), "debug panel shows explicit powered control")
	_expect(debug_text.contains("Yard:"), "debug panel shows yard control state")
	_expect(debug_text.contains("S:"), "debug overlay shows compact shunter state")

	if _failures == 0:
		print("Sprint 4 scene controls check passed")
		quit(0)
		return

	printerr("Sprint 4 scene controls check failed with %d failure(s)" % _failures)
	quit(1)


func _tap_key(scene: Node, keycode: Key) -> void:
	_send_key(scene, keycode, true)
	scene._process(1.0 / 60.0)
	await process_frame
	_send_key(scene, keycode, false)
	scene._process(1.0 / 60.0)
	await process_frame


func _hold_key(scene: Node, keycode: Key, seconds: float) -> void:
	_send_key(scene, keycode, true)
	var elapsed := 0.0
	while elapsed < seconds:
		scene._process(0.1)
		elapsed += 0.1
		await process_frame
	_send_key(scene, keycode, false)
	scene._process(1.0 / 60.0)
	await process_frame


func _send_key(scene: Node, keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	scene._input(event)


func _transition_scene_to_industrial(scene: Node) -> void:
	if scene.has_method("get_vertical_slice_state") and scene.scenario != null:
		scene.scenario.execute_scenario_interaction("clear_obstruction", "opening_obstruction", "olek")
		scene.scenario.execute_scenario_interaction("repair_onboard_fault", "locomotive_fault", "marta")
	scene.train_resources.set_amount("diesel", 24.0)
	_expect(scene.lifecycle.request_transition(), "fixture enters the industrial sector for shunter control checks")
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.interior = scene.crew.interior


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)
