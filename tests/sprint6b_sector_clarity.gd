extends SceneTree

# Sprint 6B — Sector clarity / UAT stabilisation tests.
# Verifies that Sector 1 no longer reads like a reset, stale Sprint 4/5 labels
# are gone, and the forward-only transition remains mechanically safe.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 6B Sector Clarity Tests ---")
	await test_readme_and_scene_guide_are_current()
	await test_sector_b_visual_state_is_distinct()
	test_exit_requires_forward_main_departure()
	test_sector_one_disembark_and_reverse_do_not_reset()
	await test_departure_confirmation_flow()
	_finish()


func test_readme_and_scene_guide_are_current() -> void:
	print("Testing current README and in-game guide labels...")
	var readme := FileAccess.get_file_as_string("res://README.md")
	_expect(readme.contains("Sprint 12: Mobility, Burden & Route Requirements"), "README names Sprint 12 as active sprint")
	_expect(readme.contains("Sprint 10 rolling-stock salvage remains seeded"), "README records Sprint 10 salvage compatibility")
	_expect(not readme.contains("Sprint 4: Railway Operations Systems"), "README no longer advertises stale Sprint 4 active sprint")

	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var lines: Array[String] = scene.get_uat_tutorial_lines()
	var guide := "\n".join(lines)
	_expect(guide.contains("Train Scav - Sprint 12 UAT"), "in-game guide title names Sprint 12")
	_expect(guide.contains("Sprint 11 Procgen Check"), "in-game guide exposes Sprint 11 load check")
	_expect(guide.contains("Opening still uses Sprint 8 vertical slice"), "in-game guide preserves authored opening context")
	_expect(not guide.contains("Sprint 5A UAT Guide"), "in-game guide no longer exposes stale Sprint 5A label")
	scene.queue_free()


func test_sector_b_visual_state_is_distinct() -> void:
	print("Testing Sector B visual identity...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("get_sector_visual_state"), "Main scene exposes sector visual-state helper")
	if scene.has_method("get_sector_visual_state"):
		_prepare_scene_for_departure(scene)
		var visual_a: Dictionary = scene.get_sector_visual_state()
		_expect(str(visual_a.get("template_name", "")) == "Sector A", "initial sector visual state names Sector A")

		scene.rail.current_segment = scene.lifecycle.current_sector.definition.exit_segment
		scene.rail.distance = scene.lifecycle.current_sector.definition.exit_distance + 5.0
		scene.rail.direction = 1
		scene.rail.speed = 20.0
		scene._process(1.0 / 60.0)
		_expect(scene.is_departure_confirmation_open(), "exit boundary opens confirmation before visual transition")
		_expect(scene.confirm_sector_departure(), "fixture confirms departure to inspect Sector B visual state")
		var visual_b: Dictionary = scene.get_sector_visual_state()
		_expect(str(visual_b.get("template_name", "")) == "Sector B", "transitioned sector visual state names Sector B")
		_expect(str(visual_b.get("display_name", "")) != str(visual_a.get("display_name", "")), "Sector B display name differs from Sector A")
		_expect(str(visual_b.get("entry_label", "")) != "", "Sector B exposes an entry label")
		_expect(str(visual_b.get("entry_label", "")).contains("Sector 1"), "Sector B entry label makes sector index visible")
		_expect(visual_b.get("accent_color", Color.WHITE) != visual_a.get("accent_color", Color.WHITE), "Sector B uses a distinct accent color")

	scene.queue_free()


func test_exit_requires_forward_main_departure() -> void:
	print("Testing forward-only exit boundary placement...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var lifecycle := SectorLifecycle.new(12345, crew, broker)
	var def = lifecycle.current_sector.definition

	_expect(def.exit_segment == "main_exit", "sector exit is on an eastbound main-exit segment beyond P2")
	_expect(rail.get_track_segments().has("main_exit"), "rail model exposes a visible main-exit track segment")
	if rail.get_track_segments().has("main_exit"):
		var exit_points: Array = rail.get_track_segments()["main_exit"]
		_expect(exit_points.size() >= 2, "main-exit segment has drawable track")
		_expect((exit_points[exit_points.size() - 1] as Vector2).x > 1600.0, "main-exit segment extends far enough east to read as leaving the sector")

	rail.current_segment = def.exit_segment
	rail.distance = def.exit_distance + 5.0
	rail.direction = -1
	rail.speed = 20.0
	_expect(not lifecycle.step(), "backward movement across the exit boundary does not transition sectors")
	_expect(lifecycle.run_state.sector_index == 0, "backward exit-boundary contact keeps sector index at 0")

	rail.direction = 1
	rail.speed = 0.0
	_expect(not lifecycle.step(), "stationary train sitting at exit does not transition without forward motion")
	_expect(lifecycle.run_state.sector_index == 0, "stationary exit-boundary contact keeps sector index at 0")


func test_sector_one_disembark_and_reverse_do_not_reset() -> void:
	print("Testing Sector 1 disembark and no-backtracking behaviour...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var lifecycle := SectorLifecycle.new(12345, crew, broker)
	var sec_a = lifecycle.current_sector

	rail.current_segment = sec_a.definition.exit_segment
	rail.distance = sec_a.definition.exit_distance + 5.0
	rail.direction = 1
	rail.speed = 20.0
	_expect(lifecycle.step(), "fixture transitions from Sector A to Sector B")
	var sec_b = lifecycle.current_sector
	var sector_one_start_position := crew.get_survivor_world_position("marta")
	_expect(str(sec_b.definition.template_name) == "Sector B", "fixture entered Sector B")

	_expect(crew.assign_disembark("marta"), "Marta can disembark after entering Sector 1")
	_step_crew_until_idle(crew, 240)
	var marta_state := crew.get_survivor_state("marta")
	var marta_position := crew.get_survivor_world_position("marta")
	_expect(str(marta_state.get("spatial_state", "")) == CrewSimulation.SPATIAL_YARD, "Marta is in the yard after Sector 1 disembark")
	_expect(marta_position.distance_to(sector_one_start_position) < 120.0, "Sector 1 disembark occurs near the Sector 1 train, not an old-sector origin")

	sec_b.rail.set_direction(-1)
	sec_b.rail.set_throttle(1.0)
	for _i in range(240):
		sec_b.rail.step(1.0 / 60.0, false)
		lifecycle.step()
	_expect(lifecycle.run_state.sector_index == 1, "reversing left in Sector 1 does not decrement sector index")
	_expect(lifecycle.run_state.transition_count == 1, "reversing left in Sector 1 does not create a backtracking transition")
	_expect(sec_a.disposed, "Sector A remains disposed after reverse movement in Sector 1")
	_expect(str(sec_b.rail.blocked_reason).contains("End of main line"), "reverse-left attempt reports end of main line")


func test_departure_confirmation_flow() -> void:
	print("Testing departure confirmation UI flow...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("is_departure_confirmation_open"), "scene exposes departure confirmation state")
	_expect(scene.has_method("get_departure_confirmation_lines"), "scene exposes departure confirmation copy")
	_expect(scene.has_method("confirm_sector_departure"), "scene exposes explicit departure confirm command")
	_expect(scene.has_method("cancel_sector_departure"), "scene exposes explicit departure cancel command")
	if not scene.has_method("is_departure_confirmation_open"):
		scene.queue_free()
		return

	var def = scene.lifecycle.current_sector.definition
	_prepare_scene_for_departure(scene)
	scene.rail.current_segment = def.exit_segment
	scene.rail.distance = def.exit_distance + 8.0
	scene.rail.direction = 1
	scene.rail.speed = 25.0
	scene.rail.throttle = 0.4
	scene._process(1.0 / 60.0)

	_expect(scene.is_departure_confirmation_open(), "forward exit opens departure confirmation instead of immediately changing sector")
	_expect(scene.lifecycle.run_state.sector_index == 0, "pending departure keeps current sector until confirmed")
	_expect(scene.rail.speed <= 0.05, "pending departure hard-brakes the train")
	_expect(scene.rail.throttle == 0.0, "pending departure cuts throttle")

	var lines: Array[String] = scene.get_departure_confirmation_lines()
	var text := "\n".join(lines)
	_expect(text.contains("Leave Sector 0?"), "confirmation asks whether to leave the current sector")
	_expect(text.contains("Rolling stock left behind"), "confirmation reports rolling stock abandonment")
	_expect(text.contains("[C]"), "confirmation lists detached tanker C as left behind")
	_expect(not text.contains("[W]"), "confirmation does not list W before the industrial sector exists")
	_expect(text.contains("Diesel cost"), "confirmation reports departure diesel cost")
	_expect(text.contains("Uncollected POI supplies"), "confirmation warns POI supplies are abandoned")

	_expect(scene.cancel_sector_departure(), "cancel command is accepted")
	_expect(not scene.is_departure_confirmation_open(), "cancel closes departure confirmation")
	_expect(scene.lifecycle.run_state.sector_index == 0, "cancel keeps current sector")
	_expect(scene.rail.speed <= 0.05, "cancel leaves train hard-braked")
	scene._process(1.0 / 60.0)
	_expect(scene.lifecycle.run_state.sector_index == 0, "cancelled train does not auto-depart on next frame")

	scene.rail.current_segment = def.exit_segment
	scene.rail.distance = def.exit_distance + 8.0
	scene.rail.direction = 1
	scene.rail.speed = 25.0
	scene._process(1.0 / 60.0)
	_expect(scene.is_departure_confirmation_open(), "second forward exit opens confirmation again")
	_expect(scene.confirm_sector_departure(), "confirm command transitions to next sector")
	_expect(scene.lifecycle.run_state.sector_index == 1, "confirm advances to Sector 1")
	_expect(not scene.is_departure_confirmation_open(), "confirm closes departure confirmation")

	scene.queue_free()


func _step_crew_until_idle(crew: CrewSimulation, max_frames: int) -> void:
	for _i in range(max_frames):
		crew.step(1.0 / 60.0)
		var state := crew.get_survivor_state("marta")
		if str(state.get("task_status", "")) == CrewSimulation.STATUS_COMPLETED \
				or str(state.get("task_status", "")) == CrewSimulation.STATUS_IDLE:
			return


func _prepare_scene_for_departure(scene: Node) -> void:
	if scene.has_method("get_vertical_slice_state") and scene.scenario != null:
		scene.scenario.execute_scenario_interaction("clear_obstruction", "opening_obstruction", "olek")
		scene.scenario.execute_scenario_interaction("repair_onboard_fault", "locomotive_fault", "marta")
	scene.train_resources.set_amount("diesel", 24.0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 6B sector clarity acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 6B sector clarity acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
