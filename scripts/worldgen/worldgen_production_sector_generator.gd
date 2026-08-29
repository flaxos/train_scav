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

const GEOMETRY_PROFILE := {
	"poi_offsets": {
		"rural_cache": Vector2(0.0, -90.0),
		"rural_storage_parts": Vector2(0.0, 68.0),
		"station_supplies": Vector2(0.0, -92.0),
		"station_storage_cache": Vector2(0.0, 64.0),
		"village_goods_cache": Vector2(0.0, -66.0),
		"goods_shed_cache": Vector2(0.0, -70.0),
		"goods_yard_fuel_drum": Vector2(0.0, -58.0),
		"extra_storage_cache": Vector2(0.0, 64.0),
		"industrial_spur_cache": Vector2(0.0, -76.0),
		"grain_store_cache": Vector2(0.0, -72.0),
		"farm_fuel_drum": Vector2(0.0, -56.0),
		"agri_storage_cache": Vector2(0.0, 62.0),
		"extra_loading_food": Vector2(0.0, -64.0),
		"valley_station_supplies": Vector2(0.0, -88.0),
		"bridge_tool_cache": Vector2(0.0, -62.0),
		"valley_storage_cache": Vector2(0.0, 62.0),
		"overgrown_storage_cache": Vector2(0.0, -70.0),
		"branch_fuel_drum": Vector2(0.0, -86.0),
		"branch_active_storage_cache": Vector2(0.0, 64.0),
	},
	"detached_goods_loading_distance": 180.0,
	"detached_module_distance": 150.0,
	"detached_distance_margin_max": 48.0,
	"detached_distance_margin_ratio": 0.25,
}


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
	var archetype_id := _select_archetype(archetype_rng, str(identity.get("route_profile", "")))
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
	var hazards_and_routes := _make_hazards_and_routes(archetype_id, context, layout)
	var hazard_definitions := hazards_and_routes.get("hazard_definitions", []) as Array
	var route_exits := hazards_and_routes.get("route_exits", []) as Array
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
		"hazard_definitions": hazard_definitions,
		"route_exits": route_exits,
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


func _select_archetype(archetype_rng: RefCounted, route_profile: String = "") -> String:
	var norm_profile := route_profile.strip_edges().to_lower()
	if norm_profile == "" or norm_profile == "forward" or norm_profile == "main" or norm_profile == "default" or norm_profile == "industrial":
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

	var roll := int(archetype_rng.range_int(0, 99))
	match norm_profile:
		"industrial_corridor", "industrial_branch", "industry":
			if roll < 65:
				return WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS
			elif roll < 85:
				return WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION
			else:
				return WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH
		"agricultural", "agricultural_branch":
			if roll < 65:
				return WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT
			elif roll < 85:
				return WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION
			else:
				return WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH
		"settlement", "settlement_branch":
			if roll < 60:
				return WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION
			elif roll < 85:
				return WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS
			else:
				return WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED
		"declining", "declining_branch":
			if roll < 65:
				return WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH
			elif roll < 85:
				return WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH
			else:
				return WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED
		"branch", "valley_branch", "ridge_branch":
			if roll < 45:
				return WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED
			elif roll < 75:
				return WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH
			elif roll < 90:
				return WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT
			else:
				return WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH
		_:
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
	var pois: Array[Dictionary] = []
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			pois.append(_poi("rural_cache", "Wayside Cache", "Field crate", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_RURAL_MAIN), _poi_offset("rural_cache")), TrainResources.RESOURCE_DIESEL, departure_diesel))
			_append_poi_on_active_segment(pois, layout, "rural_storage_parts", "Rural Storage Cache", "Storage crates", WorldgenSemanticGenerator.TRACK_RURAL_STORAGE, _poi_offset("rural_storage_parts"), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0))
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			pois.append(_poi("station_supplies", "Station Supplies", "Platform store", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_STATION_MAIN), _poi_offset("station_supplies")), TrainResources.RESOURCE_DIESEL, departure_diesel))
			_append_poi_on_active_segment(pois, layout, "station_storage_cache", "Station Storage Cache", "Stored crates", WorldgenSemanticGenerator.TRACK_STATION_STORAGE, _poi_offset("station_storage_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0))
			_append_poi_on_active_segment(pois, layout, "village_goods_cache", "Village Goods Cache", "Goods shed crates", WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LOADING, _poi_offset("village_goods_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 5.0))
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			pois.append(_poi("goods_shed_cache", "Goods Shed Cache", "Freight crates", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_GOODS_LOADING), _poi_offset("goods_shed_cache")), TrainResources.RESOURCE_PARTS, maxf(amount, 5.0)))
			pois.append(_poi("goods_yard_fuel_drum", "Yard Fuel Drum", "Fuel drum", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD), _poi_offset("goods_yard_fuel_drum")), TrainResources.RESOURCE_DIESEL, departure_diesel))
			_append_poi_on_active_segment(pois, layout, "extra_storage_cache", "Extra Storage Cache", "Storage crates", WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE, _poi_offset("extra_storage_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0))
			_append_poi_on_active_segment(pois, layout, "industrial_spur_cache", "Industrial Spur Cache", "Factory crates", WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR, _poi_offset("industrial_spur_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 5.0))
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			pois.append(_poi("grain_store_cache", "Grain Store Cache", "Food sacks", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_GRAIN_LOADING), _poi_offset("grain_store_cache")), TrainResources.RESOURCE_FOOD, maxf(amount, 5.0)))
			pois.append(_poi("farm_fuel_drum", "Farm Fuel Drum", "Fuel drum", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR), _poi_offset("farm_fuel_drum")), TrainResources.RESOURCE_DIESEL, departure_diesel))
			_append_poi_on_active_segment(pois, layout, "agri_storage_cache", "Agricultural Storage Cache", "Stored parts", WorldgenSemanticGenerator.TRACK_AGRI_STORAGE, _poi_offset("agri_storage_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0))
			_append_poi_on_active_segment(pois, layout, "extra_loading_food", "Extra Loading Cache", "Food sacks", WorldgenSemanticGenerator.TRACK_AGRI_EXTRA_LOADING, _poi_offset("extra_loading_food"), TrainResources.RESOURCE_FOOD, maxf(amount, 4.0))
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			pois.append(_poi("valley_station_supplies", "Valley Station Supplies", "Platform store", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN), _poi_offset("valley_station_supplies")), TrainResources.RESOURCE_DIESEL, departure_diesel))
			pois.append(_poi("bridge_tool_cache", "Bridge Tool Cache", "Tool crate", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN), _poi_offset("bridge_tool_cache")), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0)))
			_append_poi_on_active_segment(pois, layout, "valley_storage_cache", "Valley Storage Cache", "Storage crates", WorldgenSemanticGenerator.TRACK_VALLEY_STORAGE, _poi_offset("valley_storage_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0))
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			pois.append(_poi("overgrown_storage_cache", "Overgrown Storage Cache", "Recovered parts", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE), _poi_offset("overgrown_storage_cache")), TrainResources.RESOURCE_PARTS, maxf(amount, 5.0)))
			pois.append(_poi("branch_fuel_drum", "Branch Fuel Drum", "Fuel drum", _offset_point(_segment_midpoint(layout, WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN), _poi_offset("branch_fuel_drum")), TrainResources.RESOURCE_DIESEL, departure_diesel))
			_append_poi_on_active_segment(pois, layout, "branch_active_storage_cache", "Active Branch Storage Cache", "Usable storage crates", WorldgenSemanticGenerator.TRACK_BRANCH_ACTIVE_STORAGE, _poi_offset("branch_active_storage_cache"), TrainResources.RESOURCE_PARTS, maxf(amount, 4.0))
	return pois


func _make_detached_rolling_stock(archetype_id: String, context: RefCounted, layout: Dictionary) -> Dictionary:
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
	var detached_consists: Array[Dictionary] = []
	var rolling_stock_units: Dictionary = {}
	if _layout_has_active_segment(layout, WorldgenSemanticGenerator.TRACK_GOODS_LOADING):
		detached_consists.append({
			"units": [unit_id],
			"segment": WorldgenSemanticGenerator.TRACK_GOODS_LOADING,
			"distance": _safe_segment_distance(layout, WorldgenSemanticGenerator.TRACK_GOODS_LOADING, _geometry_value("detached_goods_loading_distance")),
		})
		rolling_stock_units[unit_id] = type_id

	var module_segments: Array[String] = []
	for candidate in [WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR]:
		if _layout_has_active_segment(layout, str(candidate)):
			module_segments.append(str(candidate))
	if not module_segments.is_empty():
		var module_segment := str(module_segments[int(stock_rng.range_int(0, module_segments.size() - 1))])
		var module_type_id := str(salvage_types[int(stock_rng.range_int(0, salvage_types.size() - 1))])
		var module_unit_id := "sector_%03d_salvage_02" % sector_index
		detached_consists.append({
			"units": [module_unit_id],
			"segment": module_segment,
			"distance": _safe_segment_distance(layout, module_segment, _geometry_value("detached_module_distance")),
		})
		rolling_stock_units[module_unit_id] = module_type_id

	return {
		"detached_consists": detached_consists,
		"rolling_stock_units": rolling_stock_units,
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


func _poi_offset(key: String) -> Vector2:
	var offsets := GEOMETRY_PROFILE.get("poi_offsets", {}) as Dictionary
	return offsets.get(key, Vector2.ZERO) as Vector2


func _geometry_value(key: String) -> float:
	return float(GEOMETRY_PROFILE.get(key, 0.0))


func _append_poi_on_active_segment(
	pois: Array[Dictionary],
	layout: Dictionary,
	poi_id: String,
	name: String,
	target_name: String,
	segment_id: String,
	offset: Vector2,
	resource_type: String,
	amount: float
) -> void:
	if not _layout_has_active_segment(layout, segment_id):
		return
	pois.append(_poi(poi_id, name, target_name, _offset_point(_segment_midpoint(layout, segment_id), offset), resource_type, amount))


func _layout_has_active_segment(layout: Dictionary, segment_id: String) -> bool:
	var segments := layout.get("segments", {}) as Dictionary
	if not segments.has(segment_id):
		return false
	var semantics := (layout.get("segment_semantics", {}) as Dictionary).get(segment_id, {}) as Dictionary
	return str(semantics.get("runtime_status", RailMovement.SEGMENT_STATUS_ACTIVE)) != RailMovement.SEGMENT_STATUS_DISPLAY_ONLY


func _safe_segment_distance(layout: Dictionary, segment_id: String, preferred_distance: float) -> float:
	var length := _segment_length(layout, segment_id)
	if length <= 0.0:
		return preferred_distance
	var margin := minf(_geometry_value("detached_distance_margin_max"), length * _geometry_value("detached_distance_margin_ratio"))
	return clampf(preferred_distance, margin, maxf(margin, length - margin))


func _segment_length(layout: Dictionary, segment_id: String) -> float:
	var segments := layout.get("segments", {}) as Dictionary
	var points := segments.get(segment_id, []) as Array
	var total := 0.0
	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		total += start.distance_to(end)
	return total


func _first_existing_point(points: Dictionary, candidates: Array) -> String:
	for candidate in candidates:
		var point_id := str(candidate)
		if points.has(point_id):
			return point_id
	return ""


func _select_existing_point(points: Dictionary, candidates: Array, rng: RefCounted) -> String:
	var existing: Array[String] = []
	for candidate in candidates:
		var point_id := str(candidate)
		if points.has(point_id):
			existing.append(point_id)
	if existing.is_empty():
		return ""
	if existing.size() == 1 or rng == null:
		return existing[0]
	return str(existing[int(rng.range_int(0, existing.size() - 1))])


func _failure(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return _failure_with_diagnostics([_diagnostic(code, message, context)])


func _failure_with_diagnostics(diagnostics: Array) -> Dictionary:
	return {
		"success": false,
		"diagnostics": diagnostics.duplicate(true),
	}


func _make_hazards_and_routes(archetype_id: String, context: RefCounted, layout: Dictionary) -> Dictionary:
	var problem_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_GAMEPLAY_PROBLEM)
	var hazard_definitions: Array[Dictionary] = []
	var route_exits: Array[Dictionary] = []

	var default_exit_segment := str(layout.get("exit_segment", ""))
	var default_exit_distance := float(layout.get("exit_distance", 0.0))
	var points := layout.get("points", {}) as Dictionary
	var segments_dict: Dictionary = {}
	var raw_segs = layout.get("segments", {})
	if typeof(raw_segs) == TYPE_DICTIONARY:
		segments_dict = raw_segs
	elif typeof(raw_segs) == TYPE_ARRAY:
		for seg in (raw_segs as Array):
			var sid := str(seg.get("runtime_segment_id", seg.get("id", "")))
			if sid != "":
				segments_dict[sid] = seg.get("points", [])

	# 1. Generate hazards based on archetype
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			var bridge_variant := int(problem_rng.range_int(0, 1)) if problem_rng != null else 0
			var bridge_segment := WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN
			if bridge_variant == 1:
				hazard_definitions.append({
					"id": "hazard_creek_bridge",
					"type": "track",
					"target_id": bridge_segment,
					"condition": "damaged",
					"name": "Damaged Creek Bridge",
				})

		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			var switch_id := _select_existing_point(points, ["west_loop_switch", "village_yard_switch"], problem_rng)
			if points.has(switch_id):
				hazard_definitions.append({
					"id": "hazard_west_switch",
					"type": "point",
					"target_id": switch_id,
					"condition": "damaged",
					"name": "Jammed West Turnout",
				})

		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			var branch_variant := int(problem_rng.range_int(0, 1)) if problem_rng != null else 0
			var worn_track := WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN
			if branch_variant == 1:
				hazard_definitions.append({
					"id": "hazard_worn_track",
					"type": "track",
					"target_id": worn_track,
					"condition": "damaged",
					"name": "Degraded Branch Platform Track",
				})
			else:
				if points.has("old_yard_switch"):
					hazard_definitions.append({
						"id": "hazard_old_yard_switch",
						"type": "point",
						"target_id": "old_yard_switch",
						"condition": "damaged",
						"name": "Jammed Old Yard Switch",
					})

		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			var yard_switch := _first_existing_point(points, ["yard_switch", "west_yard_switch"])
			if points.has(yard_switch):
				hazard_definitions.append({
					"id": "hazard_goods_switch",
					"type": "point",
					"target_id": yard_switch,
					"condition": "damaged",
					"name": "Jammed Goods Yard Switch",
				})

		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			var spur_switch := _select_existing_point(points, ["spur_switch", "loading_switch"], problem_rng)
			if points.has(spur_switch):
				hazard_definitions.append({
					"id": "hazard_spur_switch",
					"type": "point",
					"target_id": spur_switch,
					"condition": "damaged",
					"name": "Jammed Agricultural Spur Switch",
				})

	# 2. Build outbound routes from active segments in layout
	for sid_v in segments_dict.keys():
		var sid := str(sid_v)
		var pts: Array = segments_dict[sid_v]
		var length := _polyline_length(pts)
		var dist := default_exit_distance if sid == default_exit_segment else maxf(length - 40.0, 40.0)

		match sid:
			WorldgenSemanticGenerator.TRACK_RURAL_MAIN:
				if default_exit_segment == WorldgenSemanticGenerator.TRACK_RURAL_MAIN:
					route_exits.append(_build_route_exit(
						"rural_main_exit", "main", "Mainline Corridor",
						"Direct onward route along the rural through line.",
						"main", sid, dist, "Main throughway line",
						["mainline", "through"], "HIGH",
						"Through Line", "MODERATE", "MODERATE", "MODERATE",
						"Standard consist traffic", "Good", [],
						{"require_traction": true}
					))
			WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN:
				route_exits.append(_build_route_exit(
					"rural_exit_main", "main", "Mainline Corridor",
					"Continue east along the rural main line.",
					"main", sid, dist, "Main throughway line",
					["mainline", "through"], "HIGH",
					"Through Line", "MODERATE", "MODERATE", "MODERATE",
					"Standard consist traffic", "Good", [],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT:
				route_exits.append(_build_route_exit(
					"rural_branch_exit", "branch", "Outbound Branch Line",
					"Secondary single-track line branching into outlying territory.",
					"branch", sid, dist, "Unsignalled single branch",
					["branch", "remote"], "MODERATE",
					"Outlying Depot", "GOOD", "MODERATE", "LOW",
					"Occasional short freights", "Fair", ["Unattended switches"],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_EXIT_MAIN:
				var exit_label := "Main Departure Line"
				var exit_profile := "settlement"
				var summary := "Continue along the primary departure corridor."
				if archetype_id == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
					exit_label = "Town East Departure"
					summary = "Continue east from the small town goods yard."
				route_exits.append(_build_route_exit(
					"main_exit", "main", exit_label,
					summary, exit_profile, sid, dist, "Primary regional corridor",
					["mainline", "settlement"], "HIGH",
					"Regional Junction", "GOOD", "GOOD", "MODERATE",
					"Mixed freight & passengers", "Well-maintained", [],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_EXIT:
				route_exits.append(_build_route_exit(
					"industrial_exit", "industrial", "Industrial Spur Exit",
					"Heavy outbound branch serving factories and machine works.",
					"industrial_corridor", sid, dist, "Heavy industrial feeder",
					["industrial", "parts", "tools"], "HIGH",
					"Heavy Industrial Works", "LOW", "EXCELLENT", "GOOD",
					"Heavy flatcars & boxcars", "Fair / Heavy grease", ["Industrial debris"],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT, WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT:
				route_exits.append(_build_route_exit(
					"agricultural_exit", "agricultural", "Grain Country Branch",
					"Outbound corridor heading into fertile farming valleys.",
					"agricultural", sid, dist, "Rural grain feeder",
					["agricultural", "grain", "food"], "HIGH",
					"Grain Elevator Facility", "EXCELLENT", "LOW", "MODERATE",
					"Hopper cars and cattle wagons", "Good ballast", [],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_MAIN_EAST:
				if archetype_id == WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
					route_exits.append(_build_route_exit(
						"agri_main_east", "main", "Eastward Mainline",
						"Continue past the grain loading facility along the main track.",
						"agricultural", sid, dist, "Agricultural throughway",
						["mainline", "grain"], "HIGH",
						"Grain District Terminal", "GOOD", "MODERATE", "MODERATE",
						"Grain freight consists", "Fair", [],
						{"require_traction": true}
					))
				elif archetype_id == WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
					var worn_track := WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN
					var reqs: Dictionary = {"require_traction": true}
					var has_worn_hazard := false
					for h in hazard_definitions:
						if str(h.get("target_id", "")) == worn_track:
							has_worn_hazard = true
							break
					if has_worn_hazard:
						reqs["required_segments_operational"] = [worn_track]
					route_exits.append(_build_route_exit(
						"declining_main_east", "declining", "Branch Line Exit",
						"Continue past the neglected station along the old line.",
						"declining", sid, dist, "Neglected branch track",
						["branch", "abandoned", "salvage"], "MODERATE",
						"Abandoned Terminus", "LOW", "GOOD", "POOR",
						"Derelict rolling stock reported", "Rough / Overgrown", ["Degraded track"],
						reqs
					))
			WorldgenSemanticGenerator.TRACK_AGRI_BRANCH_EXIT:
				route_exits.append(_build_route_exit(
					"agri_branch_exit", "agricultural", "Deep Grain Branch",
					"Dedicated single-line spur leading to rural grain silos.",
					"agricultural", sid, dist, "Silo spur line",
					["agricultural", "silos", "food"], "HIGH",
					"Silo Complex", "EXCELLENT", "LOW", "LOW",
					"High-capacity grain hoppers", "Fair", [],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST:
				var reqs: Dictionary = {"require_traction": true}
				var bridge_segment := WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN
				var has_bridge_hazard := false
				for h in hazard_definitions:
					if str(h.get("target_id", "")) == bridge_segment:
						has_bridge_hazard = true
						break
				if has_bridge_hazard:
					reqs["required_segments_operational"] = [bridge_segment]
				else:
					reqs["max_mass"] = 240.0
				var summary := "Direct route across the creek bridge (%s)." % ("requires track repair" if has_bridge_hazard else "240t mass limit")
				route_exits.append(_build_route_exit(
					"creek_bridge_exit", "bridge", "Creek Bridge route",
					summary, "forward", sid, dist, "Constrained gorge line",
					["valley", "bridge", "scenic"], "HIGH",
					"River Crossing", "MODERATE", "MODERATE", "MODERATE",
					"Light consists", "Good / Trestle structure", ["Mass limitation" if not has_bridge_hazard else "Damaged bridge"],
					reqs
				))
			WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT:
				route_exits.append(_build_route_exit(
					"valley_branch_exit", "branch", "High Ridge Branch",
					"Steep mountain branch climbing above the river gorge.",
					"branch", sid, dist, "Mountain feeder track",
					["mountain", "remote"], "MODERATE",
					"Highland Outpost", "LOW", "MODERATE", "LOW",
					"Worn maintenance stock", "Rough ballast", ["Steep gradient"],
					{"require_traction": true}
				))
			WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT:
				route_exits.append(_build_route_exit(
					"declining_freight_exit", "industrial", "Old Freight Bypass",
					"Weathered track skirting past the abandoned goods yard.",
					"industrial_corridor", sid, dist, "Weathered industrial bypass",
					["industrial", "salvage", "derelict"], "MODERATE",
					"Disused Industrial Park", "LOW", "EXCELLENT", "LOW",
					"Abandoned freight wagons", "Rusty rail heads", ["Derelict stock on sidings"],
					{"require_traction": true}
				))

	if route_exits.is_empty():
		route_exits.append(_build_route_exit(
			"forward_exit", "forward", "Procedural forward exit",
			"Continue to the next procedural sector.",
			"forward", default_exit_segment, default_exit_distance, "Procedural corridor",
			["mainline"], "HIGH", "Forward Sector", "MODERATE", "MODERATE", "MODERATE",
			"Standard traffic", "Good", [], {"require_traction": true}
		))

	return {
		"hazard_definitions": hazard_definitions,
		"route_exits": route_exits,
	}


func _polyline_length(pts: Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		var p1: Vector2
		if typeof(pts[i]) == TYPE_VECTOR2:
			p1 = pts[i]
		else:
			p1 = Vector2(float(pts[i][0]), float(pts[i][1]))
		var p2: Vector2
		if typeof(pts[i + 1]) == TYPE_VECTOR2:
			p2 = pts[i + 1]
		else:
			p2 = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
		total += p1.distance_to(p2)
	return total


func _build_route_exit(
	id: String,
	route_id: String,
	label: String,
	summary: String,
	profile: String,
	segment: String,
	distance: float,
	character: String,
	destination_tags: Array,
	confidence: String,
	destination_type: String,
	food_prospects: String,
	parts_prospects: String,
	fuel_prospects: String,
	rolling_stock: String,
	rail_condition: String,
	known_hazards: Array,
	requirements: Dictionary
) -> Dictionary:
	return {
		"id": id,
		"route_id": route_id,
		"label": label,
		"summary": summary,
		"profile": profile,
		"segment": segment,
		"distance": distance,
		"character": character,
		"destination_tags": destination_tags.duplicate(),
		"intel": {
			"confidence": confidence,
			"destination_type": destination_type,
			"food_prospects": food_prospects,
			"parts_prospects": parts_prospects,
			"fuel_prospects": fuel_prospects,
			"rolling_stock": rolling_stock,
			"rail_condition": rail_condition,
			"known_hazards": known_hazards.duplicate(),
		},
		"requirements": requirements.duplicate(true),
	}


func _diagnostic(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"message": message,
		"context": context.duplicate(true),
	}
