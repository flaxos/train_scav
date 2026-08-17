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

	var instruction_label := scene.get_node("%InstructionLabel") as Label
	_expect(instruction_label.text.contains("Sprint 2"), "instructions identify Sprint 2")
	_expect(instruction_label.text.contains("Q"), "instructions expose decoupling control")
	_expect(instruction_label.text.contains("C"), "instructions expose coupling control")

	var debug_label := scene.get_node("%DebugLabel") as Label
	var debug_text := debug_label.text
	_expect(debug_text.contains("Consist:"), "debug overlay shows consist order")
	_expect(debug_text.contains("Mass:"), "debug overlay shows active consist mass")
	_expect(debug_text.contains("Couplers:"), "debug overlay shows coupler state")

	await _tap_key(scene, KEY_Q)
	_expect(_format_ids(scene.rail.get_active_consist_ids()) == "[L][A]", "Q decouples the rear wagon in the playable scene")

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
