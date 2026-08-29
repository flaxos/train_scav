extends RefCounted
class_name WorldgenProceduralSpatialEmbedding

const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationTrace := preload("res://scripts/worldgen/worldgen_generation_trace.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

const EMBEDDING_VERSION := "sprint9_production_procedural_embedding_v1"
const STREAM_SPATIAL := "spatial"

const ROUTE_MAIN := "main"
const ROUTE_LOOP := "loop"
const ROUTE_YARD := "yard"
const ROUTE_PLATFORM := "platform"
const ROUTE_LOADING := "loading"
const ROUTE_HEADSHUNT := "headshunt"


func generate_embedding(blueprint: RefCounted, context: RefCounted, prior_trace: RefCounted = null) -> Dictionary:
	if blueprint == null or not blueprint.has_method("to_dictionary"):
		return _failure("BLUEPRINT_INVALID", "blueprint must expose to_dictionary")
	if context == null or not _context_has_required_api(context):
		return _failure("GENERATION_CONTEXT_INVALID", "generation context does not expose required 9F API")
	if not bool(context.is_valid()):
		return _failure_with_diagnostics(context.get_diagnostics())

	var validation: Dictionary = WorldgenSchemaValidator.new().validate_blueprint(blueprint)
	if not bool(validation.get("valid", false)):
		return _failure_with_diagnostics((validation.get("diagnostics", []) as Array).duplicate(true))

	var spatial_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_SPATIAL)
	if spatial_rng == null:
		return _failure("SPATIAL_RNG_UNAVAILABLE", "spatial RNG stream is unavailable")

	var archetype_id := str(blueprint.get_archetype_id())
	var decisions := _make_decisions(archetype_id, spatial_rng)
	var embedding := _make_embedding(archetype_id, decisions)
	if embedding.is_empty():
		return _failure("SPATIAL_ARCHETYPE_UNSUPPORTED", "spatial embedding does not support %s" % archetype_id, {"archetype_id": archetype_id})

	return {
		"success": true,
		"embedding": embedding,
		"diagnostics": [],
		"generation_trace": _make_trace(context, prior_trace, decisions),
		"decisions": decisions.duplicate(true),
	}


func _context_has_required_api(context: RefCounted) -> bool:
	return context.has_method("is_valid") \
		and context.has_method("get_diagnostics") \
		and context.has_method("make_rng") \
		and context.has_method("to_trace_dictionary")


func _make_decisions(archetype_id: String, spatial_rng: RefCounted) -> Dictionary:
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			var rural_length_class := _choose(spatial_rng, ["short", "medium", "long"])
			return {
				"archetype": archetype_id,
				"main_length_class": rural_length_class,
				"signature": "rural/%s" % rural_length_class,
			}
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			return _make_loop_decisions(archetype_id, spatial_rng)
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			var loop_decisions := _make_loop_decisions(archetype_id, spatial_rng)
			var goods_length_class := _choose(spatial_rng, ["medium", "long"])
			var yard_offset_class := _choose(spatial_rng, ["standard", "wide"])
			loop_decisions["goods_length_class"] = goods_length_class
			loop_decisions["yard_offset_class"] = yard_offset_class
			loop_decisions["signature"] = "%s/%s/%s" % [
				str(loop_decisions.get("signature", "")),
				goods_length_class,
				yard_offset_class,
			]
			return loop_decisions
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			var spur_side := _choose(spatial_rng, ["north", "south"])
			var main_west_length_class := _choose(spatial_rng, ["short", "medium", "long"])
			var main_east_length_class := _choose(spatial_rng, ["medium", "long"])
			var spur_length_class := _choose(spatial_rng, ["short", "medium", "long"])
			var loading_length_class := _choose(spatial_rng, ["medium", "long"])
			return {
				"archetype": archetype_id,
				"spur_side": spur_side,
				"main_west_length_class": main_west_length_class,
				"main_east_length_class": main_east_length_class,
				"spur_length_class": spur_length_class,
				"loading_length_class": loading_length_class,
				"signature": "%s/%s/%s/%s/%s" % [
					spur_side,
					main_west_length_class,
					main_east_length_class,
					spur_length_class,
					loading_length_class,
				],
			}
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			var river_loop_side := _choose(spatial_rng, ["north", "south"])
			var valley_approach_class := _choose(spatial_rng, ["short", "medium"])
			var valley_station_class := _choose(spatial_rng, ["short", "medium"])
			var bridge_length_class := _choose(spatial_rng, ["short", "medium"])
			var valley_exit_class := _choose(spatial_rng, ["short", "medium"])
			return {
				"archetype": archetype_id,
				"loop_side": river_loop_side,
				"approach_length_class": valley_approach_class,
				"station_length_class": valley_station_class,
				"bridge_length_class": bridge_length_class,
				"exit_length_class": valley_exit_class,
				"signature": "%s/%s/%s/%s/%s" % [
					river_loop_side,
					valley_approach_class,
					valley_station_class,
					bridge_length_class,
					valley_exit_class,
				],
			}
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			var declining_loop := _make_loop_decisions(archetype_id, spatial_rng)
			var yard_side := _choose(spatial_rng, ["north", "south"])
			var storage_length_class := _choose(spatial_rng, ["short", "medium", "long"])
			var abandoned_shape := _choose(spatial_rng, ["parallel", "splayed"])
			declining_loop["yard_side"] = yard_side
			declining_loop["storage_length_class"] = storage_length_class
			declining_loop["abandoned_shape"] = abandoned_shape
			declining_loop["signature"] = "%s/%s/%s/%s" % [
				str(declining_loop.get("signature", "")),
				yard_side,
				storage_length_class,
				abandoned_shape,
			]
			return declining_loop
	return {"archetype": archetype_id, "signature": "unsupported"}


func _make_loop_decisions(archetype_id: String, spatial_rng: RefCounted) -> Dictionary:
	var loop_side := _choose(spatial_rng, ["north", "south"])
	var approach_length_class := _choose(spatial_rng, ["short", "medium", "long"])
	var station_length_class := _choose(spatial_rng, ["medium", "long", "extended"])
	var exit_length_class := _choose(spatial_rng, ["short", "medium", "long"])
	var loop_offset_class := _choose(spatial_rng, ["standard", "wide"])
	return {
		"archetype": archetype_id,
		"loop_side": loop_side,
		"approach_length_class": approach_length_class,
		"station_length_class": station_length_class,
		"exit_length_class": exit_length_class,
		"loop_offset_class": loop_offset_class,
		"signature": "%s/%s/%s/%s/%s" % [
			loop_side,
			approach_length_class,
			station_length_class,
			exit_length_class,
			loop_offset_class,
		],
	}


func _choose(rng: RefCounted, options: Array) -> String:
	if options.is_empty():
		return ""
	var index := int(rng.range_int(0, options.size() - 1))
	return str(options[index])


func _make_embedding(archetype_id: String, decisions: Dictionary) -> Dictionary:
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			return _make_rural_embedding(decisions)
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			return _make_village_embedding(decisions)
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			return _make_goods_embedding(decisions)
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			return _make_agricultural_embedding(decisions)
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			return _make_river_valley_embedding(decisions)
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			return _make_declining_embedding(decisions)
	return {}


func _make_rural_embedding(decisions: Dictionary) -> Dictionary:
	var origin_x := 120.0
	var main_y := 360.0
	var length := _length_for(str(decisions.get("main_length_class", "medium")), {
		"short": 820.0,
		"medium": 980.0,
		"long": 1140.0,
	})
	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
		"runtime_layout_id": "generated_rural_through_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN,
		"entry_distance": 24.0,
		"exit_segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN,
		"exit_distance": maxf(length - 24.0, 24.0),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			{
				"runtime_segment_id": WorldgenSemanticGenerator.TRACK_RURAL_MAIN,
				"semantic_edge_id": WorldgenSemanticGenerator.TRACK_RURAL_MAIN,
				"label": "Generated rural through main",
				"points": [[origin_x, main_y], [origin_x + length, main_y]],
				"end_b_block_reason": "End of generated rural through sector",
			},
		],
		"points": [],
		"next_connections": {},
		"previous_connections": {},
		"route_presets": [
			{
				"id": ROUTE_MAIN,
				"label": "Through main",
				"routes": {},
			},
		],
	}


func _make_village_embedding(decisions: Dictionary) -> Dictionary:
	var geometry := _loop_geometry(decisions)
	var west_point := geometry["west_point"] as Array
	var east_point := geometry["east_point"] as Array
	var loop_points := geometry["loop_points"] as Array
	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
		"runtime_layout_id": "generated_village_passing_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN,
		"entry_distance": 24.0,
		"exit_segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN,
		"exit_distance": float(geometry["exit_distance"]),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			_segment(WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, [[geometry["origin_x"], geometry["main_y"]], west_point], "No route through west generated loop switch"),
			_segment(WorldgenSemanticGenerator.TRACK_STATION_MAIN, WorldgenSemanticGenerator.TRACK_STATION_MAIN, [west_point, east_point], "East generated loop switch route blocks station main"),
			_segment(WorldgenSemanticGenerator.TRACK_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_PASSING_LOOP, loop_points, "East generated loop switch route blocks passing loop"),
			_segment(WorldgenSemanticGenerator.TRACK_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_EXIT_MAIN, [east_point, [geometry["exit_x"], geometry["main_y"]]], "End of generated village east exit"),
		],
		"points": [
			_point("west_loop_switch", "west_loop_switch", west_point, [ROUTE_MAIN, ROUTE_LOOP], ROUTE_MAIN),
			_point("east_loop_switch", "east_loop_switch", east_point, [ROUTE_MAIN, ROUTE_LOOP], ROUTE_MAIN),
		],
		"next_connections": {
			WorldgenSemanticGenerator.TRACK_APPROACH_MAIN: {"point": "west_loop_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_STATION_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_MAIN},
			WorldgenSemanticGenerator.TRACK_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_LOOP},
		},
		"previous_connections": {
			WorldgenSemanticGenerator.TRACK_STATION_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_loop_switch", "requires_route": ROUTE_MAIN, "blocked_reason": "West generated loop switch blocks station main"},
			WorldgenSemanticGenerator.TRACK_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP, "blocked_reason": "West generated loop switch blocks passing loop"},
			WorldgenSemanticGenerator.TRACK_EXIT_MAIN: {"point": "east_loop_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
		},
		"route_presets": [
			{"id": ROUTE_MAIN, "label": "Station main", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_MAIN}},
			{"id": ROUTE_LOOP, "label": "Passing loop", "routes": {"west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
		],
	}


func _make_goods_embedding(decisions: Dictionary) -> Dictionary:
	var geometry := _loop_geometry(decisions)
	var west_yard := geometry["west_point"] as Array
	var west_loop := [float(west_yard[0]) + 100.0, float(west_yard[1])]
	var east_loop := geometry["east_point"] as Array
	var loop_points := [
		west_loop,
		[float(west_loop[0]) + 76.0, float((geometry["loop_points"] as Array)[1][1])],
		[float(east_loop[0]) - 76.0, float((geometry["loop_points"] as Array)[1][1])],
		east_loop,
	]
	var yard_offset := _length_for(str(decisions.get("yard_offset_class", "standard")), {
		"standard": 175.0,
		"wide": 220.0,
	})
	var yard_sign := 1.0
	if str(decisions.get("loop_side", "north")) == "south":
		yard_sign = -1.0
	var yard_switch := [float(west_yard[0]) + 310.0, float(west_yard[1]) + yard_offset * yard_sign]
	var loading_length := _length_for(str(decisions.get("goods_length_class", "medium")), {
		"medium": 300.0,
		"long": 380.0,
	})
	var loading_end := [float(yard_switch[0]) + loading_length, float(yard_switch[1])]
	var headshunt_end := [float(yard_switch[0]) + loading_length * 0.72, float(yard_switch[1]) + 70.0 * yard_sign]

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
		"runtime_layout_id": "generated_small_town_goods_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN,
		"entry_distance": 24.0,
		"exit_segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN,
		"exit_distance": float(geometry["exit_distance"]),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			_segment(WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, [[geometry["origin_x"], geometry["main_y"]], west_yard], "No route through west yard switch"),
			_segment("west_station_throat", "", [west_yard, west_loop], "No route through west loop switch"),
			_segment(WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, [west_loop, east_loop], "East loop switch route blocks platform main"),
			_segment(WorldgenSemanticGenerator.TRACK_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_PASSING_LOOP, loop_points, "East loop switch route blocks passing loop"),
			_segment(WorldgenSemanticGenerator.TRACK_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_EXIT_MAIN, [east_loop, [geometry["exit_x"], geometry["main_y"]]], "End of generated goods east exit"),
			_segment(WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, [west_yard, [float(west_yard[0]) + 74.0, float(west_yard[1]) + 44.0 * yard_sign], yard_switch], "No route through generated yard switch"),
			_segment(WorldgenSemanticGenerator.TRACK_GOODS_LOADING, WorldgenSemanticGenerator.TRACK_GOODS_LOADING, [yard_switch, loading_end], "End of generated goods loading buffer"),
			_segment(WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT, WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT, [yard_switch, headshunt_end], "End of generated yard headshunt buffer"),
		],
		"points": [
			_point("west_yard_switch", "west_loop_switch", west_yard, [ROUTE_MAIN, ROUTE_YARD], ROUTE_MAIN),
			_point("west_loop_switch", "west_loop_switch", west_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
			_point("east_loop_switch", "east_loop_switch", east_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
			_point("yard_switch", "yard_switch", yard_switch, [ROUTE_LOADING, ROUTE_HEADSHUNT], ROUTE_LOADING),
		],
		"next_connections": {
			WorldgenSemanticGenerator.TRACK_APPROACH_MAIN: {"point": "west_yard_switch", "routes": {ROUTE_MAIN: "west_station_throat", ROUTE_YARD: WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD}},
			"west_station_throat": {"point": "west_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_PLATFORM},
			WorldgenSemanticGenerator.TRACK_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_LOOP},
			WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD: {"point": "yard_switch", "routes": {ROUTE_LOADING: WorldgenSemanticGenerator.TRACK_GOODS_LOADING, ROUTE_HEADSHUNT: WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT}},
		},
		"previous_connections": {
			"west_station_throat": {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_yard_switch", "requires_route": ROUTE_MAIN},
			WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD: {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_yard_switch", "requires_route": ROUTE_YARD},
			WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN: {"segment": "west_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_PLATFORM},
			WorldgenSemanticGenerator.TRACK_PASSING_LOOP: {"segment": "west_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP},
			WorldgenSemanticGenerator.TRACK_EXIT_MAIN: {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_GOODS_LOADING: {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_LOADING},
			WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT: {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_HEADSHUNT},
		},
		"route_presets": [
			{"id": ROUTE_MAIN, "label": "Platform main", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_PLATFORM}},
			{"id": ROUTE_LOOP, "label": "Passing loop", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
			{"id": "goods_loading", "label": "Goods loading", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_LOADING}},
			{"id": "headshunt", "label": "Yard headshunt", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_HEADSHUNT}},
		],
	}


func _make_agricultural_embedding(decisions: Dictionary) -> Dictionary:
	var origin_x := 120.0
	var main_y := 360.0
	var west_length := _length_for(str(decisions.get("main_west_length_class", "medium")), {
		"short": 220.0,
		"medium": 280.0,
		"long": 340.0,
	})
	var east_length := _length_for(str(decisions.get("main_east_length_class", "medium")), {
		"medium": 660.0,
		"long": 780.0,
	})
	var spur_length := _length_for(str(decisions.get("spur_length_class", "medium")), {
		"short": 210.0,
		"medium": 280.0,
		"long": 350.0,
	})
	var loading_length := _length_for(str(decisions.get("loading_length_class", "medium")), {
		"medium": 280.0,
		"long": 360.0,
	})
	var spur_sign := -1.0
	if str(decisions.get("spur_side", "south")) == "south":
		spur_sign = 1.0
	var spur_switch := [origin_x + west_length, main_y]
	var loading_switch := [float(spur_switch[0]) + spur_length, main_y + 132.0 * spur_sign]
	var loading_end := [float(loading_switch[0]) + loading_length, float(loading_switch[1]) + 14.0 * spur_sign]
	var headshunt_length := minf(loading_length * 0.72, 260.0)
	var headshunt_end := [float(loading_switch[0]) + headshunt_length, float(loading_switch[1]) + 82.0 * spur_sign]
	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
		"runtime_layout_id": "generated_agricultural_loading_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST,
		"entry_distance": 24.0,
		"exit_segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST,
		"exit_distance": maxf(east_length - 24.0, 24.0),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			_segment(WorldgenSemanticGenerator.TRACK_MAIN_WEST, WorldgenSemanticGenerator.TRACK_MAIN_WEST, [[origin_x, main_y], spur_switch], "No route through agricultural spur switch"),
			_segment(WorldgenSemanticGenerator.TRACK_MAIN_EAST, WorldgenSemanticGenerator.TRACK_MAIN_EAST, [spur_switch, [float(spur_switch[0]) + east_length, main_y]], "End of agricultural east exit"),
			_segment(WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, [spur_switch, [float(spur_switch[0]) + 92.0, main_y + 58.0 * spur_sign], loading_switch], "No route through agricultural loading switch"),
			_segment(WorldgenSemanticGenerator.TRACK_GRAIN_LOADING, WorldgenSemanticGenerator.TRACK_GRAIN_LOADING, [loading_switch, [float(loading_switch[0]) + loading_length * 0.42, float(loading_switch[1]) + 22.0 * spur_sign], loading_end], "End of grain loading buffer"),
			_segment(WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND, WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND, [loading_switch, [float(loading_switch[0]) + headshunt_length * 0.45, float(loading_switch[1]) + 72.0 * spur_sign], headshunt_end], "End of agricultural headshunt buffer"),
		],
		"points": [
			_point("spur_switch", "spur_switch", spur_switch, [ROUTE_MAIN, "spur"], ROUTE_MAIN),
			_point("loading_switch", "loading_switch", loading_switch, [ROUTE_LOADING, ROUTE_HEADSHUNT], ROUTE_LOADING),
		],
		"next_connections": {
			WorldgenSemanticGenerator.TRACK_MAIN_WEST: {"point": "spur_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_MAIN_EAST, "spur": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR}},
			WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR: {"point": "loading_switch", "routes": {ROUTE_LOADING: WorldgenSemanticGenerator.TRACK_GRAIN_LOADING, ROUTE_HEADSHUNT: WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND}},
		},
		"previous_connections": {
			WorldgenSemanticGenerator.TRACK_MAIN_EAST: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "spur_switch", "requires_route": ROUTE_MAIN},
			WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "spur_switch", "requires_route": "spur"},
			WorldgenSemanticGenerator.TRACK_GRAIN_LOADING: {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, "requires_point": "loading_switch", "requires_route": ROUTE_LOADING},
			WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND: {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, "requires_point": "loading_switch", "requires_route": ROUTE_HEADSHUNT},
		},
		"route_presets": [
			{"id": ROUTE_MAIN, "label": "Through main", "routes": {"spur_switch": ROUTE_MAIN}},
			{"id": "grain_loading", "label": "Grain loading", "routes": {"spur_switch": "spur", "loading_switch": ROUTE_LOADING}},
			{"id": "headshunt", "label": "Short headshunt", "routes": {"spur_switch": "spur", "loading_switch": ROUTE_HEADSHUNT}},
		],
	}


func _make_river_valley_embedding(decisions: Dictionary) -> Dictionary:
	var origin_x := 120.0
	var main_y := 360.0
	var approach_length := _length_for(str(decisions.get("approach_length_class", "short")), {
		"short": 200.0,
		"medium": 260.0,
	})
	var station_length := _length_for(str(decisions.get("station_length_class", "short")), {
		"short": 300.0,
		"medium": 360.0,
	})
	var bridge_length := _length_for(str(decisions.get("bridge_length_class", "short")), {
		"short": 150.0,
		"medium": 210.0,
	})
	var exit_length := _length_for(str(decisions.get("exit_length_class", "short")), {
		"short": 240.0,
		"medium": 300.0,
	})
	var loop_offset := -56.0
	if str(decisions.get("loop_side", "south")) == "south":
		loop_offset = 56.0
	var west_point := [origin_x + approach_length, main_y]
	var east_point := [float(west_point[0]) + station_length, main_y - 8.0]
	var bridge_joint := [float(east_point[0]) + bridge_length, main_y - 16.0]
	var exit_end := [float(bridge_joint[0]) + exit_length, main_y - 24.0]
	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED,
		"runtime_layout_id": "generated_river_valley_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST,
		"entry_distance": 24.0,
		"exit_segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST,
		"exit_distance": maxf(exit_length - 24.0, 24.0),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			_segment(WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, [[origin_x, main_y], west_point], "No route through west valley loop switch"),
			_segment(WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, [west_point, east_point], "East valley switch route blocks platform main"),
			_segment(WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP, [west_point, [float(west_point[0]) + 62.0, main_y + loop_offset], [float(east_point[0]) - 62.0, main_y + loop_offset * 0.9], east_point], "East valley switch route blocks short passing loop"),
			_segment(WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, [east_point, bridge_joint], "End of bridge approach"),
			_segment(WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST, WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST, [bridge_joint, exit_end], "End of valley east exit"),
		],
		"points": [
			_point("west_loop_switch", "west_loop_switch", west_point, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
			_point("east_loop_switch", "east_loop_switch", east_point, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
		],
		"next_connections": {
			WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST: {"point": "west_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_PLATFORM},
			WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_LOOP},
			WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST},
		},
		"previous_connections": {
			WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, "requires_point": "west_loop_switch", "requires_route": ROUTE_PLATFORM},
			WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP},
			WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN: {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST: {"segment": WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN},
		},
		"route_presets": [
			{"id": ROUTE_MAIN, "label": "Constrained main", "routes": {"west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_PLATFORM}},
			{"id": ROUTE_LOOP, "label": "Short passing loop", "routes": {"west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
		],
	}


func _make_declining_embedding(decisions: Dictionary) -> Dictionary:
	var geometry := _loop_geometry(decisions)
	var west_yard := geometry["west_point"] as Array
	var west_loop := [float(west_yard[0]) + 100.0, float(west_yard[1])]
	var east_loop := geometry["east_point"] as Array
	var loop_points := [
		west_loop,
		[float(west_loop[0]) + 76.0, float((geometry["loop_points"] as Array)[1][1])],
		[float(east_loop[0]) - 76.0, float((geometry["loop_points"] as Array)[1][1])],
		east_loop,
	]
	var yard_sign := -1.0
	if str(decisions.get("yard_side", "south")) == "south":
		yard_sign = 1.0
	var storage_length := _length_for(str(decisions.get("storage_length_class", "medium")), {
		"short": 250.0,
		"medium": 320.0,
		"long": 390.0,
	})
	var yard_end := [float(west_yard[0]) + 220.0, float(west_yard[1]) + 136.0 * yard_sign]
	var storage_end := [float(yard_end[0]) + storage_length, float(yard_end[1]) + 18.0 * yard_sign]
	var abandoned_y_offset := 76.0
	if str(decisions.get("abandoned_shape", "parallel")) == "splayed":
		abandoned_y_offset = 116.0
	var abandoned_end := [float(yard_end[0]) + storage_length * 0.82, float(yard_end[1]) + abandoned_y_offset * yard_sign]
	var removed_stub := [float(yard_end[0]) + 74.0, float(yard_end[1]) - 46.0 * yard_sign]
	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
		"runtime_layout_id": "generated_declining_branch_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST,
		"entry_distance": 24.0,
		"exit_segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST,
		"exit_distance": float(geometry["exit_distance"]),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			_segment(WorldgenSemanticGenerator.TRACK_MAIN_WEST, WorldgenSemanticGenerator.TRACK_MAIN_WEST, [[geometry["origin_x"], geometry["main_y"]], west_yard], "No route through west declining yard switch"),
			_segment("declining_station_throat", "", [west_yard, west_loop], "No route through west declining loop switch"),
			_segment(WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, [west_loop, east_loop], "East loop switch route blocks worn platform main"),
			_segment(WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP, loop_points, "East loop switch route blocks rusty passing loop"),
			_segment(WorldgenSemanticGenerator.TRACK_MAIN_EAST, WorldgenSemanticGenerator.TRACK_MAIN_EAST, [east_loop, [geometry["exit_x"], geometry["main_y"]]], "End of declining branch east exit"),
			_segment(WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, [west_yard, [float(west_yard[0]) + 90.0, float(west_yard[1]) + 68.0 * yard_sign], yard_end], "End of old goods lead"),
			_segment(WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE, WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE, [yard_end, [float(yard_end[0]) + storage_length * 0.42, float(yard_end[1]) + 20.0 * yard_sign], storage_end], "End of overgrown storage buffer"),
			_segment(WorldgenSemanticGenerator.TRACK_ABANDONED_LOADING_TRACK, WorldgenSemanticGenerator.TRACK_ABANDONED_LOADING_TRACK, [yard_end, [float(yard_end[0]) + storage_length * 0.40, float(yard_end[1]) + abandoned_y_offset * 0.82 * yard_sign], abandoned_end], "Abandoned loading track is not routable", "display_only"),
			_segment(WorldgenSemanticGenerator.TRACK_REMOVED_BRANCH_STUB, WorldgenSemanticGenerator.TRACK_REMOVED_BRANCH_STUB, [yard_end, removed_stub], "Removed branch stub is not routable", "display_only"),
		],
		"points": [
			_point("west_yard_switch", "west_loop_switch", west_yard, [ROUTE_MAIN, "old_yard"], ROUTE_MAIN),
			_point("west_loop_switch", "west_loop_switch", west_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
			_point("east_loop_switch", "east_loop_switch", east_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
		],
		"next_connections": {
			WorldgenSemanticGenerator.TRACK_MAIN_WEST: {"point": "west_yard_switch", "routes": {ROUTE_MAIN: "declining_station_throat", "old_yard": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD}},
			"declining_station_throat": {"point": "west_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST, "requires_point": "east_loop_switch", "requires_route": ROUTE_PLATFORM},
			WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST, "requires_point": "east_loop_switch", "requires_route": ROUTE_LOOP},
			WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD: {"segment": WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE},
		},
		"previous_connections": {
			"declining_station_throat": {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "west_yard_switch", "requires_route": ROUTE_MAIN},
			WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "west_yard_switch", "requires_route": "old_yard"},
			WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN: {"segment": "declining_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_PLATFORM},
			WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP: {"segment": "declining_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP},
			WorldgenSemanticGenerator.TRACK_MAIN_EAST: {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP}},
			WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE: {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD},
		},
		"route_presets": [
			{"id": ROUTE_MAIN, "label": "Worn platform main", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_PLATFORM}},
			{"id": ROUTE_LOOP, "label": "Rusty passing loop", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
			{"id": "old_storage", "label": "Overgrown storage", "routes": {"west_yard_switch": "old_yard"}},
		],
	}


func _loop_geometry(decisions: Dictionary) -> Dictionary:
	var origin_x := 120.0
	var main_y := 360.0
	var approach_length := _length_for(str(decisions.get("approach_length_class", "medium")), {
		"short": 240.0,
		"medium": 300.0,
		"long": 360.0,
	})
	var station_length := _length_for(str(decisions.get("station_length_class", "long")), {
		"medium": 380.0,
		"long": 450.0,
		"extended": 520.0,
	})
	var exit_length := _length_for(str(decisions.get("exit_length_class", "medium")), {
		"short": 280.0,
		"medium": 340.0,
		"long": 400.0,
	})
	var loop_offset_magnitude := _length_for(str(decisions.get("loop_offset_class", "standard")), {
		"standard": 68.0,
		"wide": 86.0,
	})
	var loop_offset := -loop_offset_magnitude
	if str(decisions.get("loop_side", "north")) == "south":
		loop_offset = loop_offset_magnitude

	var west_x := origin_x + approach_length
	var east_x := west_x + station_length
	var exit_x := east_x + exit_length
	var west_point := [west_x, main_y]
	var east_point := [east_x, main_y]
	return {
		"origin_x": origin_x,
		"main_y": main_y,
		"west_point": west_point,
		"east_point": east_point,
		"exit_x": exit_x,
		"exit_distance": maxf(exit_length - 24.0, 24.0),
		"loop_points": [
			west_point,
			[west_x + 74.0, main_y + loop_offset],
			[east_x - 74.0, main_y + loop_offset],
			east_point,
		],
	}


func _segment(runtime_id: String, semantic_id: String, points: Array, block_reason: String, runtime_status: String = "") -> Dictionary:
	var segment := {
		"runtime_segment_id": runtime_id,
		"semantic_edge_id": semantic_id,
		"points": points,
		"end_b_block_reason": block_reason,
	}
	if runtime_status != "":
		segment["runtime_status"] = runtime_status
	return segment


func _point(runtime_id: String, semantic_id: String, position: Array, routes: Array, initial_route: String) -> Dictionary:
	return {
		"runtime_point_id": runtime_id,
		"semantic_node_id": semantic_id,
		"position": position,
		"routes": routes,
		"initial_route": initial_route,
	}


func _length_for(key: String, lengths: Dictionary) -> float:
	return float(lengths.get(key, lengths.values()[0]))


func _make_trace(context: RefCounted, prior_trace: RefCounted, decisions: Dictionary) -> RefCounted:
	var trace_data: Dictionary = context.to_trace_dictionary()
	if prior_trace != null and prior_trace.has_method("to_dictionary"):
		trace_data = prior_trace.to_dictionary()
	var stage_decisions := (trace_data.get("stage_decisions", []) as Array).duplicate(true)
	for key in decisions.keys():
		var key_string := str(key)
		if key_string == "archetype" or key_string == "signature":
			continue
		stage_decisions.append({
			"stage": "spatial_embedding",
			"key": key_string,
			"value": decisions[key],
			"stream": STREAM_SPATIAL,
		})
	trace_data["stage_decisions"] = stage_decisions
	return WorldgenGenerationTrace.new(trace_data)


func _failure(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return _failure_with_diagnostics([_diagnostic(code, message, context)])


func _failure_with_diagnostics(diagnostics: Array) -> Dictionary:
	return {
		"success": false,
		"embedding": {},
		"diagnostics": diagnostics.duplicate(true),
		"generation_trace": null,
		"decisions": {},
	}


func _diagnostic(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"message": message,
		"context": context.duplicate(true),
	}
