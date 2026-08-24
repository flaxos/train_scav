extends SceneTree

# Sprint 8D — physical final route branch and workshop persistence.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 8D Physical Route Branch Tests ---")
	test_physical_route_branch_changes_next_sector_state_and_preserves_workshop()
	_finish()


func test_physical_route_branch_changes_next_sector_state_and_preserves_workshop() -> void:
	print("Testing physical route branch decision and next transition...")
	var fixture := _make_online_workshop_fixture()
	var rail: RailMovement = fixture["rail"]
	var lifecycle: SectorLifecycle = fixture["lifecycle"]
	var scenario: FirstRunScenario = fixture["scenario"]
	var resources: TrainResources = fixture["resources"]

	_expect(rail.get_active_consist_ids().has("W"), "fixture has physically recovered W")
	_expect(bool(scenario.get_state().get("workshop_online", false)), "fixture has online workshop")
	_expect(not lifecycle.can_depart(), "industrial departure is blocked until train occupies a route exit branch")
	_expect(lifecycle.transition_blocked_reason.contains("exit branch"), "blocked departure tells player to drive onto a route exit branch")
	_expect(scenario.has_method("get_route_options"), "scenario exposes route intel options")
	if not scenario.has_method("get_route_options"):
		return

	var options: Array[Dictionary] = scenario.get_route_options()
	_expect(options.size() >= 3, "route intel has three branch options")
	_expect(_option_has_exit_segment(options, "direct"), "direct route has a physical exit segment")
	_expect(_option_has_exit_segment(options, "industrial"), "industrial route has a physical exit segment")
	_expect(_option_has_exit_segment(options, "settlement"), "settlement route has a physical exit segment")

	_expect(lifecycle.current_sector.has_method("get_route_exit_states"), "industrial sector exposes route exit states")
	if lifecycle.current_sector.has_method("get_route_exit_states"):
		var exits: Array[Dictionary] = lifecycle.current_sector.get_route_exit_states()
		_expect(exits.size() >= 3, "industrial sector draws at least three exit branches")

	_expect(_set_rail_to_route_exit(rail, lifecycle.current_sector, "industrial"), "fixture positions train on the industrial exit branch")
	_expect(lifecycle.can_depart(), "online workshop plus physical route branch allows industrial departure")
	_expect(str(scenario.get_state().get("selected_route", "")) == "industrial", "scenario records route from the occupied branch")
	_expect(str(lifecycle.run_state.get("next_sector_profile")) == "industrial", "run state stores selected branch profile")
	var diesel_before := resources.get_amount(TrainResources.RESOURCE_DIESEL)
	_expect(lifecycle.request_transition(), "final sector departure succeeds")
	_expect(lifecycle.run_state.sector_index == 2, "final departure enters the next sector")
	_expect(lifecycle.current_sector.rail.active_units.has("W"), "recovered workshop persists in the train after transition")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) < diesel_before, "final departure still consumes diesel")
	_expect(str(lifecycle.current_sector.definition.template_name).contains("Industrial"), "physical branch route alters the next sector template/profile")


func _option_has_exit_segment(options: Array[Dictionary], route_id: String) -> bool:
	for option in options:
		if str(option.get("id", "")) != route_id:
			continue
		return str(option.get("exit_segment", "")) != "" and str(option.get("exit_id", "")) != ""
	return false


func _set_rail_to_route_exit(rail: RailMovement, sector: RefCounted, route_id: String) -> bool:
	if sector == null or sector.definition == null:
		return false
	var raw_exits: Variant = sector.definition.get("route_exits")
	if not raw_exits is Array:
		return false
	var exits: Array = raw_exits as Array
	for exit_state in exits:
		var route: Dictionary = exit_state as Dictionary
		if str(route.get("route_id", route.get("id", ""))) != route_id:
			continue
		rail.current_segment = str(route.get("segment", ""))
		rail.distance = float(route.get("distance", 0.0)) + 8.0
		rail.direction = 1
		rail.speed = 20.0
		return true
	return false


func _make_online_workshop_fixture() -> Dictionary:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 24.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 5.0,
	})
	var lifecycle := SectorLifecycle.new(12345, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)
	scenario.execute_scenario_interaction(FirstRunScenario.ACTION_CLEAR_OBSTRUCTION, FirstRunScenario.OBSTRUCTION_ID, "olek")
	scenario.execute_scenario_interaction(FirstRunScenario.ACTION_REPAIR_ONBOARD_FAULT, FirstRunScenario.ONBOARD_FAULT_ID, "marta")
	_expect(lifecycle.request_transition(), "fixture transitions to industrial sector")

	var sector = lifecycle.current_sector
	var next_rail: RailMovement = sector.rail
	next_rail.set_points_route(RailMovement.POINTS_MAIN)
	next_rail.set_yard_point_route(YardOperations.POINT_P2, RailMovement.POINTS_SIDING)
	next_rail.max_speed = 10.0
	next_rail.acceleration = 24.0
	next_rail.coast_deceleration = 6.0
	next_rail.set_throttle(1.0)
	var elapsed := 0.0
	while elapsed < 140.0 and not next_rail.can_couple_unit("W"):
		next_rail.step(0.1, false)
		elapsed += 0.1
	next_rail.set_throttle(0.0)
	_expect(next_rail.couple_nearest(), "fixture couples W physically")

	var activation: Dictionary = scenario.get_interaction_state(FirstRunScenario.WORKSHOP_ACTIVATION_ID)
	_expect(scenario.execute_scenario_interaction(
		str(activation.get("action_id", "")),
		str(activation.get("id", "")),
		"marta"
	), "fixture activates W")
	return {
		"rail": next_rail,
		"yard": sector.yard,
		"crew": crew,
		"broker": broker,
		"resources": resources,
		"lifecycle": lifecycle,
		"scenario": scenario,
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 8D decision persistence acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 8D decision persistence FAILED with %d failure(s)" % _failures)
		quit(1)
