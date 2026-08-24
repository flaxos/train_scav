extends RefCounted
class_name WorldgenRuntimeReconstructor

const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")

const ROLE_ABANDONED_TRACK := "ABANDONED_TRACK"
const STATUS_ACTIVE := "active"
const STATUS_DISPLAY_ONLY := "display_only"


func reconstruct_runtime_layout(blueprint: RefCounted, embedding: Dictionary, validator: RefCounted = null) -> Dictionary:
	var diagnostics: Array[Dictionary] = []
	if blueprint == null or not blueprint.has_method("to_dictionary"):
		_add_diagnostic(diagnostics, "BLUEPRINT_INVALID", "blueprint must expose to_dictionary")
		return _result(false, {}, diagnostics)

	var active_validator := validator
	if active_validator == null:
		active_validator = WorldgenSchemaValidator.new()
	if active_validator != null and active_validator.has_method("validate_blueprint"):
		var validation_result: Dictionary = active_validator.validate_blueprint(blueprint)
		if not bool(validation_result.get("valid", false)):
			for diagnostic in validation_result.get("diagnostics", []):
				diagnostics.append((diagnostic as Dictionary).duplicate(true))
			return _result(false, {}, diagnostics)

	var data: Dictionary = blueprint.to_dictionary()
	var archetype_id := str(data.get("archetype_id", ""))
	if str(embedding.get("archetype_id", "")) != archetype_id:
		_add_diagnostic(
			diagnostics,
			"EMBEDDING_ARCHETYPE_MISMATCH",
			"embedding archetype_id does not match blueprint",
			"",
			"",
			"",
			"",
			{"expected": archetype_id, "actual": str(embedding.get("archetype_id", ""))}
		)
		return _result(false, {}, diagnostics)

	var edge_by_id := _index_edges(data)
	var layout := _build_layout(embedding, edge_by_id, diagnostics)
	if not diagnostics.is_empty():
		return _result(false, {}, diagnostics)
	return _result(true, layout, diagnostics)


func _build_layout(embedding: Dictionary, edge_by_id: Dictionary, diagnostics: Array[Dictionary]) -> Dictionary:
	var segments: Dictionary = {}
	var segment_semantics: Dictionary = {}
	var semantic_map: Dictionary = {}
	var endpoint_b_block_reasons: Dictionary = {}

	for raw_segment in embedding.get("segments", []):
		if typeof(raw_segment) != TYPE_DICTIONARY:
			_add_diagnostic(diagnostics, "EMBEDDING_SEGMENT_INVALID", "runtime segment entry must be a dictionary")
			continue
		var segment := raw_segment as Dictionary
		var runtime_segment_id := str(segment.get("runtime_segment_id", ""))
		var semantic_edge_id := str(segment.get("semantic_edge_id", ""))
		if runtime_segment_id.is_empty():
			_add_diagnostic(diagnostics, "RUNTIME_SEGMENT_ID_REQUIRED", "runtime segment id is required")
			continue
		if segments.has(runtime_segment_id):
			_add_diagnostic(diagnostics, "DUPLICATE_RUNTIME_SEGMENT_ID", "duplicate runtime segment id %s" % runtime_segment_id, runtime_segment_id)
			continue

		var points := _parse_points(segment.get("points", []), diagnostics, runtime_segment_id)
		if points.size() < 2:
			continue

		var role := ""
		if not semantic_edge_id.is_empty():
			if not edge_by_id.has(semantic_edge_id):
				_add_diagnostic(
					diagnostics,
					"UNKNOWN_SEMANTIC_EDGE_FOR_RUNTIME_SEGMENT",
					"runtime segment %s references unknown semantic edge %s" % [runtime_segment_id, semantic_edge_id],
					semantic_edge_id,
					"",
					"",
					"",
					{"runtime_segment_id": runtime_segment_id}
				)
				continue
			var edge := edge_by_id[semantic_edge_id] as Dictionary
			role = str(edge.get("role", ""))
			if not semantic_map.has(semantic_edge_id):
				semantic_map[semantic_edge_id] = []
			(semantic_map[semantic_edge_id] as Array).append(runtime_segment_id)
		var runtime_status := _runtime_status_for_segment(segment, role)

		segments[runtime_segment_id] = points
		segment_semantics[runtime_segment_id] = {
			"semantic_edge_id": semantic_edge_id,
			"semantic_role": role,
			"label": str(segment.get("label", "")),
			"runtime_status": runtime_status,
		}
		endpoint_b_block_reasons[runtime_segment_id] = str(segment.get("end_b_block_reason", "End of track"))

	var point_definitions: Dictionary = {}
	for raw_point in embedding.get("points", []):
		if typeof(raw_point) != TYPE_DICTIONARY:
			_add_diagnostic(diagnostics, "EMBEDDING_POINT_INVALID", "runtime point entry must be a dictionary")
			continue
		var point := raw_point as Dictionary
		var point_id := str(point.get("runtime_point_id", ""))
		if point_id.is_empty():
			_add_diagnostic(diagnostics, "RUNTIME_POINT_ID_REQUIRED", "runtime point id is required")
			continue
		if point_definitions.has(point_id):
			_add_diagnostic(diagnostics, "DUPLICATE_RUNTIME_POINT_ID", "duplicate runtime point id %s" % point_id, "", point_id)
			continue
		var routes: Array[String] = []
		for raw_route in point.get("routes", []):
			routes.append(str(raw_route))
		if routes.size() < 2:
			_add_diagnostic(diagnostics, "RUNTIME_POINT_ROUTES_REQUIRED", "runtime point %s needs at least two routes" % point_id, "", point_id)
			continue
		var initial_route := str(point.get("initial_route", routes[0]))
		if not routes.has(initial_route):
			_add_diagnostic(diagnostics, "RUNTIME_POINT_INITIAL_ROUTE_INVALID", "runtime point %s has invalid initial route" % point_id, "", point_id)
			continue
		point_definitions[point_id] = {
			"id": point_id,
			"semantic_node_id": str(point.get("semantic_node_id", "")),
			"position": _parse_point_position(point.get("position", [])),
			"routes": routes,
			"initial_route": initial_route,
		}

	_validate_connections(embedding.get("next_connections", {}) as Dictionary, segments, segment_semantics, point_definitions, diagnostics, "next")
	_validate_connections(embedding.get("previous_connections", {}) as Dictionary, segments, segment_semantics, point_definitions, diagnostics, "previous")
	if not diagnostics.is_empty():
		return {}

	return {
		"layout_id": str(embedding.get("runtime_layout_id", "")),
		"embedding_version": str(embedding.get("embedding_version", "")),
		"entry_segment": str(embedding.get("entry_segment", "")),
		"entry_distance": float(embedding.get("entry_distance", 0.0)),
		"exit_segment": str(embedding.get("exit_segment", "")),
		"exit_distance": float(embedding.get("exit_distance", 0.0)),
		"segments": segments,
		"segment_semantics": segment_semantics,
		"semantic_edge_to_runtime_segments": semantic_map,
		"points": point_definitions,
		"next_connections": (embedding.get("next_connections", {}) as Dictionary).duplicate(true),
		"previous_connections": (embedding.get("previous_connections", {}) as Dictionary).duplicate(true),
		"endpoint_b_block_reasons": endpoint_b_block_reasons,
		"route_presets": (embedding.get("route_presets", []) as Array).duplicate(true),
		"canonical_topology": _make_canonical_topology(embedding, semantic_map),
	}


func _validate_connections(
	connections: Dictionary,
	segments: Dictionary,
	segment_semantics: Dictionary,
	point_definitions: Dictionary,
	diagnostics: Array[Dictionary],
	label: String
) -> void:
	for raw_segment_id in connections.keys():
		var segment_id := str(raw_segment_id)
		if not segments.has(segment_id):
			_add_diagnostic(diagnostics, "RUNTIME_CONNECTION_UNKNOWN_SEGMENT", "%s connection references unknown segment %s" % [label, segment_id], segment_id)
			continue
		if _is_display_only_segment(segment_semantics, segment_id):
			_add_diagnostic(diagnostics, "DISPLAY_ONLY_SEGMENT_ROUTED", "%s connection starts from display-only segment %s" % [label, segment_id], segment_id)
			continue
		var connection := connections[raw_segment_id] as Dictionary
		if connection.has("segment"):
			var target_segment := str(connection.get("segment", ""))
			if not segments.has(target_segment):
				_add_diagnostic(diagnostics, "RUNTIME_CONNECTION_UNKNOWN_SEGMENT", "%s connection from %s references unknown target" % [label, segment_id], segment_id)
			elif _is_display_only_segment(segment_semantics, target_segment):
				_add_diagnostic(diagnostics, "DISPLAY_ONLY_SEGMENT_ROUTED", "%s connection from %s targets display-only segment %s" % [label, segment_id, target_segment], target_segment)
		if connection.has("point") and not point_definitions.has(str(connection.get("point", ""))):
			_add_diagnostic(diagnostics, "RUNTIME_CONNECTION_UNKNOWN_POINT", "%s connection from %s references unknown point" % [label, segment_id], segment_id, str(connection.get("point", "")))
		if connection.has("requires_point") and not point_definitions.has(str(connection.get("requires_point", ""))):
			_add_diagnostic(diagnostics, "RUNTIME_CONNECTION_UNKNOWN_POINT", "%s connection from %s references unknown required point" % [label, segment_id], segment_id, str(connection.get("requires_point", "")))
		var route_targets := connection.get("routes", {}) as Dictionary
		for raw_route in route_targets.keys():
			var route_target := str(route_targets[raw_route])
			if not segments.has(route_target):
				_add_diagnostic(diagnostics, "RUNTIME_CONNECTION_UNKNOWN_SEGMENT", "%s route %s from %s references unknown target" % [label, str(raw_route), segment_id], segment_id)
			elif _is_display_only_segment(segment_semantics, route_target):
				_add_diagnostic(diagnostics, "DISPLAY_ONLY_SEGMENT_ROUTED", "%s route %s from %s targets display-only segment %s" % [label, str(raw_route), segment_id, route_target], route_target)


func _make_canonical_topology(embedding: Dictionary, semantic_map: Dictionary) -> Dictionary:
	return {
		"runtime_layout_id": str(embedding.get("runtime_layout_id", "")),
		"entry_segment": str(embedding.get("entry_segment", "")),
		"exit_segment": str(embedding.get("exit_segment", "")),
		"segments": (embedding.get("segments", []) as Array).duplicate(true),
		"points": (embedding.get("points", []) as Array).duplicate(true),
		"next_connections": (embedding.get("next_connections", {}) as Dictionary).duplicate(true),
		"previous_connections": (embedding.get("previous_connections", {}) as Dictionary).duplicate(true),
		"route_presets": (embedding.get("route_presets", []) as Array).duplicate(true),
		"semantic_edge_to_runtime_segments": semantic_map.duplicate(true),
	}


func _runtime_status_for_segment(segment: Dictionary, semantic_role: String) -> String:
	var explicit_status := str(segment.get("runtime_status", ""))
	if explicit_status == STATUS_DISPLAY_ONLY:
		return STATUS_DISPLAY_ONLY
	if semantic_role == ROLE_ABANDONED_TRACK:
		return STATUS_DISPLAY_ONLY
	return STATUS_ACTIVE


func _is_display_only_segment(segment_semantics: Dictionary, segment_id: String) -> bool:
	var semantics := segment_semantics.get(segment_id, {}) as Dictionary
	return str(semantics.get("runtime_status", STATUS_ACTIVE)) == STATUS_DISPLAY_ONLY


func _index_edges(data: Dictionary) -> Dictionary:
	var indexed: Dictionary = {}
	var rail_graph := data.get("rail_graph", {}) as Dictionary
	for raw_edge in rail_graph.get("edges", []):
		if typeof(raw_edge) != TYPE_DICTIONARY:
			continue
		var edge := raw_edge as Dictionary
		var edge_id := str(edge.get("id", ""))
		if edge_id.is_empty():
			continue
		indexed[edge_id] = edge
	return indexed


func _parse_points(raw_points: Variant, diagnostics: Array[Dictionary], runtime_segment_id: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if typeof(raw_points) != TYPE_ARRAY:
		_add_diagnostic(diagnostics, "RUNTIME_SEGMENT_POINTS_INVALID", "runtime segment %s points must be an array" % runtime_segment_id, runtime_segment_id)
		return points
	for raw_point in raw_points as Array:
		var point := _parse_point_position(raw_point)
		points.append(point)
	if points.size() < 2:
		_add_diagnostic(diagnostics, "RUNTIME_SEGMENT_POINTS_INVALID", "runtime segment %s needs at least two points" % runtime_segment_id, runtime_segment_id)
	return points


func _parse_point_position(raw_point: Variant) -> Vector2:
	if typeof(raw_point) != TYPE_ARRAY:
		return Vector2.ZERO
	var values := raw_point as Array
	if values.size() < 2:
		return Vector2.ZERO
	return Vector2(float(values[0]), float(values[1]))


func _result(valid: bool, layout: Dictionary, diagnostics: Array[Dictionary]) -> Dictionary:
	return {
		"valid": valid,
		"layout": layout.duplicate(true),
		"diagnostics": diagnostics.duplicate(true),
	}


func _add_diagnostic(
	diagnostics: Array[Dictionary],
	code: String,
	message: String,
	track_id: String = "",
	node_id: String = "",
	entity_id: String = "",
	relationship_id: String = "",
	context: Dictionary = {}
) -> void:
	diagnostics.append({
		"code": code,
		"message": message,
		"track_id": track_id,
		"node_id": node_id,
		"entity_id": entity_id,
		"relationship_id": relationship_id,
		"context": context.duplicate(true),
	})
