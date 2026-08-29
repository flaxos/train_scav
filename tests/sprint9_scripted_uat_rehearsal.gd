extends SceneTree

const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")

var _failures: int = 0
var _previous_env_seed: String = ""


func _init() -> void:
	print("\n--- Starting Sprint 9 Scripted UAT Rehearsal ---")
	_previous_env_seed = OS.get_environment(ENV_RUN_SEED)
	var first_goods := await _run_goods_seed_rehearsal(6001)
	var repeat_goods := await _run_goods_seed_rehearsal(6001)
	_compare_repeated_seed(first_goods, repeat_goods)
	var contrast_seed := _find_seed_for_archetype("village_passing_station", 6002, 1000, "industrial")
	_expect(contrast_seed >= 0, "contrast UAT seed reaches village passing station")
	if contrast_seed >= 0:
		var contrast := await _run_to_first_procedural(contrast_seed, "industrial")
		_expect(str(contrast.get("sector2_archetype", "")) == "village_passing_station", "contrast UAT seed reaches village passing station")
		_expect(str(contrast.get("sector2_blueprint", "")) != str(first_goods.get("sector2_blueprint", "")), "contrast seed produces materially different procedural identity")
	_restore_env_seed()
	_finish()


func _run_goods_seed_rehearsal(seed: int) -> Dictionary:
	var result := await _run_to_first_procedural(seed, "industrial")
	_expect(str(result.get("sector2_archetype", "")) == "small_town_goods", "goods UAT seed reaches small_town_goods sector 2")
	var scene: Node = result.get("scene", null)
	if scene == null:
		return result

	var procedural = scene.lifecycle.current_sector
	var detached := procedural.definition.detached_consists as Array
	_expect(detached.size() >= 1, "small_town_goods sector includes detached generated salvage")
	if detached.is_empty():
		_cleanup_scene(scene)
		return result
	var target_unit := str((detached[0] as Dictionary).get("units", [])[0])
	var pre_coupling_consist: Array = scene.rail.get_active_consist_ids()
	_expect(not pre_coupling_consist.has(target_unit), "generated salvage is not owned before coupling")

	_apply_route_preset(scene.rail, _find_route_preset(procedural.definition.runtime_layout, "goods_loading"))
	scene.rail.current_segment = procedural.definition.entry_segment
	scene.rail.distance = procedural.definition.entry_distance
	scene.rail.direction = 1
	scene.rail.speed = 12.0
	scene.rail.throttle = 1.0
	scene.rail.max_speed = 12.0
	_step_until_can_couple(scene.rail, target_unit, 160.0)
	scene.rail.speed = 0.0
	scene.rail.throttle = 0.0
	_expect(scene.rail.can_couple_unit(target_unit), "persisted train can enter generated goods/loading track and reach salvage coupler")
	_expect(scene.rail.couple_nearest(), "generated wagon is recovered through existing physical coupling")
	_expect(scene.rail.get_active_consist_ids().has(target_unit), "generated wagon joins owned persistent consist after coupling")
	_expect(_all_aboard(scene.crew), "crew is aboard before procedural departure")

	var sector2_consist: Array = scene.rail.get_active_consist_ids()
	_cross_forward_exit(procedural)
	_expect(scene.lifecycle.request_transition(), "scripted UAT departs generated sector 2 normally")
	_sync_scene_to_lifecycle(scene)
	var sector3 = scene.lifecycle.current_sector
	_expect(str(sector3.definition.source_type) == SectorDefinition.SOURCE_PROCEDURAL, "sector 3 is another procedural sector")
	_expect(int(sector3.definition.sector_index) == 3, "sector 3 increments sector index")
	_expect(scene.rail.get_active_consist_ids() == sector2_consist, "persistent consist including recovered generated wagon survives into sector 3")
	_expect(_all_aboard(scene.crew), "crew persists aboard into sector 3")
	result["sector3_archetype"] = str(sector3.definition.archetype_id)
	result["sector3_blueprint"] = str(sector3.definition.blueprint_hash)
	result["recovered_unit"] = target_unit
	result["sector3_consist"] = sector2_consist.duplicate(true)

	_cleanup_scene(scene)
	result.erase("scene")
	return result


func _run_to_first_procedural(seed: int, route_id: String) -> Dictionary:
	OS.set_environment(ENV_RUN_SEED, str(seed))
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "normal production Main scene loads for scripted UAT")
	if packed_scene == null:
		return {}
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var visual0: Dictionary = scene.get_sector_visual_state()
	_expect(int(visual0.get("run_seed", 0)) == seed, "fresh run uses known UAT seed")
	_expect(int(visual0.get("sector_index", -1)) == 0, "fresh run starts in sector 0")
	_expect(str(visual0.get("source_type", "")) == SectorDefinition.SOURCE_AUTHORED, "sector 0 is authored")
	_expect(scene.scenario.obstruction_state == FirstRunScenario.STATE_ACTIVE, "authored sector 0 begins with opening obstruction")
	_expect(not scene.lifecycle.can_depart(), "authored sector 0 departure is blocked until opening work is complete")
	_expect(_all_aboard(scene.crew), "fresh survivors start aboard the train")
	var initial_consist: Array = scene.rail.get_active_consist_ids()

	scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 100.0)
	scene.train_resources.set_amount(TrainResources.RESOURCE_FOOD, 12.0)
	scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 5.0)
	scene.scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
	scene.scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	_cross_forward_exit(scene.lifecycle.current_sector)
	_expect(scene.lifecycle.request_transition(), "scripted UAT departs authored sector 0 normally")
	_sync_scene_to_lifecycle(scene)

	var sector1 = scene.lifecycle.current_sector
	_expect(int(sector1.definition.sector_index) == 1, "authored sector 1 follows sector 0")
	_expect(str(sector1.definition.source_type) == SectorDefinition.SOURCE_AUTHORED, "sector 1 is authored")
	_expect(scene.rail.get_active_consist_ids() == initial_consist, "same train consist persists into sector 1")
	_expect(scene.lifecycle.previous_sector.disposed, "departed sector 0 is disposed")

	if not scene.rail.active_units.has("W"):
		scene.rail.active_units.append("W")
	scene.scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	var sector1_consist: Array = scene.rail.get_active_consist_ids()
	_cross_route_exit(sector1, route_id)
	_expect(scene.lifecycle.request_transition(), "scripted UAT departs authored sector 1 through %s route" % route_id)
	_sync_scene_to_lifecycle(scene)

	var procedural = scene.lifecycle.current_sector
	var visual2: Dictionary = scene.get_sector_visual_state()
	_expect(int(procedural.definition.sector_index) == 2, "sector 2 is reached")
	_expect(str(procedural.definition.source_type) == SectorDefinition.SOURCE_PROCEDURAL, "sector 2 is automatically procedural")
	_expect(str(procedural.definition.archetype_id) != "", "sector 2 records generated archetype")
	_expect(str(procedural.definition.blueprint_hash) != "", "sector 2 records blueprint hash")
	_expect(scene.rail.get_active_consist_ids() == sector1_consist, "same locomotive and consist persist into sector 2")
	_expect(_all_aboard(scene.crew), "survivors persist aboard into sector 2")
	_expect(scene.lifecycle.previous_sector.disposed, "authored sector 1 is disposed and cannot be revisited")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "PROCEDURAL"), "debug panel exposes procedural source")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Run:%d" % seed), "debug panel exposes run seed")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Idx:2"), "debug panel exposes sector index 2")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Archetype:"), "debug panel exposes archetype")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Hash:"), "debug panel exposes blueprint hash")

	scene.rail.current_segment = procedural.definition.entry_segment
	scene.rail.distance = maxf(procedural.definition.entry_distance - 4.0, 0.0)
	scene.rail.direction = -1
	scene.rail.speed = 8.0
	_expect(not scene.lifecycle.step(), "reverse movement toward old boundary does not revisit disposed authored sector")
	_expect(int(scene.lifecycle.run_state.sector_index) == 2, "sector index remains 2 after reverse-boundary probe")

	return {
		"scene": scene,
		"seed": seed,
		"route_id": route_id,
		"sector2_archetype": str(procedural.definition.archetype_id),
		"sector2_blueprint": str(procedural.definition.blueprint_hash),
		"sector2_visual_archetype": str(visual2.get("archetype_id", "")),
		"sector2_visual_blueprint": str(visual2.get("blueprint_hash", "")),
	}


func _find_seed_for_archetype(archetype_id: String, seed_start: int, count: int, route_id: String) -> int:
	var generator := WorldgenProductionSectorGenerator.new()
	for seed in range(seed_start, seed_start + count):
		var result: Dictionary = generator.generate_sector(seed, 2, route_id)
		if bool(result.get("success", false)) and str(result.get("archetype_id", "")) == archetype_id:
			return seed
	return -1


func _compare_repeated_seed(first: Dictionary, second: Dictionary) -> void:
	_expect(str(first.get("sector2_archetype", "")) == str(second.get("sector2_archetype", "")), "same seed repeats sector 2 archetype")
	_expect(str(first.get("sector2_blueprint", "")) == str(second.get("sector2_blueprint", "")), "same seed repeats sector 2 blueprint identity")
	_expect(str(first.get("sector3_archetype", "")) == str(second.get("sector3_archetype", "")), "same seed repeats sector 3 archetype")
	_expect(str(first.get("sector3_blueprint", "")) == str(second.get("sector3_blueprint", "")), "same seed repeats sector 3 blueprint identity")


func _sync_scene_to_lifecycle(scene: Node) -> void:
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.train_resources = scene.lifecycle.get_train_resources()
	scene.interior = scene.crew.interior


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


func _step_until_can_couple(rail: RefCounted, target_unit: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and not rail.can_couple_unit(target_unit):
		rail.step(0.1, false)
		elapsed += 0.1


func _all_aboard(crew: RefCounted) -> bool:
	return crew != null and crew.has_method("are_all_survivors_aboard") and crew.are_all_survivors_aboard()


func _lines_contain(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if line.contains(needle):
			return true
	return false


func _cleanup_scene(scene: Node) -> void:
	if scene == null:
		return
	scene.queue_free()


func _restore_env_seed() -> void:
	if _previous_env_seed.is_empty():
		OS.unset_environment(ENV_RUN_SEED)
	else:
		OS.set_environment(ENV_RUN_SEED, _previous_env_seed)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9 scripted UAT rehearsal passed")
		quit(0)
	else:
		printerr("\nSprint 9 scripted UAT rehearsal FAILED with %d failure(s)" % _failures)
		quit(1)
