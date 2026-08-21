extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	await _hold_key(scene, KEY_W, 1.0)
	_expect(scene.rail.throttle > 0.4, "W increases throttle")
	_expect(scene.rail.speed > 10.0, "locomotive visibly moves after throttle input")

	await _hold_key(scene, KEY_SPACE, 1.0)
	_expect(scene.rail.is_stopped(), "Space brakes the locomotive to a stop")
	_expect(scene.rail.brake_active == false, "brake state clears after Space is released")

	var initial_route: String = scene.rail.points_route
	await _tap_key(scene, KEY_E)
	_expect(scene.rail.points_route == initial_route, "E no longer changes the switch route instantly")
	_expect(str(scene.crew.get_survivor_state("marta").get("task_type", "")) == CrewSimulation.TASK_OPERATE_POINTS, "E assigns a crew task to operate P1")
	scene.crew.cancel_task("marta")

	var initial_direction: int = scene.rail.direction
	await _tap_key(scene, KEY_R)
	_expect(scene.rail.direction == -initial_direction, "R changes direction while stopped")

	if _failures == 0:
		print("Sprint 1 scene controls check passed")
		quit(0)
		return

	printerr("Sprint 1 scene controls check failed with %d failure(s)" % _failures)
	quit(1)


func _hold_key(scene: Node, keycode: Key, seconds: float) -> void:
	_send_key(scene, keycode, true)
	var elapsed := 0.0
	while elapsed < seconds:
		scene._process(1.0 / 60.0)
		await process_frame
		elapsed += 1.0 / 60.0
	_send_key(scene, keycode, false)
	scene._process(1.0 / 60.0)
	await process_frame


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)
