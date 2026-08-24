extends RefCounted
class_name WorldgenSchemaValidator

const GRAMMAR_VERSION := "central_eu_small_town_station_v1"
const GENERATOR_VERSION := "9a_schema_v1"

const ROLE_THROUGH_MAIN := "THROUGH_MAIN"
const ROLE_PASSING_LOOP := "PASSING_LOOP"
const ROLE_PLATFORM_TRACK := "PLATFORM_TRACK"
const ROLE_GOODS_YARD_TRACK := "GOODS_YARD_TRACK"
const ROLE_LOADING_TRACK := "LOADING_TRACK"
const ROLE_HEADSHUNT := "HEADSHUNT"
const ROLE_INDUSTRIAL_SPUR := "INDUSTRIAL_SPUR"
const ROLE_AGRICULTURAL_SPUR := "AGRICULTURAL_SPUR"
const ROLE_STORAGE_TRACK := "STORAGE_TRACK"
const ROLE_DEPOT_TRACK := "DEPOT_TRACK"
const ROLE_CROSSOVER := "CROSSOVER"
const ROLE_ABANDONED_TRACK := "ABANDONED_TRACK"

const NODE_ENTRY := "ENTRY"
const NODE_EXIT := "EXIT"
const NODE_BUFFER_STOP := "BUFFER_STOP"

const ENTITY_STATION := "STATION"
const ENTITY_SETTLEMENT := "SETTLEMENT"
const ENTITY_PLATFORM := "PLATFORM"
const ENTITY_GOODS_YARD := "GOODS_YARD"
const ENTITY_GOODS_SHED := "GOODS_SHED"
const ENTITY_INDUSTRY := "INDUSTRY"
const ENTITY_AGRICULTURAL_FACILITY := "AGRICULTURAL_FACILITY"
const ENTITY_ROAD := "ROAD"
const ENTITY_BRIDGE := "BRIDGE"
const ENTITY_CREEK := "CREEK"
const ENTITY_RIVER := "RIVER"
const ENTITY_WATERWAY := "WATERWAY"

const REL_SERVES_SETTLEMENT := "SERVES_SETTLEMENT"
const REL_ADJACENT_TO_TRACK := "ADJACENT_TO_TRACK"
const REL_PLATFORM_SERVES_TRACK := "PLATFORM_SERVES_TRACK"
const REL_ROAD_ACCESS := "ROAD_ACCESS"
const REL_FREIGHT_FACILITY_ON_TRACK := "FREIGHT_FACILITY_ON_TRACK"
const REL_WATER_CROSSED_BY_TRACK := "WATER_CROSSED_BY_TRACK"
const REL_BRIDGE_CARRIES_TRACK := "BRIDGE_CARRIES_TRACK"

const _ALLOWED_ROLES := {
	ROLE_THROUGH_MAIN: true,
	ROLE_PASSING_LOOP: true,
	ROLE_PLATFORM_TRACK: true,
	ROLE_GOODS_YARD_TRACK: true,
	ROLE_LOADING_TRACK: true,
	ROLE_HEADSHUNT: true,
	ROLE_INDUSTRIAL_SPUR: true,
	ROLE_AGRICULTURAL_SPUR: true,
	ROLE_STORAGE_TRACK: true,
	ROLE_DEPOT_TRACK: true,
	ROLE_CROSSOVER: true,
	ROLE_ABANDONED_TRACK: true,
}

const _YARD_ROLES := {
	ROLE_GOODS_YARD_TRACK: true,
	ROLE_LOADING_TRACK: true,
	ROLE_HEADSHUNT: true,
	ROLE_STORAGE_TRACK: true,
	ROLE_DEPOT_TRACK: true,
}

const _SPUR_ROLES := {
	ROLE_INDUSTRIAL_SPUR: true,
	ROLE_AGRICULTURAL_SPUR: true,
}

const _FREIGHT_ENTITY_TYPES := {
	ENTITY_GOODS_YARD: true,
	ENTITY_GOODS_SHED: true,
	ENTITY_INDUSTRY: true,
	ENTITY_AGRICULTURAL_FACILITY: true,
}

const _FREIGHT_TRACK_ROLES := {
	ROLE_GOODS_YARD_TRACK: true,
	ROLE_LOADING_TRACK: true,
	ROLE_HEADSHUNT: true,
	ROLE_STORAGE_TRACK: true,
	ROLE_DEPOT_TRACK: true,
	ROLE_INDUSTRIAL_SPUR: true,
	ROLE_AGRICULTURAL_SPUR: true,
	ROLE_ABANDONED_TRACK: true,
}


func validate_blueprint(blueprint: RefCounted) -> Dictionary:
	var diagnostics: Array[Dictionary] = []
	if blueprint == null or not blueprint.has_method("to_dictionary"):
		_add_diagnostic(diagnostics, "BLUEPRINT_INVALID", "blueprint must expose to_dictionary")
		return _result(diagnostics)
	return validate_semantic_graph(blueprint.to_dictionary())


func validate_semantic_graph(data: Dictionary) -> Dictionary:
	var diagnostics: Array[Dictionary] = []
	_validate_root(data, diagnostics)

	var rail_graph := _as_dictionary(data.get("rail_graph", {}))
	var world_graph := _as_dictionary(data.get("world_graph", {}))
	var nodes := _as_array(rail_graph.get("nodes", []))
	var edges := _as_array(rail_graph.get("edges", []))
	var entities := _as_array(world_graph.get("entities", []))
	var relations := _as_array(world_graph.get("relations", []))

	var node_ids := _collect_ids(nodes, "rail node", "DUPLICATE_NODE_ID", diagnostics)
	var edge_ids := _collect_ids(edges, "rail edge", "DUPLICATE_TRACK_ID", diagnostics)
	var entity_ids := _collect_ids(entities, "world entity", "DUPLICATE_ENTITY_ID", diagnostics)
	var relation_ids := _collect_ids(relations, "world relation", "DUPLICATE_RELATIONSHIP_ID", diagnostics)
	var node_by_id := _index_by_id(nodes)
	var edge_by_id := _index_by_id(edges)
	var entity_by_id := _index_by_id(entities)

	_validate_rail_edges(edges, node_ids, diagnostics)
	_validate_entry_exit_connectivity(rail_graph, node_ids, edges, diagnostics)
	_validate_rail_topology(rail_graph, node_by_id, edge_by_id, relations, entity_by_id, diagnostics)
	_validate_world_graph(world_graph, edge_ids, edge_by_id, entity_ids, entity_by_id, relation_ids, diagnostics)

	return _result(diagnostics)


func _validate_root(data: Dictionary, diagnostics: Array[Dictionary]) -> void:
	_expect_string(data, "grammar_version", diagnostics)
	_expect_string(data, "generator_version", diagnostics)
	_expect_dictionary(data, "rail_graph", diagnostics)
	_expect_dictionary(data, "world_graph", diagnostics)
	if str(data.get("grammar_version", "")) != GRAMMAR_VERSION:
		_add_diagnostic(
			diagnostics,
			"GRAMMAR_VERSION_INVALID",
			"grammar_version must be %s" % GRAMMAR_VERSION,
			"",
			"",
			"",
			"",
			{"expected": GRAMMAR_VERSION, "actual": str(data.get("grammar_version", ""))}
		)
	if str(data.get("generator_version", "")) != GENERATOR_VERSION:
		_add_diagnostic(
			diagnostics,
			"GENERATOR_VERSION_INVALID",
			"generator_version must be %s" % GENERATOR_VERSION,
			"",
			"",
			"",
			"",
			{"expected": GENERATOR_VERSION, "actual": str(data.get("generator_version", ""))}
		)


func _validate_rail_edges(edges: Array, node_ids: Dictionary, diagnostics: Array[Dictionary]) -> void:
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			_add_diagnostic(diagnostics, "TRACK_NOT_DICTIONARY", "rail edge must be a dictionary")
			continue

		var edge_dict := edge as Dictionary
		var edge_id := str(edge_dict.get("id", ""))
		var role := str(edge_dict.get("role", ""))
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))

		if not _ALLOWED_ROLES.has(role):
			_add_diagnostic(
				diagnostics,
				"UNSUPPORTED_TRACK_ROLE",
				"rail edge %s has unsupported source-neutral role %s" % [edge_id, role],
				edge_id,
				"",
				"",
				"",
				{"role": role}
			)
		if not node_ids.has(from_id):
			_add_diagnostic(
				diagnostics,
				"UNKNOWN_TRACK_ENDPOINT_NODE",
				"rail edge %s references unknown_node %s" % [edge_id, from_id],
				edge_id,
				from_id,
				"",
				"",
				{"endpoint": "from"}
			)
		if not node_ids.has(to_id):
			_add_diagnostic(
				diagnostics,
				"UNKNOWN_TRACK_ENDPOINT_NODE",
				"rail edge %s references unknown_node %s" % [edge_id, to_id],
				edge_id,
				to_id,
				"",
				"",
				{"endpoint": "to"}
			)
		if edge_dict.has("source_tag"):
			_add_diagnostic(
				diagnostics,
				"RAW_SOURCE_TAG_IN_RUNTIME_FIXTURE",
				"rail edge %s must not store raw external source_tag in runtime fixture" % edge_id,
				edge_id
			)


func _validate_entry_exit_connectivity(
	rail_graph: Dictionary,
	node_ids: Dictionary,
	edges: Array,
	diagnostics: Array[Dictionary]
) -> void:
	var entry_id := str(rail_graph.get("entry_node", ""))
	var exit_id := str(rail_graph.get("exit_node", ""))
	if entry_id.is_empty():
		_add_diagnostic(diagnostics, "MISSING_ENTRY_NODE", "rail_graph.entry_node is required")
	if exit_id.is_empty():
		_add_diagnostic(diagnostics, "MISSING_EXIT_NODE", "rail_graph.exit_node is required")
	if entry_id.is_empty() or exit_id.is_empty():
		return
	if not node_ids.has(entry_id):
		_add_diagnostic(diagnostics, "ENTRY_NODE_UNKNOWN", "entry_node references unknown_node %s" % entry_id, "", entry_id)
		return
	if not node_ids.has(exit_id):
		_add_diagnostic(diagnostics, "EXIT_NODE_UNKNOWN", "exit_node references unknown_node %s" % exit_id, "", exit_id)
		return
	if not _has_active_path(edges, entry_id, exit_id):
		_add_diagnostic(
			diagnostics,
			"ENTRY_EXIT_DISCONNECTED",
			"entry_node %s has no active route to exit_node %s" % [entry_id, exit_id],
			"",
			entry_id,
			"",
			"",
			{"entry_node": entry_id, "exit_node": exit_id}
		)


func _validate_rail_topology(
	rail_graph: Dictionary,
	node_by_id: Dictionary,
	edge_by_id: Dictionary,
	relations: Array,
	entity_by_id: Dictionary,
	diagnostics: Array[Dictionary]
) -> void:
	var edges := _as_array(rail_graph.get("edges", []))
	var entry_id := str(rail_graph.get("entry_node", ""))
	var active_component := _reachable_active_nodes(edges, entry_id)
	_validate_passing_loops(edges, entry_id, diagnostics)
	_validate_active_stubs(edges, node_by_id, diagnostics)
	_validate_active_connectivity(edges, active_component, diagnostics)
	_validate_yard_connectivity(edges, active_component, diagnostics)
	_validate_spurs(edges, active_component, relations, entity_by_id, edge_by_id, diagnostics)


func _validate_passing_loops(edges: Array, entry_id: String, diagnostics: Array[Dictionary]) -> void:
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("role", "")) != ROLE_PASSING_LOOP:
			continue

		var edge_id := str(edge_dict.get("id", ""))
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))
		var reachable_without_loop := _reachable_active_nodes(edges, entry_id, edge_id)
		var usable_connections := 0
		if from_id != to_id and reachable_without_loop.has(from_id) and _active_degree(edges, from_id, edge_id) > 0:
			usable_connections += 1
		if from_id != to_id and reachable_without_loop.has(to_id) and _active_degree(edges, to_id, edge_id) > 0:
			usable_connections += 1
		if usable_connections < 2:
			_add_diagnostic(
				diagnostics,
				"PASSING_LOOP_NOT_DOUBLE_ENDED",
				"Passing loop %s has only %d usable connection(s) to the active network." % [edge_id, usable_connections],
				edge_id,
				"",
				"",
				"",
				{"usable_connections": usable_connections, "from": from_id, "to": to_id}
			)


func _validate_active_stubs(edges: Array, node_by_id: Dictionary, diagnostics: Array[Dictionary]) -> void:
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		if not _is_active_edge(edge_dict):
			continue

		var edge_id := str(edge_dict.get("id", ""))
		for node_id in [str(edge_dict.get("from", "")), str(edge_dict.get("to", ""))]:
			if node_id.is_empty() or _active_degree(edges, node_id) > 1:
				continue
			var node := node_by_id.get(node_id, {}) as Dictionary
			var node_type := str(node.get("type", ""))
			if node_type == NODE_BUFFER_STOP or node_type == NODE_ENTRY or node_type == NODE_EXIT:
				continue
			_add_diagnostic(
				diagnostics,
				"ACTIVE_STUB_MISSING_TERMINAL",
				"Active dead-end track %s terminates at non-terminal node %s." % [edge_id, node_id],
				edge_id,
				node_id,
				"",
				"",
				{"node_type": node_type}
			)


func _validate_active_connectivity(edges: Array, active_component: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if active_component.is_empty():
		return
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		if not _is_active_edge(edge_dict):
			continue
		var edge_id := str(edge_dict.get("id", ""))
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))
		if active_component.has(from_id) or active_component.has(to_id):
			continue
		_add_diagnostic(
			diagnostics,
			"ISOLATED_ACTIVE_TRACK",
			"Active track %s is isolated from the entry-connected usable railway network." % edge_id,
			edge_id,
			"",
			"",
			"",
			{"from": from_id, "to": to_id}
		)


func _validate_yard_connectivity(edges: Array, active_component: Dictionary, diagnostics: Array[Dictionary]) -> void:
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		var role := str(edge_dict.get("role", ""))
		if not _YARD_ROLES.has(role) or not _is_active_edge(edge_dict):
			continue
		var edge_id := str(edge_dict.get("id", ""))
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))
		if active_component.has(from_id) or active_component.has(to_id):
			continue
		_add_diagnostic(
			diagnostics,
			"YARD_TRACK_DISCONNECTED",
			"Yard/loading track %s is disconnected from the usable railway network." % edge_id,
			edge_id,
			"",
			"",
			"",
			{"role": role}
		)


func _validate_spurs(
	edges: Array,
	active_component: Dictionary,
	relations: Array,
	entity_by_id: Dictionary,
	edge_by_id: Dictionary,
	diagnostics: Array[Dictionary]
) -> void:
	var served_track_ids := _served_freight_track_ids(relations, entity_by_id, edge_by_id)
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		var role := str(edge_dict.get("role", ""))
		if not _SPUR_ROLES.has(role) or not _is_active_edge(edge_dict):
			continue

		var edge_id := str(edge_dict.get("id", ""))
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))
		if not active_component.has(from_id) and not active_component.has(to_id):
			_add_diagnostic(
				diagnostics,
				"SPUR_DISCONNECTED",
				"Spur %s is disconnected from the usable railway network." % edge_id,
				edge_id,
				"",
				"",
				"",
				{"role": role}
			)
			continue

		if not _spur_has_served_facility(edge_dict, edges, served_track_ids):
			_add_diagnostic(
				diagnostics,
				"SPUR_MISSING_SERVED_FACILITY",
				"Spur %s does not serve a freight, industrial or agricultural facility." % edge_id,
				edge_id,
				"",
				"",
				"",
				{"role": role}
			)


func _validate_world_graph(
	world_graph: Dictionary,
	edge_ids: Dictionary,
	edge_by_id: Dictionary,
	entity_ids: Dictionary,
	entity_by_id: Dictionary,
	relation_ids: Dictionary,
	diagnostics: Array[Dictionary]
) -> void:
	if world_graph.is_empty():
		_add_diagnostic(diagnostics, "WORLD_GRAPH_REQUIRED", "world_graph is required")
		return

	var relations := _as_array(world_graph.get("relations", []))
	for relation in relations:
		if typeof(relation) != TYPE_DICTIONARY:
			_add_diagnostic(diagnostics, "RELATION_NOT_DICTIONARY", "world relation must be a dictionary")
			continue

		var relation_dict := relation as Dictionary
		var relation_id := str(relation_dict.get("id", ""))
		var from_entity := str(relation_dict.get("from_entity", ""))
		var to_entity := str(relation_dict.get("to_entity", ""))
		var to_edge := str(relation_dict.get("to_edge", ""))

		if from_entity.is_empty():
			_add_diagnostic(diagnostics, "RELATION_FROM_ENTITY_REQUIRED", "world relation %s requires from_entity" % relation_id, "", "", "", relation_id)
		elif not entity_ids.has(from_entity):
			_add_diagnostic(
				diagnostics,
				"UNKNOWN_RELATIONSHIP_TARGET",
				"world relation %s references unknown_entity %s" % [relation_id, from_entity],
				"",
				"",
				from_entity,
				relation_id
			)

		if to_entity.is_empty() and to_edge.is_empty():
			_add_diagnostic(diagnostics, "RELATION_TARGET_REQUIRED", "world relation %s requires to_entity or to_edge" % relation_id, "", "", from_entity, relation_id)
		if not to_entity.is_empty() and not entity_ids.has(to_entity):
			_add_diagnostic(
				diagnostics,
				"UNKNOWN_RELATIONSHIP_TARGET",
				"world relation %s references unknown_entity %s" % [relation_id, to_entity],
				"",
				"",
				to_entity,
				relation_id
			)
		if not to_edge.is_empty() and not edge_ids.has(to_edge):
			_add_diagnostic(
				diagnostics,
				"UNKNOWN_RELATIONSHIP_TARGET",
				"world relation %s references unknown_edge %s" % [relation_id, to_edge],
				to_edge,
				"",
				from_entity,
				relation_id
			)

		_validate_world_relationship_semantics(relation_dict, entity_by_id, edge_by_id, relations, relation_ids, diagnostics)


func _validate_world_relationship_semantics(
	relation: Dictionary,
	entity_by_id: Dictionary,
	edge_by_id: Dictionary,
	relations: Array,
	_relation_ids: Dictionary,
	diagnostics: Array[Dictionary]
) -> void:
	var relation_id := str(relation.get("id", ""))
	var relation_type := str(relation.get("type", ""))
	var from_entity_id := str(relation.get("from_entity", ""))
	var to_entity_id := str(relation.get("to_entity", ""))
	var to_edge_id := str(relation.get("to_edge", ""))
	var from_entity := entity_by_id.get(from_entity_id, {}) as Dictionary
	var to_entity := entity_by_id.get(to_entity_id, {}) as Dictionary
	var edge := edge_by_id.get(to_edge_id, {}) as Dictionary
	var from_type := str(from_entity.get("type", ""))
	var to_type := str(to_entity.get("type", ""))

	if (relation_type == REL_ADJACENT_TO_TRACK or relation_type == REL_PLATFORM_SERVES_TRACK) and from_type == ENTITY_PLATFORM:
		if edge.is_empty() or not _is_active_edge(edge):
			_add_diagnostic(
				diagnostics,
				"PLATFORM_TRACK_REFERENCE_INVALID",
				"Platform relation %s references missing or unusable track %s." % [relation_id, to_edge_id],
				to_edge_id,
				"",
				from_entity_id,
				relation_id
			)

	if relation_type == REL_FREIGHT_FACILITY_ON_TRACK:
		var role := str(edge.get("role", ""))
		if edge.is_empty() or not _FREIGHT_TRACK_ROLES.has(role):
			_add_diagnostic(
				diagnostics,
				"FREIGHT_FACILITY_TRACK_INVALID",
				"Freight facility relation %s references unsuitable track %s." % [relation_id, to_edge_id],
				to_edge_id,
				"",
				from_entity_id,
				relation_id,
				{"role": role}
			)

	if relation_type == REL_ROAD_ACCESS:
		if from_type != ENTITY_ROAD or to_entity.is_empty():
			_add_diagnostic(
				diagnostics,
				"ROAD_ACCESS_INVALID",
				"Road access relation %s must originate at ROAD and resolve its target." % relation_id,
				"",
				"",
				from_entity_id,
				relation_id,
				{"from_type": from_type, "to_type": to_type}
			)

	if relation_type == REL_BRIDGE_CARRIES_TRACK:
		if from_type != ENTITY_BRIDGE or edge.is_empty() or not _is_active_edge(edge):
			_add_diagnostic(
				diagnostics,
				"BRIDGE_TRACK_REFERENCE_INVALID",
				"Bridge relation %s references missing or unusable rail edge %s." % [relation_id, to_edge_id],
				to_edge_id,
				"",
				from_entity_id,
				relation_id
			)
		if not _has_water_crossing_for_edge(relations, to_edge_id):
			_add_diagnostic(
				diagnostics,
				"BRIDGE_CROSSING_MISSING",
				"Bridge relation %s has no corresponding water crossing on track %s." % [relation_id, to_edge_id],
				to_edge_id,
				"",
				from_entity_id,
				relation_id
			)

	if relation_type == REL_WATER_CROSSED_BY_TRACK:
		if edge.is_empty() or not _is_active_edge(edge):
			_add_diagnostic(
				diagnostics,
				"BRIDGE_TRACK_REFERENCE_INVALID",
				"Water crossing relation %s references missing or unusable rail edge %s." % [relation_id, to_edge_id],
				to_edge_id,
				"",
				from_entity_id,
				relation_id
			)

	if relation_type == REL_SERVES_SETTLEMENT:
		if from_type != ENTITY_STATION or to_type != ENTITY_SETTLEMENT:
			_add_diagnostic(
				diagnostics,
				"SETTLEMENT_STATION_RELATION_INVALID",
				"Settlement relation %s must connect STATION to SETTLEMENT." % relation_id,
				"",
				"",
				from_entity_id,
				relation_id,
				{"from_type": from_type, "to_type": to_type}
			)

	if _FREIGHT_ENTITY_TYPES.has(from_type):
		_validate_entity_has_freight_service(from_entity_id, from_type, relations, diagnostics)


func _validate_entity_has_freight_service(
	entity_id: String,
	entity_type: String,
	relations: Array,
	diagnostics: Array[Dictionary]
) -> void:
	for relation in relations:
		if typeof(relation) != TYPE_DICTIONARY:
			continue
		var relation_dict := relation as Dictionary
		if str(relation_dict.get("type", "")) == REL_FREIGHT_FACILITY_ON_TRACK and str(relation_dict.get("from_entity", "")) == entity_id:
			return
	_add_diagnostic(
		diagnostics,
		"INDUSTRY_MISSING_RAIL_SERVICE",
		"Rail-service entity %s has no freight facility track relationship." % entity_id,
		"",
		"",
		entity_id,
		"",
		{"entity_type": entity_type}
	)


func _collect_ids(items: Array, label: String, duplicate_code: String, diagnostics: Array[Dictionary]) -> Dictionary:
	var ids: Dictionary = {}
	if items.is_empty():
		_add_diagnostic(diagnostics, "%s_LIST_REQUIRED" % label.to_upper().replace(" ", "_"), "%s list is required" % label)
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			_add_diagnostic(diagnostics, "%s_NOT_DICTIONARY" % label.to_upper().replace(" ", "_"), "%s must be a dictionary" % label)
			continue

		var item_dict := item as Dictionary
		var id := str(item_dict.get("id", ""))
		if id.is_empty():
			_add_diagnostic(diagnostics, "%s_ID_REQUIRED" % label.to_upper().replace(" ", "_"), "%s id is required" % label)
			continue
		if ids.has(id):
			_add_diagnostic(diagnostics, duplicate_code, "duplicate %s id %s" % [label, id], id, id)
			continue
		ids[id] = true
	return ids


func _index_by_id(items: Array) -> Dictionary:
	var indexed: Dictionary = {}
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var item_dict := item as Dictionary
		var id := str(item_dict.get("id", ""))
		if id.is_empty() or indexed.has(id):
			continue
		indexed[id] = item_dict
	return indexed


func _has_active_path(edges: Array, entry_id: String, exit_id: String) -> bool:
	return _reachable_active_nodes(edges, entry_id).has(exit_id)


func _reachable_active_nodes(edges: Array, start_id: String, excluded_edge_id: String = "") -> Dictionary:
	var adjacency := _build_active_adjacency(edges, excluded_edge_id)
	var frontier: Array[String] = [start_id]
	var visited: Dictionary = {}
	while not frontier.is_empty():
		var current := str(frontier.pop_front())
		if visited.has(current):
			continue
		visited[current] = true
		for next_id in adjacency.get(current, []):
			var next_string := str(next_id)
			if not visited.has(next_string):
				frontier.append(next_string)
	return visited


func _build_active_adjacency(edges: Array, excluded_edge_id: String = "") -> Dictionary:
	var adjacency: Dictionary = {}
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("id", "")) == excluded_edge_id or not _is_active_edge(edge_dict):
			continue
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue
		if not adjacency.has(from_id):
			adjacency[from_id] = []
		(adjacency[from_id] as Array).append(to_id)
		if bool(edge_dict.get("bidirectional", true)):
			if not adjacency.has(to_id):
				adjacency[to_id] = []
			(adjacency[to_id] as Array).append(from_id)
	return adjacency


func _active_degree(edges: Array, node_id: String, excluded_edge_id: String = "") -> int:
	var degree := 0
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("id", "")) == excluded_edge_id or not _is_active_edge(edge_dict):
			continue
		if str(edge_dict.get("from", "")) == node_id:
			degree += 1
		if str(edge_dict.get("to", "")) == node_id:
			degree += 1
	return degree


func _is_active_edge(edge: Dictionary) -> bool:
	var role := str(edge.get("role", ""))
	return _ALLOWED_ROLES.has(role) and role != ROLE_ABANDONED_TRACK


func _served_freight_track_ids(relations: Array, entity_by_id: Dictionary, edge_by_id: Dictionary) -> Dictionary:
	var served: Dictionary = {}
	for relation in relations:
		if typeof(relation) != TYPE_DICTIONARY:
			continue
		var relation_dict := relation as Dictionary
		if str(relation_dict.get("type", "")) != REL_FREIGHT_FACILITY_ON_TRACK:
			continue
		var entity_id := str(relation_dict.get("from_entity", ""))
		var edge_id := str(relation_dict.get("to_edge", ""))
		var entity := entity_by_id.get(entity_id, {}) as Dictionary
		var edge := edge_by_id.get(edge_id, {}) as Dictionary
		if _FREIGHT_ENTITY_TYPES.has(str(entity.get("type", ""))) and not edge.is_empty():
			served[edge_id] = true
	return served


func _spur_has_served_facility(spur: Dictionary, edges: Array, served_track_ids: Dictionary) -> bool:
	var spur_id := str(spur.get("id", ""))
	if served_track_ids.has(spur_id):
		return true
	var spur_from := str(spur.get("from", ""))
	var spur_to := str(spur.get("to", ""))
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("role", "")) != ROLE_LOADING_TRACK or not _is_active_edge(edge_dict):
			continue
		var edge_id := str(edge_dict.get("id", ""))
		if not served_track_ids.has(edge_id):
			continue
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))
		if from_id == spur_from or from_id == spur_to or to_id == spur_from or to_id == spur_to:
			return true
	return false


func _has_water_crossing_for_edge(relations: Array, edge_id: String) -> bool:
	for relation in relations:
		if typeof(relation) != TYPE_DICTIONARY:
			continue
		var relation_dict := relation as Dictionary
		if str(relation_dict.get("type", "")) == REL_WATER_CROSSED_BY_TRACK and str(relation_dict.get("to_edge", "")) == edge_id:
			return true
	return false


func _expect_string(data: Dictionary, key: String, diagnostics: Array[Dictionary]) -> void:
	if data.has(key) and typeof(data.get(key)) == TYPE_STRING and not str(data.get(key)).is_empty():
		return
	_add_diagnostic(diagnostics, "%s_REQUIRED" % key.to_upper(), "%s is required" % key)


func _expect_dictionary(data: Dictionary, key: String, diagnostics: Array[Dictionary]) -> void:
	if data.has(key) and typeof(data.get(key)) == TYPE_DICTIONARY:
		return
	_add_diagnostic(diagnostics, "%s_REQUIRED" % key.to_upper(), "%s is required" % key)


func _as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value as Dictionary
	return {}


func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value as Array
	return []


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


func _result(diagnostics: Array[Dictionary]) -> Dictionary:
	var errors: Array[String] = []
	for diagnostic in diagnostics:
		errors.append(_format_diagnostic(diagnostic))
	return {
		"valid": diagnostics.is_empty(),
		"errors": errors,
		"diagnostics": diagnostics,
	}


func _format_diagnostic(diagnostic: Dictionary) -> String:
	var parts: Array[String] = ["[%s]" % str(diagnostic.get("code", "")), str(diagnostic.get("message", ""))]
	var track_id := str(diagnostic.get("track_id", ""))
	var node_id := str(diagnostic.get("node_id", ""))
	var entity_id := str(diagnostic.get("entity_id", ""))
	var relationship_id := str(diagnostic.get("relationship_id", ""))
	if not track_id.is_empty():
		parts.append("track=%s" % track_id)
	if not node_id.is_empty():
		parts.append("node=%s" % node_id)
	if not entity_id.is_empty():
		parts.append("entity=%s" % entity_id)
	if not relationship_id.is_empty():
		parts.append("relationship=%s" % relationship_id)
	return " ".join(parts)
