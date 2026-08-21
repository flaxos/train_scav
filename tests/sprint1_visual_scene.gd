extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	_expect(scene.get_node_or_null("Background") == null, "full-screen background does not cover the rail drawing layer")
	_expect(scene.has_method("_draw_track"), "main scene can draw railway track")
	_expect(scene.has_method("_draw_switch"), "main scene can draw switch/points")
	_expect(scene.has_method("_draw_locomotive"), "main scene can draw locomotive")
	_expect(scene.has_node("%DebugLabel"), "debug label exists")
	if scene.has_node("%DebugLabel"):
		var debug_label := scene.get_node("%DebugLabel") as Label
		_expect(debug_label.anchor_top == 0.0, "debug label is anchored to the top of the viewport")
		_expect(debug_label.global_position.y >= 0.0 and debug_label.global_position.y < 680.0, "debug label is inside the visible viewport")

	if _failures == 0:
		print("Sprint 1 visual scene check passed")
		quit(0)
		return

	printerr("Sprint 1 visual scene check failed with %d failure(s)" % _failures)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)
