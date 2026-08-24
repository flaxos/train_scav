extends SceneTree

const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9 Production Lifecycle Tests ---")
	_authored_opening_hands_off_to_procedural_sector_two()
	_rural_procedural_sector_with_low_entry_diesel_can_refuel_through_existing_poi_loop()
	await _normal_game_reports_procedural_sector_debug_state()
	_finish()


func _authored_opening_hands_off_to_procedural_sector_two() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 80.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 5.0,
	})
	var lifecycle := SectorLifecycle.new(24680, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)

	var sector0 = lifecycle.current_sector
	_expect(int(sector0.definition.sector_index) == 0, "fresh run starts at authored sector 0")
	_expect(str(sector0.definition.source_type) == "AUTHORED", "sector 0 is marked AUTHORED")
	_expect(str(sector0.definition.template_name) == "Sector A", "sector 0 keeps crafted opening template")
	_expect(_all_aboard(crew), "fresh crew starts aboard")

	crew.needs.set_need("marta", "hunger", 73.0)
	crew.skills.set_skill("marta", "engineering", 88.0)
	var initial_consist: Array[String] = sector0.rail.active_units.duplicate()

	scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	_cross_forward_exit(sector0)
	_expect(lifecycle.request_transition(), "authored sector 0 transitions through normal lifecycle")

	var sector1 = lifecycle.current_sector
	_expect(sector0.disposed, "departed sector 0 is destroyed")
	_expect(int(sector1.definition.sector_index) == 1, "sector 1 follows authored opening")
	_expect(str(sector1.definition.source_type) == "AUTHORED", "sector 1 is marked AUTHORED")
	_expect(str(sector1.definition.template_name) == "Sector B", "sector 1 keeps crafted industrial template")
	_expect(sector1.rail.active_units == initial_consist, "train consist persists into authored sector 1")
	_expect(is_equal_approx(crew.needs.get_need("marta", "hunger"), 73.0), "survivor needs persist into authored sector 1")
	_expect(crew.skills.get_skill("marta", "engineering") == 88.0, "survivor skills persist into authored sector 1")

	# Complete the authored industrial gate without replacing its underlying lifecycle path.
	if not sector1.rail.active_units.has("W"):
		sector1.rail.active_units.append("W")
	scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	var sector1_consist: Array[String] = sector1.rail.active_units.duplicate()
	_cross_route_exit(sector1, "direct")
	_expect(lifecycle.request_transition(), "final authored sector exits through normal route-branch lifecycle")

	var procedural_a = lifecycle.current_sector
	_expect(sector1.disposed, "authored sector 1 is destroyed at procedural handoff")
	_expect(int(procedural_a.definition.sector_index) == 2, "first procedural sector is sector index 2")
	_expect(str(procedural_a.definition.source_type) == "PROCEDURAL", "sector 2 is selected from procedural provider")
	_expect(str(procedural_a.definition.archetype_id) != "", "procedural sector records selected archetype")
	_expect(str(procedural_a.definition.blueprint_hash) != "", "procedural sector records blueprint hash")
	_expect(not (procedural_a.definition.runtime_layout as Dictionary).is_empty(), "procedural SectorDefinition carries runtime layout")
	_expect(not procedural_a.rail.get_runtime_topology_snapshot().is_empty(), "procedural SectorInstance has configured RailMovement")
	_expect(procedural_a.rail.active_units == sector1_consist, "same train consist persists into procedural sector")
	_expect(procedural_a.rail.controlled_power_unit_id == "L", "controlled locomotive authority persists into procedural sector")
	_expect(_all_aboard(crew), "crew remains aboard after authored-to-procedural handoff")
	_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) < 80.0, "normal departure diesel cost is consumed")
	_expect(is_equal_approx(crew.needs.get_need("marta", "hunger"), 73.0), "survivor needs persist into procedural sector")
	_expect(crew.skills.get_skill("marta", "engineering") == 88.0, "survivor skills persist into procedural sector")
	_expect(str(lifecycle.run_state.next_sector_profile) == "direct", "route profile chosen in authored sector is retained for generation identity")

	var previous_procedural = procedural_a
	var procedural_a_consist: Array[String] = procedural_a.rail.active_units.duplicate()
	_cross_forward_exit(procedural_a)
	_expect(lifecycle.request_transition(), "procedural sector transitions to another procedural sector")
	var procedural_b = lifecycle.current_sector
	_expect(previous_procedural.disposed, "old procedural sector is destroyed")
	_expect(procedural_b != previous_procedural, "current sector instance is replaced")
	_expect(int(procedural_b.definition.sector_index) == 3, "second procedural sector increments sector index")
	_expect(str(procedural_b.definition.source_type) == "PROCEDURAL", "sector 3 is also procedural")
	_expect(procedural_b.rail.active_units == procedural_a_consist, "same train consist persists procedural-to-procedural")
	_expect(_all_aboard(crew), "crew remains aboard procedural-to-procedural")
	_expect(lifecycle.previous_sector == previous_procedural and lifecycle.previous_sector.disposed, "previous procedural sector cannot be revisited")
	_expect(lifecycle.run_state.run_journal.size() == 3, "run journal records authored and procedural transitions")


func _normal_game_reports_procedural_sector_debug_state() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal Main scene loads")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	scene.scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scene.scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 80.0)
	_cross_forward_exit(scene.lifecycle.current_sector)
	_expect(scene.lifecycle.request_transition(), "normal game can leave crafted sector 0")
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.interior = scene.crew.interior

	if not scene.rail.active_units.has("W"):
		scene.rail.active_units.append("W")
	scene.scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	_cross_route_exit(scene.lifecycle.current_sector, "direct")
	_expect(scene.lifecycle.request_transition(), "normal game can leave crafted sector 1 into procedural")
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.interior = scene.crew.interior

	var state: Dictionary = scene.get_sector_state()
	_expect(str(state.get("source_type", "")) == "PROCEDURAL", "normal game sector state reports PROCEDURAL source")
	_expect(str(state.get("archetype_id", "")) != "", "normal game sector state reports generated archetype")
	_expect(str(state.get("blueprint_hash", "")) != "", "normal game sector state reports blueprint hash")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "PROCEDURAL"), "normal game debug panel exposes procedural source")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Archetype:"), "normal game debug panel exposes archetype")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Run:"), "normal game debug panel exposes run seed")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Idx:2"), "normal game debug panel exposes sector index")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Hash:"), "normal game debug panel exposes blueprint hash")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Gen:"), "normal game debug panel exposes generator version")

	scene.queue_free()
	await process_frame
	await process_frame


func _rural_procedural_sector_with_low_entry_diesel_can_refuel_through_existing_poi_loop() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 28.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 5.0,
	})
	var lifecycle := SectorLifecycle.new(24680, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)

	scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	_cross_forward_exit(lifecycle.current_sector)
	_expect(lifecycle.request_transition(), "low-diesel fixture leaves authored sector 0")

	var sector1 = lifecycle.current_sector
	if not sector1.rail.active_units.has("W"):
		sector1.rail.active_units.append("W")
	scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	_cross_route_exit(sector1, "direct")
	_expect(lifecycle.request_transition(), "low-diesel fixture enters first procedural sector")

	var procedural = lifecycle.current_sector
	_expect(int(procedural.definition.sector_index) == 2, "low-diesel fixture reaches sector 2")
	_expect(str(procedural.definition.source_type) == "PROCEDURAL", "low-diesel fixture reaches procedural sector")
	_expect(str(procedural.definition.archetype_id) == "rural_through", "known low-diesel fixture reaches rural through sector")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), 8.0), "fixture enters rural sector below departure diesel threshold")
	_expect(not lifecycle.can_depart(), "low-diesel procedural sector cannot depart before scavenging")

	_expect(_collect_generated_sector_resources(lifecycle, crew, resources), "generated rural POI loop supplies enough diesel through search, carry and deposit")
	_cross_forward_exit(procedural)
	_expect(lifecycle.can_depart(), "returned crew and deposited generated diesel allow rural departure")


func _cross_forward_exit(sector: RefCounted) -> void:
	sector.rail.current_segment = sector.definition.exit_segment
	sector.rail.distance = sector.definition.exit_distance + 8.0
	sector.rail.direction = 1
	sector.rail.speed = 25.0


func _cross_route_exit(sector: RefCounted, route_id: String) -> void:
	for route_exit in sector.definition.route_exits:
		var exit := route_exit as Dictionary
		if str(exit.get("route_id", "")) != route_id:
			continue
		sector.rail.current_segment = str(exit.get("segment", ""))
		sector.rail.distance = float(exit.get("distance", 0.0)) + 8.0
		sector.rail.direction = 1
		sector.rail.speed = 25.0
		return
	_cross_forward_exit(sector)


func _all_aboard(crew: RefCounted) -> bool:
	return crew != null and crew.has_method("are_all_survivors_aboard") and crew.are_all_survivors_aboard()


func _collect_generated_sector_resources(lifecycle: RefCounted, crew: RefCounted, resources: TrainResources) -> bool:
	if lifecycle == null or lifecycle.current_sector == null:
		return false
	var sector = lifecycle.current_sector
	var diesel_before := resources.get_amount(TrainResources.RESOURCE_DIESEL)
	for poi_id in sector.pois.get_poi_ids():
		sector.rail.speed = 0.0
		sector.rail.brake_active = true
		if not crew.assign_search_poi("nia", poi_id):
			continue
		_step_until_task_done(crew, sector, "nia", 24.0)
		var after_search: Dictionary = sector.get_poi_state(poi_id)
		_expect(resources.get_amount(TrainResources.RESOURCE_DIESEL) == diesel_before, "generated POI search does not directly grant diesel")
		if float(after_search.get("available_amount", 0.0)) <= 0.0:
			continue
		if not crew.assign_haul_poi_resource("nia", poi_id):
			continue
		_step_until_task_done(crew, sector, "nia", 28.0)
		if resources.can_afford(TrainResources.RESOURCE_DIESEL, TrainResources.DEPARTURE_DIESEL_COST):
			break
	if not _all_aboard(crew):
		sector.rail.speed = 0.0
		sector.rail.brake_active = true
		if crew.assign_board_nearest("nia"):
			_step_until_task_done(crew, sector, "nia", 16.0)
	return _all_aboard(crew) and resources.can_afford(TrainResources.RESOURCE_DIESEL, TrainResources.DEPARTURE_DIESEL_COST)


func _step_until_task_done(crew: RefCounted, sector: RefCounted, survivor_id: String, max_seconds: float) -> void:
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


func _lines_contain(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if line.contains(needle):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9 production lifecycle acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9 production lifecycle acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
