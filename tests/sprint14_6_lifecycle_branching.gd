extends SceneTree

const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const SectorDefinitionProvider := preload("res://scripts/sector/sector_definition_provider.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const RunState := preload("res://scripts/run/run_state.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

var _failures: Array[String] = []

func _init() -> void:
	print("\n--- SPRINT 14.6: SECTOR LIFECYCLE BRANCHING INTEGRATION TESTS ---")
	test_physical_exit_branching()

	if _failures.is_empty():
		print("\n>>> ALL SPRINT 14.6 LIFECYCLE BRANCHING TESTS PASSED <<<\n")
		quit(0)
	else:
		printerr("\n>>> FAILED with %d error(s): <<<" % _failures.size())
		for f in _failures:
			printerr("  - %s" % f)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		printerr("FAIL: %s" % msg)
	else:
		print("  PASS: %s" % msg)


func test_physical_exit_branching() -> void:
	print("\n[TEST] Physical Train Branching Across Different Route Exits")
	var provider := SectorDefinitionProvider.new()

	# Find a seed with 3 exits
	var multi_exit_seed := 0
	var initial_def = null
	for s in range(100):
		var candidate_seed := 7000 + s
		var d := provider.create_definition(candidate_seed, 2, "forward")
		if d != null and d.route_exits.size() >= 3:
			multi_exit_seed = candidate_seed
			initial_def = d
			break

	_expect(initial_def != null, "Found procedural sector with >= 3 distinct physical outbound exits (seed %d)" % multi_exit_seed)
	if initial_def == null:
		return

	print("  Available route exits in seed %d:" % multi_exit_seed)
	for re in initial_def.route_exits:
		print("    • %s (profile: %s, segment: %s, dist: %.1f)" % [
			re.get("label", ""), re.get("profile", ""), re.get("segment", ""), float(re.get("distance", 0.0))
		])

	# Test taking each distinct route exit independently
	for target_exit in initial_def.route_exits:
		var target_route_id := str(target_exit.get("route_id", target_exit.get("id", "")))
		var target_profile := str(target_exit.get("profile", ""))
		var target_segment := str(target_exit.get("segment", ""))
		var target_distance := float(target_exit.get("distance", 0.0))

		print("\n  Simulating run taking route: %s (%s) on segment %s..." % [target_exit.get("label", ""), target_profile, target_segment])

		var run_state := RunState.new()
		run_state.run_seed = multi_exit_seed
		run_state.sector_index = 2

		var resources := TrainResources.new()
		resources.add(TrainResources.RESOURCE_DIESEL, 50.0)

		var crew := CrewSimulation.new()

		var lifecycle := SectorLifecycle.new(multi_exit_seed, crew, null, resources, provider)
		lifecycle.run_state = run_state

		var entered := bool(lifecycle.debug_start_at_sector(2, "forward"))
		_expect(entered, "Successfully entered initial sector")
		_expect(lifecycle.current_sector != null, "Current sector instance is active")

		# Position train on the chosen outbound track segment past the exit distance
		var current_sec: SectorInstance = lifecycle.current_sector
		current_sec.rail.current_segment = target_segment
		current_sec.rail.distance = target_distance + 5.0
		current_sec.rail.direction = 1
		current_sec.rail.speed = 10.0

		_expect(current_sec.is_exit_crossed(), "Train is detected crossing exit boundary for %s" % target_route_id)
		var crossed_exit: Dictionary = current_sec.get_crossed_exit()
		_expect(str(crossed_exit.get("route_id", crossed_exit.get("id", ""))) == target_route_id, "Detected crossed exit matches target route %s" % target_route_id)

		# Trigger transition
		var transitioned := bool(lifecycle.request_transition())
		_expect(transitioned, "Transition to next sector succeeded via route %s" % target_route_id)

		_expect(run_state.sector_index == 3, "Advanced to sector index 3")
		_expect(run_state.route_choice == target_route_id, "run_state.route_choice recorded as '%s' (got '%s')" % [target_route_id, run_state.route_choice])
		_expect(run_state.next_sector_profile == target_profile, "run_state.next_sector_profile recorded as '%s' (got '%s')" % [target_profile, run_state.next_sector_profile])

		var next_sector: SectorInstance = lifecycle.current_sector
		_expect(next_sector != null, "Next sector instance spawned")
		_expect(next_sector != current_sec, "Old sector replaced by new sector instance")
		_expect(next_sector.definition.sector_index == 3, "Next sector definition index is 3")
		_expect(not next_sector.rail.active_units.is_empty(), "Train consist carried over into next sector")
		_expect(crew.get_survivor_ids().size() > 0, "Crew persisted across sector transition")
