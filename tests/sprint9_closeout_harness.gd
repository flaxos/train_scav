extends SceneTree

const HARNESS_SCENE := "res://scenes/worldgen/Sprint9GeneratedRailway.tscn"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9 Closeout Generated Harness Tests ---")
	await _generated_harness_loads_and_supports_seed_controls()
	_finish()


func _generated_harness_loads_and_supports_seed_controls() -> void:
	_expect(ResourceLoader.exists(HARNESS_SCENE), "Sprint 9 generated railway harness scene exists")
	var packed_scene := load(HARNESS_SCENE) as PackedScene
	_expect(packed_scene != null, "Sprint 9 generated railway harness scene loads")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.rail != null, "generated harness owns live RailMovement")
	_expect(str(scene.blueprint_hash) != "", "generated harness displays blueprint hash")
	_expect(str(scene.generation_trace_hash) != "", "generated harness displays generation trace hash")
	_expect(str(scene.spatial_embedding_hash) != "", "generated harness displays spatial embedding hash")
	_expect(str(scene.current_runtime_segment) == str(scene.rail.current_segment), "generated harness reports live RailMovement segment")

	var original_seed := int(scene.current_seed)
	var original_blueprint_hash := str(scene.blueprint_hash)
	var original_spatial_hash := str(scene.spatial_embedding_hash)
	_send_key(scene, KEY_SPACE)
	await process_frame
	_expect(float(scene.rail.throttle) > 0.0, "Space input sets ordinary RailMovement throttle")
	_send_key(scene, KEY_2)
	await process_frame
	_expect(str(scene.selected_route_id) == "loop", "2 selects generated passing-loop route preset")
	_send_key(scene, KEY_0)
	await process_frame
	_expect(str(scene.current_runtime_segment) == str(scene.layout.get("entry_segment", "")), "0 resets locomotive to generated entry segment")

	_send_key(scene, KEY_BRACKETRIGHT)
	await process_frame
	_expect(int(scene.current_seed) == original_seed + 1, "right bracket increments generated seed")
	_expect(str(scene.spatial_embedding_hash) != "", "next generated seed has spatial hash")

	_send_key(scene, KEY_BRACKETLEFT)
	await process_frame
	_expect(int(scene.current_seed) == original_seed, "left bracket returns to original generated seed")
	_expect(str(scene.blueprint_hash) == original_blueprint_hash, "returning to seed reproduces blueprint hash")
	_expect(str(scene.spatial_embedding_hash) == original_spatial_hash, "returning to seed reproduces spatial embedding")
	scene.queue_free()


func _send_key(scene: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	scene._input(event)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9 closeout generated harness acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9 closeout generated harness acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
