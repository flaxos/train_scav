extends RefCounted
class_name WorldgenProductionSectorGenerator

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")
const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenGenerationTrace := preload("res://scripts/worldgen/worldgen_generation_trace.gd")
const WorldgenProceduralSpatialEmbedding := preload("res://scripts/worldgen/worldgen_procedural_spatial_embedding.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

const GENERATOR_VERSION := "9_production_procedural_sectors_v1"
const SUPPORTED_ARCHETYPES := [
	WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
	WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
	WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
	WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
	WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED,
	WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
]

const LEGACY_SELECTION_ARCHETYPES := [
	WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
	WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
	WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
]


func generate_sector(
	run_seed: int,
	sector_index: int,
	route_profile: String = WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE,
	region_pack: String = WorldgenGenerationRequest.DEFAULT_REGION_PACK,
	grammar_version: String = WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION
) -> Dictionary:
	var request := WorldgenGenerationRequest.new(
		run_seed,
		sector_index,
		route_profile,
		region_pack,
		grammar_version,
		GENERATOR_VERSION
	)
	var context := WorldgenGenerationContext.new(request)
	return generate_sector_from_context(context)


func generate_sector_from_context(context: RefCounted) -> Dictionary:
	if context == null or not _context_has_required_api(context):
		return _failure("GENERATION_CONTEXT_INVALID", "generation context does not expose required 9F API")
	if not bool(context.is_valid()):
		return _failure_with_diagnostics(context.get_diagnostics())

	var identity: Dictionary = context.get_identity()
	if str(identity.get("generator_version", "")) != GENERATOR_VERSION:
		return _failure(
			"GENERATOR_VERSION_MISMATCH",
			"production sector generator requires generator_version %s" % GENERATOR_VERSION,
			{"expected": GENERATOR_VERSION, "actual": str(identity.get("generator_version", ""))}
		)

	var archetype_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_ARCHETYPE)
	if archetype_rng == null:
		return _failure("ARCHETYPE_RNG_UNAVAILABLE", "archetype RNG stream is unavailable")
	var archetype_id := _select_archetype(archetype_rng)
	var archetype_trace := _make_archetype_trace(context, archetype_id)

	var semantic_result := WorldgenSemanticGenerator.new().generate_blueprint_for_archetype(context, archetype_id, archetype_trace)
	if not bool(semantic_result.get("success", false)):
		return _failure_with_diagnostics(semantic_result.get("diagnostics", []) as Array)
	var blueprint: RefCounted = semantic_result.get("blueprint", null)
	var semantic_trace: RefCounted = semantic_result.get("generation_trace", null)

	var validator := WorldgenSchemaValidator.new()
	var validation: Dictionary = validator.validate_blueprint(blueprint)
	if not bool(validation.get("valid", false)):
		return _failure_with_diagnostics(validation.get("diagnostics", []) as Array)

	var spatial_result := WorldgenProceduralSpatialEmbedding.new().generate_embedding(blueprint, context, semantic_trace)
	if not bool(spatial_result.get("success", false)):
		return _failure_with_diagnostics(spatial_result.get("diagnostics", []) as Array)
	var embedding := spatial_result.get("embedding", {}) as Dictionary
	var final_trace: RefCounted = spatial_result.get("generation_trace", null)

	var reconstruction := WorldgenRuntimeReconstructor.new().reconstruct_runtime_layout(blueprint, embedding, validator)
	if not bool(reconstruction.get("valid", false)):
		return _failure_with_diagnostics(reconstruction.get("diagnostics", []) as Array)
	var layout := reconstruction.get("layout", {}) as Dictionary

	var rail := RailMovement.new()
	var configure_result := rail.configure_track_layout(layout)
	if not bool(configure_result.get("valid", false)):
		return _failure_with_diagnostics(configure_result.get("diagnostics", []) as Array)

	var poi_definitions := _make_poi_definitions(archetype_id, context, layout)
	var rolling_stock := _make_detached_rolling_stock(archetype_id, context, layout)
	var detached_consists := rolling_stock.get("detached_consists", []) as Array
	var rolling_stock_units := rolling_stock.get("rolling_stock_units", {}) as Dictionary
	var canonical := WorldgenCanonical.new()
	var result := {
		"success": true,
		"diagnostics": [],
		"run_seed": int(identity.get("run_seed", 0)),
		"sector_index": int(identity.get("sector_index", 0)),
		"sector_seed": context.get_stream_subseed(WorldgenGenerationContext.STREAM_ARCHETYPE),
		"route_profile": str(identity.get("route_profile", "")),
		"region_pack": str(identity.get("region_pack", "")),
		"grammar_version": str(identity.get("grammar_version", "")),
		"generator_version": GENERATOR_VERSION,
		"archetype_id": archetype_id,
		"blueprint": blueprint,
		"blueprint_hash": str(blueprint.get_canonical_hash()),
		"generation_trace": final_trace,
		"generation_trace_hash": str(final_trace.get_canonical_hash()),
		"embedding": embedding,
		"spatial_embedding_hash": canonical.hash_dictionary(embedding),
		"layout": layout,
		"runtime_topology_hash": canonical.hash_dictionary(rail.get_runtime_topology_snapshot()),
		"poi_definitions": poi_definitions,
		"poi_signature": canonical.hash_dictionary({"pois": poi_definitions}),
		"detached_consists": detached_consists,
		"rolling_stock_units": rolling_stock_units,
		"rolling_stock_signature": canonical.hash_dictionary({
			"detached_consists": detached_consists,
			"rolling_stock_units": rolling_stock_units,
		}),
		"summary": {
			"archetype_id": archetype_id,
			"semantic_decisions": (semantic_result.get("decisions", {}) as Dictionary).duplicate(true),
			"spatial_decisions": (spatial_result.get("decisions", {}) as Dictionary).duplicate(true),
		},
	}
	result["sector_definition"] = SectorDefinition.from_procedural_result(result)
	return result


func _context_has_required_api(context: RefCounted) -> bool:
	return context.has_method("is_valid") \
		and context.has_method("get_diagnostics") \
		and context.has_method("get_identity") \
		and context.has_method("make_rng") \
		and context.has_method("get_stream_subseed") \
		and context.has_method("to_trace_dictionary")


func _select_archetype(archetype_rng: RefCounted) -> String:
	var legacy_index := int(archetype_rng.range_int(0, LEGACY_SELECTION_ARCHETYPES.size() - 1))
	var legacy_archetype := str(LEGACY_SELECTION_ARCHETYPES[legacy_index])
	match legacy_archetype:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			var rural_family_index := int(archetype_rng.range_int(0, 2))
			match rural_family_index:
				0:
					return WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH
				1:
					return WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT
				_:
					return WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			var village_family_index := int(archetype_rng.range_int(0, 1))
			if village_family_index == 1:
				return WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED
			return WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION
		_:
			return WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS


func _make_archetype_trace(context: RefCounted, archetype_id: String) -> RefCounted:
	var trace_data: Dictionary = context.to_trace_dictionary()
	var stage_decisions := (trace_data.get("stage_decisions", []) as Array).duplicate(true)
	stage_decisions.append({
		"stage": "archetype_selection",
		"key": "archetype",
		"value": archetype_id,
		"stream": WorldgenGenerationContext.STREAM_ARCHETYPE,
	})
	trace_data["stage_decisions"] = stage_decisions
	return WorldgenGenerationTrace.new(trace_data)


func _make_poi_definitions(archetype_id: String, context: RefCounted, layout: Dictionary) -> Array[Dictionary]:
	var pois_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_POIS)
	var amount := float(pois_rng.range_int(3, 8))
	var departure_diesel := TrainResources.DEPARTURE_DIESEL_COST
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			return [
				_poi("rural_cache", "Wayside Cache", "Field crate", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_RURAL_MAIN), Vector2(0.0, -90.0)), TrainResources.RESOURCE_DIESEL, departure_diesel),
			]
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			return [
				_poi("station_supplies", "Station Supplies", "Platform store", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_STATION_MAIN), Vector2(0.0, -92.0)), TrainResources.RESOURCE_DIESEL, departure_diesel),
			]
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			return [
				_poi("goods_shed_cache", "Goods Shed Cache", "Freight crates", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_GOODS_LOADING), Vector2(0.0, -70.0)), TrainResources.RESOURCE_PARTS, maxf(amount, 5.0)),
				_poi("goods_yard_fuel_drum", "Yard Fuel Drum", "Fuel drum", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD), Vector2(0.0, -58.0)), TrainResources.RESOURCE_DIESEL, departure_diesel),
			]
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			return [
				_poi("grain_store_cache", "Grain Store Cache", "Food sacks", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_GRAIN_LOADING), Vector2(0.0, -72.0)), TrainResources.RESOURCE_FOOD, maxf(amount, 5.0)),
				_poi("farm_fuel_drum", "Farm Fuel Drum", "Fuel drum", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR), Vector2(0.0, -56.0)), TrainResources.RESOURCE_DIESEL, departure_diesel),
			]
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			return [
				_poi("valley_station_supplies", "Valley Station Supplies", "Platform store", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN), Vector2(0.0, -88.0)), TrainResources.RESOURCE_DIESEL, departure_diesel),
				_poi("bridge_tool_cache", "Bridge Tool Cache", "Tool crate", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN), Vector2(0.0, -62.0)), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0)),
			]
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			return [
				_poi("overgrown_storage_cache", "Overgrown Storage Cache", "Recovered parts", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE), Vector2(0.0, -70.0)), TrainResources.RESOURCE_PARTS, maxf(amount, 5.0)),
				_poi("branch_fuel_drum", "Branch Fuel Drum", "Fuel drum", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN), Vector2(0.0, -86.0)), TrainResources.RESOURCE_DIESEL, departure_diesel),
			]
	return []


func _make_detached_rolling_stock(archetype_id: String, context: RefCounted, _layout: Dictionary) -> Dictionary:
	if archetype_id != WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
		return {
			"detached_consists": [],
			"rolling_stock_units": {},
		}
	var stock_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_ROLLING_STOCK)
	var salvage_types := RollingStockCatalog.get_salvage_type_ids()
	if salvage_types.is_empty():
		return {
			"detached_consists": [],
			"rolling_stock_units": {},
		}
	var type_id := str(salvage_types[int(stock_rng.range_int(0, salvage_types.size() - 1))])
	var identity: Dictionary = context.get_identity()
	var sector_index := int(identity.get("sector_index", 0))
	var unit_id := "sector_%03d_salvage_01" % sector_index
	return {
		"detached_consists": [
			{
				"units": [unit_id],
				"segment": WorldgenSemanticGenerator.TRACK_GOODS_LOADING,
				"distance": 180.0,
			},
		],
		"rolling_stock_units": {
			unit_id: type_id,
		},
	}


func _poi(poi_id: String, name: String, target_name: String, position: Array, resource_type: String, amount: float) -> Dictionary:
	return {
		"id": poi_id,
		"name": name,
		"target_name": target_name,
		"position": position,
		"yield_type": resource_type,
		"yield_amount": amount,
	}


func _segment_midpoint(layout: Dictionary, segment_id: String) -> Array:
	var segments := layout.get("segments", {}) as Dictionary
	var points := segments.get(segment_id, []) as Array
	if points.size() < 2:
		return [0.0, 0.0]
	var start := points[0] as Vector2
	var end := points[points.size() - 1] as Vector2
	var midpoint := start.lerp(end, 0.5)
	return [midpoint.x, midpoint.y]


func _offset_point(point: Array, offset: Vector2) -> Array:
	if point.size() < 2:
		return [offset.x, offset.y]
	return [float(point[0]) + offset.x, float(point[1]) + offset.y]


func _failure(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return _failure_with_diagnostics([_diagnostic(code, message, context)])


func _failure_with_diagnostics(diagnostics: Array) -> Dictionary:
	return {
		"success": false,
		"diagnostics": diagnostics.duplicate(true),
	}


func _diagnostic(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"message": message,
		"context": context.duplicate(true),
	}
