extends SceneTree

# Sprint 7 end-to-end domain acceptance:
# fail departure -> search -> discover -> haul -> deposit -> return crew -> depart.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7 Acceptance Loop Tests ---")
	test_stop_search_haul_return_depart_loop()
	_finish()


func test_stop_search_haul_return_depart_loop() -> void:
	print("Testing full Sprint 7 scavenging loop...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 6.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 0.0,
	})
	var lifecycle := SectorLifecycle.new(12345, crew, broker, resources)
	var sector = lifecycle.current_sector

	_drive_to_exit(rail, sector)
	_expect(not lifecycle.can_depart(), "departure initially blocked by diesel shortage")

	rail.speed = 0.0
	rail.brake_active = true
	_expect(crew.assign_search_poi("nia", "fuel_depot"), "Nia can be assigned to search fuel depot")
	_step_until_task_done(crew, sector, "nia", 20.0)
	var fuel_after_search: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(bool(fuel_after_search.get("searched", false)), "fuel depot becomes searched")
	_expect(float(fuel_after_search.get("available_amount", 0.0)) > 0.0, "diesel is discovered at POI")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), 6.0), "search does not alter train diesel")

	_expect(crew.assign_haul_poi_resource("nia", "fuel_depot"), "Nia can haul discovered diesel")
	_step_until_task_done(crew, sector, "nia", 24.0)
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), 14.0), "deposit increases train diesel")
	_expect(not lifecycle.can_depart(), "outside expedition crew blocks departure after deposit")
	_expect(lifecycle.transition_blocked_reason.contains("Nia"), "crew-blocked departure names Nia")

	_expect(crew.assign_board_nearest("nia"), "Nia can board after deposit")
	_step_until_task_done(crew, sector, "nia", 12.0)
	var nia: Dictionary = crew.get_survivor_state("nia")
	_expect(str(nia.get("spatial_state", "")) == CrewSimulation.SPATIAL_ABOARD, "Nia physically returns aboard")

	_drive_to_exit(rail, sector)
	_expect(lifecycle.request_transition(), "returned crew and sufficient diesel allow departure")
	_expect(lifecycle.run_state.sector_index == 1, "departure enters next sector")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), 4.0), "successful departure consumes diesel")
	_expect(sector.disposed, "departed sector is destroyed/unavailable")


func _step_until_task_done(crew: CrewSimulation, sector, survivor_id: String, max_seconds: float) -> void:
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


func _drive_to_exit(rail: RailMovement, sector) -> void:
	rail.current_segment = sector.definition.exit_segment
	rail.distance = sector.definition.exit_distance + 8.0
	rail.direction = 1
	rail.speed = 25.0


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 7 acceptance loop passed")
		quit(0)
	else:
		printerr("\nSprint 7 acceptance loop FAILED with %d failure(s)" % _failures)
		quit(1)
