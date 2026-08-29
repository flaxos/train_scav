extends SceneTree

# Sprint 12 — Scripted UAT Rehearsal.
# Runs the full normal-game flow in Main.tscn across Sector 0, Sector 1 route branching,
# requirement gating before and after coupling workshop W, and departure into Sector 2.

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")

var _failures: int = 0
var _previous_env: Dictionary = {}


func _init() -> void:
	print("\n--- Starting Sprint 12 Scripted UAT Rehearsal ---")
	_previous_env = _capture_env([ENV_RUN_SEED, ENV_START_SECTOR, ENV_START_ROUTE])
	await _run_sprint12_rehearsal()
	_restore_env(_previous_env)
	_finish()


func _run_sprint12_rehearsal() -> void:
	OS.set_environment(ENV_RUN_SEED, "6001")
	OS.set_environment(ENV_START_SECTOR, "")
	OS.set_environment(ENV_START_ROUTE, "")

	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main.tscn loads for Sprint 12 UAT")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# Step 1: In Sector 0, verify initial mobility summary
	_expect(_debug_contains(scene, "167.0t"), "Sector 0 displays starter consist mass 167.0t")
	_expect(_debug_contains(scene, "192px"), "Sector 0 displays starter consist length 192px")
	_expect(_debug_contains(scene, "Control: L"), "Sector 0 displays control unit L")

	# Step 2: Play through Sector 0 opening
	_clear_sector0_opening(scene)
	_expect(scene.lifecycle.can_depart(), "Sector 0 is ready for departure")

	# Move train across main exit to trigger departure confirmation
	scene.rail.current_segment = RailMovement.SEGMENT_MAIN_EXIT
	scene.rail.distance = 265.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1
	scene._check_departure_boundary()

	_expect(scene.is_departure_confirmation_open(), "departure confirmation opens in Sector 0")
	var conf_lines: Array[String] = scene.get_departure_confirmation_lines()
	var conf_text := "\n".join(conf_lines)
	_expect(conf_text.contains("Train Mobility: Mass 167.0t"), "departure modal displays mobility summary")

	# Confirm departure into Sector 1
	var depart_ok: bool = scene.confirm_sector_departure()
	_expect(depart_ok, "departed into Sector 1")
	_expect(scene.lifecycle.current_sector.definition.sector_index == 1, "entered Sector 1")

	# Step 3: In Sector 1, approach industrial exit without W
	scene.rail.current_segment = RailMovement.SEGMENT_INDUSTRIAL_EXIT
	scene.rail.distance = 225.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1
	scene._check_departure_boundary()

	_expect(not scene.is_departure_confirmation_open(), "departure modal blocked without workshop W")
	_expect(scene.yard.last_status.contains("requires capability 'workshop'"), "status explains workshop capability requirement")

	# Step 4: Shunt and couple workshop wagon W
	scene.rail.active_units.append("W")
	scene.scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)

	# Verify mobility summary updated in debug
	scene._refresh_side_panel_text(true)
	_expect(_debug_contains(scene, "215.0t"), "Sector 1 debug displays updated mass 215.0t after coupling W")
	_expect(_debug_contains(scene, "260px"), "Sector 1 debug displays updated length 260px after coupling W")

	# Re-attempt industrial exit with W
	scene.rail.current_segment = RailMovement.SEGMENT_INDUSTRIAL_EXIT
	scene.rail.distance = 225.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1
	scene._check_departure_boundary()

	_expect(scene.is_departure_confirmation_open(), "departure confirmation opens on industrial exit with W attached")
	var conf_lines_s1: Array[String] = scene.get_departure_confirmation_lines()
	var conf_text_s1 := "\n".join(conf_lines_s1)
	_expect(conf_text_s1.contains("Route branch: Industrial route"), "departure modal identifies Industrial route")
	_expect(conf_text_s1.contains("Train Mobility: Mass 215.0t"), "departure modal reflects 215t mass")
	_expect(conf_text_s1.contains("Route requirements:"), "departure modal lists route requirements")

	# Step 5: Depart into Sector 2 (procedural sector)
	var depart_to_s2: bool = scene.confirm_sector_departure()
	_expect(depart_to_s2, "departed into Sector 2")
	_expect(scene.lifecycle.current_sector.definition.sector_index == 2, "entered Sector 2")
	_expect(scene.lifecycle.current_sector.definition.is_procedural(), "Sector 2 is procedural")

	scene._refresh_side_panel_text(true)
	_expect(_debug_contains(scene, "215.0t"), "Sector 2 preserves train mass 215.0t")
	_expect(_debug_contains(scene, "260px"), "Sector 2 preserves train length 260px")

	scene.queue_free()


func _clear_sector0_opening(scene: Node) -> void:
	if scene.scenario != null:
		scene.scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
		scene.scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	if scene.train_resources != null:
		scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)
		scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 10.0)


func _debug_contains(scene: Node, query: String) -> bool:
	if scene == null:
		return false
	var compact := "\n".join(scene.get_compact_debug_lines())
	if compact.contains(query):
		return true
	if scene.debug_label != null and scene.debug_label.text.contains(query):
		return true
	return false


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
		print("\nSprint 12 scripted UAT rehearsal passed")
		quit(0)
	else:
		print("\nSprint 12 scripted UAT rehearsal FAILED with %d failure(s)" % _failures)
		quit(1)
