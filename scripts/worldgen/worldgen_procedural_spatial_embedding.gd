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
const ROUTE_STORAGE := "storage"
const ROUTE_SPUR := "spur"
const ROUTE_EXTRA_LOADING := "extra_loading"
const ROUTE_EXTRA_STORAGE := "extra_storage"
const ROUTE_INDUSTRIAL := "industrial"
const ROUTE_ACTIVE_STORAGE := "active_storage"
const ROUTE_OLD_YARD := "old_yard"
const ROUTE_INDUSTRIAL_EXIT := "industrial_exit"
const ROUTE_AGRICULTURAL_EXIT := "agricultural_exit"
const ROUTE_BRANCH_EXIT := "branch_exit"

const GEOMETRY_PROFILE := {
	"origin_x": 120.0,
	"main_y": 360.0,
	"entry_distance": 24.0,
	"outbound_branch_offset": 110.0,
	"outbound_curve_x": 90.0,
	"rural_switch_margin": 230.0,
	"rural_loop_offset": 76.0,
	"loop_throat_length": 100.0,
	"legacy_loop_curve_x": 76.0,
	"module_curve_x": 74.0,
	"module_gap": 44.0,
	"storage_track_length": 240.0,
	"short_storage_track_length": 190.0,
	"loading_track_length": 260.0,
	"headshunt_track_length": 210.0,
	"industrial_spur_length": 280.0,
	"goods_yard_switch_x": 310.0,
	"goods_headshunt_length_ratio": 0.72,
	"goods_headshunt_y_offset": 70.0,
	"agri_loading_y_offset": 132.0,
	"agri_loading_end_y_offset": 14.0,
	"agri_spur_curve_x": 92.0,
	"agri_spur_curve_y": 58.0,
	"agri_grain_curve_ratio": 0.42,
	"agri_grain_curve_y": 22.0,
	"agri_headshunt_length_ratio": 0.72,
	"agri_headshunt_max_length": 260.0,
	"agri_headshunt_y_offset": 82.0,
	"agri_headshunt_curve_ratio": 0.45,
	"module_parallel_offset": 72.0,
	"module_wide_offset": 118.0,
	"abandoned_gap": 42.0,
	"abandoned_track_length": 180.0,
	"abandoned_parallel_offset": 92.0,
	"valley_loop_offset": 56.0,
	"valley_platform_y_drift": 8.0,
	"valley_bridge_y_drift": 16.0,
	"valley_exit_y_drift": 24.0,
	"valley_loop_curve_x": 62.0,
	"valley_loop_end_offset_ratio": 0.9,
	"declining_yard_end_x": 220.0,
	"declining_yard_end_y": 136.0,
	"declining_storage_end_y": 18.0,
	"declining_abandoned_parallel_y": 76.0,
	"declining_abandoned_splayed_y": 116.0,
	"declining_abandoned_length_ratio": 0.68,
	"declining_abandoned_end_y": 16.0,
	"declining_removed_stub_length_ratio": 0.45,
	"declining_removed_stub_y": 46.0,
	"declining_lead_curve_x": 90.0,
	"declining_lead_curve_y": 68.0,
	"declining_storage_curve_ratio": 0.42,
	"declining_storage_curve_y": 20.0,
	"rural_main_lengths": {
		"short": 820.0,
		"medium": 980.0,
		"long": 1140.0,
	},
	"goods_yard_offset_lengths": {
		"standard": 175.0,
		"wide": 220.0,
	},
	"goods_loading_lengths": {
		"medium": 300.0,
		"long": 380.0,
	},
	"agri_west_main_lengths": {
		"short": 220.0,
		"medium": 280.0,
		"long": 340.0,
	},
	"agri_east_main_lengths": {
		"medium": 660.0,
		"long": 780.0,
	},
	"agri_spur_lengths": {
		"short": 210.0,
		"medium": 280.0,
		"long": 350.0,
	},
	"agri_loading_lengths": {
		"medium": 280.0,
		"long": 360.0,
	},
	"valley_approach_lengths": {
		"short": 200.0,
		"medium": 260.0,
	},
	"valley_station_lengths": {
		"short": 300.0,
		"medium": 360.0,
	},
	"valley_bridge_lengths": {
		"short": 150.0,
		"medium": 210.0,
	},
	"valley_exit_lengths": {
		"short": 240.0,
		"medium": 300.0,
	},
	"declining_storage_lengths": {
		"short": 250.0,
		"medium": 320.0,
		"long": 390.0,
	},
	"loop_approach_lengths": {
		"short": 240.0,
		"medium": 300.0,
		"long": 360.0,
	},
	"loop_station_lengths": {
		"medium": 380.0,
		"long": 450.0,
		"extended": 520.0,
	},
	"loop_exit_lengths": {
		"short": 280.0,
		"medium": 340.0,
		"long": 400.0,
	},
	"loop_offset_lengths": {
		"standard": 68.0,
		"wide": 86.0,
	},
}


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
	var semantic_edges := _semantic_edge_ids(blueprint)
	var decisions := _make_decisions(archetype_id, spatial_rng)
	var embedding := _make_embedding(archetype_id, decisions, semantic_edges)
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


func _semantic_edge_ids(blueprint: RefCounted) -> Dictionary:
	var edge_ids: Dictionary = {}
	if blueprint == null or not blueprint.has_method("to_dictionary"):
		return edge_ids
	var data: Dictionary = blueprint.to_dictionary()
	var rail_graph := data.get("rail_graph", {}) as Dictionary
	for edge_v in rail_graph.get("edges", []) as Array:
		var edge := edge_v as Dictionary
		var edge_id := str(edge.get("id", ""))
		if not edge_id.is_empty():
			edge_ids[edge_id] = true
	return edge_ids


func _has_edge(semantic_edges: Dictionary, edge_id: String) -> bool:
	return semantic_edges.has(edge_id)


func _g(key: String) -> float:
	return float(GEOMETRY_PROFILE.get(key, 0.0))


func _profile_length(profile_key: String, key: String) -> float:
	return _length_for(key, GEOMETRY_PROFILE.get(profile_key, {}) as Dictionary)


func _make_embedding(archetype_id: String, decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			return _make_rural_embedding(decisions, semantic_edges)
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			return _make_village_embedding(decisions, semantic_edges)
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			return _make_goods_embedding(decisions, semantic_edges)
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			return _make_agricultural_embedding(decisions, semantic_edges)
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			return _make_river_valley_embedding(decisions, semantic_edges)
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			return _make_declining_embedding(decisions, semantic_edges)
	return {}


func _make_rural_embedding(decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	var origin_x := _g("origin_x")
	var main_y := _g("main_y")
	var length := _profile_length("rural_main_lengths", str(decisions.get("main_length_class", "medium")))
	var has_loop := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_RURAL_LOOP)
	var has_storage := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_RURAL_STORAGE)
	var has_branch := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT)
	if has_loop or has_storage or has_branch:
		return _make_rural_module_embedding(decisions, length, has_loop, has_storage, has_branch)

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
		"runtime_layout_id": "generated_rural_through_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN,
		"entry_distance": _g("entry_distance"),
		"exit_segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN,
		"exit_distance": maxf(length - _g("entry_distance"), _g("entry_distance")),
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


func _make_rural_module_embedding(decisions: Dictionary, length: float, has_loop: bool, has_storage: bool, has_branch: bool = false) -> Dictionary:
	var origin_x := _g("origin_x")
	var main_y := _g("main_y")
	var exit_x := origin_x + length
	var segments: Array[Dictionary] = []
	var points: Array[Dictionary] = []
	var next_connections: Dictionary = {}
	var previous_connections: Dictionary = {}
	var route_presets: Array[Dictionary] = []
	var entry_segment := WorldgenSemanticGenerator.TRACK_RURAL_MAIN
	var exit_segment := WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN
	var exit_segment_length := _g("entry_distance")

	if has_loop:
		var west_switch := [origin_x + _g("rural_switch_margin"), main_y]
		var east_switch := [exit_x - _g("rural_switch_margin"), main_y]
		exit_segment_length = exit_x - float(east_switch[0])
		var loop_offset := -_g("rural_loop_offset")
		var loop_points := [
			west_switch,
			[float(west_switch[0]) + _g("module_curve_x"), main_y + loop_offset],
			[float(east_switch[0]) - _g("module_curve_x"), main_y + loop_offset],
			east_switch,
		]
		var west_routes := [ROUTE_MAIN, ROUTE_LOOP]
		var west_targets := {
			ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN,
			ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RURAL_LOOP,
		}
		var east_routes := [ROUTE_MAIN, ROUTE_LOOP]

		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_MAIN, [[origin_x, main_y], west_switch], "No route through rural west switch"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN, [west_switch, east_switch], "East rural switch route blocks station main"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_LOOP, WorldgenSemanticGenerator.TRACK_RURAL_LOOP, loop_points, "East rural switch route blocks passing loop"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, [east_switch, [exit_x, main_y]], "End of generated rural east exit"))

		if has_storage:
			var storage_end := [
				float(west_switch[0]) + _g("storage_track_length"),
				main_y + _g("module_wide_offset"),
			]
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_STORAGE, WorldgenSemanticGenerator.TRACK_RURAL_STORAGE, [west_switch, [float(west_switch[0]) + _g("module_curve_x"), main_y + _g("module_parallel_offset")], storage_end], "End of rural storage siding"))
			west_routes.append(ROUTE_STORAGE)
			west_targets[ROUTE_STORAGE] = WorldgenSemanticGenerator.TRACK_RURAL_STORAGE
			previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_west_switch", "requires_route": ROUTE_STORAGE}
			route_presets.append({"id": ROUTE_STORAGE, "label": "Rural storage", "routes": {"rural_west_switch": ROUTE_STORAGE}})

		if has_branch:
			var branch_end := [exit_x, main_y - _g("outbound_branch_offset")]
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT, WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT, [east_switch, [float(east_switch[0]) + _g("outbound_curve_x"), main_y - _g("outbound_branch_offset")], branch_end], "End of rural branch exit"))
			east_routes.append(ROUTE_BRANCH_EXIT)
			next_connections[WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN] = {"point": "rural_east_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, ROUTE_BRANCH_EXIT: WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT}}
			next_connections[WorldgenSemanticGenerator.TRACK_RURAL_LOOP] = {"point": "rural_east_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, ROUTE_BRANCH_EXIT: WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT}}
			previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT] = {"point": "rural_east_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RURAL_LOOP}}
			route_presets.append({"id": "rural_branch", "label": "Rural branch exit", "routes": {"rural_west_switch": ROUTE_MAIN, "rural_east_switch": ROUTE_BRANCH_EXIT}})
		else:
			next_connections[WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, "requires_point": "rural_east_switch", "requires_route": ROUTE_MAIN}
			next_connections[WorldgenSemanticGenerator.TRACK_RURAL_LOOP] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, "requires_point": "rural_east_switch", "requires_route": ROUTE_LOOP}

		points.append(_point("rural_west_switch", "rural_west_switch", west_switch, west_routes, ROUTE_MAIN))
		points.append(_point("rural_east_switch", "rural_east_switch", east_switch, east_routes, ROUTE_MAIN))
		next_connections[WorldgenSemanticGenerator.TRACK_RURAL_MAIN] = {"point": "rural_west_switch", "routes": west_targets}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_west_switch", "requires_route": ROUTE_MAIN}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_LOOP] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_west_switch", "requires_route": ROUTE_LOOP}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN] = {"point": "rural_east_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RURAL_LOOP}}
		route_presets.push_front({"id": ROUTE_LOOP, "label": "Rural passing loop", "routes": {"rural_west_switch": ROUTE_LOOP, "rural_east_switch": ROUTE_LOOP}})
		route_presets.push_front({"id": ROUTE_MAIN, "label": "Rural main", "routes": {"rural_west_switch": ROUTE_MAIN, "rural_east_switch": ROUTE_MAIN}})
	elif has_storage:
		var storage_switch := [origin_x + length * 0.42, main_y]
		exit_segment_length = exit_x - float(storage_switch[0])
		var storage_end := [
			float(storage_switch[0]) + _g("storage_track_length"),
			main_y + _g("module_wide_offset"),
		]
		var storage_routes := [ROUTE_MAIN, ROUTE_STORAGE]
		var storage_targets := {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, ROUTE_STORAGE: WorldgenSemanticGenerator.TRACK_RURAL_STORAGE}

		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_MAIN, [[origin_x, main_y], storage_switch], "No route through rural storage switch"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, [storage_switch, [exit_x, main_y]], "End of generated rural east exit"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_STORAGE, WorldgenSemanticGenerator.TRACK_RURAL_STORAGE, [storage_switch, [float(storage_switch[0]) + _g("module_curve_x"), main_y + _g("module_parallel_offset")], storage_end], "End of rural storage siding"))

		if has_branch:
			var branch_end := [exit_x, main_y - _g("outbound_branch_offset")]
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT, WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT, [storage_switch, [float(storage_switch[0]) + _g("outbound_curve_x"), main_y - _g("outbound_branch_offset")], branch_end], "End of rural branch exit"))
			storage_routes.append(ROUTE_BRANCH_EXIT)
			storage_targets[ROUTE_BRANCH_EXIT] = WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT
			previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_storage_switch", "requires_route": ROUTE_BRANCH_EXIT}
			route_presets.append({"id": "rural_branch", "label": "Rural branch exit", "routes": {"rural_storage_switch": ROUTE_BRANCH_EXIT}})

		points.append(_point("rural_storage_switch", "rural_storage_switch", storage_switch, storage_routes, ROUTE_MAIN))
		next_connections[WorldgenSemanticGenerator.TRACK_RURAL_MAIN] = {"point": "rural_storage_switch", "routes": storage_targets}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_storage_switch", "requires_route": ROUTE_MAIN}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_storage_switch", "requires_route": ROUTE_STORAGE}
		route_presets.append({"id": ROUTE_MAIN, "label": "Rural main", "routes": {"rural_storage_switch": ROUTE_MAIN}})
		route_presets.append({"id": ROUTE_STORAGE, "label": "Rural storage", "routes": {"rural_storage_switch": ROUTE_STORAGE}})
	else:
		# Plain through with outbound branch
		var junction_switch := [origin_x + length * 0.60, main_y]
		exit_segment_length = exit_x - float(junction_switch[0])
		var branch_end := [exit_x, main_y - _g("outbound_branch_offset")]

		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_MAIN, [[origin_x, main_y], junction_switch], "No route through rural junction switch"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, [junction_switch, [exit_x, main_y]], "End of generated rural through sector"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT, WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT, [junction_switch, [float(junction_switch[0]) + _g("outbound_curve_x"), main_y - _g("outbound_branch_offset")], branch_end], "End of rural branch exit"))

		points.append(_point("rural_junction_switch", "rural_junction_switch", junction_switch, [ROUTE_MAIN, ROUTE_BRANCH_EXIT], ROUTE_MAIN))
		next_connections[WorldgenSemanticGenerator.TRACK_RURAL_MAIN] = {"point": "rural_junction_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN, ROUTE_BRANCH_EXIT: WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT}}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_EXIT_MAIN] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_junction_switch", "requires_route": ROUTE_MAIN}
		previous_connections[WorldgenSemanticGenerator.TRACK_RURAL_BRANCH_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_RURAL_MAIN, "requires_point": "rural_junction_switch", "requires_route": ROUTE_BRANCH_EXIT}
		route_presets.append({"id": ROUTE_MAIN, "label": "Through main", "routes": {"rural_junction_switch": ROUTE_MAIN}})
		route_presets.append({"id": "rural_branch", "label": "Rural branch exit", "routes": {"rural_junction_switch": ROUTE_BRANCH_EXIT}})

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
		"runtime_layout_id": "generated_rural_through_%s" % str(decisions.get("signature", "")),
		"entry_segment": entry_segment,
		"entry_distance": _g("entry_distance"),
		"exit_segment": exit_segment,
		"exit_distance": maxf(exit_segment_length - _g("entry_distance"), _g("entry_distance")),
		"spatial_decisions": decisions.duplicate(true),
		"segments": segments,
		"points": points,
		"next_connections": next_connections,
		"previous_connections": previous_connections,
		"route_presets": route_presets,
	}


func _make_village_embedding(decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	var geometry := _loop_geometry(decisions)
	var west_point := geometry["west_point"] as Array
	var east_point := geometry["east_point"] as Array
	var loop_points := geometry["loop_points"] as Array
	var main_y := float(geometry["main_y"])
	var has_goods := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD)
	var has_storage := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_STATION_STORAGE)
	var has_abandoned := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_STATION_ABANDONED_STUB)
	var has_industrial_exit := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT)
	var has_agricultural_exit := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT)
	var branch_sign := 1.0
	if str(decisions.get("loop_side", "north")) == "south":
		branch_sign = -1.0

	var segments: Array[Dictionary] = [
		_segment(WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, [[geometry["origin_x"], geometry["main_y"]], west_point], "No route through west generated loop switch"),
		_segment(WorldgenSemanticGenerator.TRACK_STATION_MAIN, WorldgenSemanticGenerator.TRACK_STATION_MAIN, [west_point, east_point], "East generated loop switch route blocks station main"),
		_segment(WorldgenSemanticGenerator.TRACK_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_PASSING_LOOP, loop_points, "East generated loop switch route blocks passing loop"),
		_segment(WorldgenSemanticGenerator.TRACK_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_EXIT_MAIN, [east_point, [geometry["exit_x"], geometry["main_y"]]], "End of generated village east exit"),
	]
	var west_routes := [ROUTE_MAIN, ROUTE_LOOP]
	var west_targets := {
		ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_STATION_MAIN,
		ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP,
	}
	var east_routes := [ROUTE_MAIN, ROUTE_LOOP]
	var station_next_routes := {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_EXIT_MAIN}
	var passing_next_routes := {ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_EXIT_MAIN}
	var next_connections: Dictionary = {}
	var previous_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_STATION_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_loop_switch", "requires_route": ROUTE_MAIN, "blocked_reason": "West generated loop switch blocks station main"},
		WorldgenSemanticGenerator.TRACK_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP, "blocked_reason": "West generated loop switch blocks passing loop"},
		WorldgenSemanticGenerator.TRACK_EXIT_MAIN: {"point": "east_loop_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
	}
	var points: Array[Dictionary] = []
	var route_presets: Array[Dictionary] = [
		{"id": ROUTE_MAIN, "label": "Station main", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_MAIN}},
		{"id": ROUTE_LOOP, "label": "Passing loop", "routes": {"west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
	]

	if has_storage:
		var storage_end := [
			float(west_point[0]) + _g("short_storage_track_length"),
			main_y + _g("module_wide_offset") * branch_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_STATION_STORAGE, WorldgenSemanticGenerator.TRACK_STATION_STORAGE, [west_point, [float(west_point[0]) + _g("module_curve_x"), main_y + _g("module_parallel_offset") * branch_sign], storage_end], "End of station storage siding"))
		west_routes.append(ROUTE_STORAGE)
		west_targets[ROUTE_STORAGE] = WorldgenSemanticGenerator.TRACK_STATION_STORAGE
		previous_connections[WorldgenSemanticGenerator.TRACK_STATION_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_loop_switch", "requires_route": ROUTE_STORAGE}
		route_presets.append({"id": ROUTE_STORAGE, "label": "Station storage", "routes": {"west_loop_switch": ROUTE_STORAGE}})

	if has_goods:
		var yard_switch := [
			float(east_point[0]) + _g("module_curve_x"),
			main_y + _g("module_wide_offset") * branch_sign,
		]
		var loading_end := [float(yard_switch[0]) + _g("loading_track_length"), float(yard_switch[1])]
		var headshunt_end := [
			float(yard_switch[0]) + _g("headshunt_track_length"),
			float(yard_switch[1]) + _g("module_parallel_offset") * branch_sign,
		]
		var yard_routes := [ROUTE_LOADING, ROUTE_HEADSHUNT]
		var yard_targets := {
			ROUTE_LOADING: WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LOADING,
			ROUTE_HEADSHUNT: WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_HEADSHUNT,
		}
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD, WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD, [east_point, [float(east_point[0]) + _g("module_curve_x"), main_y + _g("module_parallel_offset") * branch_sign], yard_switch], "No route through village goods switch"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LOADING, WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LOADING, [yard_switch, loading_end], "End of village goods loading track"))
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_HEADSHUNT, WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_HEADSHUNT, [yard_switch, headshunt_end], "End of village goods headshunt"))

		if has_industrial_exit:
			var ind_end := [float(geometry["exit_x"]), main_y + _g("outbound_branch_offset") * branch_sign]
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT, WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT, [yard_switch, [float(yard_switch[0]) + _g("outbound_curve_x"), main_y + _g("outbound_branch_offset") * branch_sign], ind_end], "End of village industrial exit"))
			yard_routes.append(ROUTE_INDUSTRIAL_EXIT)
			yard_targets[ROUTE_INDUSTRIAL_EXIT] = WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT
			previous_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD, "requires_point": "village_yard_switch", "requires_route": ROUTE_INDUSTRIAL_EXIT}
			route_presets.append({"id": "village_industrial_exit", "label": "Village industrial exit", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_YARD, "village_yard_switch": ROUTE_INDUSTRIAL_EXIT}})

		east_routes.append(ROUTE_YARD)
		station_next_routes[ROUTE_YARD] = WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD
		points.append(_point("village_yard_switch", "village_yard_switch", yard_switch, yard_routes, ROUTE_LOADING))
		next_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD] = {"point": "village_yard_switch", "routes": yard_targets}
		previous_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD] = {"segment": WorldgenSemanticGenerator.TRACK_STATION_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_YARD}
		previous_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LOADING] = {"segment": WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD, "requires_point": "village_yard_switch", "requires_route": ROUTE_LOADING}
		previous_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_HEADSHUNT] = {"segment": WorldgenSemanticGenerator.TRACK_VILLAGE_GOODS_LEAD, "requires_point": "village_yard_switch", "requires_route": ROUTE_HEADSHUNT}
		route_presets.append({"id": "village_goods_loading", "label": "Village goods loading", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_YARD, "village_yard_switch": ROUTE_LOADING}})
		route_presets.append({"id": "village_headshunt", "label": "Village headshunt", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_YARD, "village_yard_switch": ROUTE_HEADSHUNT}})
	elif has_industrial_exit:
		var ind_end := [float(geometry["exit_x"]), main_y + _g("outbound_branch_offset") * branch_sign]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT, WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT, [east_point, [float(east_point[0]) + _g("outbound_curve_x"), main_y + _g("outbound_branch_offset") * branch_sign], ind_end], "End of village industrial exit"))
		east_routes.append(ROUTE_INDUSTRIAL_EXIT)
		station_next_routes[ROUTE_INDUSTRIAL_EXIT] = WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT
		passing_next_routes[ROUTE_INDUSTRIAL_EXIT] = WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT
		previous_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT] = {"point": "east_loop_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}}
		route_presets.append({"id": "village_industrial_exit", "label": "Village industrial exit", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_INDUSTRIAL_EXIT}})

	if has_agricultural_exit:
		var agri_end := [float(geometry["exit_x"]), main_y - _g("outbound_branch_offset") * branch_sign]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT, WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT, [east_point, [float(east_point[0]) + _g("outbound_curve_x"), main_y - _g("outbound_branch_offset") * branch_sign], agri_end], "End of village agricultural exit"))
		if not east_routes.has(ROUTE_AGRICULTURAL_EXIT):
			east_routes.append(ROUTE_AGRICULTURAL_EXIT)
		station_next_routes[ROUTE_AGRICULTURAL_EXIT] = WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT
		passing_next_routes[ROUTE_AGRICULTURAL_EXIT] = WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT
		previous_connections[WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT] = {"point": "east_loop_switch", "routes": {ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_STATION_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}}
		route_presets.append({"id": "village_agricultural_exit", "label": "Village agricultural exit", "routes": {"west_loop_switch": ROUTE_MAIN, "east_loop_switch": ROUTE_AGRICULTURAL_EXIT}})

	if has_abandoned:
		var abandoned_start := [
			float(east_point[0]) + _g("abandoned_gap"),
			main_y - _g("module_parallel_offset") * branch_sign,
		]
		var abandoned_end := [
			float(abandoned_start[0]) + _g("abandoned_track_length"),
			float(abandoned_start[1]) - _g("abandoned_parallel_offset") * branch_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_STATION_ABANDONED_STUB, WorldgenSemanticGenerator.TRACK_STATION_ABANDONED_STUB, [abandoned_start, abandoned_end], "Abandoned station stub is not routable", "display_only"))

	points.push_front(_point("east_loop_switch", "east_loop_switch", east_point, east_routes, ROUTE_MAIN))
	points.push_front(_point("west_loop_switch", "west_loop_switch", west_point, west_routes, ROUTE_MAIN))
	next_connections[WorldgenSemanticGenerator.TRACK_APPROACH_MAIN] = {"point": "west_loop_switch", "routes": west_targets}
	next_connections[WorldgenSemanticGenerator.TRACK_STATION_MAIN] = {"point": "east_loop_switch", "routes": station_next_routes}
	next_connections[WorldgenSemanticGenerator.TRACK_PASSING_LOOP] = {"point": "east_loop_switch", "routes": passing_next_routes}

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
		"runtime_layout_id": "generated_village_passing_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN,
		"entry_distance": _g("entry_distance"),
		"exit_segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN,
		"exit_distance": float(geometry["exit_distance"]),
		"spatial_decisions": decisions.duplicate(true),
		"segments": segments,
		"points": points,
		"next_connections": next_connections,
		"previous_connections": previous_connections,
		"route_presets": route_presets,
	}


func _make_goods_embedding(decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	var geometry := _loop_geometry(decisions)
	var main_y := float(geometry["main_y"])
	var west_yard := geometry["west_point"] as Array
	var west_loop := [float(west_yard[0]) + _g("loop_throat_length"), float(west_yard[1])]
	var east_loop := geometry["east_point"] as Array
	var loop_points := [
		west_loop,
		[float(west_loop[0]) + _g("legacy_loop_curve_x"), float((geometry["loop_points"] as Array)[1][1])],
		[float(east_loop[0]) - _g("legacy_loop_curve_x"), float((geometry["loop_points"] as Array)[1][1])],
		east_loop,
	]
	var yard_offset := _profile_length("goods_yard_offset_lengths", str(decisions.get("yard_offset_class", "standard")))
	var yard_sign := 1.0
	if str(decisions.get("loop_side", "north")) == "south":
		yard_sign = -1.0
	var yard_switch := [float(west_yard[0]) + _g("goods_yard_switch_x"), float(west_yard[1]) + yard_offset * yard_sign]
	var loading_length := _profile_length("goods_loading_lengths", str(decisions.get("goods_length_class", "medium")))
	var loading_end := [float(yard_switch[0]) + loading_length, float(yard_switch[1])]
	var headshunt_end := [float(yard_switch[0]) + loading_length * _g("goods_headshunt_length_ratio"), float(yard_switch[1]) + _g("goods_headshunt_y_offset") * yard_sign]
	var has_extra_storage := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE)
	var has_industrial := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR)
	var has_abandoned := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_TOWN_ABANDONED_REMNANT)
	var has_industrial_exit := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_EXIT)
	var has_agricultural_exit := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT)

	var segments: Array[Dictionary] = [
		_segment(WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, [[geometry["origin_x"], geometry["main_y"]], west_yard], "No route through west yard switch"),
		_segment("west_station_throat", "", [west_yard, west_loop], "No route through west loop switch"),
		_segment(WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, [west_loop, east_loop], "East loop switch route blocks platform main"),
		_segment(WorldgenSemanticGenerator.TRACK_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_PASSING_LOOP, loop_points, "East loop switch route blocks passing loop"),
		_segment(WorldgenSemanticGenerator.TRACK_EXIT_MAIN, WorldgenSemanticGenerator.TRACK_EXIT_MAIN, [east_loop, [geometry["exit_x"], geometry["main_y"]]], "End of generated goods east exit"),
		_segment(WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, [west_yard, [float(west_yard[0]) + _g("module_curve_x"), float(west_yard[1]) + _g("module_gap") * yard_sign], yard_switch], "No route through generated yard switch"),
		_segment(WorldgenSemanticGenerator.TRACK_GOODS_LOADING, WorldgenSemanticGenerator.TRACK_GOODS_LOADING, [yard_switch, loading_end], "End of generated goods loading buffer"),
		_segment(WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT, WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT, [yard_switch, headshunt_end], "End of generated yard headshunt buffer"),
	]
	var yard_routes := [ROUTE_LOADING, ROUTE_HEADSHUNT]
	var yard_targets := {
		ROUTE_LOADING: WorldgenSemanticGenerator.TRACK_GOODS_LOADING,
		ROUTE_HEADSHUNT: WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT,
	}
	var east_loop_routes := [ROUTE_PLATFORM, ROUTE_LOOP]
	var platform_next_routes := {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_EXIT_MAIN}
	var passing_next_routes := {ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_EXIT_MAIN}
	var next_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_APPROACH_MAIN: {"point": "west_yard_switch", "routes": {ROUTE_MAIN: "west_station_throat", ROUTE_YARD: WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD}},
		"west_station_throat": {"point": "west_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
	}
	var previous_connections: Dictionary = {
		"west_station_throat": {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_yard_switch", "requires_route": ROUTE_MAIN},
		WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD: {"segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN, "requires_point": "west_yard_switch", "requires_route": ROUTE_YARD},
		WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN: {"segment": "west_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_PLATFORM},
		WorldgenSemanticGenerator.TRACK_PASSING_LOOP: {"segment": "west_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP},
		WorldgenSemanticGenerator.TRACK_EXIT_MAIN: {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}},
		WorldgenSemanticGenerator.TRACK_GOODS_LOADING: {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_LOADING},
		WorldgenSemanticGenerator.TRACK_YARD_HEADSHUNT: {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_HEADSHUNT},
	}
	var route_presets: Array[Dictionary] = [
		{"id": ROUTE_MAIN, "label": "Platform main", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_PLATFORM}},
		{"id": ROUTE_LOOP, "label": "Passing loop", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
		{"id": "goods_loading", "label": "Goods loading", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_LOADING}},
		{"id": "headshunt", "label": "Yard headshunt", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_HEADSHUNT}},
	]

	if has_extra_storage:
		var extra_storage_end := [
			float(yard_switch[0]) + _g("storage_track_length"),
			float(yard_switch[1]) - _g("module_parallel_offset") * yard_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE, WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE, [yard_switch, [float(yard_switch[0]) + _g("module_curve_x"), float(yard_switch[1]) - _g("module_parallel_offset") * yard_sign], extra_storage_end], "End of extra goods storage"))
		yard_routes.append(ROUTE_EXTRA_STORAGE)
		yard_targets[ROUTE_EXTRA_STORAGE] = WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE
		previous_connections[WorldgenSemanticGenerator.TRACK_EXTRA_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_EXTRA_STORAGE}
		route_presets.append({"id": ROUTE_EXTRA_STORAGE, "label": "Extra storage", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_EXTRA_STORAGE}})

	if has_industrial:
		var industrial_end := [
			float(yard_switch[0]) + _g("industrial_spur_length"),
			float(yard_switch[1]) + _g("module_wide_offset") * yard_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR, [yard_switch, [float(yard_switch[0]) + _g("module_curve_x"), float(yard_switch[1]) + _g("module_parallel_offset") * yard_sign], industrial_end], "End of town industrial spur"))
		yard_routes.append(ROUTE_INDUSTRIAL)
		yard_targets[ROUTE_INDUSTRIAL] = WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR
		previous_connections[WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_SPUR] = {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_INDUSTRIAL}
		route_presets.append({"id": ROUTE_INDUSTRIAL, "label": "Industrial spur", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_INDUSTRIAL}})

	if has_industrial_exit:
		var ind_end := [float(geometry["exit_x"]), main_y + _g("outbound_branch_offset") * yard_sign]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_EXIT, WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_EXIT, [yard_switch, [float(yard_switch[0]) + _g("outbound_curve_x"), main_y + _g("outbound_branch_offset") * yard_sign], ind_end], "End of town industrial exit"))
		yard_routes.append(ROUTE_INDUSTRIAL_EXIT)
		yard_targets[ROUTE_INDUSTRIAL_EXIT] = WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_EXIT
		previous_connections[WorldgenSemanticGenerator.TRACK_TOWN_INDUSTRIAL_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD, "requires_point": "yard_switch", "requires_route": ROUTE_INDUSTRIAL_EXIT}
		route_presets.append({"id": "town_industrial_exit", "label": "Industrial branch exit", "routes": {"west_yard_switch": ROUTE_YARD, "yard_switch": ROUTE_INDUSTRIAL_EXIT}})

	if has_agricultural_exit:
		var agri_end := [float(geometry["exit_x"]), main_y - _g("outbound_branch_offset") * yard_sign]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT, WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT, [east_loop, [float(east_loop[0]) + _g("outbound_curve_x"), main_y - _g("outbound_branch_offset") * yard_sign], agri_end], "End of town agricultural exit"))
		east_loop_routes.append(ROUTE_AGRICULTURAL_EXIT)
		platform_next_routes[ROUTE_AGRICULTURAL_EXIT] = WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT
		passing_next_routes[ROUTE_AGRICULTURAL_EXIT] = WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT
		previous_connections[WorldgenSemanticGenerator.TRACK_TOWN_AGRICULTURAL_EXIT] = {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_PASSING_LOOP}}
		route_presets.append({"id": "town_agricultural_exit", "label": "Agricultural branch exit", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_AGRICULTURAL_EXIT}})

	if has_abandoned:
		var abandoned_start := [
			float(yard_switch[0]) + _g("abandoned_gap"),
			float(yard_switch[1]) - _g("module_wide_offset") * yard_sign,
		]
		var abandoned_end := [
			float(abandoned_start[0]) + _g("abandoned_track_length"),
			float(abandoned_start[1]) - _g("abandoned_parallel_offset") * yard_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_TOWN_ABANDONED_REMNANT, WorldgenSemanticGenerator.TRACK_TOWN_ABANDONED_REMNANT, [abandoned_start, abandoned_end], "Town abandoned remnant is not routable", "display_only"))

	next_connections[WorldgenSemanticGenerator.TRACK_GOODS_YARD_LEAD] = {"point": "yard_switch", "routes": yard_targets}
	next_connections[WorldgenSemanticGenerator.TRACK_PLATFORM_MAIN] = {"point": "east_loop_switch", "routes": platform_next_routes}
	next_connections[WorldgenSemanticGenerator.TRACK_PASSING_LOOP] = {"point": "east_loop_switch", "routes": passing_next_routes}

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
		"runtime_layout_id": "generated_small_town_goods_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_APPROACH_MAIN,
		"entry_distance": _g("entry_distance"),
		"exit_segment": WorldgenSemanticGenerator.TRACK_EXIT_MAIN,
		"exit_distance": float(geometry["exit_distance"]),
		"spatial_decisions": decisions.duplicate(true),
		"segments": segments,
		"points": [
			_point("west_yard_switch", "west_loop_switch", west_yard, [ROUTE_MAIN, ROUTE_YARD], ROUTE_MAIN),
			_point("west_loop_switch", "west_loop_switch", west_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
			_point("east_loop_switch", "east_loop_switch", east_loop, east_loop_routes, ROUTE_PLATFORM),
			_point("yard_switch", "yard_switch", yard_switch, yard_routes, ROUTE_LOADING),
		],
		"next_connections": next_connections,
		"previous_connections": previous_connections,
		"route_presets": route_presets,
	}


func _make_agricultural_embedding(decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	var origin_x := _g("origin_x")
	var main_y := _g("main_y")
	var west_length := _profile_length("agri_west_main_lengths", str(decisions.get("main_west_length_class", "medium")))
	var east_length := _profile_length("agri_east_main_lengths", str(decisions.get("main_east_length_class", "medium")))
	var spur_length := _profile_length("agri_spur_lengths", str(decisions.get("spur_length_class", "medium")))
	var loading_length := _profile_length("agri_loading_lengths", str(decisions.get("loading_length_class", "medium")))
	var spur_sign := -1.0
	if str(decisions.get("spur_side", "south")) == "south":
		spur_sign = 1.0
	var spur_switch := [origin_x + west_length, main_y]
	var loading_switch := [float(spur_switch[0]) + spur_length, main_y + _g("agri_loading_y_offset") * spur_sign]
	var loading_end := [float(loading_switch[0]) + loading_length, float(loading_switch[1]) + _g("agri_loading_end_y_offset") * spur_sign]
	var headshunt_length := minf(loading_length * _g("agri_headshunt_length_ratio"), _g("agri_headshunt_max_length"))
	var headshunt_end := [float(loading_switch[0]) + headshunt_length, float(loading_switch[1]) + _g("agri_headshunt_y_offset") * spur_sign]
	var has_headshunt := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND)
	var has_storage := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_AGRI_STORAGE)
	var has_extra_loading := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_AGRI_EXTRA_LOADING)
	var has_agri_exit := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_AGRI_BRANCH_EXIT)

	var segments: Array[Dictionary] = [
		_segment(WorldgenSemanticGenerator.TRACK_MAIN_WEST, WorldgenSemanticGenerator.TRACK_MAIN_WEST, [[origin_x, main_y], spur_switch], "No route through agricultural spur switch"),
		_segment(WorldgenSemanticGenerator.TRACK_MAIN_EAST, WorldgenSemanticGenerator.TRACK_MAIN_EAST, [spur_switch, [float(spur_switch[0]) + east_length, main_y]], "End of agricultural east exit"),
		_segment(WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, [spur_switch, [float(spur_switch[0]) + _g("agri_spur_curve_x"), main_y + _g("agri_spur_curve_y") * spur_sign], loading_switch], "No route through agricultural loading switch"),
		_segment(WorldgenSemanticGenerator.TRACK_GRAIN_LOADING, WorldgenSemanticGenerator.TRACK_GRAIN_LOADING, [loading_switch, [float(loading_switch[0]) + loading_length * _g("agri_grain_curve_ratio"), float(loading_switch[1]) + _g("agri_grain_curve_y") * spur_sign], loading_end], "End of grain loading buffer"),
	]
	var points: Array[Dictionary] = []
	var spur_routes := [ROUTE_MAIN, ROUTE_SPUR]
	var spur_targets := {
		ROUTE_MAIN: WorldgenSemanticGenerator.TRACK_MAIN_EAST,
		ROUTE_SPUR: WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR,
	}
	var next_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_MAIN_WEST: {"point": "spur_switch", "routes": spur_targets},
	}
	var previous_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_MAIN_EAST: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "spur_switch", "requires_route": ROUTE_MAIN},
		WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "spur_switch", "requires_route": ROUTE_SPUR},
	}
	var route_presets: Array[Dictionary] = [
		{"id": ROUTE_MAIN, "label": "Through main", "routes": {"spur_switch": ROUTE_MAIN}},
		{"id": "grain_loading", "label": "Grain loading", "routes": {"spur_switch": ROUTE_SPUR}},
	]

	if has_storage:
		var storage_end := [
			float(spur_switch[0]) + _g("short_storage_track_length"),
			main_y - _g("module_wide_offset") * spur_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_AGRI_STORAGE, WorldgenSemanticGenerator.TRACK_AGRI_STORAGE, [spur_switch, [float(spur_switch[0]) + _g("module_curve_x"), main_y - _g("module_parallel_offset") * spur_sign], storage_end], "End of agricultural storage siding"))
		spur_routes.append(ROUTE_STORAGE)
		spur_targets[ROUTE_STORAGE] = WorldgenSemanticGenerator.TRACK_AGRI_STORAGE
		previous_connections[WorldgenSemanticGenerator.TRACK_AGRI_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "spur_switch", "requires_route": ROUTE_STORAGE}
		route_presets.append({"id": ROUTE_STORAGE, "label": "Agricultural storage", "routes": {"spur_switch": ROUTE_STORAGE}})

	if has_headshunt or has_extra_loading or has_agri_exit:
		var loading_routes := [ROUTE_LOADING]
		var loading_targets := {ROUTE_LOADING: WorldgenSemanticGenerator.TRACK_GRAIN_LOADING}
		if has_headshunt:
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND, WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND, [loading_switch, [float(loading_switch[0]) + headshunt_length * _g("agri_headshunt_curve_ratio"), float(loading_switch[1]) + _g("module_parallel_offset") * spur_sign], headshunt_end], "End of agricultural headshunt buffer"))
			loading_routes.append(ROUTE_HEADSHUNT)
			loading_targets[ROUTE_HEADSHUNT] = WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND
			previous_connections[WorldgenSemanticGenerator.TRACK_SHORT_RUNAROUND] = {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, "requires_point": "loading_switch", "requires_route": ROUTE_HEADSHUNT}
			route_presets.append({"id": "headshunt", "label": "Short headshunt", "routes": {"spur_switch": ROUTE_SPUR, "loading_switch": ROUTE_HEADSHUNT}})
		if has_extra_loading:
			var extra_loading_end := [
				float(loading_switch[0]) + _g("loading_track_length"),
				float(loading_switch[1]) - _g("module_parallel_offset") * spur_sign,
			]
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_AGRI_EXTRA_LOADING, WorldgenSemanticGenerator.TRACK_AGRI_EXTRA_LOADING, [loading_switch, [float(loading_switch[0]) + _g("module_curve_x"), float(loading_switch[1]) - _g("module_parallel_offset") * spur_sign], extra_loading_end], "End of extra agricultural loading track"))
			loading_routes.append(ROUTE_EXTRA_LOADING)
			loading_targets[ROUTE_EXTRA_LOADING] = WorldgenSemanticGenerator.TRACK_AGRI_EXTRA_LOADING
			previous_connections[WorldgenSemanticGenerator.TRACK_AGRI_EXTRA_LOADING] = {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, "requires_point": "loading_switch", "requires_route": ROUTE_EXTRA_LOADING}
			route_presets.append({"id": ROUTE_EXTRA_LOADING, "label": "Extra loading", "routes": {"spur_switch": ROUTE_SPUR, "loading_switch": ROUTE_EXTRA_LOADING}})
		if has_agri_exit:
			var agri_exit_x := float(spur_switch[0]) + east_length
			segments.append(_segment(WorldgenSemanticGenerator.TRACK_AGRI_BRANCH_EXIT, WorldgenSemanticGenerator.TRACK_AGRI_BRANCH_EXIT, [loading_switch, [float(loading_switch[0]) + _g("outbound_curve_x"), float(loading_switch[1])], [agri_exit_x, float(loading_switch[1])]], "End of agricultural branch exit"))
			loading_routes.append(ROUTE_AGRICULTURAL_EXIT)
			loading_targets[ROUTE_AGRICULTURAL_EXIT] = WorldgenSemanticGenerator.TRACK_AGRI_BRANCH_EXIT
			previous_connections[WorldgenSemanticGenerator.TRACK_AGRI_BRANCH_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, "requires_point": "loading_switch", "requires_route": ROUTE_AGRICULTURAL_EXIT}
			route_presets.append({"id": "agri_branch_exit", "label": "Agricultural branch exit", "routes": {"spur_switch": ROUTE_SPUR, "loading_switch": ROUTE_AGRICULTURAL_EXIT}})
		points.append(_point("loading_switch", "loading_switch", loading_switch, loading_routes, ROUTE_LOADING))
		next_connections[WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR] = {"point": "loading_switch", "routes": loading_targets}
		previous_connections[WorldgenSemanticGenerator.TRACK_GRAIN_LOADING] = {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR, "requires_point": "loading_switch", "requires_route": ROUTE_LOADING}
	else:
		next_connections[WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR] = {"segment": WorldgenSemanticGenerator.TRACK_GRAIN_LOADING}
		previous_connections[WorldgenSemanticGenerator.TRACK_GRAIN_LOADING] = {"segment": WorldgenSemanticGenerator.TRACK_AGRICULTURAL_SPUR}

	points.push_front(_point("spur_switch", "spur_switch", spur_switch, spur_routes, ROUTE_MAIN))

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
		"runtime_layout_id": "generated_agricultural_loading_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST,
		"entry_distance": _g("entry_distance"),
		"exit_segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST,
		"exit_distance": maxf(east_length - _g("entry_distance"), _g("entry_distance")),
		"spatial_decisions": decisions.duplicate(true),
		"segments": segments,
		"points": points,
		"next_connections": next_connections,
		"previous_connections": previous_connections,
		"route_presets": route_presets,
	}


func _make_river_valley_embedding(decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	var origin_x := _g("origin_x")
	var main_y := _g("main_y")
	var approach_length := _profile_length("valley_approach_lengths", str(decisions.get("approach_length_class", "short")))
	var station_length := _profile_length("valley_station_lengths", str(decisions.get("station_length_class", "short")))
	var bridge_length := _profile_length("valley_bridge_lengths", str(decisions.get("bridge_length_class", "short")))
	var exit_length := _profile_length("valley_exit_lengths", str(decisions.get("exit_length_class", "short")))
	var loop_offset := -_g("valley_loop_offset")
	if str(decisions.get("loop_side", "south")) == "south":
		loop_offset = _g("valley_loop_offset")
	var west_point := [origin_x + approach_length, main_y]
	var east_point := [float(west_point[0]) + station_length, main_y - _g("valley_platform_y_drift")]
	var bridge_joint := [float(east_point[0]) + bridge_length, main_y - _g("valley_bridge_y_drift")]
	var exit_end := [float(bridge_joint[0]) + exit_length, main_y - _g("valley_exit_y_drift")]
	var has_storage := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_VALLEY_STORAGE)
	var has_valley_branch := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT)
	var west_routes := [ROUTE_PLATFORM, ROUTE_LOOP]
	var west_targets := {
		ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN,
		ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP,
	}
	var east_routes := [ROUTE_PLATFORM, ROUTE_LOOP]
	var segments: Array[Dictionary] = [
		_segment(WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, [[origin_x, main_y], west_point], "No route through west valley loop switch"),
		_segment(WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, [west_point, east_point], "East valley switch route blocks platform main"),
		_segment(WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP, [west_point, [float(west_point[0]) + _g("valley_loop_curve_x"), main_y + loop_offset], [float(east_point[0]) - _g("valley_loop_curve_x"), main_y + loop_offset * _g("valley_loop_end_offset_ratio")], east_point], "East valley switch route blocks short passing loop"),
		_segment(WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, [east_point, bridge_joint], "End of bridge approach"),
		_segment(WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST, WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST, [bridge_joint, exit_end], "End of valley east exit"),
	]
	var previous_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, "requires_point": "west_loop_switch", "requires_route": ROUTE_PLATFORM},
		WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP},
		WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN: {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP}},
		WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST: {"segment": WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN},
	}
	var next_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST: {"point": "west_loop_switch", "routes": west_targets},
		WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST},
	}
	var route_presets: Array[Dictionary] = [
		{"id": ROUTE_MAIN, "label": "Constrained main", "routes": {"west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_PLATFORM}},
		{"id": ROUTE_LOOP, "label": "Short passing loop", "routes": {"west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
	]

	if has_valley_branch:
		var river_sign := 1.0 if str(decisions.get("loop_side", "south")) == "south" else -1.0
		var branch_end := [float(exit_end[0]), main_y - _g("outbound_branch_offset") * river_sign]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT, WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT, [east_point, [float(east_point[0]) + _g("outbound_curve_x"), main_y - _g("outbound_branch_offset") * river_sign], branch_end], "End of valley branch exit"))
		east_routes.append(ROUTE_BRANCH_EXIT)
		next_connections[WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN] = {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, ROUTE_BRANCH_EXIT: WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT}}
		next_connections[WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP] = {"point": "east_loop_switch", "routes": {ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, ROUTE_BRANCH_EXIT: WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT}}
		previous_connections[WorldgenSemanticGenerator.TRACK_VALLEY_BRANCH_EXIT] = {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP}}
		route_presets.append({"id": "valley_branch", "label": "High valley branch", "routes": {"west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_BRANCH_EXIT}})
	else:
		next_connections[WorldgenSemanticGenerator.TRACK_VALLEY_PLATFORM_MAIN] = {"segment": WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_PLATFORM}
		next_connections[WorldgenSemanticGenerator.TRACK_SHORT_PASSING_LOOP] = {"segment": WorldgenSemanticGenerator.TRACK_CREEK_BRIDGE_MAIN, "requires_point": "east_loop_switch", "requires_route": ROUTE_LOOP}

	if has_storage:
		var storage_end := [
			float(west_point[0]) + _g("short_storage_track_length"),
			main_y - _g("module_wide_offset"),
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_VALLEY_STORAGE, WorldgenSemanticGenerator.TRACK_VALLEY_STORAGE, [west_point, [float(west_point[0]) + _g("module_curve_x"), main_y - _g("module_parallel_offset")], storage_end], "End of valley storage siding"))
		west_routes.append(ROUTE_STORAGE)
		west_targets[ROUTE_STORAGE] = WorldgenSemanticGenerator.TRACK_VALLEY_STORAGE
		previous_connections[WorldgenSemanticGenerator.TRACK_VALLEY_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST, "requires_point": "west_loop_switch", "requires_route": ROUTE_STORAGE}
		route_presets.append({"id": ROUTE_STORAGE, "label": "Valley storage", "routes": {"west_loop_switch": ROUTE_STORAGE}})

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED,
		"runtime_layout_id": "generated_river_valley_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_WEST,
		"entry_distance": _g("entry_distance"),
		"exit_segment": WorldgenSemanticGenerator.TRACK_VALLEY_MAIN_EAST,
		"exit_distance": maxf(exit_length - _g("entry_distance"), _g("entry_distance")),
		"spatial_decisions": decisions.duplicate(true),
		"segments": segments,
		"points": [
			_point("west_loop_switch", "west_loop_switch", west_point, west_routes, ROUTE_PLATFORM),
			_point("east_loop_switch", "east_loop_switch", east_point, east_routes, ROUTE_PLATFORM),
		],
		"next_connections": next_connections,
		"previous_connections": previous_connections,
		"route_presets": route_presets,
	}


func _make_declining_embedding(decisions: Dictionary, semantic_edges: Dictionary) -> Dictionary:
	var geometry := _loop_geometry(decisions)
	var main_y := float(geometry["main_y"])
	var west_yard := geometry["west_point"] as Array
	var west_loop := [float(west_yard[0]) + _g("loop_throat_length"), float(west_yard[1])]
	var east_loop := geometry["east_point"] as Array
	var loop_points := [
		west_loop,
		[float(west_loop[0]) + _g("legacy_loop_curve_x"), float((geometry["loop_points"] as Array)[1][1])],
		[float(east_loop[0]) - _g("legacy_loop_curve_x"), float((geometry["loop_points"] as Array)[1][1])],
		east_loop,
	]
	var yard_sign := -1.0
	if str(decisions.get("yard_side", "south")) == "south":
		yard_sign = 1.0
	var storage_length := _profile_length("declining_storage_lengths", str(decisions.get("storage_length_class", "medium")))
	var yard_end := [float(west_yard[0]) + _g("declining_yard_end_x"), float(west_yard[1]) + _g("declining_yard_end_y") * yard_sign]
	var storage_end := [float(yard_end[0]) + storage_length, float(yard_end[1]) + _g("declining_storage_end_y") * yard_sign]
	var abandoned_y_offset := _g("declining_abandoned_parallel_y")
	if str(decisions.get("abandoned_shape", "parallel")) == "splayed":
		abandoned_y_offset = _g("declining_abandoned_splayed_y")
	var abandoned_start := [
		float(yard_end[0]) + _g("abandoned_gap"),
		float(yard_end[1]) + abandoned_y_offset * yard_sign,
	]
	var abandoned_end := [float(abandoned_start[0]) + storage_length * _g("declining_abandoned_length_ratio"), float(abandoned_start[1]) + _g("declining_abandoned_end_y") * yard_sign]
	var removed_stub_start := [
		float(yard_end[0]) + _g("abandoned_gap"),
		float(yard_end[1]) - _g("module_parallel_offset") * yard_sign,
	]
	var removed_stub := [float(removed_stub_start[0]) + _g("abandoned_track_length") * _g("declining_removed_stub_length_ratio"), float(removed_stub_start[1]) - _g("declining_removed_stub_y") * yard_sign]
	var has_extra_abandoned := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_BRANCH_EXTRA_ABANDONED)
	var has_active_storage := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_BRANCH_ACTIVE_STORAGE)
	var has_freight_exit := _has_edge(semantic_edges, WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT)

	var segments: Array[Dictionary] = [
		_segment(WorldgenSemanticGenerator.TRACK_MAIN_WEST, WorldgenSemanticGenerator.TRACK_MAIN_WEST, [[geometry["origin_x"], geometry["main_y"]], west_yard], "No route through west declining yard switch"),
		_segment("declining_station_throat", "", [west_yard, west_loop], "No route through west declining loop switch"),
		_segment(WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, [west_loop, east_loop], "East loop switch route blocks worn platform main"),
		_segment(WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP, WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP, loop_points, "East loop switch route blocks rusty passing loop"),
		_segment(WorldgenSemanticGenerator.TRACK_MAIN_EAST, WorldgenSemanticGenerator.TRACK_MAIN_EAST, [east_loop, [geometry["exit_x"], geometry["main_y"]]], "End of declining branch east exit"),
		_segment(WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, [west_yard, [float(west_yard[0]) + _g("declining_lead_curve_x"), float(west_yard[1]) + _g("declining_lead_curve_y") * yard_sign], yard_end], "End of old goods lead"),
		_segment(WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE, WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE, [yard_end, [float(yard_end[0]) + storage_length * _g("declining_storage_curve_ratio"), float(yard_end[1]) + _g("declining_storage_curve_y") * yard_sign], storage_end], "End of overgrown storage buffer"),
		_segment(WorldgenSemanticGenerator.TRACK_ABANDONED_LOADING_TRACK, WorldgenSemanticGenerator.TRACK_ABANDONED_LOADING_TRACK, [abandoned_start, abandoned_end], "Abandoned loading track is not routable", "display_only"),
		_segment(WorldgenSemanticGenerator.TRACK_REMOVED_BRANCH_STUB, WorldgenSemanticGenerator.TRACK_REMOVED_BRANCH_STUB, [removed_stub_start, removed_stub], "Removed branch stub is not routable", "display_only"),
	]
	var points: Array[Dictionary] = [
		_point("west_yard_switch", "west_loop_switch", west_yard, [ROUTE_MAIN, ROUTE_OLD_YARD], ROUTE_MAIN),
		_point("west_loop_switch", "west_loop_switch", west_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
		_point("east_loop_switch", "east_loop_switch", east_loop, [ROUTE_PLATFORM, ROUTE_LOOP], ROUTE_PLATFORM),
	]
	var next_connections: Dictionary = {
		WorldgenSemanticGenerator.TRACK_MAIN_WEST: {"point": "west_yard_switch", "routes": {ROUTE_MAIN: "declining_station_throat", ROUTE_OLD_YARD: WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD}},
		"declining_station_throat": {"point": "west_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP}},
		WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST, "requires_point": "east_loop_switch", "requires_route": ROUTE_PLATFORM},
		WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST, "requires_point": "east_loop_switch", "requires_route": ROUTE_LOOP},
	}
	var previous_connections: Dictionary = {
		"declining_station_throat": {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "west_yard_switch", "requires_route": ROUTE_MAIN},
		WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD: {"segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST, "requires_point": "west_yard_switch", "requires_route": ROUTE_OLD_YARD},
		WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN: {"segment": "declining_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_PLATFORM},
		WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP: {"segment": "declining_station_throat", "requires_point": "west_loop_switch", "requires_route": ROUTE_LOOP},
		WorldgenSemanticGenerator.TRACK_MAIN_EAST: {"point": "east_loop_switch", "routes": {ROUTE_PLATFORM: WorldgenSemanticGenerator.TRACK_WORN_PLATFORM_MAIN, ROUTE_LOOP: WorldgenSemanticGenerator.TRACK_RUSTY_PASSING_LOOP}},
	}
	var route_presets: Array[Dictionary] = [
		{"id": ROUTE_MAIN, "label": "Worn platform main", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_PLATFORM, "east_loop_switch": ROUTE_PLATFORM}},
		{"id": ROUTE_LOOP, "label": "Rusty passing loop", "routes": {"west_yard_switch": ROUTE_MAIN, "west_loop_switch": ROUTE_LOOP, "east_loop_switch": ROUTE_LOOP}},
	]

	if has_freight_exit:
		var freight_end := [float(geometry["exit_x"]), main_y + _g("outbound_branch_offset") * yard_sign]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT, WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT, [yard_end, [float(yard_end[0]) + _g("outbound_curve_x"), main_y + _g("outbound_branch_offset") * yard_sign], freight_end], "End of declining freight exit"))

	if has_active_storage:
		var active_storage_end := [
			float(yard_end[0]) + _g("storage_track_length"),
			float(yard_end[1]) - _g("module_parallel_offset") * yard_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_BRANCH_ACTIVE_STORAGE, WorldgenSemanticGenerator.TRACK_BRANCH_ACTIVE_STORAGE, [yard_end, [float(yard_end[0]) + _g("module_curve_x"), float(yard_end[1]) - _g("module_parallel_offset") * yard_sign], active_storage_end], "End of active branch storage"))
		var old_yard_routes := [ROUTE_STORAGE, ROUTE_ACTIVE_STORAGE]
		var old_yard_targets := {ROUTE_STORAGE: WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE, ROUTE_ACTIVE_STORAGE: WorldgenSemanticGenerator.TRACK_BRANCH_ACTIVE_STORAGE}
		if has_freight_exit:
			old_yard_routes.append(ROUTE_INDUSTRIAL_EXIT)
			old_yard_targets[ROUTE_INDUSTRIAL_EXIT] = WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT
			previous_connections[WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, "requires_point": "old_yard_switch", "requires_route": ROUTE_INDUSTRIAL_EXIT}
			route_presets.append({"id": "declining_freight_exit", "label": "Freight branch exit", "routes": {"west_yard_switch": ROUTE_OLD_YARD, "old_yard_switch": ROUTE_INDUSTRIAL_EXIT}})
		points.append(_point("old_yard_switch", "old_yard_switch", yard_end, old_yard_routes, ROUTE_STORAGE))
		next_connections[WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD] = {"point": "old_yard_switch", "routes": old_yard_targets}
		previous_connections[WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, "requires_point": "old_yard_switch", "requires_route": ROUTE_STORAGE}
		previous_connections[WorldgenSemanticGenerator.TRACK_BRANCH_ACTIVE_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, "requires_point": "old_yard_switch", "requires_route": ROUTE_ACTIVE_STORAGE}
		route_presets.append({"id": "old_storage", "label": "Overgrown storage", "routes": {"west_yard_switch": ROUTE_OLD_YARD, "old_yard_switch": ROUTE_STORAGE}})
		route_presets.append({"id": ROUTE_ACTIVE_STORAGE, "label": "Active storage", "routes": {"west_yard_switch": ROUTE_OLD_YARD, "old_yard_switch": ROUTE_ACTIVE_STORAGE}})
	elif has_freight_exit:
		var old_yard_routes := [ROUTE_STORAGE, ROUTE_INDUSTRIAL_EXIT]
		var old_yard_targets := {ROUTE_STORAGE: WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE, ROUTE_INDUSTRIAL_EXIT: WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT}
		points.append(_point("old_yard_switch", "old_yard_switch", yard_end, old_yard_routes, ROUTE_STORAGE))
		next_connections[WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD] = {"point": "old_yard_switch", "routes": old_yard_targets}
		previous_connections[WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, "requires_point": "old_yard_switch", "requires_route": ROUTE_STORAGE}
		previous_connections[WorldgenSemanticGenerator.TRACK_BRANCH_FREIGHT_EXIT] = {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD, "requires_point": "old_yard_switch", "requires_route": ROUTE_INDUSTRIAL_EXIT}
		route_presets.append({"id": "old_storage", "label": "Overgrown storage", "routes": {"west_yard_switch": ROUTE_OLD_YARD, "old_yard_switch": ROUTE_STORAGE}})
		route_presets.append({"id": "declining_freight_exit", "label": "Freight branch exit", "routes": {"west_yard_switch": ROUTE_OLD_YARD, "old_yard_switch": ROUTE_INDUSTRIAL_EXIT}})
	else:
		next_connections[WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD] = {"segment": WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE}
		previous_connections[WorldgenSemanticGenerator.TRACK_OVERGROWN_STORAGE] = {"segment": WorldgenSemanticGenerator.TRACK_OLD_GOODS_LEAD}
		route_presets.append({"id": "old_storage", "label": "Overgrown storage", "routes": {"west_yard_switch": ROUTE_OLD_YARD}})

	if has_extra_abandoned:
		var extra_abandoned_start := [
			float(yard_end[0]) + _g("abandoned_gap"),
			float(yard_end[1]) + _g("module_wide_offset") * yard_sign,
		]
		var extra_abandoned_end := [
			float(extra_abandoned_start[0]) + _g("abandoned_track_length"),
			float(extra_abandoned_start[1]) + _g("abandoned_parallel_offset") * yard_sign,
		]
		segments.append(_segment(WorldgenSemanticGenerator.TRACK_BRANCH_EXTRA_ABANDONED, WorldgenSemanticGenerator.TRACK_BRANCH_EXTRA_ABANDONED, [extra_abandoned_start, extra_abandoned_end], "Extra abandoned branch track is not routable", "display_only"))

	return {
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
		"runtime_layout_id": "generated_declining_branch_%s" % str(decisions.get("signature", "")),
		"entry_segment": WorldgenSemanticGenerator.TRACK_MAIN_WEST,
		"entry_distance": _g("entry_distance"),
		"exit_segment": WorldgenSemanticGenerator.TRACK_MAIN_EAST,
		"exit_distance": float(geometry["exit_distance"]),
		"spatial_decisions": decisions.duplicate(true),
		"segments": segments,
		"points": points,
		"next_connections": next_connections,
		"previous_connections": previous_connections,
		"route_presets": route_presets,
	}


func _loop_geometry(decisions: Dictionary) -> Dictionary:
	var origin_x := _g("origin_x")
	var main_y := _g("main_y")
	var approach_length := _profile_length("loop_approach_lengths", str(decisions.get("approach_length_class", "medium")))
	var station_length := _profile_length("loop_station_lengths", str(decisions.get("station_length_class", "long")))
	var exit_length := _profile_length("loop_exit_lengths", str(decisions.get("exit_length_class", "medium")))
	var loop_offset_magnitude := _profile_length("loop_offset_lengths", str(decisions.get("loop_offset_class", "standard")))
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
		"exit_distance": maxf(exit_length - _g("entry_distance"), _g("entry_distance")),
		"loop_points": [
			west_point,
			[west_x + _g("module_curve_x"), main_y + loop_offset],
			[east_x - _g("module_curve_x"), main_y + loop_offset],
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
