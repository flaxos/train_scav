extends SceneTree

# Sprint 8A — first-session scenario composition.
# The vertical slice should be an authored composition over the existing rail,
# crew, sector and resource systems, not a replacement simulation.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

const SCENARIO_SCRIPT_PATH := "res://scripts/run/first_run_scenario.gd"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 8A Vertical Slice Scenario Tests ---")
	test_first_session_scenario_initialises_opening_sector()
	_finish()


func test_first_session_scenario_initialises_opening_sector() -> void:
	print("Testing first-session scenario setup...")
	_expect(ResourceLoader.exists(SCENARIO_SCRIPT_PATH), "FirstRunScenario script exists")
	if not ResourceLoader.exists(SCENARIO_SCRIPT_PATH):
		return

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
	var scenario = load(SCENARIO_SCRIPT_PATH).new()

	_expect(scenario.has_method("attach"), "scenario exposes attach")
	_expect(lifecycle.has_method("set_scenario_coordinator"), "lifecycle accepts a scenario coordinator")
	if not scenario.has_method("attach") or not lifecycle.has_method("set_scenario_coordinator"):
		return

	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)

	var state: Dictionary = scenario.get_state()
	_expect(str(state.get("phase", "")) == "opening", "scenario starts in the opening sector phase")
	_expect(bool(state.get("obstruction_active", false)), "opening sector has a visible obstruction/problem")
	_expect(bool(state.get("onboard_fault_active", false)), "opening sector has an onboard fault for job response")
	_expect(rail.get_active_consist_ids() == ["L", "A", "B"], "starting train is [L][A][B]")
	_expect(not rail.get_active_consist_ids().has("W"), "workshop wagon is not initially in the player consist")
	_expect(not _detached_has_unit(rail, "W"), "workshop wagon is not sitting in the opening sector")
	_expect(lifecycle.current_sector.get_poi_state("fuel_depot").has("id"), "opening sector still exposes fuel POI")
	_expect(lifecycle.current_sector.get_poi_state("maintenance_shed").has("id"), "opening sector exposes parts POI")
	_expect(not lifecycle.can_depart(), "opening obstruction/fault can block first departure")
	_expect(lifecycle.transition_blocked_reason.contains("obstruction"), "blocked departure names the opening obstruction first")


func _detached_has_unit(rail: RailMovement, unit_id: String) -> bool:
	for consist in rail.detached_consists:
		var units: Array = consist.get("units", [])
		if units.has(unit_id):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 8A vertical slice scenario acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 8A vertical slice scenario acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
