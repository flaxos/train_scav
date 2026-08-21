extends SceneTree

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	_expect(scene.has_method("_draw_rolling_stock"), "main scene can draw locomotive and wagons")
	_expect(scene.has_method("_draw_couplers"), "main scene can draw front/rear couplers")
	_expect(scene.has_method("_draw_coupling_zones"), "main scene can draw low-speed coupling affordances")
	_expect(scene.has_method("_draw_locomotive_indicator"), "main scene restores a clear locomotive indicator")
	_expect(scene.has_method("_draw_unit_label"), "main scene labels rolling stock programmer-art units")

	var instruction_label := scene.get_node("%InstructionLabel") as Label
	_expect(instruction_label.text.contains("Sprint 4"), "instructions identify the current active playable sprint")
	_expect(instruction_label.text.contains("Right click"), "instructions expose mouse context menus for object actions")
	_expect(instruction_label.text.contains("Drive remains keyboard"), "instructions separate driving keys from railway operation actions")
	_expect(scene.has_method("get_context_menu_labels"), "scene exposes context menu labels for coupling and uncoupling actions")

	var debug_label := scene.get_node("%DebugLabel") as Label
	var debug_text := debug_label.text
	_expect(debug_text.contains("Consist:"), "debug overlay shows consist order")
	_expect(debug_text.contains("Control:"), "debug panel shows explicit powered control")
	_expect(debug_text.contains("Speed:"), "debug panel shows movement state")
	_expect(debug_text.contains("Route:"), "debug panel shows active route state")

	var consist_before := _format_ids(scene.rail.get_active_consist_ids())
	await _tap_key(scene, KEY_Q)
	_expect(_format_ids(scene.rail.get_active_consist_ids()) == consist_before, "Q no longer decouples rolling stock directly in the playable scene")
	_expect(str(scene.yard.last_status).contains("right-click joint menu"), "Q directs tester to crew uncoupling menu")

	await _tap_key(scene, KEY_F)
	_expect(_format_ids(scene.rail.get_active_consist_ids()) == consist_before, "F no longer decouples rolling stock directly in the playable scene")
	_expect(str(scene.yard.last_status).contains("right-click joint menu"), "F directs tester to crew uncoupling menu")

	if _failures == 0:
		print("Sprint 2 scene controls check passed")
		quit(0)
		return

	printerr("Sprint 2 scene controls check failed with %d failure(s)" % _failures)
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
