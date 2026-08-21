extends SceneTree

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	_expect(scene.has_method("get_playfield_rect"), "scene exposes playfield layout rect")
	_expect(scene.has_method("get_ui_panel_rect"), "scene exposes side UI panel rect")
	_expect(scene.has_method("get_instruction_panel_rect"), "scene exposes instruction panel rect")
	_expect(scene.has_method("get_debug_panel_rect"), "scene exposes debug panel rect")
	_expect(scene.has_method("get_compact_debug_lines"), "scene exposes compact debug lines")
	if _failures > 0:
		_finish()
		return

	var playfield: Rect2 = scene.get_playfield_rect()
	var ui_panel: Rect2 = scene.get_ui_panel_rect()
	var instructions: Rect2 = scene.get_instruction_panel_rect()
	var debug: Rect2 = scene.get_debug_panel_rect()

	_expect(playfield.size.x > 480.0 and playfield.size.y > 320.0, "playfield remains large enough for readable yard operation")
	_expect(not playfield.intersects(ui_panel), "side UI panel does not overlap playfield")
	_expect(ui_panel.encloses(instructions), "instruction text fits inside side UI panel")
	_expect(ui_panel.encloses(debug), "debug text fits inside side UI panel")
	_expect(not instructions.intersects(debug), "instruction and debug regions do not overlap")

	var instruction_label := scene.get_node("%InstructionLabel") as Label
	var debug_label := scene.get_node("%DebugLabel") as Label
	var instruction_label_rect := Rect2(instruction_label.position, instruction_label.size)
	var debug_label_rect := Rect2(debug_label.position, debug_label.size)
	_expect(instructions.encloses(instruction_label_rect), "instruction label is contained by its panel region; panel %s label %s" % [str(instructions), str(instruction_label_rect)])
	_expect(debug.encloses(debug_label_rect), "debug label is contained by its panel region; panel %s label %s" % [str(debug), str(debug_label_rect)])

	scene._process(1.0 / 60.0)
	await process_frame
	var debug_lines: Array[String] = scene.get_compact_debug_lines()
	_expect(debug_lines.size() <= 10, "playable UI uses compact debug instead of dumping every raw diagnostic line")
	_expect(debug_label.text.split("\n", false).size() <= 10, "debug label remains compact enough for UAT panel")
	_expect(debug_label.text.contains("Speed:"), "compact debug still exposes train speed")
	_expect(debug_label.text.contains("Control:"), "compact debug still exposes selected powered unit")
	_expect(debug_label.text.contains("Yard:"), "compact debug still exposes yard control state")
	_expect(debug_label.text.contains("Crew:"), "compact debug still exposes selected crew state")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 UAT layout check passed")
		quit(0)
		return

	printerr("Sprint 4 UAT layout check failed with %d failure(s)" % _failures)
	quit(1)
