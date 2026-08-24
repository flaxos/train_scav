extends RefCounted
class_name WorldgenSemanticGenerator

const SectorBlueprint := preload("res://scripts/worldgen/sector_blueprint.gd")
const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationTrace := preload("res://scripts/worldgen/worldgen_generation_trace.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")

const GENERATOR_VERSION := "9g_village_passing_station_semantic_v1"
const PRODUCTION_GENERATOR_VERSION := "9_production_procedural_sectors_v1"
const LEGACY_BLUEPRINT_GENERATOR_VERSION := "9a_schema_v1"
const GRAMMAR_VERSION := "central_eu_small_town_station_v1"
const ARCHETYPE_RURAL_THROUGH := "rural_through"
const ARCHETYPE_VILLAGE_PASSING_STATION := "village_passing_station"
const ARCHETYPE_SMALL_TOWN_GOODS := "small_town_goods"

const STREAM_FIXED := "fixed"

const TRACK_RURAL_MAIN := "rural_main"
const TRACK_APPROACH_MAIN := "approach_main"
const TRACK_STATION_MAIN := "station_main"
const TRACK_PLATFORM_MAIN := "platform_main"
const TRACK_PASSING_LOOP := "passing_loop"
const TRACK_EXIT_MAIN := "exit_main"
const TRACK_GOODS_YARD_LEAD := "goods_yard_lead"
const TRACK_GOODS_LOADING := "goods_loading"
const TRACK_YARD_HEADSHUNT := "yard_headshunt"


func generate_blueprint(source: RefCounted) -> Dictionary:
	if source == null:
		return _failure("GENERATION_SOURCE_REQUIRED", "generation request or context is required")
	if source.has_method("make_rng") and source.has_method("to_trace_dictionary") and source.has_method("get_identity"):
		return generate_blueprint_from_context(source)

	var context := WorldgenGenerationContext.new(source)
	return generate_blueprint_from_context(context)


func generate_blueprint_from_context(context: RefCounted) -> Dictionary:
	if context == null:
		return _failure("GENERATION_CONTEXT_REQUIRED", "generation context is required")
	if not _context_has_required_api(context):
		return _failure("GENERATION_CONTEXT_INVALID", "generation context does not expose required 9F API")
	if not bool(context.is_valid()):
		return _failure_with_diagnostics(context.get_diagnostics())

	var identity: Dictionary = context.get_identity()
	var actual_version := str(identity.get("generator_version", ""))
	if actual_version != GENERATOR_VERSION:
		return _failure(
			"GENERATOR_VERSION_MISMATCH",
			"9G village passing generator requires generator_version %s" % GENERATOR_VERSION,
			{"expected": GENERATOR_VERSION, "actual": actual_version}
		)

	var topology_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_TOPOLOGY)
	var world_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_WORLD_ENTITIES)
	if topology_rng == null:
		return _failure("TOPOLOGY_RNG_UNAVAILABLE", "topology RNG stream is unavailable")
	if world_rng == null:
		return _failure("WORLD_ENTITIES_RNG_UNAVAILABLE", "world_entities RNG stream is unavailable")

	var decisions := _make_decisions(topology_rng, world_rng)
	var data := _make_village_passing_station_data(decisions)
	var blueprint: RefCounted = SectorBlueprint.from_dictionary(data)
	var validation: Dictionary = WorldgenSchemaValidator.new().validate_blueprint(blueprint)
	if not bool(validation.get("valid", false)):
		return {
			"success": false,
			"blueprint": null,
			"diagnostics": (validation.get("diagnostics", []) as Array).duplicate(true),
			"generation_trace": _make_trace(context, decisions),
			"decisions": decisions.duplicate(true),
		}

	return {
		"success": true,
		"blueprint": blueprint,
		"diagnostics": [],
		"generation_trace": _make_trace(context, decisions),
		"decisions": decisions.duplicate(true),
	}


func generate_blueprint_for_archetype(context: RefCounted, archetype_id: String, prior_trace: RefCounted = null) -> Dictionary:
	if context == null:
		return _failure("GENERATION_CONTEXT_REQUIRED", "generation context is required")
	if not _context_has_required_api(context):
		return _failure("GENERATION_CONTEXT_INVALID", "generation context does not expose required 9F API")
	if not bool(context.is_valid()):
		return _failure_with_diagnostics(context.get_diagnostics())
	if not [ARCHETYPE_RURAL_THROUGH, ARCHETYPE_VILLAGE_PASSING_STATION, ARCHETYPE_SMALL_TOWN_GOODS].has(archetype_id):
		return _failure(
			"SEMANTIC_ARCHETYPE_UNSUPPORTED",
			"production semantic generator does not support %s" % archetype_id,
			{"archetype_id": archetype_id}
		)

	var identity: Dictionary = context.get_identity()
	var actual_version := str(identity.get("generator_version", ""))
	if actual_version != PRODUCTION_GENERATOR_VERSION:
		return _failure(
			"GENERATOR_VERSION_MISMATCH",
			"production semantic generation requires generator_version %s" % PRODUCTION_GENERATOR_VERSION,
			{"expected": PRODUCTION_GENERATOR_VERSION, "actual": actual_version}
		)

	var topology_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_TOPOLOGY)
	var world_rng: RefCounted = context.make_rng(WorldgenGenerationContext.STREAM_WORLD_ENTITIES)
	if topology_rng == null:
		return _failure("TOPOLOGY_RNG_UNAVAILABLE", "topology RNG stream is unavailable")
	if world_rng == null:
		return _failure("WORLD_ENTITIES_RNG_UNAVAILABLE", "world_entities RNG stream is unavailable")

	var decisions := _make_decisions_for_archetype(archetype_id, topology_rng, world_rng)
	var data := _make_data_for_archetype(archetype_id, decisions)
	var blueprint: RefCounted = SectorBlueprint.from_dictionary(data)
	var validation: Dictionary = WorldgenSchemaValidator.new().validate_blueprint(blueprint)
	var trace := _make_trace(context, decisions, prior_trace, false)
	if not bool(validation.get("valid", false)):
		return {
			"success": false,
			"blueprint": null,
			"diagnostics": (validation.get("diagnostics", []) as Array).duplicate(true),
			"generation_trace": trace,
			"decisions": decisions.duplicate(true),
		}

	return {
		"success": true,
		"blueprint": blueprint,
		"diagnostics": [],
		"generation_trace": trace,
		"decisions": decisions.duplicate(true),
	}


func _context_has_required_api(context: RefCounted) -> bool:
	return context.has_method("is_valid") \
		and context.has_method("get_diagnostics") \
		and context.has_method("get_identity") \
		and context.has_method("make_rng") \
		and context.has_method("to_trace_dictionary")


func _make_decisions(topology_rng: RefCounted, world_rng: RefCounted) -> Dictionary:
	var platform_track := TRACK_STATION_MAIN
	if int(topology_rng.range_int(0, 1)) == 1:
		platform_track = TRACK_PASSING_LOOP
	var road_access := int(world_rng.range_int(0, 1)) == 1
	return {
		"archetype": ARCHETYPE_VILLAGE_PASSING_STATION,
		"platform_track": platform_track,
		"road_access": road_access,
	}


func _make_decisions_for_archetype(archetype_id: String, topology_rng: RefCounted, world_rng: RefCounted) -> Dictionary:
	match archetype_id:
		ARCHETYPE_RURAL_THROUGH:
			return {
				"archetype": archetype_id,
				"wayside_stop": int(world_rng.range_int(0, 1)) == 1,
			}
		ARCHETYPE_VILLAGE_PASSING_STATION:
			return _make_decisions(topology_rng, world_rng)
		ARCHETYPE_SMALL_TOWN_GOODS:
			var platform_track := TRACK_PLATFORM_MAIN
			if int(topology_rng.range_int(0, 1)) == 1:
				platform_track = TRACK_PASSING_LOOP
			var road_access := int(world_rng.range_int(0, 1)) == 1
			return {
				"archetype": archetype_id,
				"platform_track": platform_track,
				"road_access": road_access,
			}
	return {"archetype": archetype_id}


func _make_data_for_archetype(archetype_id: String, decisions: Dictionary) -> Dictionary:
	match archetype_id:
		ARCHETYPE_RURAL_THROUGH:
			return _make_rural_through_data(decisions)
		ARCHETYPE_VILLAGE_PASSING_STATION:
			return _make_village_passing_station_data(decisions)
		ARCHETYPE_SMALL_TOWN_GOODS:
			return _make_small_town_goods_data(decisions)
	return {}


func _make_rural_through_data(decisions: Dictionary) -> Dictionary:
	var entities: Array[Dictionary] = [
		{"id": "wayside_stop", "type": "STATION"},
	]
	var relations: Array[Dictionary] = [
		{
			"id": "wayside_stop_on_main",
			"type": "ADJACENT_TO_TRACK",
			"from_entity": "wayside_stop",
			"to_edge": TRACK_RURAL_MAIN,
		},
	]
	if bool(decisions.get("wayside_stop", false)):
		entities.append({"id": "field_road", "type": "ROAD"})
		relations.append({
			"id": "road_access_wayside_stop",
			"type": "ROAD_ACCESS",
			"from_entity": "field_road",
			"to_entity": "wayside_stop",
		})
	return {
		"grammar_version": GRAMMAR_VERSION,
		"generator_version": LEGACY_BLUEPRINT_GENERATOR_VERSION,
		"archetype_id": ARCHETYPE_RURAL_THROUGH,
		"title": "Generated Rural Through",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "exit", "type": "EXIT"},
			],
			"edges": [
				{
					"id": TRACK_RURAL_MAIN,
					"role": "THROUGH_MAIN",
					"from": "entry",
					"to": "exit",
					"bidirectional": true,
				},
			],
		},
		"world_graph": {
			"entities": entities,
			"relations": relations,
		},
	}


func _make_village_passing_station_data(decisions: Dictionary) -> Dictionary:
	var entities: Array[Dictionary] = [
		{"id": "station_01", "type": "STATION"},
		{"id": "platform_01", "type": "PLATFORM"},
		{"id": "village_01", "type": "SETTLEMENT"},
	]
	var relations: Array[Dictionary] = [
		{
			"id": "station_serves_village",
			"type": "SERVES_SETTLEMENT",
			"from_entity": "station_01",
			"to_entity": "village_01",
		},
		{
			"id": "platform_serves_track",
			"type": "PLATFORM_SERVES_TRACK",
			"from_entity": "platform_01",
			"to_edge": str(decisions.get("platform_track", TRACK_STATION_MAIN)),
		},
	]
	if bool(decisions.get("road_access", false)):
		entities.append({"id": "station_road_01", "type": "ROAD"})
		relations.append({
			"id": "road_access_station",
			"type": "ROAD_ACCESS",
			"from_entity": "station_road_01",
			"to_entity": "station_01",
		})

	return {
		"grammar_version": GRAMMAR_VERSION,
		"generator_version": LEGACY_BLUEPRINT_GENERATOR_VERSION,
		"archetype_id": ARCHETYPE_VILLAGE_PASSING_STATION,
		"title": "Generated Village Passing Station",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "west_loop_switch", "type": "SWITCH"},
				{"id": "east_loop_switch", "type": "SWITCH"},
				{"id": "exit", "type": "EXIT"},
			],
			"edges": [
				{
					"id": "approach_main",
					"role": "THROUGH_MAIN",
					"from": "entry",
					"to": "west_loop_switch",
					"bidirectional": true,
				},
				{
					"id": TRACK_STATION_MAIN,
					"role": "PLATFORM_TRACK",
					"from": "west_loop_switch",
					"to": "east_loop_switch",
					"bidirectional": true,
				},
				{
					"id": TRACK_PASSING_LOOP,
					"role": "PASSING_LOOP",
					"from": "west_loop_switch",
					"to": "east_loop_switch",
					"bidirectional": true,
				},
				{
					"id": "exit_main",
					"role": "THROUGH_MAIN",
					"from": "east_loop_switch",
					"to": "exit",
					"bidirectional": true,
				},
			],
		},
		"world_graph": {
			"entities": entities,
			"relations": relations,
		},
	}


func _make_small_town_goods_data(decisions: Dictionary) -> Dictionary:
	var entities: Array[Dictionary] = [
		{"id": "town_station", "type": "STATION"},
		{"id": "town_platform", "type": "PLATFORM"},
		{"id": "small_town", "type": "SETTLEMENT"},
		{"id": "goods_yard", "type": "GOODS_YARD"},
		{"id": "goods_shed", "type": "INDUSTRY"},
	]
	var relations: Array[Dictionary] = [
		{
			"id": "station_serves_town",
			"type": "SERVES_SETTLEMENT",
			"from_entity": "town_station",
			"to_entity": "small_town",
		},
		{
			"id": "platform_serves_track",
			"type": "PLATFORM_SERVES_TRACK",
			"from_entity": "town_platform",
			"to_edge": str(decisions.get("platform_track", TRACK_PLATFORM_MAIN)),
		},
		{
			"id": "yard_on_lead",
			"type": "FREIGHT_FACILITY_ON_TRACK",
			"from_entity": "goods_yard",
			"to_edge": TRACK_GOODS_YARD_LEAD,
		},
		{
			"id": "shed_on_loading",
			"type": "FREIGHT_FACILITY_ON_TRACK",
			"from_entity": "goods_shed",
			"to_edge": TRACK_GOODS_LOADING,
		},
	]
	if bool(decisions.get("road_access", false)):
		entities.append({"id": "goods_road", "type": "ROAD"})
		relations.append({
			"id": "road_serves_shed",
			"type": "ROAD_ACCESS",
			"from_entity": "goods_road",
			"to_entity": "goods_shed",
		})

	return {
		"grammar_version": GRAMMAR_VERSION,
		"generator_version": LEGACY_BLUEPRINT_GENERATOR_VERSION,
		"archetype_id": ARCHETYPE_SMALL_TOWN_GOODS,
		"title": "Generated Small-Town Goods Sector",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "west_loop_switch", "type": "SWITCH"},
				{"id": "east_loop_switch", "type": "SWITCH"},
				{"id": "yard_switch", "type": "SWITCH"},
				{"id": "exit", "type": "EXIT"},
				{"id": "goods_buffer", "type": "BUFFER_STOP"},
				{"id": "headshunt_buffer", "type": "BUFFER_STOP"},
			],
			"edges": [
				{
					"id": TRACK_APPROACH_MAIN,
					"role": "THROUGH_MAIN",
					"from": "entry",
					"to": "west_loop_switch",
					"bidirectional": true,
				},
				{
					"id": TRACK_PLATFORM_MAIN,
					"role": "PLATFORM_TRACK",
					"from": "west_loop_switch",
					"to": "east_loop_switch",
					"bidirectional": true,
				},
				{
					"id": TRACK_PASSING_LOOP,
					"role": "PASSING_LOOP",
					"from": "west_loop_switch",
					"to": "east_loop_switch",
					"bidirectional": true,
				},
				{
					"id": TRACK_EXIT_MAIN,
					"role": "THROUGH_MAIN",
					"from": "east_loop_switch",
					"to": "exit",
					"bidirectional": true,
				},
				{
					"id": TRACK_GOODS_YARD_LEAD,
					"role": "GOODS_YARD_TRACK",
					"from": "west_loop_switch",
					"to": "yard_switch",
					"bidirectional": true,
				},
				{
					"id": TRACK_GOODS_LOADING,
					"role": "LOADING_TRACK",
					"from": "yard_switch",
					"to": "goods_buffer",
					"bidirectional": true,
				},
				{
					"id": TRACK_YARD_HEADSHUNT,
					"role": "HEADSHUNT",
					"from": "yard_switch",
					"to": "headshunt_buffer",
					"bidirectional": true,
				},
			],
		},
		"world_graph": {
			"entities": entities,
			"relations": relations,
		},
	}


func _make_trace(context: RefCounted, decisions: Dictionary, prior_trace: RefCounted = null, include_archetype_decision: bool = true) -> RefCounted:
	var trace_data: Dictionary = context.to_trace_dictionary()
	if prior_trace != null and prior_trace.has_method("to_dictionary"):
		trace_data = prior_trace.to_dictionary()
	var stage_decisions := (trace_data.get("stage_decisions", []) as Array).duplicate(true)
	if include_archetype_decision:
		stage_decisions.append(_stage_decision("archetype", decisions.get("archetype", ""), STREAM_FIXED))
	if decisions.has("platform_track"):
		stage_decisions.append(_stage_decision("platform_track", decisions.get("platform_track", ""), WorldgenGenerationContext.STREAM_TOPOLOGY))
	if decisions.has("road_access"):
		stage_decisions.append(_stage_decision("road_access", decisions.get("road_access", false), WorldgenGenerationContext.STREAM_WORLD_ENTITIES))
	if decisions.has("wayside_stop"):
		stage_decisions.append(_stage_decision("wayside_stop", decisions.get("wayside_stop", false), WorldgenGenerationContext.STREAM_WORLD_ENTITIES))
	trace_data["stage_decisions"] = stage_decisions
	return WorldgenGenerationTrace.new(trace_data)


func _stage_decision(key: String, value: Variant, stream_name: String) -> Dictionary:
	return {
		"stage": "semantic_topology",
		"key": key,
		"value": value,
		"stream": stream_name,
	}


func _failure(code: String, message: String, context: Dictionary = {}) -> Dictionary:
	return _failure_with_diagnostics([_diagnostic(code, message, context)])


func _failure_with_diagnostics(diagnostics: Array) -> Dictionary:
	return {
		"success": false,
		"blueprint": null,
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
