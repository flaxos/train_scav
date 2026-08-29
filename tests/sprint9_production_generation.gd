extends SceneTree

const GENERATOR_PATH := "res://scripts/worldgen/worldgen_production_sector_generator.gd"
const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const CONTEXT_PATH := "res://scripts/worldgen/worldgen_generation_context.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const TrainResources := preload("res://scripts/train/train_resources.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")

const GENERATOR_VERSION := "9_production_procedural_sectors_v1"
const SUPPORTED_ARCHETYPES := {
	"rural_through": true,
	"village_passing_station": true,
	"small_town_goods": true,
	"agricultural_loading_point": true,
	"river_valley_constrained": true,
	"declining_abandoned_branch": true,
}

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9 Production Generation Tests ---")
	_required_files_exist()
	_same_seed_reproduces_complete_generated_sector()
	_known_sample_produces_supported_archetypes()
	_generated_sector_sweep_is_valid_and_configurable()
	_all_supported_archetypes_include_departure_diesel()
	_decoration_stream_consumption_does_not_change_generated_sector()
	_generated_goods_sector_reuses_existing_physical_coupling()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(GENERATOR_PATH), "production sector generator exists")
	_expect(ResourceLoader.exists(REQUEST_PATH), "generation request exists")
	_expect(ResourceLoader.exists(CONTEXT_PATH), "generation context exists")
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "semantic validator exists")
	_expect(ResourceLoader.exists(RAIL_PATH), "RailMovement exists")
	_expect(ResourceLoader.exists(CANONICAL_PATH), "canonical helper exists")


func _same_seed_reproduces_complete_generated_sector() -> void:
	var first := _generate(8123, 2, "industrial")
	var second := _generate(8123, 2, "industrial")
	if first.is_empty() or second.is_empty():
		return

	_expect(str(first.get("archetype_id", "")) == str(second.get("archetype_id", "")), "same request chooses identical archetype")
	_expect(str(first.get("blueprint_hash", "")) == str(second.get("blueprint_hash", "")), "same request keeps blueprint hash stable")
	_expect(str(first.get("generation_trace_hash", "")) == str(second.get("generation_trace_hash", "")), "same request keeps trace hash stable")
	_expect(str(first.get("spatial_embedding_hash", "")) == str(second.get("spatial_embedding_hash", "")), "same request keeps spatial embedding hash stable")
	_expect(str(first.get("runtime_topology_hash", "")) == str(second.get("runtime_topology_hash", "")), "same request keeps runtime topology hash stable")
	_expect(str(first.get("poi_signature", "")) == str(second.get("poi_signature", "")), "same request keeps generated POI signature stable")
	_expect(str(first.get("rolling_stock_signature", "")) == str(second.get("rolling_stock_signature", "")), "same request keeps generated rolling-stock signature stable")

	var definition: RefCounted = first.get("sector_definition", null)
	_expect(definition != null, "generated result exposes a SectorDefinition")
	if definition != null:
		_expect(str(definition.source_type) == "PROCEDURAL", "generated definition is marked PROCEDURAL")
		_expect(str(definition.archetype_id) == str(first.get("archetype_id", "")), "definition records generated archetype")
		_expect(not (definition.runtime_layout as Dictionary).is_empty(), "definition carries runtime layout for SectorInstance")


func _known_sample_produces_supported_archetypes() -> void:
	var seen: Dictionary = {}
	for index in range(2, 242):
		var result := _generate(44001, index, "forward")
		if result.is_empty():
			continue
		seen[str(result.get("archetype_id", ""))] = true

	for archetype_id in SUPPORTED_ARCHETYPES.keys():
		_expect(seen.has(archetype_id), "known production sample includes %s" % archetype_id)


func _generated_sector_sweep_is_valid_and_configurable() -> void:
	for offset in range(120):
		var sector_index := 2 + offset
		var result := _generate(52000 + offset, sector_index, "settlement")
		_expect(not result.is_empty(), "generated sector %d succeeds" % sector_index)
		if result.is_empty():
			continue
		_expect(SUPPORTED_ARCHETYPES.has(str(result.get("archetype_id", ""))), "generated sector %d uses supported archetype" % sector_index)
		_expect(_configure_and_drive_to_exit(result), "generated sector %d configures RailMovement and has active entry-to-exit movement" % sector_index)


func _all_supported_archetypes_include_departure_diesel() -> void:
	for archetype_id in SUPPORTED_ARCHETYPES.keys():
		var result := _find_archetype(archetype_id, 9000, 2000)
		_expect(not result.is_empty(), "known sample can generate %s" % archetype_id)
		if result.is_empty():
			continue
		_expect(_has_departure_diesel_poi(result), "%s generated content includes enough obtainable diesel for departure" % archetype_id)


func _decoration_stream_consumption_does_not_change_generated_sector() -> void:
	var baseline := _generate(9001, 7, "direct", false)
	var preconsumed := _generate(9001, 7, "direct", true)
	if baseline.is_empty() or preconsumed.is_empty():
		return

	for key in [
		"archetype_id",
		"blueprint_hash",
		"generation_trace_hash",
		"spatial_embedding_hash",
		"runtime_topology_hash",
		"poi_signature",
		"rolling_stock_signature",
	]:
		_expect(str(baseline.get(key, "")) == str(preconsumed.get(key, "")), "decoration pre-consumption does not alter %s" % key)


func _generated_goods_sector_reuses_existing_physical_coupling() -> void:
	var goods := _find_archetype("small_town_goods", 7000, 500)
	_expect(not goods.is_empty(), "known sample can generate small_town_goods")
	if goods.is_empty():
		return

	var definition: RefCounted = goods.get("sector_definition", null)
	_expect(definition != null, "goods result exposes generated SectorDefinition")
	if definition == null:
		return
	_expect((definition.detached_consists as Array).size() >= 1, "generated goods sector places existing rolling stock on a freight track")
	var detached := (definition.detached_consists as Array)[0] as Dictionary
	var units: Array = detached.get("units", [])
	_expect(not units.is_empty(), "generated goods detached consist names a unit")
	if units.is_empty():
		return
	var target_unit := str(units[0])
	var unit_types := definition.rolling_stock_units as Dictionary
	var target_type := str(unit_types.get(target_unit, ""))
	_expect(target_unit.begins_with("sector_"), "generated salvage unit uses deterministic sector-scoped identity")
	_expect(RollingStockCatalog.get_salvage_type_ids().has(target_type), "generated salvage unit records an allowed explicit wagon type")

	var main_result := _make_configured_rail(goods)
	if main_result.is_empty():
		return
	var main_rail: RefCounted = main_result.get("rail", null)
	var layout := main_result.get("layout", {}) as Dictionary
	_apply_route_preset(main_rail, _find_route_preset(layout, "main"))
	_prepare_single_loco(main_rail, layout)
	main_rail.detached_consists = definition.detached_consists.duplicate(true)
	_drive_until_exit(main_rail, layout, 26.0)
	_expect(str(main_rail.current_segment) == str(layout.get("exit_segment", "")), "goods-sector salvage stock does not block mandatory main traversal")
	_expect(main_rail.get_last_contact().is_empty(), "main traversal does not collide with generated freight stock")

	var yard_result := _make_configured_rail(goods)
	if yard_result.is_empty():
		return
	var yard_rail: RefCounted = yard_result.get("rail", null)
	_apply_route_preset(yard_rail, _find_route_preset(layout, "goods_loading"))
	_prepare_single_loco(yard_rail, layout)
	yard_rail.speed = 12.0
	yard_rail.max_speed = 12.0
	yard_rail.detached_consists = definition.detached_consists.duplicate(true)
	_drive_until_coupling_candidate(yard_rail, target_unit, 120.0)
	_expect(yard_rail.can_couple_unit(target_unit), "locomotive physically reaches generated freight wagon coupler")
	_expect(yard_rail.couple_nearest(), "existing RailMovement coupling recovers generated freight wagon")
	_expect(yard_rail.get_active_consist_ids().has(target_unit), "generated freight wagon becomes owned only by physical coupling")


func _generate(run_seed: int, sector_index: int, route_profile: String, consume_decoration_first: bool = false) -> Dictionary:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if generator == null or request_script == null or context_script == null:
		return {}

	var request: RefCounted = request_script.create(
		run_seed,
		sector_index,
		route_profile,
		"central_eu_v1",
		"central_eu_small_town_station_v1",
		GENERATOR_VERSION
	)
	var context: RefCounted = context_script.create(request)
	if consume_decoration_first:
		var decoration_rng: RefCounted = context.make_rng("decoration")
		for _i in range(500):
			decoration_rng.next_int()

	if not generator.has_method("generate_sector_from_context"):
		_expect(false, "production generator exposes generate_sector_from_context")
		return {}
	var result: Dictionary = generator.generate_sector_from_context(context)
	_expect(bool(result.get("success", false)), "production generation succeeds for seed %d index %d" % [run_seed, sector_index])
	if not bool(result.get("success", false)):
		printerr("Generation diagnostics: %s" % str(result.get("diagnostics", [])))
		return {}
	return result


func _find_archetype(archetype_id: String, seed_start: int, count: int) -> Dictionary:
	for seed in range(seed_start, seed_start + count):
		var result := _generate(seed, 2, "industrial")
		if str(result.get("archetype_id", "")) == archetype_id:
			return result
	return {}


func _has_departure_diesel_poi(result: Dictionary) -> bool:
	var diesel_total := 0.0
	for raw_poi in result.get("poi_definitions", []) as Array:
		var poi := raw_poi as Dictionary
		if str(poi.get("yield_type", "")) != TrainResources.RESOURCE_DIESEL:
			continue
		diesel_total += float(poi.get("yield_amount", 0.0))
	return diesel_total >= TrainResources.DEPARTURE_DIESEL_COST


func _configure_and_drive_to_exit(result: Dictionary) -> bool:
	var configured := _make_configured_rail(result)
	if configured.is_empty():
		return false
	var rail: RefCounted = configured.get("rail", null)
	var layout := configured.get("layout", {}) as Dictionary
	if rail == null:
		return false
	_apply_route_preset(rail, _find_route_preset(layout, "main"))
	_prepare_single_loco(rail, layout)
	_drive_until_exit(rail, layout, 24.0)
	return str(rail.current_segment) == str(layout.get("exit_segment", "")) \
		and float(rail.distance) >= float(layout.get("exit_distance", 0.0))


func _make_configured_rail(result: Dictionary) -> Dictionary:
	var rail_script := load(RAIL_PATH) as Script
	if rail_script == null:
		_expect(false, "RailMovement script loads")
		return {}
	var rail = rail_script.new()
	var layout := result.get("layout", {}) as Dictionary
	var configured: Dictionary = rail.configure_track_layout(layout)
	_expect(bool(configured.get("valid", false)), "generated layout configures RailMovement")
	if not bool(configured.get("valid", false)):
		printerr("Rail diagnostics: %s" % str(configured.get("diagnostics", [])))
		return {}
	if rail.has_method("set_unit_type_map"):
		rail.set_unit_type_map(result.get("rolling_stock_units", {}) as Dictionary)
	return {
		"rail": rail,
		"layout": layout,
	}


func _prepare_single_loco(rail: RefCounted, layout: Dictionary) -> void:
	var active: Array[String] = ["L"]
	var detached: Array[Dictionary] = []
	rail.active_units = active
	rail.detached_consists = detached
	rail.current_segment = str(layout.get("entry_segment", ""))
	rail.distance = float(layout.get("entry_distance", 24.0))
	rail.direction = 1
	rail.speed = 70.0
	rail.throttle = 1.0
	rail.max_speed = 70.0
	rail.acceleration = 0.0
	rail.coast_deceleration = 0.0
	rail.brake_deceleration = 140.0


func _apply_route_preset(rail: RefCounted, preset: Dictionary) -> void:
	if preset.is_empty():
		return
	for point_id in (preset.get("routes", {}) as Dictionary).keys():
		_expect(rail.set_point_route(str(point_id), str((preset.get("routes", {}) as Dictionary)[point_id])), "sets point %s for preset %s" % [str(point_id), str(preset.get("id", ""))])


func _find_route_preset(layout: Dictionary, preset_id: String) -> Dictionary:
	for preset in layout.get("route_presets", []) as Array:
		var preset_dict := preset as Dictionary
		if str(preset_dict.get("id", "")) == preset_id:
			return preset_dict
	return {}


func _drive_until_exit(rail: RefCounted, layout: Dictionary, max_seconds: float) -> void:
	var target_segment := str(layout.get("exit_segment", ""))
	var target_distance := float(layout.get("exit_distance", 0.0))
	var elapsed := 0.0
	while elapsed < max_seconds:
		if str(rail.current_segment) == target_segment and float(rail.distance) >= target_distance:
			return
		rail.step(0.1, false)
		elapsed += 0.1


func _drive_until_coupling_candidate(rail: RefCounted, target_unit: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and not rail.can_couple_unit(target_unit):
		rail.step(0.1, false)
		elapsed += 0.1


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
		_expect(false, "%s exists" % path)
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		_expect(false, "%s loads and can instantiate" % path)
		return null
	return script.new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9 production generation acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9 production generation acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
