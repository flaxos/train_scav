extends SceneTree

# Sprint 8C — industrial yard workshop wagon recovery and activation.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 8C Workshop Recovery Tests ---")
	test_workshop_wagon_is_recovered_physically_and_activated_by_crew()
	_finish()


func test_workshop_wagon_is_recovered_physically_and_activated_by_crew() -> void:
	print("Testing physical W recovery and activation...")
	var fixture := _make_industrial_fixture()
	var rail: RailMovement = fixture["rail"]
	var crew: CrewSimulation = fixture["crew"]
	var lifecycle: SectorLifecycle = fixture["lifecycle"]
	var resources: TrainResources = fixture["resources"]
	var scenario: FirstRunScenario = fixture["scenario"]
	var sector = lifecycle.current_sector

	_expect(lifecycle.run_state.sector_index == 1, "fixture enters the industrial sector")
	_expect(not rail.get_active_consist_ids().has("W"), "W is not automatically in the player consist")
	_expect(_detached_has_unit(rail, "W"), "W exists physically in the industrial yard")
	_expect(not scenario.is_workshop_recovered(), "scenario does not treat discovered W as recovered")
	_expect(scenario.get_interaction_state(FirstRunScenario.WORKSHOP_ACTIVATION_ID).is_empty(), "unattached W cannot be activated")

	_expect(_drive_to_workshop_contact(rail), "main train physically contacts W in the yard")
	_expect(rail.can_couple_unit("W"), "W is a valid physical coupling candidate after contact")
	_expect(rail.couple_nearest(), "existing rail coupling physically attaches W")
	_expect(rail.get_active_consist_ids().has("W"), "W enters the actual active consist after coupling")
	_expect(scenario.is_workshop_recovered(), "scenario detects W recovery from physical consist state")

	resources.set_amount(TrainResources.RESOURCE_PARTS, 5.0)
	var activation: Dictionary = scenario.get_interaction_state(FirstRunScenario.WORKSHOP_ACTIVATION_ID)
	_expect(not activation.is_empty(), "attached offline W exposes activation work")
	_expect(crew.assign_scenario_interaction(
		"marta",
		str(activation.get("action_id", "")),
		str(activation.get("id", "")),
		activation.get("position", Vector2.ZERO) as Vector2,
		str(activation.get("label", "")),
		float(activation.get("duration", 0.0))
	), "Marta can be assigned to activate W")
	crew.step(0.1)
	_expect(not bool(scenario.get_state().get("workshop_online", false)), "W does not become online before physical work")
	_step_task_until_done(crew, sector, "marta", 12.0)
	_expect(bool(scenario.get_state().get("workshop_online", false)), "W becomes online after crew activation")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_PARTS), 3.0), "activation consumes the configured parts cost")


func _make_industrial_fixture() -> Dictionary:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 22.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 0.0,
	})
	var lifecycle := SectorLifecycle.new(12345, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)
	scenario.execute_scenario_interaction(FirstRunScenario.ACTION_CLEAR_OBSTRUCTION, FirstRunScenario.OBSTRUCTION_ID, "olek")
	scenario.execute_scenario_interaction(FirstRunScenario.ACTION_REPAIR_ONBOARD_FAULT, FirstRunScenario.ONBOARD_FAULT_ID, "marta")
	_expect(lifecycle.request_transition(), "fixture transitions after opening blockers are resolved")
	return {
		"rail": lifecycle.current_sector.rail,
		"yard": lifecycle.current_sector.yard,
		"crew": crew,
		"broker": broker,
		"resources": resources,
		"lifecycle": lifecycle,
		"scenario": scenario,
	}


func _drive_to_workshop_contact(rail: RailMovement) -> bool:
	rail.set_points_route(RailMovement.POINTS_MAIN)
	rail.set_yard_point_route(YardOperations.POINT_P2, RailMovement.POINTS_SIDING)
	rail.max_speed = 10.0
	rail.acceleration = 24.0
	rail.coast_deceleration = 6.0
	rail.set_throttle(1.0)
	var elapsed := 0.0
	while elapsed < 140.0 and not rail.can_couple_unit("W"):
		rail.step(0.1, false)
		elapsed += 0.1
	rail.set_throttle(0.0)
	return rail.can_couple_unit("W")


func _detached_has_unit(rail: RailMovement, unit_id: String) -> bool:
	for consist in rail.detached_consists:
		var units: Array = consist.get("units", [])
		if units.has(unit_id):
			return true
	return false


func _step_task_until_done(crew: CrewSimulation, sector, survivor_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds:
		var state: Dictionary = crew.get_survivor_state(survivor_id)
		var status := str(state.get("task_status", ""))
		if status != CrewSimulation.STATUS_ASSIGNED \
				and status != CrewSimulation.STATUS_MOVING \
				and status != CrewSimulation.STATUS_INTERACTING:
			return
		crew.step(0.1)
		sector.step(0.1)
		elapsed += 0.1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 8C workshop recovery acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 8C workshop recovery FAILED with %d failure(s)" % _failures)
		quit(1)
