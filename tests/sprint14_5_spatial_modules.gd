extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const SectorBlueprint := preload("res://scripts/worldgen/sector_blueprint.gd")
const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenProceduralSpatialEmbedding := preload("res://scripts/worldgen/worldgen_procedural_spatial_embedding.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

const ROLE_ABANDONED_TRACK := "ABANDONED_TRACK"
const STATUS_DISPLAY_ONLY := "display_only"

var _failures: int = 0


func _init() -> void:
	print("\n--- SPRINT 14.5: SPATIAL MODULE RECONSTRUCTION TESTS ---")
	_composed_module_edges_reconstruct()
	_skipped_headshunt_is_not_embedded()
	_finish()


func _composed_module_edges_reconstruct() -> void:
	print("\n[TEST] Composed Semantic Module Edges Reconstruct")
	var generator := WorldgenSemanticGenerator.new()
	var scenarios := [
		{
			"name": "rural_loop_storage",
			"method": "_make_rural_through_data",
			"decisions": {
				"archetype": WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
				"wayside_stop": false,
				"modules": [WorldgenSemanticGenerator.MODULE_PASSING_LOOP, WorldgenSemanticGenerator.MODULE_STORAGE_SIDING],
			},
		},
		{
			"name": "village_goods_storage_abandoned",
			"method": "_make_village_passing_station_data",
			"decisions": {
				"archetype": WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
				"platform_track": WorldgenSemanticGenerator.TRACK_STATION_MAIN,
				"road_access": false,
				"modules": [
					WorldgenSemanticGenerator.MODULE_SHORT_GOODS_SIDING,
					WorldgenSemanticGenerator.MODULE_STORAGE_SIDING,
					WorldgenSemanticGenerator.MODULE_ABANDONED_STUB,
				],
			},
		},
		{
			"name": "small_town_extra_spur_abandoned",
			"method": "_make_small_town_goods_data",
			"decisions": {
				"archetype": WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
				"platform_track": WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN,
				"road_access": false,
				"modules": [
					WorldgenSemanticGenerator.MODULE_EXTRA_STORAGE,
					WorldgenSemanticGenerator.MODULE_INDUSTRIAL_SPUR,
					WorldgenSemanticGenerator.MODULE_ABANDONED_REMNANT,
				],
			},
		},
		{
			"name": "agricultural_all_modules",
			"method": "_make_agricultural_loading_point_data",
			"decisions": {
				"archetype": WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
				"secondary_coop": false,
				"road_access": false,
				"modules": [
					WorldgenSemanticGenerator.MODULE_HEADSHUNT,
					WorldgenSemanticGenerator.MODULE_STORAGE_SIDING,
					WorldgenSemanticGenerator.MODULE_EXTRA_LOADING,
				],
			},
		},
		{
			"name": "river_valley_storage",
			"method": "_make_river_valley_constrained_data",
			"decisions": {
				"archetype": WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED,
				"platform_track": WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN,
				"road_access": false,
				"modules": [WorldgenSemanticGenerator.MODULE_STORAGE_SIDING],
			},
		},
		{
			"name": "declining_extra_abandoned_storage",
			"method": "_make_declining_abandoned_branch_data",
			"decisions": {
				"archetype": WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
				"platform_track": WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN,
				"closed_factory": false,
				"modules": [WorldgenSemanticGenerator.MODULE_EXTRA_ABANDONED, WorldgenSemanticGenerator.MODULE_ACTIVE_STORAGE],
			},
		},
	]

	for scenario_v in scenarios:
		var scenario := scenario_v as Dictionary
		var decisions := (scenario.get("decisions", {}) as Dictionary).duplicate(true)
		var data: Dictionary = generator.call(str(scenario.get("method", "")), decisions)
		var result := _build_runtime(data, 9500 + int(scenarios.find(scenario_v)))
		if result.is_empty():
			continue
		var blueprint: RefCounted = result.get("blueprint", null)
		var layout := result.get("layout", {}) as Dictionary
		_expect(_all_semantic_edges_mapped(blueprint, layout), "%s maps every semantic edge to runtime geometry" % str(scenario.get("name", "")))
		_expect(_abandoned_edges_are_display_only_and_unrouted(blueprint, layout), "%s keeps abandoned semantic edges display-only and unrouted" % str(scenario.get("name", "")))


func _skipped_headshunt_is_not_embedded() -> void:
	print("\n[TEST] Skipped Agricultural Headshunt Is Not Embedded")
	var generator := WorldgenSemanticGenerator.new()
	var decisions := {
		"archetype": WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
		"secondary_coop": false,
		"road_access": false,
		"modules": [],
	}
	var data: Dictionary = generator.call("_make_agricultural_loading_point_data", decisions)
	var result := _build_runtime(data, 9661)
	if result.is_empty():
		return
	var layout := result.get("layout", {}) as Dictionary
	_expect(not (layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary).has(WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND), "omitted agricultural headshunt has no runtime semantic mapping")
	_expect(not (layout.get("segments", {}) as Dictionary).has(WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND), "omitted agricultural headshunt has no runtime segment")


func _build_runtime(data: Dictionary, seed: int) -> Dictionary:
	var validator := WorldgenSchemaValidator.new()
	var blueprint := SectorBlueprint.from_dictionary(data)
	var validation := validator.validate_blueprint(blueprint)
	_expect(bool(validation.get("valid", false)), "semantic blueprint validates before spatial embedding")
	if not bool(validation.get("valid", false)):
		printerr("Semantic diagnostics: %s" % str(validation.get("diagnostics", [])))
		return {}

	var context := WorldgenGenerationContext.new(WorldgenGenerationRequest.new(
		seed,
		2,
		WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE,
		WorldgenGenerationRequest.DEFAULT_REGION_PACK,
		WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION,
		WorldgenSemanticGenerator.PRODUCTION_GENERATOR_VERSION
	))
	var spatial_result := WorldgenProceduralSpatialEmbedding.new().generate_embedding(blueprint, context)
	_expect(bool(spatial_result.get("success", false)), "spatial embedding succeeds")
	if not bool(spatial_result.get("success", false)):
		printerr("Spatial diagnostics: %s" % str(spatial_result.get("diagnostics", [])))
		return {}

	var reconstruction := WorldgenRuntimeReconstructor.new().reconstruct_runtime_layout(blueprint, spatial_result.get("embedding", {}) as Dictionary, validator)
	_expect(bool(reconstruction.get("valid", false)), "runtime reconstruction succeeds")
	if not bool(reconstruction.get("valid", false)):
		printerr("Reconstruction diagnostics: %s" % str(reconstruction.get("diagnostics", [])))
		return {}

	var layout := reconstruction.get("layout", {}) as Dictionary
	var rail := RailMovement.new()
	var configured := rail.configure_track_layout(layout)
	_expect(bool(configured.get("valid", false)), "RailMovement accepts reconstructed module layout")
	if not bool(configured.get("valid", false)):
		printerr("RailMovement diagnostics: %s" % str(configured.get("diagnostics", [])))
		return {}

	return {
		"blueprint": blueprint,
		"layout": layout,
		"rail": rail,
	}


func _all_semantic_edges_mapped(blueprint: RefCounted, layout: Dictionary) -> bool:
	if blueprint == null:
		return false
	var semantic_map := layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary
	var data: Dictionary = blueprint.to_dictionary()
	for edge_v in ((data.get("rail_graph", {}) as Dictionary).get("edges", []) as Array):
		var edge := edge_v as Dictionary
		var edge_id := str(edge.get("id", ""))
		if edge_id.is_empty() or semantic_map.has(edge_id):
			continue
		printerr("Missing runtime mapping for semantic edge: %s" % edge_id)
		return false
	return true


func _abandoned_edges_are_display_only_and_unrouted(blueprint: RefCounted, layout: Dictionary) -> bool:
	if blueprint == null:
		return false
	var semantic_map := layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary
	var segment_semantics := layout.get("segment_semantics", {}) as Dictionary
	var data: Dictionary = blueprint.to_dictionary()
	for edge_v in ((data.get("rail_graph", {}) as Dictionary).get("edges", []) as Array):
		var edge := edge_v as Dictionary
		if str(edge.get("role", "")) != ROLE_ABANDONED_TRACK:
			continue
		var edge_id := str(edge.get("id", ""))
		for segment_id_v in semantic_map.get(edge_id, []) as Array:
			var segment_id := str(segment_id_v)
			var semantics := segment_semantics.get(segment_id, {}) as Dictionary
			if str(semantics.get("runtime_status", "")) != STATUS_DISPLAY_ONLY:
				printerr("Abandoned segment is not display-only: %s" % segment_id)
				return false
			if _connections_reference_segment(layout.get("next_connections", {}) as Dictionary, segment_id):
				printerr("Next connections route abandoned segment: %s" % segment_id)
				return false
			if _connections_reference_segment(layout.get("previous_connections", {}) as Dictionary, segment_id):
				printerr("Previous connections route abandoned segment: %s" % segment_id)
				return false
	return true


func _connections_reference_segment(connections: Dictionary, segment_id: String) -> bool:
	for raw_key in connections.keys():
		if str(raw_key) == segment_id:
			return true
		var connection := connections[raw_key] as Dictionary
		if str(connection.get("segment", "")) == segment_id:
			return true
		for route_target_v in (connection.get("routes", {}) as Dictionary).values():
			if str(route_target_v) == segment_id:
				return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 14.5 spatial module reconstruction passed")
		quit(0)
	else:
		printerr("\nSprint 14.5 spatial module reconstruction FAILED with %d failure(s)" % _failures)
		quit(1)
