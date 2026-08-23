extends SceneTree

# Sprint 7 UAT stabilisation — side-panel diagnostics should not churn every frame.

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7 UI Performance Guard Tests ---")
	await test_side_panel_refresh_is_throttled()
	_finish()


func test_side_panel_refresh_is_throttled() -> void:
	print("Testing side-panel refresh throttling...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("get_ui_panel_refresh_count"), "scene exposes UI refresh count for performance guard")
	_expect(scene.has_method("get_ui_refresh_interval"), "scene exposes UI refresh interval")
	if not scene.has_method("get_ui_panel_refresh_count") or not scene.has_method("get_ui_refresh_interval"):
		scene.queue_free()
		return

	var initial_count: int = scene.get_ui_panel_refresh_count()
	for _i in range(60):
		scene._process(1.0 / 60.0)

	var refreshes: int = scene.get_ui_panel_refresh_count() - initial_count
	_expect(refreshes <= 12, "side-panel text refreshes at a throttled cadence instead of every frame")
	_expect(scene.get_ui_refresh_interval() >= 0.05, "UI refresh interval is high enough to avoid label churn")

	scene.queue_free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 7 UI performance guard passed")
		quit(0)
	else:
		printerr("\nSprint 7 UI performance guard FAILED with %d failure(s)" % _failures)
		quit(1)
