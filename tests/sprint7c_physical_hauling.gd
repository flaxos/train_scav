extends SceneTree

# Sprint 7C — discovered resources must be physically hauled to train storage.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7C Physical Hauling Tests ---")
	test_discovered_loot_requires_physical_haul_and_deposit()
	_finish()


func test_discovered_loot_requires_physical_haul_and_deposit() -> void:
	print("Testing physical hauling and deposit...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var sector := SectorInstance.new(SectorDefinition.create_for_index(12345, 0), rail, yard)
	var crew := CrewSimulation.new(rail, yard)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 6.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 0.0,
	})

	_expect(crew.has_method("assign_haul_poi_resource"), "crew exposes POI hauling assignment")
	if not crew.has_method("set_scavenging_context") or not crew.has_method("assign_haul_poi_resource"):
		return

	crew.set_scavenging_context(sector.pois, resources)
	_expect(sector.search_poi("fuel_depot"), "fixture searches fuel depot")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) == 6.0, "search does not change train diesel")
	var fuel_after_search: Dictionary = sector.get_poi_state("fuel_depot")
	var discovered_amount := float(fuel_after_search.get("available_amount", 0.0))
	_expect(discovered_amount > 0.0, "fuel depot has discovered diesel to haul")

	crew.force_survivor_yard_position("nia", fuel_after_search.get("position", Vector2.ZERO) as Vector2)
	_expect(crew.assign_haul_poi_resource("nia", "fuel_depot"), "Nia can be assigned to haul discovered fuel")
	var assigned: Dictionary = crew.get_survivor_state("nia")
	_expect(float(assigned.get("cargo_amount", 0.0)) == 0.0, "cargo is not picked up at assignment time")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) == 6.0, "train diesel unchanged at haul assignment")

	_step_until_carrying(crew, sector, "nia", 4.0)
	var carrying: Dictionary = crew.get_survivor_state("nia")
	_expect(str(carrying.get("cargo_type", "")) == TrainResources.RESOURCE_DIESEL, "survivor visibly carries diesel after pickup")
	_expect(float(carrying.get("cargo_amount", 0.0)) == discovered_amount, "survivor carries discovered quantity")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) == 6.0, "train diesel still unchanged while survivor carries cargo")
	var fuel_after_pickup: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(float(fuel_after_pickup.get("available_amount", -1.0)) == 0.0, "POI quantity clears when cargo transfers to survivor")

	_step_until_task_done(crew, sector, "nia", 18.0)
	var done: Dictionary = crew.get_survivor_state("nia")
	_expect(str(done.get("task_status", "")) == CrewSimulation.STATUS_COMPLETED, "haul task completes after return and deposit")
	_expect(float(done.get("cargo_amount", -1.0)) == 0.0, "survivor cargo clears after deposit")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) == 6.0 + discovered_amount, "deposit transfers diesel to train stockpile")


func _step_until_carrying(crew: CrewSimulation, sector: SectorInstance, survivor_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds:
		var state: Dictionary = crew.get_survivor_state(survivor_id)
		if float(state.get("cargo_amount", 0.0)) > 0.0:
			return
		crew.step(0.1)
		sector.step(0.1)
		elapsed += 0.1


func _step_until_task_done(crew: CrewSimulation, sector: SectorInstance, survivor_id: String, max_seconds: float) -> void:
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
		print("\nSprint 7C physical hauling acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 7C physical hauling acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
