extends SceneTree

# Sprint 12.5 — Scripted UAT Rehearsal.
# Runs the full human UAT scenario from Sprint 12 / 12.5:
# 1. Start with consist [S][W][L][A][B] (277t, workshop online) in Sector 1.
# 2. Attempt Direct route: assert departure blocked due to mass limit and
#    assert high-priority blocker message is NOT shadowed by route selection text.
# 3. Present Industrial route as eligible with actionable switch hint.
# 4. Switch P2 to Industrial branch and depart cleanly into Sector 2.
# 5. Verify clean player presentation vs F3 debug overlay.

const MainScene := preload("res://scenes/bootstrap/Main.tscn")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"

var _failures: int = 0
var _previous_env: Dictionary = {}


func _init() -> void:
	print("\n--- Starting Sprint 12.5 Scripted UAT Rehearsal ---")
	_previous_env = _capture_env([ENV_RUN_SEED, ENV_START_SECTOR, ENV_START_ROUTE])
	await _run_sprint12_5_uat_rehearsal()
	_restore_env(_previous_env)
	_finish()


func _run_sprint12_5_uat_rehearsal() -> void:
	OS.set_environment(ENV_RUN_SEED, "6001")
	OS.set_environment(ENV_START_SECTOR, "")
	OS.set_environment(ENV_START_ROUTE, "")

	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main.tscn loads for Sprint 12.5 UAT")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# Setup Sector 1 state matching user screenshot: Consist [S][W][L][A][B], mass 277t, workshop online
	_advance_to_sector1_with_full_consist(scene)
	_expect(scene.lifecycle.current_sector.definition.sector_index == 1, "in Sector 1")

	var mobility: Dictionary = scene.rail.get_mobility_summary()
	_expect(is_equal_approx(float(mobility.get("total_mass", 0.0)), 277.0), "train mass is exactly 277.0t")
	_expect(int(mobility.get("unit_count", 0)) == 5, "consist has 5 vehicles [S, W, L, A, B]")

	# --- TEST A: Route Decision Presentation ---
	var routes_panel: Array[String] = scene.get_player_routes_panel_lines()
	var routes_text := "\n".join(routes_panel)

	_expect(routes_text.contains("Sector 1"), "routes panel shows Sector 1 header")
	_expect(routes_text.contains("Direct Line [BLOCKED ✕]"), "Direct Line is marked BLOCKED")
	_expect(routes_text.contains("Bridge limit: 250t (Train: 277.0t, 27.0t too heavy)"), "Direct Line explains 250t limit vs 277t train")
	_expect(routes_text.contains("Industrial Line [AVAILABLE ✓]"), "Industrial Line is marked AVAILABLE")
	_expect(routes_text.contains("Settlement Line [BLOCKED ✕]"), "Settlement Line is marked BLOCKED")

	# --- TEST B: Attempt Direct Route & Verify Message Priority ---
	# Set P2 switch to Main (Direct route)
	scene.rail.set_yard_point_route(YardOperations.POINT_P2, RailMovement.POINTS_MAIN)
	scene.rail.current_segment = RailMovement.SEGMENT_MAIN_EXIT
	scene.rail.distance = 265.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1
	scene._check_departure_boundary()

	# Departure must be blocked
	_expect(not scene.is_departure_confirmation_open(), "Direct Line departure is blocked due to 277t > 250t")
	var latest_status: String = scene._latest_status_line()
	_expect(latest_status.contains("exceeds Direct") or latest_status.contains("250.0t max") or latest_status.contains("250t"), "status line reports mass limit blocker")
	_expect(not latest_status.begins_with("Route selected"), "blocker is NOT shadowed by route selected text")

	# --- TEST C: Switch to Industrial Route & Depart ---
	# Set switch P2 to Siding (Industrial route)
	scene.rail.set_yard_point_route(YardOperations.POINT_P2, RailMovement.POINTS_SIDING)
	scene.rail.current_segment = RailMovement.SEGMENT_INDUSTRIAL_EXIT
	scene.rail.distance = 225.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1
	scene._check_departure_boundary()

	_expect(scene.is_departure_confirmation_open(), "Industrial Line departure confirmation opens")
	var conf_text := "\n".join(scene.get_departure_confirmation_lines())
	_expect(conf_text.contains("Industrial"), "departure confirmation specifies Industrial Line")

	var depart_ok: bool = scene.confirm_sector_departure()
	_expect(depart_ok, "departed into Sector 2 via Industrial Line")
	_expect(scene.lifecycle.current_sector.definition.sector_index == 2, "entered Sector 2")
	_expect(scene.lifecycle.current_sector.definition.is_procedural(), "Sector 2 is procedural")

	# --- TEST D: Sector 2 Clean UI Presentation ---
	var s2_routes_text := "\n".join(scene.get_player_routes_panel_lines())
	_expect(not s2_routes_text.contains("blueprint_hash"), "Sector 2 routes panel has no blueprint hash")
	_expect(not s2_routes_text.contains("generator_version"), "Sector 2 routes panel has no generator version")
	_expect(s2_routes_text.contains("Sector 2"), "Sector 2 header is player-readable")

	var s2_status_text := "\n".join(scene.get_player_status_panel_lines())
	_expect(s2_status_text.contains("277.0t"), "Sector 2 preserves train mass 277.0t")
	_expect(not s2_status_text.contains("322px"), "Sector 2 normal status hides raw px measurements")

	# --- TEST E: Debug Mode Toggle (F3) ---
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_F3
	key_event.pressed = true
	scene._input(key_event)
	_expect(bool(scene.debug_mode_enabled) == true, "F3 enabled debug mode")

	var debug_lines: Array[String] = scene.get_compact_debug_lines()
	var debug_text := "\n".join(debug_lines)
	_expect(debug_text.contains("Idx:2") or debug_text.contains("Sector:"), "debug lines expose sector index")
	_expect(debug_text.contains("277.0t"), "debug lines expose consist mass")

	scene.release_runtime_references()
	scene.queue_free()


func _advance_to_sector1_with_full_consist(scene: Node) -> void:
	# Clear Sector 0
	if scene.scenario != null:
		scene.scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
		scene.scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	if scene.train_resources != null:
		scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)
		scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 10.0)
	if scene.crew != null:
		for s_id in scene.crew.get_survivor_ids():
			scene.crew.force_survivor_aboard_unit(str(s_id), "L")

	scene.rail.current_segment = RailMovement.SEGMENT_MAIN_EXIT
	scene.rail.distance = 265.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1
	scene._check_departure_boundary()
	scene.confirm_sector_departure()

	# In Sector 1, add S and W to consist [S, W, L, A, B]
	var units: Array[String] = ["S", "W", "L", "A", "B"]
	scene.rail.active_units = units
	scene.rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	scene.rail.controlled_power_unit_id = "S"
	if scene.crew != null:
		scene.crew.force_survivor_aboard_unit("iris", "S")
		scene.crew.force_survivor_aboard_unit("marta", "W")
		scene.crew.force_survivor_aboard_unit("olek", "L")
		scene.crew.force_survivor_aboard_unit("nia", "A")
		scene.crew.force_survivor_aboard_unit("pavel", "B")
	if scene.scenario != null:
		scene.scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	if scene.train_resources != null:
		scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)
	scene._refresh_side_panel_text(true)


func _capture_env(keys: Array[String]) -> Dictionary:
	var state: Dictionary = {}
	for key in keys:
		state[key] = OS.get_environment(key)
	return state


func _restore_env(state: Dictionary) -> void:
	for key in state.keys():
		OS.set_environment(str(key), str(state[key]))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12.5 scripted UAT rehearsal passed")
		quit(0)
	else:
		print("\nSprint 12.5 scripted UAT rehearsal FAILED with %d failure(s)" % _failures)
		quit(1)
