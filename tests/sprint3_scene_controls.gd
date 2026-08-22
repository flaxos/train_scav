extends SceneTree

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	_expect(scene.has_method("_draw_survivors"), "main scene draws physical survivors")
	_expect(scene.has_method("_draw_crew_interaction_anchors"), "main scene draws crew interaction anchors")
	_expect(scene.has_method("_draw_task_targets"), "main scene draws task targets")
	_expect(scene.crew != null, "main scene owns a crew simulation")
	_expect(scene.crew.get_survivor_ids().size() == 5, "playable scene has five survivors")

	var instruction_label := scene.get_node("%InstructionLabel") as Label
	_expect(instruction_label.text.contains("Sprint"), "instructions identify the current playable sprint while preserving Sprint 3 controls")
	_expect(instruction_label.text.contains("Left click survivor"), "instructions expose direct survivor selection")
	_expect(instruction_label.text.contains("Right click"), "instructions expose crew task context menus")
	_expect(instruction_label.text.contains("Left click menu item"), "instructions expose menu confirmation")
	_expect(instruction_label.text.contains("Dev"), "direct rail shortcuts are labelled as developer shortcuts")

	await _tap_key(scene, KEY_2)
	_expect(scene.crew.get_selected_survivor_id() == "olek", "number keys select a survivor")

	await _tap_key(scene, KEY_U)
	_expect(str(scene.crew.get_survivor_state("olek").get("task_type", "")) == "uncouple", "U assigns selected survivor to uncouple A/B")
	_expect(_format_ids(scene.rail.get_active_consist_ids()) == "[L][A][B]", "scene uncoupling does not happen immediately on key press")

	var debug_label := scene.get_node("%DebugLabel") as Label
	scene._process(1.0 / 60.0)
	await process_frame
	var debug_text := debug_label.text
	_expect(debug_text.contains("Crew:"), "debug panel shows selected survivor state")
	_expect(debug_text.contains("Task:"), "debug panel shows crew task")
	_expect(debug_text.contains("Crew:"), "debug overlay summarizes crew")

	if _failures == 0:
		print("Sprint 3 scene controls check passed")
		quit(0)
		return

	printerr("Sprint 3 scene controls check failed with %d failure(s)" % _failures)
	quit(1)


func _tap_key(scene: Node, keycode: Key) -> void:
	_send_key(scene, keycode, true)
	scene._process(1.0 / 60.0)
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


func _format_ids(ids: Array) -> String:
	var text := ""
	for id in ids:
		text += "[%s]" % id
	return text


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)
