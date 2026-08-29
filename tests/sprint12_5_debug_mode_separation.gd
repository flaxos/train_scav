extends SceneTree

# Sprint 12.5 — Debug Mode Separation Tests.
# Verifies that normal player mode hides internal debug telemetry
# (hashes, versions, seeds, raw px), while debug mode (F3) exposes full diagnostics.

const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 12.5 Debug Mode Separation Tests ---")
	await test_normal_mode_cleanliness()
	await test_debug_mode_toggle_and_diagnostics()
	_finish()


func test_normal_mode_cleanliness() -> void:
	print("Testing normal player mode cleanliness...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# 1. Default mode must be normal (debug_mode_enabled == false)
	_expect(bool(scene.debug_mode_enabled) == false, "default debug mode is disabled (clean player view)")

	# 2. Check player routes panel lines
	var route_lines: Array[String] = scene.get_player_routes_panel_lines()
	var joined_routes := "\n".join(route_lines)
	_expect(not joined_routes.contains("blueprint_hash"), "normal routes panel hides blueprint hash")
	_expect(not joined_routes.contains("generator_version"), "normal routes panel hides generator version")
	_expect(not joined_routes.contains("Seed:"), "normal routes panel hides internal seed value")
	_expect(joined_routes.contains("Sector 0") or joined_routes.contains("Departure Yard"), "normal routes panel has readable sector name")

	# 3. Check player status panel lines
	var status_lines: Array[String] = scene.get_player_status_panel_lines()
	var joined_status := "\n".join(status_lines)
	_expect(not joined_status.contains("322px"), "normal status panel hides raw internal px length")
	_expect(not joined_status.contains("Task none target Cargo none"), "normal status panel hides raw task broker internals")
	_expect(joined_status.contains("Consist:"), "normal status panel contains clean train mobility section")
	_expect(joined_status.contains("Supplies:"), "normal status panel contains supplies section")
	_expect(joined_status.contains("Crew:"), "normal status panel contains crew section")

	scene.release_runtime_references()
	scene.queue_free()


func test_debug_mode_toggle_and_diagnostics() -> void:
	print("Testing debug mode toggle and diagnostics...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# 1. Simulate pressing F3
	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.pressed = true
	scene._input(event)
	_expect(bool(scene.debug_mode_enabled) == true, "pressing F3 enables debug mode")

	# 2. In debug mode, tutorial and compact debug lines remain fully available
	var debug_lines: Array[String] = scene.get_compact_debug_lines()
	var joined_debug := "\n".join(debug_lines)
	_expect(joined_debug.contains("Sector:"), "debug mode exposes sector telemetry")
	_expect(joined_debug.contains("Consist:"), "debug mode exposes consist details")
	_expect(joined_debug.contains("Speed:"), "debug mode exposes speed telemetry")

	var tutorial_lines: Array[String] = scene.get_uat_tutorial_lines()
	_expect(tutorial_lines.size() > 0, "debug tutorial checklist lines available")

	# 3. Pressing F3 again toggles it off
	scene._input(event)
	_expect(bool(scene.debug_mode_enabled) == false, "pressing F3 again disables debug mode")

	scene.release_runtime_references()
	scene.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12.5 debug mode separation acceptance passed")
		quit(0)
	else:
		print("\nSprint 12.5 debug mode separation acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
