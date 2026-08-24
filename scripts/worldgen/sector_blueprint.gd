extends RefCounted
class_name SectorBlueprint

const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")

var _data: Dictionary = {}
var _canonical_hash: String = ""


static func from_dictionary(data: Dictionary) -> RefCounted:
	return new(data)


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)
	_canonical_hash = WorldgenCanonical.new().hash_dictionary(_data)


func to_dictionary() -> Dictionary:
	return _data.duplicate(true)


func get_archetype_id() -> String:
	return str(_data.get("archetype_id", ""))


func get_canonical_hash() -> String:
	return _canonical_hash


func get_tracks_by_role(role: String) -> Array[Dictionary]:
	var tracks: Array[Dictionary] = []
	for edge in _get_rail_edges():
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("role", "")) == role:
			tracks.append(edge_dict.duplicate(true))
	return tracks


func get_nodes_by_type(type_name: String) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	for node in _get_rail_nodes():
		var node_dict := node as Dictionary
		if str(node_dict.get("type", "")) == type_name:
			nodes.append(node_dict.duplicate(true))
	return nodes


func get_entities_by_type(type_name: String) -> Array[Dictionary]:
	var entities: Array[Dictionary] = []
	for entity in _get_world_entities():
		var entity_dict := entity as Dictionary
		if str(entity_dict.get("type", "")) == type_name:
			entities.append(entity_dict.duplicate(true))
	return entities


func get_station() -> Dictionary:
	for entity in _get_world_entities():
		var entity_dict := entity as Dictionary
		if str(entity_dict.get("type", "")) == "STATION":
			return entity_dict.duplicate(true)
	return {}


func get_goods_yards() -> Array[Dictionary]:
	var yards: Array[Dictionary] = []
	for entity in _get_world_entities():
		var entity_dict := entity as Dictionary
		if str(entity_dict.get("type", "")) == "GOODS_YARD":
			yards.append(entity_dict.duplicate(true))
	return yards


func get_industries() -> Array[Dictionary]:
	var industries: Array[Dictionary] = []
	for entity in _get_world_entities():
		var entity_dict := entity as Dictionary
		var entity_type := str(entity_dict.get("type", ""))
		if entity_type == "INDUSTRY" or entity_type == "AGRICULTURAL_FACILITY":
			industries.append(entity_dict.duplicate(true))
	return industries


func get_water_crossings() -> Array[Dictionary]:
	var crossings: Array[Dictionary] = []
	for relation in _get_world_relations():
		var relation_dict := relation as Dictionary
		var relation_type := str(relation_dict.get("type", ""))
		if relation_type == "WATER_CROSSED_BY_TRACK" or relation_type == "BRIDGE_CARRIES_TRACK":
			crossings.append(relation_dict.duplicate(true))
	return crossings


func has_rail_path(from_node_id: String = "", to_node_id: String = "") -> bool:
	var rail_graph := _get_rail_graph()
	var start_id := from_node_id
	var end_id := to_node_id
	if start_id.is_empty():
		start_id = str(rail_graph.get("entry_node", ""))
	if end_id.is_empty():
		end_id = str(rail_graph.get("exit_node", ""))
	if start_id.is_empty() or end_id.is_empty():
		return false

	var node_ids: Dictionary = {}
	for node in _get_rail_nodes():
		node_ids[str((node as Dictionary).get("id", ""))] = true
	if not node_ids.has(start_id) or not node_ids.has(end_id):
		return false

	var adjacency: Dictionary = {}
	for edge in _get_rail_edges():
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

	var frontier: Array[String] = [start_id]
	var visited: Dictionary = {}
	while not frontier.is_empty():
		var current := str(frontier.pop_front())
		if current == end_id:
			return true
		if visited.has(current):
			continue
		visited[current] = true
		for next_id in adjacency.get(current, []):
			var next_string := str(next_id)
			if not visited.has(next_string):
				frontier.append(next_string)
	return false


func _get_rail_graph() -> Dictionary:
	return _data.get("rail_graph", {}) as Dictionary


func _get_world_graph() -> Dictionary:
	return _data.get("world_graph", {}) as Dictionary


func _get_rail_nodes() -> Array:
	return _get_rail_graph().get("nodes", []) as Array


func _get_rail_edges() -> Array:
	return _get_rail_graph().get("edges", []) as Array


func _get_world_entities() -> Array:
	return _get_world_graph().get("entities", []) as Array


func _get_world_relations() -> Array:
	return _get_world_graph().get("relations", []) as Array
