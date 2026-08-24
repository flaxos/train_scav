extends SceneTree

const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const BLUEPRINT_PATH := "res://scripts/worldgen/sector_blueprint.gd"
const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const REGISTRY_PATH := "res://data/worldgen/archetypes/reference_archetypes_v1.json"
const GOODS_FIXTURE := "res://data/worldgen/archetypes/reference/small_town_goods_station_v1.json"
const VILLAGE_FIXTURE := "res://data/worldgen/archetypes/reference/village_passing_station_v1.json"
const RURAL_FIXTURE := "res://data/worldgen/archetypes/reference/rural_through_v1.json"
const AGRI_FIXTURE := "res://data/worldgen/archetypes/reference/agricultural_loading_point_v1.json"
const RIVER_FIXTURE := "res://data/worldgen/archetypes/reference/river_valley_constrained_v1.json"
const DECLINING_FIXTURE := "res://data/worldgen/archetypes/reference/declining_abandoned_branch_v1.json"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9C Semantic Topology Validator Tests ---")
	_required_api_exists()
	_reference_blueprints_still_validate_and_are_not_mutated()
	_topology_mutations_report_diagnostic_codes_and_ids()
	_world_relationship_mutations_report_diagnostic_codes_and_ids()
	_finish()


func _required_api_exists() -> void:
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "worldgen validator exists")
	_expect(ResourceLoader.exists(BLUEPRINT_PATH), "SectorBlueprint exists")
	_expect(ResourceLoader.exists(LOADER_PATH), "fixture loader exists")
	if not ResourceLoader.exists(VALIDATOR_PATH):
		return
	var validator: RefCounted = (load(VALIDATOR_PATH) as Script).new()
	_expect(validator.has_method("validate_blueprint"), "validator exposes validate_blueprint")


func _reference_blueprints_still_validate_and_are_not_mutated() -> void:
	var validator := _load_validator()
	var loader := _load_loader()
	var canonical := _load_canonical()
	if validator == null or loader == null or canonical == null or not validator.has_method("validate_blueprint"):
		return

	var registry: Array = loader.load_registry(REGISTRY_PATH)
	_expect(registry.size() == 6, "registry still contains six Sprint 9B reference archetypes")
	for entry in registry:
		var path := str((entry as Dictionary).get("path", ""))
		var blueprint = loader.load_blueprint(path)
		_expect(blueprint != null, "%s constructs a blueprint" % path)
		if blueprint == null:
			continue

		var before_hash := str(blueprint.get_canonical_hash())
		var before_data: Dictionary = blueprint.to_dictionary()
		var before_canonical := str(canonical.canonical_stringify(before_data))
		var result: Dictionary = validator.validate_blueprint(blueprint)
		var after_canonical := str(canonical.canonical_stringify(blueprint.to_dictionary()))
		var after_hash := str(blueprint.get_canonical_hash())

		_expect(bool(result.get("valid", false)), "%s validates through 9C semantic validator" % path)
		_expect((result.get("diagnostics", []) as Array).is_empty(), "%s has no 9C diagnostics" % path)
		_expect(after_hash == before_hash, "%s validation leaves canonical hash unchanged" % path)
		_expect(after_canonical == before_canonical, "%s validation does not mutate blueprint data" % path)


func _topology_mutations_report_diagnostic_codes_and_ids() -> void:
	var validator := _load_validator()
	if validator == null or not validator.has_method("validate_blueprint"):
		return

	var disconnected := _read_json(GOODS_FIXTURE)
	_add_node(disconnected, "isolated_exit_feed", "JOINT")
	_set_edge_field(disconnected, "main_east", "from", "isolated_exit_feed")
	_expect_diagnostic(
		_validate_data(validator, disconnected),
		"ENTRY_EXIT_DISCONNECTED",
		"",
		"",
		"",
		""
	)

	var one_ended_loop := _read_json(VILLAGE_FIXTURE)
	_add_node(one_ended_loop, "dead_loop_buffer", "BUFFER_STOP")
	_set_edge_field(one_ended_loop, "passing_loop", "to", "dead_loop_buffer")
	_expect_diagnostic(
		_validate_data(validator, one_ended_loop),
		"PASSING_LOOP_NOT_DOUBLE_ENDED",
		"passing_loop",
		"",
		"",
		""
	)

	var isolated_track := _read_json(RURAL_FIXTURE)
	_add_node(isolated_track, "isolated_switch", "SWITCH")
	_add_node(isolated_track, "isolated_buffer", "BUFFER_STOP")
	_add_edge(isolated_track, {
		"id": "isolated_active",
		"role": "STORAGE_TRACK",
		"from": "isolated_switch",
		"to": "isolated_buffer",
		"bidirectional": true,
	})
	_expect_diagnostic(
		_validate_data(validator, isolated_track),
		"ISOLATED_ACTIVE_TRACK",
		"isolated_active",
		"",
		"",
		""
	)

	var disconnected_yard := _read_json(GOODS_FIXTURE)
	_add_node(disconnected_yard, "detached_yard_feed", "JOINT")
	_set_edge_field(disconnected_yard, "goods_yard_lead", "from", "detached_yard_feed")
	_expect_diagnostic(
		_validate_data(validator, disconnected_yard),
		"YARD_TRACK_DISCONNECTED",
		"goods_yard_lead",
		"",
		"",
		""
	)

	var spur_without_facility := _read_json(AGRI_FIXTURE)
	_remove_relation(spur_without_facility, "coop_on_spur")
	_remove_relation(spur_without_facility, "grain_store_on_loading")
	_expect_diagnostic(
		_validate_data(validator, spur_without_facility),
		"SPUR_MISSING_SERVED_FACILITY",
		"agricultural_spur",
		"",
		"",
		""
	)


func _world_relationship_mutations_report_diagnostic_codes_and_ids() -> void:
	var validator := _load_validator()
	if validator == null or not validator.has_method("validate_blueprint"):
		return

	var unresolved_relation := _read_json(RURAL_FIXTURE)
	_set_relation_field(unresolved_relation, "wayside_stop_on_main", "to_edge", "missing_track")
	_expect_diagnostic(
		_validate_data(validator, unresolved_relation),
		"UNKNOWN_RELATIONSHIP_TARGET",
		"missing_track",
		"",
		"",
		"wayside_stop_on_main"
	)

	var bridge_without_crossing := _read_json(RIVER_FIXTURE)
	_remove_relation(bridge_without_crossing, "creek_crossed_by_main")
	_expect_diagnostic(
		_validate_data(validator, bridge_without_crossing),
		"BRIDGE_CROSSING_MISSING",
		"creek_bridge_main",
		"",
		"",
		"bridge_carries_main"
	)

	var platform_on_abandoned := _read_json(DECLINING_FIXTURE)
	_set_relation_field(platform_on_abandoned, "platform_on_worn_main", "to_edge", "abandoned_loading_track")
	_expect_diagnostic(
		_validate_data(validator, platform_on_abandoned),
		"PLATFORM_TRACK_REFERENCE_INVALID",
		"abandoned_loading_track",
		"",
		"branch_platform",
		"platform_on_worn_main"
	)


func _validate_data(validator: RefCounted, data: Dictionary) -> Dictionary:
	var blueprint = _make_blueprint(data)
	if blueprint == null:
		return {}
	return validator.validate_blueprint(blueprint)


func _make_blueprint(data: Dictionary):
	if not ResourceLoader.exists(BLUEPRINT_PATH):
		return null
	return (load(BLUEPRINT_PATH) as Script).new(data)


func _load_validator() -> RefCounted:
	if not ResourceLoader.exists(VALIDATOR_PATH):
		return null
	return (load(VALIDATOR_PATH) as Script).new()


func _load_loader() -> RefCounted:
	if not ResourceLoader.exists(LOADER_PATH):
		return null
	return (load(LOADER_PATH) as Script).new()


func _load_canonical() -> RefCounted:
	if not ResourceLoader.exists(CANONICAL_PATH):
		return null
	return (load(CANONICAL_PATH) as Script).new()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_expect(false, "%s exists" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_expect(false, "can open %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_expect(false, "%s parses as dictionary" % path)
		return {}
	return parsed as Dictionary


func _add_node(data: Dictionary, node_id: String, node_type: String) -> void:
	var nodes: Array = (data.get("rail_graph", {}) as Dictionary).get("nodes", [])
	nodes.append({"id": node_id, "type": node_type})


func _add_edge(data: Dictionary, edge: Dictionary) -> void:
	var edges: Array = (data.get("rail_graph", {}) as Dictionary).get("edges", [])
	edges.append(edge)


func _set_edge_field(data: Dictionary, edge_id: String, field: String, value: Variant) -> void:
	for edge in (data.get("rail_graph", {}) as Dictionary).get("edges", []):
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("id", "")) == edge_id:
			edge_dict[field] = value
			return
	_expect(false, "test mutation found edge %s" % edge_id)


func _set_relation_field(data: Dictionary, relation_id: String, field: String, value: Variant) -> void:
	for relation in (data.get("world_graph", {}) as Dictionary).get("relations", []):
		var relation_dict := relation as Dictionary
		if str(relation_dict.get("id", "")) == relation_id:
			relation_dict[field] = value
			return
	_expect(false, "test mutation found relation %s" % relation_id)


func _remove_relation(data: Dictionary, relation_id: String) -> void:
	var relations: Array = (data.get("world_graph", {}) as Dictionary).get("relations", [])
	for i in range(relations.size() - 1, -1, -1):
		var relation_dict := relations[i] as Dictionary
		if str(relation_dict.get("id", "")) == relation_id:
			relations.remove_at(i)
			return
	_expect(false, "test mutation removed relation %s" % relation_id)


func _expect_diagnostic(
	result: Dictionary,
	code: String,
	track_id: String,
	node_id: String,
	entity_id: String,
	relationship_id: String
) -> void:
	_expect(not bool(result.get("valid", true)), "%s mutation is rejected" % code)
	var diagnostics: Array = result.get("diagnostics", [])
	for diagnostic in diagnostics:
		var diagnostic_dict := diagnostic as Dictionary
		if str(diagnostic_dict.get("code", "")) != code:
			continue
		if not track_id.is_empty() and str(diagnostic_dict.get("track_id", "")) != track_id:
			continue
		if not node_id.is_empty() and str(diagnostic_dict.get("node_id", "")) != node_id:
			continue
		if not entity_id.is_empty() and str(diagnostic_dict.get("entity_id", "")) != entity_id:
			continue
		if not relationship_id.is_empty() and str(diagnostic_dict.get("relationship_id", "")) != relationship_id:
			continue
		_expect(not str(diagnostic_dict.get("message", "")).is_empty(), "%s diagnostic has message" % code)
		return
	_failures += 1
	printerr("FAIL: expected diagnostic %s track=%s node=%s entity=%s relation=%s in %s" % [
		code,
		track_id,
		node_id,
		entity_id,
		relationship_id,
		JSON.stringify(diagnostics),
	])


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9C semantic topology validator acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9C semantic topology validator acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
