extends SceneTree

const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const RECONSTRUCTOR_PATH := "res://scripts/worldgen/worldgen_runtime_reconstructor.gd"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"
const HARNESS_SCENE := "res://scenes/worldgen/Sprint9DReconstruction.tscn"
const GOODS_FIXTURE := "res://data/worldgen/archetypes/reference/small_town_goods_station_v1.json"
const GOODS_EMBEDDING := "res://data/worldgen/embeddings/reference/small_town_goods_station_embedding_v1.json"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9D Runtime Movement Tests ---")
	_reconstructed_layout_configures_rail_movement()
	_locomotive_traverses_main_loop_and_goods_yard()
	await _harness_input_path_advances_live_railmovement()
	_finish()


func _reconstructed_layout_configures_rail_movement() -> void:
	var rail: RefCounted = _make_configured_rail()
	if rail == null:
		return
	_expect(rail.has_method("configure_track_layout"), "RailMovement exposes configure_track_layout")
	_expect((rail.get_track_segments() as Dictionary).has("passing_loop"), "configured rail exposes passing loop segment")
	_expect((rail.get_track_segments() as Dictionary).has("goods_loading"), "configured rail exposes goods loading segment")
	_expect(str(rail.get_segment_semantic_id("passing_loop")) == "passing_loop", "runtime segment retains passing_loop semantic ID")
	_expect(str(rail.get_segment_semantic_role("goods_loading")) == "LOADING_TRACK", "runtime segment retains loading role")
	_expect((rail.get_point_ids() as Array).has("west_yard_switch"), "configured rail exposes west yard switch")


func _locomotive_traverses_main_loop_and_goods_yard() -> void:
	var main_rail: RefCounted = _make_configured_rail()
	if main_rail != null:
		_set_route(main_rail, {
			"west_yard_switch": "main",
			"west_loop_switch": "platform",
			"east_loop_switch": "platform",
		})
		_prepare_single_loco(main_rail)
		_step_until(main_rail, "main_east", 15.0)
		_expect(str(main_rail.current_segment) == "main_east", "locomotive traverses entry to east exit via platform main")
		_step_until_distance(main_rail, "main_east", 240.0, 8.0)
		_expect(float(main_rail.distance) > 120.0, "locomotive advances onto the exit segment")

	var loop_rail: RefCounted = _make_configured_rail()
	if loop_rail != null:
		_set_route(loop_rail, {
			"west_yard_switch": "main",
			"west_loop_switch": "loop",
			"east_loop_switch": "loop",
		})
		_prepare_single_loco(loop_rail)
		_step_until(loop_rail, "passing_loop", 8.0)
		_expect(str(loop_rail.current_segment) == "passing_loop", "turnout route sends locomotive through passing loop")
		_step_until(loop_rail, "main_east", 12.0)
		_expect(str(loop_rail.current_segment) == "main_east", "passing loop reconnects to east exit segment")

	var yard_rail: RefCounted = _make_configured_rail()
	if yard_rail != null:
		_set_route(yard_rail, {
			"west_yard_switch": "yard",
			"yard_switch": "loading",
		})
		_prepare_single_loco(yard_rail)
		_step_until(yard_rail, "goods_loading", 12.0)
		_expect(str(yard_rail.current_segment) == "goods_loading", "turnout route sends locomotive into goods loading track")
		_step_until_stopped(yard_rail, 12.0)
		_expect(str(yard_rail.current_segment) == "goods_loading", "goods loading track terminates as an active stub")
		_expect(yard_rail.blocked_reason.contains("goods loading"), "goods loading buffer reports a useful block reason")
		_expect(yard_rail.reverse_direction(), "stopped locomotive can reverse out of goods loading")
		yard_rail.speed = 80.0
		yard_rail.throttle = 1.0
		_step_until(yard_rail, "main_west", 18.0)
		_expect(str(yard_rail.current_segment) == "main_west", "locomotive reverses from goods yard back to the main approach")

	var headshunt_rail: RefCounted = _make_configured_rail()
	if headshunt_rail != null:
		_set_route(headshunt_rail, {
			"west_yard_switch": "yard",
			"yard_switch": "headshunt",
		})
		_prepare_single_loco(headshunt_rail)
		_step_until(headshunt_rail, "yard_headshunt", 12.0)
		_expect(str(headshunt_rail.current_segment) == "yard_headshunt", "turnout route sends locomotive into yard headshunt")
		_step_until_stopped(headshunt_rail, 12.0)
		_expect(str(headshunt_rail.current_segment) == "yard_headshunt", "headshunt terminates as an active stub")
		_expect(headshunt_rail.blocked_reason.contains("headshunt"), "headshunt buffer reports a useful block reason")


func _make_configured_rail() -> RefCounted:
	if not ResourceLoader.exists(RAIL_PATH):
		_expect(false, "RailMovement exists")
		return null
	if not ResourceLoader.exists(RECONSTRUCTOR_PATH):
		_expect(false, "9D reconstructor exists")
		return null
	if not FileAccess.file_exists(GOODS_EMBEDDING):
		_expect(false, "9D small-town goods embedding exists")
		return null

	var loader = (load(LOADER_PATH) as Script).new()
	var validator = (load(VALIDATOR_PATH) as Script).new()
	var reconstructor = (load(RECONSTRUCTOR_PATH) as Script).new()
	var blueprint = loader.load_blueprint(GOODS_FIXTURE)
	var embedding: Dictionary = loader.load_json(GOODS_EMBEDDING)
	var reconstruction: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	_expect(bool(reconstruction.get("valid", false)), "layout reconstructs for RailMovement configuration")
	if not bool(reconstruction.get("valid", false)):
		return null

	var rail = (load(RAIL_PATH) as Script).new()
	var configure_result: Dictionary = rail.configure_track_layout(reconstruction.get("layout", {}) as Dictionary)
	_expect(bool(configure_result.get("valid", false)), "RailMovement accepts reconstructed layout")
	if not bool(configure_result.get("valid", false)):
		return null
	return rail


func _prepare_single_loco(rail: RefCounted) -> void:
	var active: Array[String] = ["L"]
	var detached: Array[Dictionary] = []
	rail.active_units = active
	rail.detached_consists = detached
	rail.current_segment = "main_west"
	rail.distance = 24.0
	rail.direction = 1
	rail.speed = 80.0
	rail.throttle = 1.0
	rail.max_speed = 80.0
	rail.acceleration = 0.0
	rail.coast_deceleration = 0.0
	rail.brake_deceleration = 120.0


func _set_route(rail: RefCounted, routes: Dictionary) -> void:
	for point_id in routes.keys():
		_expect(rail.set_point_route(str(point_id), str(routes[point_id])), "sets route %s to %s" % [str(point_id), str(routes[point_id])])


func _step_until(rail: RefCounted, target_segment: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and str(rail.current_segment) != target_segment:
		rail.step(0.25, false)
		elapsed += 0.25


func _step_until_distance(rail: RefCounted, target_segment: String, target_distance: float, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds:
		if str(rail.current_segment) == target_segment and float(rail.distance) >= target_distance:
			return
		rail.step(0.25, false)
		elapsed += 0.25


func _step_until_stopped(rail: RefCounted, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and float(rail.speed) > 0.05:
		rail.step(0.25, false)
		elapsed += 0.25


func _harness_input_path_advances_live_railmovement() -> void:
	var packed_scene := load(HARNESS_SCENE) as PackedScene
	_expect(packed_scene != null, "Sprint 9D harness scene loads")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.rail != null, "Sprint 9D harness owns a RailMovement instance")
	if scene.rail == null:
		scene.queue_free()
		return

	var start_distance := float(scene.rail.distance)
	_send_key(scene, KEY_SPACE, true)
	await process_frame
	_expect(float(scene.rail.throttle) > 0.0, "Space input reaches harness and opens RailMovement throttle")
	for _index in range(45):
		scene._process(1.0 / 60.0)
		await process_frame
	_expect(float(scene.rail.speed) > 0.0, "harness process path advances RailMovement speed")
	_expect(float(scene.rail.distance) > start_distance, "harness draws from live RailMovement distance changes")
	var moved_distance := float(scene.rail.distance)
	_send_key(scene, KEY_B, true)
	await process_frame
	for _index in range(90):
		scene._process(1.0 / 60.0)
		await process_frame
	_expect(float(scene.rail.speed) <= 0.05, "B input brakes the live RailMovement locomotive to a stop")
	_send_key(scene, KEY_B, true)
	_send_key(scene, KEY_R, true)
	await process_frame
	_expect(int(scene.rail.direction) == -1, "R input reverses the live RailMovement direction while stopped")
	_send_key(scene, KEY_SPACE, true)
	for _index in range(30):
		scene._process(1.0 / 60.0)
		await process_frame
	_expect(float(scene.rail.distance) < moved_distance, "reversed harness locomotive moves physically backward")
	scene.queue_free()


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


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9D runtime movement acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9D runtime movement acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
