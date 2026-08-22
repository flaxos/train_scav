extends SceneTree

const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	# Separate two survivors in the yard so mouse targeting is unambiguous.
	scene.crew.force_survivor_yard_position("marta", Vector2(690.0, 520.0))
	scene.crew.force_survivor_yard_position("olek", Vector2(760.0, 520.0))
	scene.crew.select_survivor("marta")

	var olek_screen: Vector2 = scene.world_to_screen_position(Vector2(760.0, 520.0))
	await _right_click(scene, olek_screen)

	_expect(scene.crew.get_selected_survivor_id() == "olek", "right-clicking Olek selects Olek before opening the menu")
	_expect(scene.get_context_menu_actor_id() == "olek", "context menu captures Olek as its actor")
	_expect(scene.get_context_menu_actor_name() == "Olek", "context menu exposes the actor name")
	_expect(scene.get_context_menu_target_label() == "Olek", "survivor context menu identifies the clicked survivor as target")
	_expect(_menu_has(scene, "Move Olek here"), "menu actions are rebuilt for newly selected Olek instead of previous survivor")
	_expect(_header_has(scene, "CREW: Olek"), "menu header clearly identifies selected crew")

	# Deliberately mutate global selection after the menu is open. Confirmation
	# must still dispatch to the actor captured by the menu item.
	scene.crew.select_survivor("marta")
	await _left_click_context_option(scene, "Move Olek here")
	_expect(str(scene.crew.get_survivor_state("olek").get("task_type", "")) == CrewSimulation.TASK_MOVE, "captured menu actor receives the order even if global selection changes")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) != CrewSimulation.TASK_MOVE, "previous/global survivor does not accidentally receive Olek's order")

	# Object right-click keeps the current actor and makes the target explicit.
	scene.crew.cancel_task("olek")
	scene.crew.select_survivor("olek")
	var p3_screen: Vector2 = scene.world_to_screen_position(scene.yard.get_point_anchor("P3"))
	await _right_click(scene, p3_screen)
	_expect(scene.crew.get_selected_survivor_id() == "olek", "right-clicking a world object preserves selected crew")
	_expect(scene.get_context_menu_actor_id() == "olek", "object menu retains Olek as actor")
	_expect(scene.get_context_menu_target_label() == "P3", "object menu identifies P3 as target")
	_expect(_menu_has(scene, "Repair P3"), "damaged P3 exposes repair action for the selected crew member")

	_finish()


func _right_click(scene: Node, position: Vector2) -> void:
	await _click(scene, position, MOUSE_BUTTON_RIGHT)


func _left_click_context_option(scene: Node, label_fragment: String) -> void:
	var option_position: Vector2 = scene.get_context_menu_option_position(label_fragment)
	_expect(option_position != Vector2.INF, "context menu has option matching %s" % label_fragment)
	if option_position == Vector2.INF:
		return
	await _click(scene, option_position, MOUSE_BUTTON_LEFT)


func _click(scene: Node, position: Vector2, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = true
	scene._gui_input(event)
	scene._process(1.0 / 60.0)
	await process_frame


func _menu_has(scene: Node, label_fragment: String) -> bool:
	for label in scene.get_context_menu_labels():
		if str(label).contains(label_fragment):
			return true
	return false


func _header_has(scene: Node, label_fragment: String) -> bool:
	for label in scene.get_context_menu_header_lines():
		if str(label).contains(label_fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4.5 context actor acceptance passed")
		quit(0)
		return
	printerr("Sprint 4.5 context actor acceptance failed with %d failure(s)" % _failures)
	quit(1)
