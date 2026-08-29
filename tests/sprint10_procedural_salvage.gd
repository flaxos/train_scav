extends SceneTree

const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")
const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CATALOG_PATH := "res://scripts/train/rolling_stock_catalog.gd"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Procedural Salvage Tests ---")
	_generated_goods_salvage_has_explicit_deterministic_type_metadata()
	_known_uat_seed_samples_have_distinct_recoverable_functions()
	_known_goods_sample_produces_multiple_recoverable_functions()
	_generated_salvage_is_not_owned_until_physical_coupling()
	_finish()


func _generated_goods_salvage_has_explicit_deterministic_type_metadata() -> void:
	var first := _find_goods_result(6000, 1200)
	var second := WorldgenProductionSectorGenerator.new().generate_sector(
		int(first.get("run_seed", 0)),
		int(first.get("sector_index", 2)),
		str(first.get("route_profile", "industrial"))
	) if not first.is_empty() else {}
	_expect(not first.is_empty(), "known sample can generate small_town_goods")
	if first.is_empty() or second.is_empty():
		return

	_expect(str(first.get("rolling_stock_signature", "")) == str(second.get("rolling_stock_signature", "")), "same generation identity keeps salvage signature deterministic")
	var unit_types := first.get("rolling_stock_units", {}) as Dictionary
	_expect(not unit_types.is_empty(), "generated goods result includes explicit unit_id -> type_id metadata")
	var detached := first.get("detached_consists", []) as Array
	_expect(detached.size() >= 1, "generated goods sector places detached salvage")
	if detached.is_empty():
		return
	var units := (detached[0] as Dictionary).get("units", []) as Array
	_expect(units.size() == 1, "Sprint 10 goods salvage places one bounded candidate")
	if units.is_empty():
		return
	var unit_id := str(units[0])
	var type_id := str(unit_types.get(unit_id, ""))
	var catalog := _load_catalog()
	_expect(unit_id.begins_with("sector_"), "generated salvage ID is deterministic and not prefix-type encoded")
	_expect(type_id != "", "generated salvage unit has explicit type id")
	if catalog != null:
		_expect(catalog.get_salvage_type_ids().has(type_id), "generated salvage type %s is allowed by catalogue" % type_id)
		_expect(type_id != "workshop_car", "generated workshop cars are excluded without a generic activation path")


func _known_uat_seed_samples_have_distinct_recoverable_functions() -> void:
	var expected := {
		6001: "fuel_tanker",
		6006: "parts_flatbed",
		6061: "boxcar_storage",
	}
	for seed in expected.keys():
		var result := WorldgenProductionSectorGenerator.new().generate_sector(int(seed), 2, "industrial")
		_expect(bool(result.get("success", false)), "UAT seed %d generates successfully" % int(seed))
		_expect(str(result.get("archetype_id", "")) == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, "UAT seed %d reaches small_town_goods" % int(seed))
		var unit_types := result.get("rolling_stock_units", {}) as Dictionary
		_expect(str(unit_types.get("sector_002_salvage_01", "")) == str(expected[seed]), "UAT seed %d produces %s" % [int(seed), str(expected[seed])])
		var detached := result.get("detached_consists", []) as Array
		_expect(detached.size() == 1, "UAT seed %d produces one detached salvage consist" % int(seed))
		if detached.is_empty():
			continue
		var placement := detached[0] as Dictionary
		_expect(str(placement.get("segment", "")) == WorldgenSemanticGenerator.TRACK_GOODS_LOADING, "UAT seed %d places salvage on goods loading track" % int(seed))
		_expect(is_equal_approx(float(placement.get("distance", 0.0)), 180.0), "UAT seed %d keeps deterministic salvage placement distance" % int(seed))


func _known_goods_sample_produces_multiple_recoverable_functions() -> void:
	var seen: Dictionary = {}
	for seed in range(7000, 7800):
		var result := WorldgenProductionSectorGenerator.new().generate_sector(seed, 2, "industrial")
		if not bool(result.get("success", false)):
			continue
		if str(result.get("archetype_id", "")) != WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			continue
		var unit_types := result.get("rolling_stock_units", {}) as Dictionary
		for unit_id in unit_types.keys():
			seen[str(unit_types[unit_id])] = true
		if seen.size() >= 2:
			break

	_expect(seen.has("fuel_tanker"), "known goods sample includes tanker salvage function")
	_expect(seen.has("boxcar_storage"), "known goods sample includes storage salvage function")


func _generated_salvage_is_not_owned_until_physical_coupling() -> void:
	var result := _find_goods_result(8000, 1200)
	_expect(not result.is_empty(), "known sample can generate goods sector for coupling proof")
	if result.is_empty():
		return

	var definition: RefCounted = result.get("sector_definition", null)
	_expect(definition != null, "generated result exposes SectorDefinition")
	if definition == null:
		return
	var detached := definition.detached_consists as Array
	_expect(detached.size() >= 1, "definition has detached salvage")
	if detached.is_empty():
		return
	var target_unit := str((detached[0] as Dictionary).get("units", [])[0])
	var rail := RailMovement.new()
	var configured: Dictionary = rail.configure_track_layout(result.get("layout", {}) as Dictionary)
	_expect(bool(configured.get("valid", false)), "generated layout configures RailMovement")
	if not bool(configured.get("valid", false)):
		return
	if rail.has_method("set_unit_type_map"):
		rail.set_unit_type_map(definition.rolling_stock_units)
	rail.detached_consists = detached.duplicate(true)
	_apply_route_preset(rail, _find_route_preset(result.get("layout", {}) as Dictionary, "goods_loading"))
	var active: Array[String] = ["L"]
	rail.active_units = active
	rail.current_segment = str((result.get("layout", {}) as Dictionary).get("entry_segment", ""))
	rail.distance = float((result.get("layout", {}) as Dictionary).get("entry_distance", 24.0))
	rail.direction = 1
	rail.speed = 12.0
	rail.throttle = 1.0
	rail.max_speed = 12.0

	_expect(not rail.get_active_consist_ids().has(target_unit), "generated salvage starts detached, not owned")
	_step_until_can_couple(rail, target_unit, 140.0)
	rail.speed = 0.0
	rail.throttle = 0.0
	_expect(rail.can_couple_unit(target_unit), "generated salvage is physically reachable")
	_expect(rail.couple_nearest(), "existing physical coupling recovers generated salvage")
	_expect(rail.get_active_consist_ids().has(target_unit), "generated salvage becomes owned only after coupling")


func _find_goods_result(seed_start: int, count: int) -> Dictionary:
	for seed in range(seed_start, seed_start + count):
		var result := WorldgenProductionSectorGenerator.new().generate_sector(seed, 2, "industrial")
		if bool(result.get("success", false)) and str(result.get("archetype_id", "")) == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			return result
	return {}


func _load_catalog() -> RefCounted:
	if not ResourceLoader.exists(CATALOG_PATH):
		_expect(false, "RollingStockCatalog script exists")
		return null
	var script := load(CATALOG_PATH) as Script
	if script == null or not script.can_instantiate():
		_expect(false, "RollingStockCatalog loads")
		return null
	return script.new()


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 procedural salvage acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 procedural salvage FAILED with %d failure(s)" % _failures)
		quit(1)
