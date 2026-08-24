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


func validate_semantic_graph(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	_validate_root(data, errors)

	var rail_graph: Dictionary = data.get("rail_graph", {})
	var node_ids := _collect_ids(rail_graph.get("nodes", []), "rail node", errors)
	var edge_ids := _collect_ids(rail_graph.get("edges", []), "rail edge", errors)
	_validate_rail_edges(rail_graph.get("edges", []), node_ids, errors)
	_validate_entry_exit_connectivity(rail_graph, node_ids, errors)
	_validate_world_graph(data.get("world_graph", {}), edge_ids, errors)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


func _validate_root(data: Dictionary, errors: Array[String]) -> void:
	_expect_string(data, "grammar_version", errors)
	_expect_string(data, "generator_version", errors)
	_expect_dictionary(data, "rail_graph", errors)
	_expect_dictionary(data, "world_graph", errors)
	if str(data.get("grammar_version", "")) != GRAMMAR_VERSION:
		errors.append("grammar_version must be %s" % GRAMMAR_VERSION)
	if str(data.get("generator_version", "")) != GENERATOR_VERSION:
		errors.append("generator_version must be %s" % GENERATOR_VERSION)


func _validate_rail_edges(edges: Array, node_ids: Dictionary, errors: Array[String]) -> void:
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			errors.append("rail edge must be a dictionary")
			continue

		var edge_dict := edge as Dictionary
		var edge_id := str(edge_dict.get("id", ""))
		var role := str(edge_dict.get("role", ""))
		var from_id := str(edge_dict.get("from", ""))
		var to_id := str(edge_dict.get("to", ""))

		if not _ALLOWED_ROLES.has(role):
			errors.append("rail edge %s has unsupported source-neutral role %s" % [edge_id, role])
		if not node_ids.has(from_id):
			errors.append("rail edge %s references unknown_node %s" % [edge_id, from_id])
		if not node_ids.has(to_id):
			errors.append("rail edge %s references unknown_node %s" % [edge_id, to_id])
		if edge_dict.has("source_tag"):
			errors.append("rail edge %s must not store raw external source_tag in runtime fixture" % edge_id)


func _validate_entry_exit_connectivity(rail_graph: Dictionary, node_ids: Dictionary, errors: Array[String]) -> void:
	var entry_id := str(rail_graph.get("entry_node", ""))
	var exit_id := str(rail_graph.get("exit_node", ""))
	if entry_id.is_empty():
		errors.append("rail_graph.entry_node is required")
	if exit_id.is_empty():
		errors.append("rail_graph.exit_node is required")
	if entry_id.is_empty() or exit_id.is_empty():
		return
	if not node_ids.has(entry_id):
		errors.append("entry_node references unknown_node %s" % entry_id)
		return
	if not node_ids.has(exit_id):
		errors.append("exit_node references unknown_node %s" % exit_id)
		return
	if not _has_path(rail_graph.get("edges", []), entry_id, exit_id):
		errors.append("entry_node %s has no route to exit_node %s" % [entry_id, exit_id])


func _validate_world_graph(world_graph: Dictionary, edge_ids: Dictionary, errors: Array[String]) -> void:
	if world_graph.is_empty():
		errors.append("world_graph is required")
		return

	var entity_ids := _collect_ids(world_graph.get("entities", []), "world entity", errors)
	for relation in world_graph.get("relations", []):
		if typeof(relation) != TYPE_DICTIONARY:
			errors.append("world relation must be a dictionary")
			continue

		var relation_dict := relation as Dictionary
		var relation_id := str(relation_dict.get("id", ""))
		var from_entity := str(relation_dict.get("from_entity", ""))
		var to_entity := str(relation_dict.get("to_entity", ""))
		var to_edge := str(relation_dict.get("to_edge", ""))

		if from_entity.is_empty():
			errors.append("world relation %s requires from_entity" % relation_id)
		elif not entity_ids.has(from_entity):
			errors.append("world relation %s references unknown_entity %s" % [relation_id, from_entity])

		if to_entity.is_empty() and to_edge.is_empty():
			errors.append("world relation %s requires to_entity or to_edge" % relation_id)
		if not to_entity.is_empty() and not entity_ids.has(to_entity):
			errors.append("world relation %s references unknown_entity %s" % [relation_id, to_entity])
		if not to_edge.is_empty() and not edge_ids.has(to_edge):
			errors.append("world relation %s references unknown_edge %s" % [relation_id, to_edge])


func _collect_ids(items: Array, label: String, errors: Array[String]) -> Dictionary:
	var ids: Dictionary = {}
	if items.is_empty():
		errors.append("%s list is required" % label)
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			errors.append("%s must be a dictionary" % label)
			continue

		var item_dict := item as Dictionary
		var id := str(item_dict.get("id", ""))
		if id.is_empty():
			errors.append("%s id is required" % label)
			continue
		if ids.has(id):
			errors.append("duplicate %s id %s" % [label, id])
			continue
		ids[id] = true
	return ids


func _has_path(edges: Array, entry_id: String, exit_id: String) -> bool:
	var adjacency: Dictionary = {}
	for edge in edges:
		if typeof(edge) != TYPE_DICTIONARY:
			continue
		var edge_dict := edge as Dictionary
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

	var frontier: Array[String] = [entry_id]
	var visited: Dictionary = {}
	while not frontier.is_empty():
		var current: String = str(frontier.pop_front())
		if current == exit_id:
			return true
		if visited.has(current):
			continue
		visited[current] = true
		for next_id in adjacency.get(current, []):
			if not visited.has(str(next_id)):
				frontier.append(str(next_id))
	return false


func _expect_string(data: Dictionary, key: String, errors: Array[String]) -> void:
	if data.has(key) and typeof(data.get(key)) == TYPE_STRING and not str(data.get(key)).is_empty():
		return
	errors.append("%s is required" % key)


func _expect_dictionary(data: Dictionary, key: String, errors: Array[String]) -> void:
	if data.has(key) and typeof(data.get(key)) == TYPE_DICTIONARY:
		return
	errors.append("%s is required" % key)
