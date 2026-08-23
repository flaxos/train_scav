extends SceneTree

# Sprint 6A — Disposable Sector Lifecycle Acceptance Test.
# Verifies persistent train/crew transfer across disposable sector replacements,
# departure safety rules, idempotency, journal tracking, and state isolation.

const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const RunState := preload("res://scripts/run/run_state.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 6A Sector Lifecycle Tests ---")
	test_sector_definition_determinism()
	test_departure_safety_and_transition()
	await test_scene_lifecycle_integration()

	_finish()


func test_sector_definition_determinism() -> void:
	print("Testing SectorDefinition determinism...")
	var def_a1 := SectorDefinition.create_for_index(12345, 0)
	var def_a2 := SectorDefinition.create_for_index(12345, 0)
	_expect(def_a1.sector_id == def_a2.sector_id, "Sector A IDs match for same seed/index")
	_expect(def_a1.template_name == "Sector A", "Sector index 0 uses Sector A template")
	_expect(def_a1.seed_value == 12345, "Sector A seed matches run seed")

	var def_b1 := SectorDefinition.create_for_index(12345, 1)
	var def_b2 := SectorDefinition.create_for_index(12345, 1)
	_expect(def_b1.sector_id == def_b2.sector_id, "Sector B IDs match for same seed/index")
	_expect(def_b1.template_name == "Sector B", "Sector index 1 uses Sector B template")
	_expect(def_b1.sector_id != def_a1.sector_id, "Sector B ID differs from Sector A ID")


func test_departure_safety_and_transition() -> void:
	print("Testing departure safety and transition persistence...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	broker.enabled = true

	var lifecycle := SectorLifecycle.new(9999, crew, broker)
	var sec_a := lifecycle.current_sector

	_expect(lifecycle.run_state.sector_index == 0, "Run starts at sector index 0")
	_expect(sec_a.definition.template_name == "Sector A", "Initial sector is Sector A")

	# Modify survivor needs & skills deliberately to test persistence
	crew.needs.set_need("marta", "hunger", 80.0)
	crew.skills.set_skill("marta", "engineering", 85.0)

	# Place Marta in yard to test departure safety rule
	crew.survivors[0]["spatial_state"] = CrewSimulation.SPATIAL_YARD

	# Drive train to exit boundary
	rail.current_segment = sec_a.definition.exit_segment
	rail.distance = sec_a.definition.exit_distance + 10.0
	rail.direction = 1
	rail.speed = 20.0

	# Stepping lifecycle when survivor is in yard MUST block transition
	var transitioned := lifecycle.step()
	_expect(not transitioned, "Transition is blocked when survivor is in yard")
	_expect(sec_a.disposed == false, "Sector A is NOT disposed when departure is blocked")
	_expect(lifecycle.run_state.sector_index == 0, "Sector index remains 0 when blocked")
	_expect(lifecycle.run_state.run_journal.is_empty(), "Run journal remains empty when blocked")
	_expect(lifecycle.transition_blocked_reason.contains("Marta"), "Blocked reason mentions unboarded survivor Marta")

	# Board Marta back onto carriage L
	crew.survivors[0]["spatial_state"] = CrewSimulation.SPATIAL_ABOARD
	crew.survivors[0]["host_unit"] = "L"

	# Now step lifecycle -> transition MUST succeed
	rail.direction = 1
	rail.speed = 20.0
	transitioned = lifecycle.step()
	_expect(transitioned, "Transition succeeds after all survivors are aboard")

	# Verify Sector A disposal
	_expect(sec_a.disposed == true, "Sector A is disposed after transition")

	# Verify Sector B activation
	var sec_b := lifecycle.current_sector
	_expect(sec_b != sec_a, "Active sector instance replaced")
	_expect(sec_b.definition.template_name == "Sector B", "New active sector is Sector B")
	_expect(lifecycle.run_state.sector_index == 1, "Sector index incremented to 1")
	_expect(lifecycle.run_state.transition_count == 1, "Transition count incremented to 1")

	# Verify persistent train state on Sector B entry track
	_expect(sec_b.rail.current_segment == sec_b.definition.entry_segment, "Train placed on Sector B entry segment")
	_expect(sec_b.rail.distance == sec_b.definition.entry_distance, "Train placed at Sector B entry distance")
	_expect(sec_b.rail.active_units == ["L", "A", "B"], "Consist order ['L', 'A', 'B'] preserved")
	_expect(sec_b.rail.controlled_power_unit_id == "L", "Controlled power unit 'L' preserved")

	# Verify persistent survivor needs, skills, jobs
	var marta_hunger: float = crew.needs.get_need("marta", "hunger")
	_expect(is_equal_approx(marta_hunger, 80.0), "Marta hunger value (80.0) preserved across transition")
	_expect(crew.skills.get_skill("marta", "engineering") == 85.0, "Marta engineering skill (85) preserved across transition")

	# Verify broker toggle preference preserved
	_expect(broker.enabled == true, "Task broker enabled setting preserved across transition")

	# Verify idempotency: staying at entry track does NOT re-trigger transition
	var step_again := lifecycle.step()
	_expect(not step_again, "Idempotent: staying near entry does not trigger another transition")
	_expect(lifecycle.run_state.sector_index == 1, "Sector index stays 1")
	_expect(lifecycle.run_state.transition_count == 1, "Transition count stays 1")

	# Verify run journal entry
	var journal := lifecycle.run_state.run_journal
	_expect(journal.size() == 1, "Exactly one journal entry created")
	_expect(str(journal[0].get("departed_sector_id", "")) == sec_a.definition.sector_id, "Journal records departed sector ID")
	_expect(str(journal[0].get("entered_sector_id", "")) == sec_b.definition.sector_id, "Journal records entered sector ID")
	_expect(journal[0].get("destination_seed", 0) == sec_b.definition.seed_value, "Journal records destination seed")
	_expect(journal[0].get("consist_order", []) == ["L", "A", "B"], "Journal records consist order")


func test_scene_lifecycle_integration() -> void:
	print("Testing Main scene lifecycle integration...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	scene._process(1.0 / 60.0)

	_expect(scene.has_method("get_sector_state"), "Main scene exposes get_sector_state helper")
	var st: Dictionary = scene.get_sector_state()
	_expect(str(st.get("template_name", "")) == "Sector A", "Main scene starts in Sector A")
	_expect(st.get("sector_index", -1) == 0, "Main scene starts at index 0")

	var debug_lines: Array[String] = scene.get_compact_debug_lines()
	_expect(debug_lines.size() <= 10, "Compact debug lines size <= 10 preserved with Sector state")
	_expect(debug_lines[0].contains("Sector:"), "First debug line exposes Sector ID")

	scene.queue_free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 6A sector lifecycle acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 6A sector lifecycle acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
