extends RefCounted
class_name WorldgenVillagePassingSpatialEmbedding

const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationTrace := preload("res://scripts/worldgen/worldgen_generation_trace.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")

const EMBEDDING_VERSION := "sprint9_closeout_generated_village_passing_embedding_v1"
const ARCHETYPE_VILLAGE_PASSING_STATION := "village_passing_station"
const STREAM_SPATIAL := "spatial"

const TRACK_APPROACH_MAIN := "approach_main"
const TRACK_STATION_MAIN := "station_main"
const TRACK_PASSING_LOOP := "passing_loop"
const TRACK_EXIT_MAIN := "exit_main"

const POINT_WEST_LOOP := "west_loop_switch"
const POINT_EAST_LOOP := "east_loop_switch"

const ROUTE_MAIN := "main"
const ROUTE_LOOP := "loop"


func generate_embedding(blueprint: RefCounted, context: RefCounted, prior_trace: RefCounted = null) -> Dictionary:
	if blueprint == null or not blueprint.has_method("to_dictionary"):
		return _failure("BLUEPRINT_INVALID", "blueprint must expose to_dictionary")
	if context == null or not _context_has_required_api(context):
		return _failure("GENERATION_CONTEXT_INVALID", "generation context does not expose required 9F API")
	if not bool(context.is_valid()):
		return _failure_with_diagnostics(context.get_diagnostics())

	var data: Dictionary = blueprint.to_dictionary()
	if str(data.get("archetype_id", "")) != ARCHETYPE_VILLAGE_PASSING_STATION:
		return _failure(
			"SPATIAL_ARCHETYPE_UNSUPPORTED",
			"closeout spatial embedding only supports village_passing_station",
			{"actual": str(data.get("archetype_id", ""))}
		)

	var validation: Dictionary = WorldgenSchemaValidator.new().validate_blueprint(blueprint)
	if not bool(validation.get("valid", false)):
		return _failure_with_diagnostics((validation.get("diagnostics", []) as Array).duplicate(true))

	var spatial_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_SPATIAL)
	if spatial_rng == null:
		return _failure("SPATIAL_RNG_UNAVAILABLE", "spatial RNG stream is unavailable")

	var decisions := _make_decisions(spatial_rng)
	var embedding := _make_embedding(decisions)
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


func _make_decisions(spatial_rng: RefCounted) -> Dictionary:
	var loop_side := _choose(spatial_rng, ["north", "south"])
	var approach_length_class := _choose(spatial_rng, ["short", "medium", "long"])
	var station_length_class := _choose(spatial_rng, ["medium", "long", "extended"])
	var exit_length_class := _choose(spatial_rng, ["short", "medium", "long"])
	var loop_offset_class := _choose(spatial_rng, ["standard", "wide"])
	return {
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


func _make_embedding(decisions: Dictionary) -> Dictionary:
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
		"embedding_version": EMBEDDING_VERSION,
		"archetype_id": ARCHETYPE_VILLAGE_PASSING_STATION,
		"runtime_layout_id": "generated_village_passing_%s" % str(decisions.get("signature", "")),
		"entry_segment": TRACK_APPROACH_MAIN,
		"entry_distance": 24.0,
		"exit_segment": TRACK_EXIT_MAIN,
		"exit_distance": maxf(exit_length - 24.0, 24.0),
		"spatial_decisions": decisions.duplicate(true),
		"segments": [
			{
				"runtime_segment_id": TRACK_APPROACH_MAIN,
				"semantic_edge_id": TRACK_APPROACH_MAIN,
				"label": "Generated approach main",
				"points": [[origin_x, main_y], west_point],
				"end_b_block_reason": "No route through west generated loop switch",
			},
			{
				"runtime_segment_id": TRACK_STATION_MAIN,
				"semantic_edge_id": TRACK_STATION_MAIN,
				"label": "Generated station main",
				"points": [west_point, east_point],
				"end_b_block_reason": "East generated loop switch route blocks station main",
			},
			{
				"runtime_segment_id": TRACK_PASSING_LOOP,
				"semantic_edge_id": TRACK_PASSING_LOOP,
				"label": "Generated passing loop",
				"points": [
					west_point,
					[west_x + 74.0, main_y + loop_offset],
					[east_x - 74.0, main_y + loop_offset],
					east_point,
				],
				"end_b_block_reason": "East generated loop switch route blocks passing loop",
			},
			{
				"runtime_segment_id": TRACK_EXIT_MAIN,
				"semantic_edge_id": TRACK_EXIT_MAIN,
				"label": "Generated exit main",
				"points": [east_point, [exit_x, main_y]],
				"end_b_block_reason": "End of generated village east exit",
			},
		],
		"points": [
			{
				"runtime_point_id": POINT_WEST_LOOP,
				"semantic_node_id": POINT_WEST_LOOP,
				"position": west_point,
				"routes": [ROUTE_MAIN, ROUTE_LOOP],
				"initial_route": ROUTE_MAIN,
			},
			{
				"runtime_point_id": POINT_EAST_LOOP,
				"semantic_node_id": POINT_EAST_LOOP,
				"position": east_point,
				"routes": [ROUTE_MAIN, ROUTE_LOOP],
				"initial_route": ROUTE_MAIN,
			},
		],
		"next_connections": {
			TRACK_APPROACH_MAIN: {
				"point": POINT_WEST_LOOP,
				"routes": {
					ROUTE_MAIN: TRACK_STATION_MAIN,
					ROUTE_LOOP: TRACK_PASSING_LOOP,
				},
			},
			TRACK_STATION_MAIN: {
				"segment": TRACK_EXIT_MAIN,
				"requires_point": POINT_EAST_LOOP,
				"requires_route": ROUTE_MAIN,
			},
			TRACK_PASSING_LOOP: {
				"segment": TRACK_EXIT_MAIN,
				"requires_point": POINT_EAST_LOOP,
				"requires_route": ROUTE_LOOP,
			},
		},
		"previous_connections": {
			TRACK_STATION_MAIN: {
				"segment": TRACK_APPROACH_MAIN,
				"requires_point": POINT_WEST_LOOP,
				"requires_route": ROUTE_MAIN,
				"blocked_reason": "West generated loop switch blocks station main",
			},
			TRACK_PASSING_LOOP: {
				"segment": TRACK_APPROACH_MAIN,
				"requires_point": POINT_WEST_LOOP,
				"requires_route": ROUTE_LOOP,
				"blocked_reason": "West generated loop switch blocks passing loop",
			},
			TRACK_EXIT_MAIN: {
				"point": POINT_EAST_LOOP,
				"routes": {
					ROUTE_MAIN: TRACK_STATION_MAIN,
					ROUTE_LOOP: TRACK_PASSING_LOOP,
				},
			},
		},
		"route_presets": [
			{
				"id": ROUTE_MAIN,
				"label": "Station main",
				"routes": {
					POINT_WEST_LOOP: ROUTE_MAIN,
					POINT_EAST_LOOP: ROUTE_MAIN,
				},
			},
			{
				"id": ROUTE_LOOP,
				"label": "Passing loop",
				"routes": {
					POINT_WEST_LOOP: ROUTE_LOOP,
					POINT_EAST_LOOP: ROUTE_LOOP,
				},
			},
		],
	}


func _length_for(key: String, lengths: Dictionary) -> float:
	return float(lengths.get(key, lengths.values()[0]))


func _make_trace(context: RefCounted, prior_trace: RefCounted, decisions: Dictionary) -> RefCounted:
	var trace_data: Dictionary = context.to_trace_dictionary()
	if prior_trace != null and prior_trace.has_method("to_dictionary"):
		trace_data = prior_trace.to_dictionary()
	var stage_decisions := (trace_data.get("stage_decisions", []) as Array).duplicate(true)
	for key in ["loop_side", "approach_length_class", "station_length_class", "exit_length_class", "loop_offset_class"]:
		stage_decisions.append({
			"stage": "spatial_embedding",
			"key": key,
			"value": decisions.get(key, ""),
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
