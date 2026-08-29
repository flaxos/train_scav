extends SceneTree

const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Lifecycle Persistence Tests ---")
	_recovered_generated_wagon_type_persists_to_next_sector()
	_unrecovered_generated_wagon_is_discarded_with_old_sector()
	_finish()


func _recovered_generated_wagon_type_persists_to_next_sector() -> void:
	var seed := _find_seed_with_goods_sector_two(9000, 1600)
	_expect(seed >= 0, "known seed can produce sector 2 small_town_goods")
	if seed < 0:
		return

	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 80.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 5.0,
	})
	var lifecycle := SectorLifecycle.new(seed, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)

	scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	_cross_forward_exit(lifecycle.current_sector)
	_expect(lifecycle.request_transition(), "fixture leaves authored sector 0")

	var sector1 = lifecycle.current_sector
	if not sector1.rail.active_units.has("W"):
		sector1.rail.active_units.append("W")
	if sector1.rail.has_method("set_unit_type"):
		sector1.rail.set_unit_type("W", "workshop_car")
	scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	_cross_route_exit(sector1, "industrial")
	_expect(lifecycle.request_transition(), "fixture enters procedural goods sector")

	var goods_sector = lifecycle.current_sector
	_expect(str(goods_sector.definition.archetype_id) == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, "sector 2 is generated goods")
	var detached := goods_sector.definition.detached_consists as Array
	_expect(detached.size() >= 1, "goods sector contains detached salvage")
	if detached.is_empty():
		return
	var target_unit := str((detached[0] as Dictionary).get("units", [])[0])
	var type_id := str(goods_sector.definition.rolling_stock_units.get(target_unit, ""))
	_expect(type_id != "", "goods sector definition records generated unit type")
	_expect(not goods_sector.rail.get_active_consist_ids().has(target_unit), "generated wagon is not owned before coupling")

	_apply_route_preset(goods_sector.rail, _find_route_preset(goods_sector.definition.runtime_layout, "goods_loading"))
	var active: Array[String] = ["L"]
	goods_sector.rail.active_units = active
	goods_sector.rail.current_segment = goods_sector.definition.entry_segment
	goods_sector.rail.distance = goods_sector.definition.entry_distance
	goods_sector.rail.direction = 1
	goods_sector.rail.speed = 12.0
	goods_sector.rail.throttle = 1.0
	goods_sector.rail.max_speed = 12.0
	_step_until_can_couple(goods_sector.rail, target_unit, 140.0)
	goods_sector.rail.speed = 0.0
	goods_sector.rail.throttle = 0.0
	_expect(goods_sector.rail.can_couple_unit(target_unit), "generated wagon can be reached for coupling")
	_expect(goods_sector.rail.couple_nearest(), "generated wagon is recovered through physical coupling")
	_expect(goods_sector.rail.get_active_consist_ids().has(target_unit), "recovered wagon is now part of persistent train")
	_expect(str(goods_sector.rail.get_unit_type_id(target_unit)) == type_id, "recovered wagon has expected type before transition")
	var expected_consist_order: Array[String] = goods_sector.rail.active_units.duplicate()

	_cross_forward_exit(goods_sector)
	_expect(lifecycle.request_transition(), "fixture departs procedural goods sector")
	var next_sector = lifecycle.current_sector
	_expect(next_sector.rail.get_active_consist_ids().has(target_unit), "recovered generated wagon ID persists into next sector")
	_expect(str(next_sector.rail.get_unit_type_id(target_unit)) == type_id, "recovered generated wagon type persists into next sector")
	_expect(str(next_sector.rail.get_unit_capability_summary(target_unit)) != "", "recovered generated wagon capability remains inspectable after transition")
	_expect(str(next_sector.rail.active_units) == str(expected_consist_order), "recovered consist order persists exactly into next sector")


func _unrecovered_generated_wagon_is_discarded_with_old_sector() -> void:
	var seed := _find_seed_with_goods_sector_two(9100, 1600)
	_expect(seed >= 0, "known seed can produce second goods sector for discard proof")
	if seed < 0:
		return

	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: 80.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 5.0,
	})
	var lifecycle := SectorLifecycle.new(seed, crew, broker, resources)
	var scenario := FirstRunScenario.new()
	scenario.attach(lifecycle, crew, broker)
	lifecycle.set_scenario_coordinator(scenario)

	scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	_cross_forward_exit(lifecycle.current_sector)
	_expect(lifecycle.request_transition(), "fixture leaves authored sector 0 for discard proof")

	var sector1 = lifecycle.current_sector
	if not sector1.rail.active_units.has("W"):
		sector1.rail.active_units.append("W")
	if sector1.rail.has_method("set_unit_type"):
		sector1.rail.set_unit_type("W", "workshop_car")
	scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	_cross_route_exit(sector1, "industrial")
	_expect(lifecycle.request_transition(), "fixture enters procedural goods sector for discard proof")

	var goods_sector = lifecycle.current_sector
	var detached := goods_sector.definition.detached_consists as Array
	_expect(detached.size() >= 1, "discard fixture has generated detached salvage")
	if detached.is_empty():
		return
	var target_unit := str((detached[0] as Dictionary).get("units", [])[0])
	_expect(not goods_sector.rail.get_active_consist_ids().has(target_unit), "unrecovered generated wagon starts outside active train")

	_cross_forward_exit(goods_sector)
	_expect(lifecycle.request_transition(), "fixture departs without recovering generated wagon")
	var next_sector = lifecycle.current_sector
	_expect(not next_sector.rail.get_active_consist_ids().has(target_unit), "unrecovered generated wagon is not added to active train")
	_expect(not _detached_consists_include(next_sector.rail.detached_consists as Array, target_unit), "unrecovered generated wagon is not carried as detached stock")
	_expect(not (next_sector.rail.get_unit_type_map() as Dictionary).has(target_unit), "unrecovered generated wagon type metadata is discarded")


func _find_seed_with_goods_sector_two(seed_start: int, count: int) -> int:
	for seed in range(seed_start, seed_start + count):
		var result := WorldgenProductionSectorGenerator.new().generate_sector(seed, 2, "industrial")
		if bool(result.get("success", false)) and str(result.get("archetype_id", "")) == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			return seed
	return -1


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


func _apply_route_preset(rail: RefCounted, preset: Dictionary) -> void:
	for point_id in (preset.get("routes", {}) as Dictionary).keys():
		rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id]))


func _find_route_preset(layout: Dictionary, preset_id: String) -> Dictionary:
	for preset in layout.get("route_presets", []) as Array:
		var candidate := preset as Dictionary
		if str(candidate.get("id", "")) == preset_id:
			return candidate
	return {}


func _detached_consists_include(detached_consists: Array, unit_id: String) -> bool:
	for raw_consist in detached_consists:
		var consist := raw_consist as Dictionary
		for raw_unit in consist.get("units", []) as Array:
			if str(raw_unit) == unit_id:
				return true
	return false


func _step_until_can_couple(rail: RefCounted, target_unit: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and not rail.can_couple_unit(target_unit):
		rail.step(0.1, false)
		elapsed += 0.1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 lifecycle persistence acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 lifecycle persistence FAILED with %d failure(s)" % _failures)
		quit(1)
