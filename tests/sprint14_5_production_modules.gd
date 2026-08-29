extends SceneTree

const SectorBlueprint := preload("res://scripts/worldgen/sector_blueprint.gd")
const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenProceduralSpatialEmbedding := preload("res://scripts/worldgen/worldgen_procedural_spatial_embedding.gd")
const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

const STATUS_DISPLAY_ONLY := "display_only"

var _failures: int = 0


func _init() -> void:
	print("\n--- SPRINT 14.5: PRODUCTION MODULE INTEGRATION TESTS ---")
	_small_town_modules_feed_content_generation()
	_declining_active_module_gets_content_without_using_abandoned_track()
	_goods_hazard_targets_existing_active_switch()
	_finish()


func _small_town_modules_feed_content_generation() -> void:
	print("\n[TEST] Small-Town Modules Feed Production Content")
	var layout := _build_layout("_make_small_town_goods_data", {
		"archetype": WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
		"platform_track": WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN,
		"road_access": false,
		"modules": [
			WorldgenSemanticGenerator.MODULE_EXTRA_STORAGE,
			WorldgenSemanticGenerator.MODULE_INDUSTRIAL_SPUR,
			WorldgenSemanticGenerator.MODULE_ABANDONED_REMNANT,
		],
	}, 15101)
	if layout.is_empty():
		return

	var production := WorldgenProductionSectorGenerator.new()
	var pois := production.call("_make_poi_definitions", WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, _make_context(15102), layout) as Array
	var poi_ids := _ids(pois)
	_expect(poi_ids.has("extra_storage_cache"), "extra storage module receives a POI")
	_expect(poi_ids.has("industrial_spur_cache"), "industrial spur module receives a POI")
	_expect(not _has_id_containing(poi_ids, "abandoned"), "abandoned remnant does not receive a POI")

	var stock := production.call("_make_detached_rolling_stock", WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, _make_context(15103), layout) as Dictionary
	var detached := stock.get("detached_consists", []) as Array
	_expect(detached.size() >= 2, "active yard module receives additional physical salvage")
	if detached.size() > 0:
		_expect(str((detached[0] as Dictionary).get("segment", "")) == WorldgenSemanticGenerator.TRACK_GOODS_LOADING, "base goods-loading salvage remains first")
	_expect(_has_detached_on_any(detached, [WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR]), "module salvage is placed on active optional yard track")
	_expect(_detached_targets_active_segments(layout, detached), "all detached salvage targets active segments")


func _declining_active_module_gets_content_without_using_abandoned_track() -> void:
	print("\n[TEST] Declining Branch Content Avoids Abandoned Runtime Track")
	var layout := _build_layout("_make_declining_abandoned_branch_data", {
		"archetype": WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
		"platform_track": WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN,
		"closed_factory": false,
		"modules": [
			WorldgenSemanticGenerator.MODULE_EXTRA_ABANDONED,
			WorldgenSemanticGenerator.MODULE_ACTIVE_STORAGE,
		],
	}, 15111)
	if layout.is_empty():
		return

	var production := WorldgenProductionSectorGenerator.new()
	var pois := production.call("_make_poi_definitions", WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH, _make_context(15112), layout) as Array
	var poi_ids := _ids(pois)
	_expect(poi_ids.has("branch_active_storage_cache"), "active branch storage module receives a POI")
	_expect(not _has_id_containing(poi_ids, "abandoned"), "display-only abandoned branch receives no POI")
	_expect(_layout_has_display_only_segment(layout, WorldgenSemanticGenerator.TRACK_BRANCH_EXTRA_ABANDONED), "extra abandoned branch is display-only in runtime layout")


func _goods_hazard_targets_existing_active_switch() -> void:
	print("\n[TEST] Goods Hazard Targets Existing Active Switch")
	var layout := _build_layout("_make_small_town_goods_data", {
		"archetype": WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
		"platform_track": WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN,
		"road_access": false,
		"modules": [WorldgenSemanticGenerator.MODULE_EXTRA_STORAGE],
	}, 15121)
	if layout.is_empty():
		return

	var production := WorldgenProductionSectorGenerator.new()
	var hazards_and_routes := production.call("_make_hazards_and_routes", WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, _make_context(15122), layout) as Dictionary
	var hazards := hazards_and_routes.get("hazard_definitions", []) as Array
	var goods_hazard := _find_hazard(hazards, "hazard_goods_switch")
	_expect(not goods_hazard.is_empty(), "small-town goods creates a repairable yard-switch hazard")
	if not goods_hazard.is_empty():
		_expect(str(goods_hazard.get("target_id", "")) == "yard_switch", "goods hazard targets the generated yard switch")
	_expect(_hazards_target_active_layout(hazards, layout), "all generated hazards target existing active infrastructure")


func _build_layout(method_name: String, decisions: Dictionary, seed: int) -> Dictionary:
	var semantic := WorldgenSemanticGenerator.new()
	var data := semantic.call(method_name, decisions.duplicate(true)) as Dictionary
	var blueprint := SectorBlueprint.from_dictionary(data)
	var validator := WorldgenSchemaValidator.new()
	var validation := validator.validate_blueprint(blueprint)
	_expect(bool(validation.get("valid", false)), "semantic blueprint validates")
	if not bool(validation.get("valid", false)):
		printerr("Semantic diagnostics: %s" % str(validation.get("diagnostics", [])))
		return {}

	var spatial_result := WorldgenProceduralSpatialEmbedding.new().generate_embedding(blueprint, _make_context(seed))
	_expect(bool(spatial_result.get("success", false)), "spatial embedding succeeds")
	if not bool(spatial_result.get("success", false)):
		printerr("Spatial diagnostics: %s" % str(spatial_result.get("diagnostics", [])))
		return {}

	var reconstruction := WorldgenRuntimeReconstructor.new().reconstruct_runtime_layout(blueprint, spatial_result.get("embedding", {}) as Dictionary, validator)
	_expect(bool(reconstruction.get("valid", false)), "runtime reconstruction succeeds")
	if not bool(reconstruction.get("valid", false)):
		printerr("Reconstruction diagnostics: %s" % str(reconstruction.get("diagnostics", [])))
		return {}
	return reconstruction.get("layout", {}) as Dictionary


func _make_context(seed: int) -> RefCounted:
	return WorldgenGenerationContext.new(WorldgenGenerationRequest.new(
		seed,
		2,
		"industrial",
		WorldgenGenerationRequest.DEFAULT_REGION_PACK,
		WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION,
		WorldgenProductionSectorGenerator.GENERATOR_VERSION
	))


func _ids(items: Array) -> Array[String]:
	var ids: Array[String] = []
	for item_v in items:
		var item := item_v as Dictionary
		ids.append(str(item.get("id", "")))
	return ids


func _has_id_containing(ids: Array[String], fragment: String) -> bool:
	for id in ids:
		if id.contains(fragment):
			return true
	return false


func _has_detached_on_any(detached: Array, segment_ids: Array[String]) -> bool:
	for raw_consist in detached:
		var consist := raw_consist as Dictionary
		if segment_ids.has(str(consist.get("segment", ""))):
			return true
	return false


func _detached_targets_active_segments(layout: Dictionary, detached: Array) -> bool:
	for raw_consist in detached:
		var consist := raw_consist as Dictionary
		var segment_id := str(consist.get("segment", ""))
		if not _layout_has_active_segment(layout, segment_id):
			printerr("Detached consist targets inactive segment: %s" % segment_id)
			return false
	return true


func _find_hazard(hazards: Array, hazard_id: String) -> Dictionary:
	for raw_hazard in hazards:
		var hazard := raw_hazard as Dictionary
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _hazards_target_active_layout(hazards: Array, layout: Dictionary) -> bool:
	var points := layout.get("points", {}) as Dictionary
	for raw_hazard in hazards:
		var hazard := raw_hazard as Dictionary
		var hazard_type := str(hazard.get("type", ""))
		var target_id := str(hazard.get("target_id", ""))
		if hazard_type in ["point", "turnout", "switch"]:
			if not points.has(target_id):
				printerr("Hazard targets missing point: %s" % target_id)
				return false
		elif hazard_type in ["track", "segment", "bridge"]:
			if not _layout_has_active_segment(layout, target_id):
				printerr("Hazard targets inactive segment: %s" % target_id)
				return false
	return true


func _layout_has_active_segment(layout: Dictionary, segment_id: String) -> bool:
	var segments := layout.get("segments", {}) as Dictionary
	if not segments.has(segment_id):
		return false
	var semantics := (layout.get("segment_semantics", {}) as Dictionary).get(segment_id, {}) as Dictionary
	return str(semantics.get("runtime_status", "active")) != STATUS_DISPLAY_ONLY


func _layout_has_display_only_segment(layout: Dictionary, segment_id: String) -> bool:
	var semantics := (layout.get("segment_semantics", {}) as Dictionary).get(segment_id, {}) as Dictionary
	return str(semantics.get("runtime_status", "active")) == STATUS_DISPLAY_ONLY


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 14.5 production module integration passed")
		quit(0)
	else:
		printerr("\nSprint 14.5 production module integration FAILED with %d failure(s)" % _failures)
		quit(1)
