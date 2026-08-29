extends SceneTree

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Shutdown Cleanup Tests ---")
	await _main_scene_releases_runtime_references()
	_finish()


func _main_scene_releases_runtime_references() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.rail != null, "fixture creates rail runtime service")
	_expect(scene.crew != null, "fixture creates crew runtime service")
	_expect(scene.lifecycle != null, "fixture creates sector lifecycle")
	_expect(scene.scenario != null, "fixture creates first-run scenario")
	_expect(scene.has_method("release_runtime_references"), "Main exposes shutdown cleanup seam")
	if scene.has_method("release_runtime_references"):
		scene.release_runtime_references()
		_expect(scene.rail == null, "Main releases rail reference")
		_expect(scene.crew == null, "Main releases crew reference")
		_expect(scene.yard == null, "Main releases yard reference")
		_expect(scene.interior == null, "Main releases interior reference")
		_expect(scene.task_broker == null, "Main releases task broker reference")
		_expect(scene.lifecycle == null, "Main releases lifecycle reference")
		_expect(scene.train_resources == null, "Main releases train resources reference")
		_expect(scene.scenario == null, "Main releases scenario reference")

	scene.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nShutdown cleanup tests passed")
		quit(0)
	else:
		printerr("\nShutdown cleanup tests FAILED with %d failure(s)" % _failures)
		quit(1)
