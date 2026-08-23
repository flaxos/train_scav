extends SceneTree

# Sprint 7D — departure consumes train diesel and cannot strand expedition crew.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7D Departure Resource Tests ---")
	test_departure_requires_and_consumes_diesel()
	test_departure_cannot_strand_expedition_crew()
	test_sector_elapsed_and_survivor_needs_advance_during_stop()
	_finish()


func test_departure_requires_and_consumes_diesel() -> void:
	print("Testing diesel-gated sector departure...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var lifecycle := SectorLifecycle.new(12345, crew, broker)

	_expect(lifecycle.has_method("get_train_resources"), "lifecycle exposes persistent train resources")
	if not lifecycle.has_method("get_train_resources"):
		return
	var resources: TrainResources = lifecycle.get_train_resources()
	resources.set_amount(TrainResources.RESOURCE_DIESEL, 6.0)
	var first_sector = lifecycle.current_sector

	_drive_to_exit(rail, first_sector)
	_expect(not lifecycle.can_depart(), "insufficient diesel blocks can_depart")
	_expect(lifecycle.transition_blocked_reason.contains("diesel"), "blocked reason names diesel")
	_expect(not lifecycle.request_transition(), "insufficient diesel blocks request_transition")
	_expect(lifecycle.run_state.sector_index == 0, "sector index remains 0 when fuel-blocked")
	_expect(not first_sector.disposed, "sector is not disposed when fuel-blocked")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) == 6.0, "blocked departure consumes no diesel")

	resources.add(TrainResources.RESOURCE_DIESEL, 8.0)
	_drive_to_exit(rail, first_sector)
	_expect(lifecycle.can_depart(), "hauled diesel makes departure affordable")
	_expect(lifecycle.request_transition(), "sufficient diesel allows transition")
	_expect(lifecycle.run_state.sector_index == 1, "successful departure advances sector index")
	_expect(first_sector.disposed, "old sector is disposed after successful departure")
	_expect(lifecycle.get_train_resources() == resources, "resource store persists across sectors")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), 4.0), "departure consumes fixed diesel cost")
	_expect(crew.sector_pois == lifecycle.current_sector.pois, "crew scavenging context points at new active sector POIs")


func test_departure_cannot_strand_expedition_crew() -> void:
	print("Testing crew-outside departure block...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var lifecycle := SectorLifecycle.new(54321, crew, broker)
	if not lifecycle.has_method("get_train_resources"):
		_expect(false, "lifecycle exposes persistent train resources")
		return
	var resources: TrainResources = lifecycle.get_train_resources()
	resources.set_amount(TrainResources.RESOURCE_DIESEL, 20.0)

	crew.force_survivor_yard_position("nia", Vector2(300.0, 500.0))
	_drive_to_exit(rail, lifecycle.current_sector)
	_expect(not lifecycle.can_depart(), "crew in yard blocks departure even with enough diesel")
	_expect(lifecycle.transition_blocked_reason.contains("Nia"), "blocked reason names outside survivor")
	_expect(not lifecycle.request_transition(), "request_transition cannot strand outside crew")
	_expect(lifecycle.run_state.sector_index == 0, "sector index remains 0 when crew is outside")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), 20.0), "crew-blocked departure consumes no diesel")


func test_sector_elapsed_and_survivor_needs_advance_during_stop() -> void:
	print("Testing stop time advances sector and needs...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var lifecycle := SectorLifecycle.new(22222, crew, broker)
	var sector = lifecycle.current_sector
	var start_elapsed: float = sector.get_elapsed_time()
	var start_hunger: float = crew.needs.get_need("nia", "hunger")

	sector.step(5.0)
	crew.step(5.0)
	_expect(sector.get_elapsed_time() > start_elapsed, "sector elapsed time advances")
	_expect(crew.needs.get_need("nia", "hunger") != start_hunger, "survivor needs continue changing while stopped")


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
		print("\nSprint 7D departure resource acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 7D departure resource acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
