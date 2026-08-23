extends SceneTree

# Sprint 7B — physical expedition and search.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7B Expedition / Search Tests ---")
	test_search_task_requires_physical_arrival()
	test_scavenging_skill_affects_search_without_role_gate()
	_finish()


func test_search_task_requires_physical_arrival() -> void:
	print("Testing physical search task...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var sector := SectorInstance.new(SectorDefinition.create_for_index(12345, 0), rail, yard)
	var crew := CrewSimulation.new(rail, yard)

	_expect(crew.has_method("set_scavenging_context"), "crew accepts sector scavenging context")
	_expect(crew.has_method("assign_search_poi"), "crew exposes POI search assignment")
	if not crew.has_method("set_scavenging_context") or not crew.has_method("assign_search_poi"):
		return

	crew.set_scavenging_context(sector.pois, null)
	var fuel_before: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(not bool(fuel_before.get("searched", true)), "fuel starts unsearched before task")
	_expect(crew.assign_search_poi("nia", "fuel_depot"), "Nia can be assigned to search fuel depot")
	var assigned: Dictionary = crew.get_survivor_state("nia")
	_expect(str(assigned.get("task_type", "")) == "search_poi", "assigned task type is search_poi")
	_expect(str(assigned.get("task_status", "")) == CrewSimulation.STATUS_ASSIGNED, "search starts assigned")
	_expect(str(assigned.get("spatial_state", "")) == CrewSimulation.SPATIAL_ABOARD, "Nia starts aboard before expedition movement")

	crew.step(0.1)
	sector.step(0.1)
	var early_fuel: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(not bool(early_fuel.get("searched", true)), "POI is not searched before physical arrival")
	var moving: Dictionary = crew.get_survivor_state("nia")
	_expect(str(moving.get("task_status", "")) == CrewSimulation.STATUS_MOVING, "Nia is physically moving before search")

	_step_until_task_done(crew, sector, "nia", 18.0)
	var done: Dictionary = crew.get_survivor_state("nia")
	var fuel_after: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(str(done.get("task_status", "")) == CrewSimulation.STATUS_COMPLETED, "search task completes")
	_expect(str(done.get("spatial_state", "")) == CrewSimulation.SPATIAL_YARD, "searcher remains physically outside after search")
	_expect(bool(fuel_after.get("searched", false)), "search marks POI searched")
	_expect(str(fuel_after.get("available_type", "")) == "diesel", "search reveals diesel at POI")
	_expect(float(fuel_after.get("available_amount", 0.0)) > 0.0, "search reveals haulable quantity")


func test_scavenging_skill_affects_search_without_role_gate() -> void:
	print("Testing scavenging skill suitability...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var sector := SectorInstance.new(SectorDefinition.create_for_index(12345, 0), rail, yard)
	var crew := CrewSimulation.new(rail, yard)
	if not crew.has_method("set_scavenging_context") or not crew.has_method("assign_search_poi"):
		_expect(false, "crew search methods exist for skill test")
		return

	crew.set_scavenging_context(sector.pois, null)
	_expect(crew.assign_search_poi("nia", "fuel_depot"), "Scavenger Nia can search")
	_expect(crew.assign_search_poi("pavel", "maintenance_shed"), "Generalist Pavel can also search")
	var nia: Dictionary = crew.get_survivor_state("nia")
	var pavel: Dictionary = crew.get_survivor_state("pavel")
	_expect(float(nia.get("interaction_remaining", 0.0)) < float(pavel.get("interaction_remaining", 0.0)), "higher scavenging skill gives shorter search duration")
	_expect(str(pavel.get("task_type", "")) == "search_poi", "generalist is not blocked from scavenging")


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
		print("\nSprint 7B expedition / search acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 7B expedition / search acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
