extends SceneTree

# Sprint 8B — opening travel/stop/expedition/job response integration.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 8B Opening Problem Tests ---")
	test_obstruction_and_fault_are_physical_crew_interactions()
	test_active_obstruction_stops_forward_train_motion()
	test_job_broker_can_assign_onboard_fault_to_engineer()
	_finish()


func test_obstruction_and_fault_are_physical_crew_interactions() -> void:
	print("Testing obstruction and onboard fault physical interactions...")
	var fixture := _make_fixture()
	var crew: CrewSimulation = fixture["crew"]
	var lifecycle: SectorLifecycle = fixture["lifecycle"]
	var scenario: FirstRunScenario = fixture["scenario"]
	var sector = lifecycle.current_sector

	_expect(crew.has_method("assign_scenario_interaction"), "crew exposes generic scenario interaction task")
	if not crew.has_method("assign_scenario_interaction"):
		return

	var obstruction: Dictionary = scenario.get_interaction_state(FirstRunScenario.OBSTRUCTION_ID)
	_expect(not obstruction.is_empty(), "scenario exposes obstruction interaction state")
	_expect(str(obstruction.get("spatial_state", "")) == CrewSimulation.SPATIAL_YARD, "obstruction is a yard interaction")
	_expect(crew.assign_scenario_interaction(
		"olek",
		str(obstruction.get("action_id", "")),
		str(obstruction.get("id", "")),
		obstruction.get("position", Vector2.ZERO) as Vector2,
		str(obstruction.get("label", "")),
		float(obstruction.get("duration", 0.0))
	), "Olek can be assigned to clear obstruction")
	crew.step(0.1)
	_expect(bool(scenario.get_state().get("obstruction_active", false)), "obstruction does not clear before arrival")
	_step_task_until_done(crew, sector, "olek", 12.0)
	_expect(not bool(scenario.get_state().get("obstruction_active", true)), "obstruction clears after physical interaction")
	_expect(not lifecycle.can_depart(), "outside crew still blocks departure after clearing obstruction")
	_expect(lifecycle.transition_blocked_reason.contains("Olek"), "crew-blocked departure names Olek")
	_expect(crew.assign_board_nearest("olek"), "Olek can board after clearing obstruction")
	_step_task_until_done(crew, sector, "olek", 8.0)
	_expect(not lifecycle.can_depart(), "onboard fault still blocks departure after obstruction clears")
	_expect(lifecycle.transition_blocked_reason.contains("fault"), "blocked departure names onboard fault")

	var fault: Dictionary = scenario.get_interaction_state(FirstRunScenario.ONBOARD_FAULT_ID)
	_expect(not fault.is_empty(), "scenario exposes onboard fault interaction state")
	_expect(str(fault.get("spatial_state", "")) == CrewSimulation.SPATIAL_ABOARD, "fault is an onboard interaction")
	_expect(crew.assign_scenario_interaction(
		"marta",
		str(fault.get("action_id", "")),
		str(fault.get("id", "")),
		fault.get("position", Vector2.ZERO) as Vector2,
		str(fault.get("label", "")),
		float(fault.get("duration", 0.0)),
		{},
		str(fault.get("host_unit", "")),
		fault.get("local_offset", Vector2.ZERO) as Vector2
	), "Marta can be assigned to repair onboard fault inside L")
	crew.step(0.1)
	_expect(bool(scenario.get_state().get("onboard_fault_active", false)), "fault does not clear before onboard work completes")
	_step_task_until_done(crew, sector, "marta", 8.0)
	_expect(not bool(scenario.get_state().get("onboard_fault_active", true)), "fault clears after engineer work")
	_expect(lifecycle.can_depart(), "cleared obstruction, repaired fault, aboard crew and sufficient diesel allow departure")


func test_active_obstruction_stops_forward_train_motion() -> void:
	print("Testing obstruction movement blocker...")
	var fixture := _make_fixture()
	var rail: RailMovement = fixture["rail"]
	var scenario: FirstRunScenario = fixture["scenario"]

	rail.current_segment = RailMovement.SEGMENT_MAIN_EAST
	rail.distance = FirstRunScenario.OBSTRUCTION_DISTANCE + 40.0
	rail.speed = 28.0
	rail.direction = 1
	rail.set_throttle(1.0)
	_expect(scenario.apply_movement_constraints(rail), "active obstruction applies a movement constraint")
	_expect(is_equal_approx(rail.speed, 0.0), "obstruction stops train speed")
	_expect(is_equal_approx(rail.distance, FirstRunScenario.OBSTRUCTION_DISTANCE - FirstRunScenario.OBSTRUCTION_STOP_CLEARANCE), "obstruction clamps train before debris")
	_expect(str(rail.blocked_reason).contains("obstruction"), "movement blocker reports obstruction")

	_expect(scenario.execute_scenario_interaction(FirstRunScenario.ACTION_CLEAR_OBSTRUCTION, FirstRunScenario.OBSTRUCTION_ID, "olek"), "fixture clears obstruction")
	rail.distance = FirstRunScenario.OBSTRUCTION_DISTANCE + 40.0
	rail.speed = 28.0
	_expect(not scenario.apply_movement_constraints(rail), "cleared obstruction no longer blocks forward movement")


func test_job_broker_can_assign_onboard_fault_to_engineer() -> void:
	print("Testing broker assignment for onboard fault...")
	var fixture := _make_fixture()
	var crew: CrewSimulation = fixture["crew"]
	var broker: TaskBroker = fixture["broker"]
	broker.enabled = true

	var assigned := broker.evaluate_and_assign()
	_expect(assigned > 0, "broker assigns a scenario job")
	var marta: Dictionary = crew.get_survivor_state("marta")
	_expect(str(marta.get("task_type", "")) == "scenario_interaction", "broker uses crew scenario interaction task")
	_expect(str((marta.get("task_data", {}) as Dictionary).get("action_id", "")) == "repair_onboard_fault", "broker targets the onboard fault action")


func _make_fixture() -> Dictionary:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 12.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 0.0,
	})
	var lifecycle := SectorLifecycle.new(12345, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)
	return {
		"rail": rail,
		"yard": yard,
		"crew": crew,
		"broker": broker,
		"resources": resources,
		"lifecycle": lifecycle,
		"scenario": scenario,
	}


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
		print("\nSprint 8B opening problem acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 8B opening problem acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
