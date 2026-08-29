extends SceneTree

# Sprint 12 — Lifecycle Departure Gating Tests.
# Verifies that SectorLifecycle gates sector exit by evaluating route requirements
# on crossed exits, preserves baseline routes, and rejects invalid train compositions.

const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 12 Departure Gating Tests ---")
	test_sector0_default_departure_passes()
	test_sector1_direct_route_gating()
	test_sector1_industrial_route_gating()
	test_sector1_settlement_route_gating()
	test_procedural_forward_exit_gating()
	_finish()


func _make_test_lifecycle(run_seed: int = 12345) -> SectorLifecycle:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var resources := TrainResources.new()
	resources.set_amount(TrainResources.RESOURCE_DIESEL, 50.0)
	var lifecycle := SectorLifecycle.new(run_seed, crew, null, resources)
	return lifecycle


func test_sector0_default_departure_passes() -> void:
	print("Testing Sector 0 departure with starter consist...")
	var lifecycle := _make_test_lifecycle(12345)
	_expect(lifecycle.can_depart(), "Sector 0 starter train can depart forward exit")
	_expect(lifecycle.transition_blocked_reason == "", "no blocked reason for Sector 0")
	lifecycle.dispose()


func test_sector1_direct_route_gating() -> void:
	print("Testing Sector 1 direct route requirements...")
	var lifecycle := _make_test_lifecycle(12345)

	# Move to Sector 1 (Industrial Yard)
	var ok: bool = lifecycle.request_transition()
	_expect(ok, "transitioned to Sector 1")
	_expect(lifecycle.current_sector.definition.sector_index == 1, "in Sector 1")

	# Align train onto direct exit segment (main_exit)
	var rail: RailMovement = lifecycle.current_sector.rail
	rail.current_segment = RailMovement.SEGMENT_MAIN_EXIT
	rail.distance = 265.0
	rail.speed = 5.0
	rail.direction = 1

	var crossed: Dictionary = lifecycle.current_sector.get_crossed_exit()
	_expect(str(crossed.get("id", "")) == "direct_exit", "crossed direct_exit")

	# Direct route allows mass up to 250t. Starter train is 167t.
	_expect(lifecycle.can_depart(), "starter train satisfies direct route requirements")

	# If train is artificially overloaded > 250t
	rail.active_units = ["L", "A", "B", "C", "C"] # 90 + 35 + 42 + 50 + 50 = 267t
	_expect(not lifecycle.can_depart(), "overloaded train (267t) is blocked on direct route (max 250t)")
	_expect(lifecycle.transition_blocked_reason.contains("exceeds Direct route limit (250.0t max)"), "blocked reason explains mass limit")

	lifecycle.dispose()


func test_sector1_industrial_route_gating() -> void:
	print("Testing Sector 1 industrial route requirements (workshop requirement)...")
	var lifecycle := _make_test_lifecycle(12345)

	# Move to Sector 1
	lifecycle.request_transition()
	var rail: RailMovement = lifecycle.current_sector.rail

	# Align train onto industrial exit segment
	rail.current_segment = RailMovement.SEGMENT_INDUSTRIAL_EXIT
	rail.distance = 225.0
	rail.speed = 5.0
	rail.direction = 1

	var crossed: Dictionary = lifecycle.current_sector.get_crossed_exit()
	_expect(str(crossed.get("id", "")) == "industrial_exit", "crossed industrial_exit")

	# Starter train [L, A, B] does NOT have workshop capability
	rail.active_units = ["L", "A", "B"]
	_expect(not lifecycle.can_depart(), "starter train without workshop cannot depart industrial route")
	_expect(lifecycle.transition_blocked_reason.contains("requires capability 'workshop'"), "rejection reason mentions workshop capability")

	# Couple workshop W
	rail.active_units.append("W")
	_expect(lifecycle.can_depart(), "train with workshop W can depart industrial route")

	lifecycle.dispose()


func test_sector1_settlement_route_gating() -> void:
	print("Testing Sector 1 settlement route requirements (crew accommodation requirement)...")
	var lifecycle := _make_test_lifecycle(12345)

	# Move to Sector 1
	lifecycle.request_transition()
	var rail: RailMovement = lifecycle.current_sector.rail

	# Align train onto settlement exit segment
	rail.current_segment = RailMovement.SEGMENT_SETTLEMENT_EXIT
	rail.distance = 225.0
	rail.speed = 5.0
	rail.direction = 1

	var crossed: Dictionary = lifecycle.current_sector.get_crossed_exit()
	_expect(str(crossed.get("id", "")) == "settlement_exit", "crossed settlement_exit")

	# Train with A [L, A, B] has crew_accommodation
	rail.active_units = ["L", "A", "B"]
	_expect(lifecycle.can_depart(), "train with bunk car A can depart settlement route")

	# Train without A [L, B, C] lacks crew_accommodation
	rail.active_units = ["L", "B", "C"]
	_expect(not lifecycle.can_depart(), "train without bunk car A is blocked on settlement route")
	_expect(lifecycle.transition_blocked_reason.contains("requires capability 'crew_accommodation'"), "rejection reason mentions crew_accommodation")

	lifecycle.dispose()


func test_procedural_forward_exit_gating() -> void:
	print("Testing procedural forward exit gating...")
	var lifecycle := _make_test_lifecycle(6005)

	# Debug start at procedural sector 2 (agricultural_loading_point)
	var start_ok: bool = lifecycle.debug_start_at_sector(2, "industrial")
	_expect(start_ok, "debug started at procedural sector 2")
	_expect(lifecycle.current_sector.definition.is_procedural(), "sector is procedural")

	var rail: RailMovement = lifecycle.current_sector.rail
	var def: SectorDefinition = lifecycle.current_sector.definition
	rail.current_segment = def.exit_segment
	rail.distance = def.exit_distance + 5.0
	rail.speed = 5.0
	rail.direction = 1

	var crossed: Dictionary = lifecycle.current_sector.get_crossed_exit()
	_expect(not crossed.is_empty(), "crossed procedural forward exit")
	_expect(lifecycle.can_depart(), "standard consist can depart procedural forward exit")

	lifecycle.dispose()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12 departure gating acceptance passed")
		quit(0)
	else:
		print("\nSprint 12 departure gating acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
