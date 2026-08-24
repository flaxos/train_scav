extends SceneTree

const GENERATOR_PATH := "res://scripts/worldgen/worldgen_semantic_generator.gd"
const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const VILLAGE_FIXTURE := "res://data/worldgen/archetypes/reference/village_passing_station_v1.json"
const GENERATOR_VERSION_9G := "9g_village_passing_station_semantic_v1"
const LEGACY_BLUEPRINT_GENERATOR_VERSION := "9a_schema_v1"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9G Semantic Generator Tests ---")
	_required_files_exist()
	_generator_rejects_wrong_generation_version()
	_same_request_generates_identical_valid_blueprint_and_trace()
	_generated_blueprint_is_not_authored_fixture_clone()
	_generated_samples_print_for_developer_acceptance()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(GENERATOR_PATH), "9G semantic generator exists")
	_expect(ResourceLoader.exists(REQUEST_PATH), "9F generation request exists")
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "9C semantic validator exists")
	_expect(ResourceLoader.exists(LOADER_PATH), "fixture loader exists for authored-reference comparison")
	_expect(ResourceLoader.exists(CANONICAL_PATH), "canonical helper exists")
	_expect(FileAccess.file_exists(VILLAGE_FIXTURE), "authored village fixture exists")


func _generator_rejects_wrong_generation_version() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	if generator == null or request_script == null:
		return

	var request: RefCounted = request_script.create(12345, 0, "forward", "central_eu_v1")
	var result: Dictionary = generator.generate_blueprint(request)
	_expect(not bool(result.get("success", true)), "9G generator rejects default 9F generator identity")
	_expect(result.get("blueprint", null) == null, "version mismatch returns no blueprint")
	_expect(_has_diagnostic_code(result, "GENERATOR_VERSION_MISMATCH"), "version mismatch reports structured diagnostic")


func _same_request_generates_identical_valid_blueprint_and_trace() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	var canonical := _load_script(CANONICAL_PATH)
	if generator == null or request_script == null or validator == null or canonical == null:
		return

	var request: RefCounted = _make_request(request_script, 100, 2)
	var first: Dictionary = generator.generate_blueprint(request)
	var second: Dictionary = generator.generate_blueprint(request)
	_expect(bool(first.get("success", false)), "9G generation succeeds for valid request")
	_expect((first.get("diagnostics", []) as Array).is_empty(), "successful generation has no diagnostics")
	_expect(bool(second.get("success", false)), "same request generation succeeds twice")
	if not bool(first.get("success", false)) or not bool(second.get("success", false)):
		printerr("First diagnostics: %s" % str(first.get("diagnostics", [])))
		printerr("Second diagnostics: %s" % str(second.get("diagnostics", [])))
		return

	var first_blueprint: RefCounted = first.get("blueprint", null)
	var second_blueprint: RefCounted = second.get("blueprint", null)
	var first_trace: RefCounted = first.get("generation_trace", null)
	var second_trace: RefCounted = second.get("generation_trace", null)
	_expect(first_blueprint != null and second_blueprint != null, "result exposes generated SectorBlueprint")
	_expect(first_trace != null and second_trace != null, "result exposes generation trace")
	if first_blueprint == null or second_blueprint == null or first_trace == null or second_trace == null:
		return

	var data: Dictionary = first_blueprint.to_dictionary()
	_expect(str(data.get("archetype_id", "")) == "village_passing_station", "generated archetype is village_passing_station")
	_expect(str(data.get("generator_version", "")) == LEGACY_BLUEPRINT_GENERATOR_VERSION, "generated blueprint keeps validator-compatible legacy generator_version")
	_expect(str(first_trace.to_dictionary().get("generator_version", "")) == GENERATOR_VERSION_9G, "generation trace records actual 9G generator identity")
	_expect(str(first_blueprint.get_canonical_hash()) == str(second_blueprint.get_canonical_hash()), "same request produces identical blueprint hash")
	_expect(str(first_trace.get_canonical_hash()) == str(second_trace.get_canonical_hash()), "same request produces identical trace hash")
	_expect(str(canonical.canonical_stringify(first.get("decisions", {}))) == str(canonical.canonical_stringify(second.get("decisions", {}))), "same request produces identical decisions")

	var validation: Dictionary = validator.validate_blueprint(first_blueprint)
	_expect(bool(validation.get("valid", false)), "generated blueprint validates through 9C")
	if not bool(validation.get("valid", false)):
		printerr("Validation diagnostics: %s" % str(validation.get("diagnostics", [])))
	_expect(first_blueprint.has_rail_path(), "generated blueprint has active entry-to-exit path")
	_expect(first_blueprint.get_nodes_by_type("ENTRY").size() == 1, "generated blueprint has one entry node")
	_expect(first_blueprint.get_nodes_by_type("EXIT").size() == 1, "generated blueprint has one exit node")
	_expect(first_blueprint.get_tracks_by_role("PASSING_LOOP").size() == 1, "generated blueprint has one passing loop")
	_expect(not first_blueprint.get_station().is_empty(), "generated blueprint has station semantics")
	_expect(first_blueprint.get_entities_by_type("PLATFORM").size() == 1, "generated blueprint has one platform")
	_expect(first_blueprint.get_entities_by_type("SETTLEMENT").size() == 1, "generated blueprint has one settlement")
	_expect(first_blueprint.get_goods_yards().is_empty(), "9G village generator does not create goods yards")
	_expect(first_blueprint.get_industries().is_empty(), "9G village generator does not create industries")
	_expect(first_blueprint.get_water_crossings().is_empty(), "9G village generator does not create water crossings")
	_expect(_platform_relation_targets_valid_track(data), "platform relation targets a generated active rail edge")
	_expect(_relationships_resolve(data), "all generated world relationships resolve")
	_expect(_stage_decisions_contain_actual_choices(first_trace.to_dictionary(), first.get("decisions", {}) as Dictionary), "generation trace records actual 9G decisions")


func _generated_blueprint_is_not_authored_fixture_clone() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	var loader := _load_script(LOADER_PATH)
	if generator == null or request_script == null or loader == null:
		return

	var generated: Dictionary = generator.generate_blueprint(_make_request(request_script, 101, 0))
	_expect(bool(generated.get("success", false)), "generated blueprint succeeds for authored-clone comparison")
	if not bool(generated.get("success", false)):
		return
	var generated_blueprint: RefCounted = generated.get("blueprint", null)
	var authored = loader.load_blueprint(VILLAGE_FIXTURE)
	_expect(authored != null, "authored village fixture loads")
	if generated_blueprint == null or authored == null:
		return
	_expect(str(generated_blueprint.get_canonical_hash()) != str(authored.get_canonical_hash()), "generated village blueprint is not a clone of authored fixture")

	var source_text := _read_text(GENERATOR_PATH)
	_expect(not source_text.contains("WorldgenFixtureLoader"), "semantic generator does not depend on fixture loader")
	_expect(not source_text.contains("village_passing_station_v1.json"), "semantic generator does not reference authored village fixture path")


func _generated_samples_print_for_developer_acceptance() -> void:
	var generator := _load_script(GENERATOR_PATH)
	var request_script := _load_script(REQUEST_PATH)
	if generator == null or request_script == null:
		return
	for seed in [100, 101, 102]:
		var result: Dictionary = generator.generate_blueprint(_make_request(request_script, seed, 0))
		if not bool(result.get("success", false)):
			continue
		var blueprint: RefCounted = result.get("blueprint", null)
		var decisions := result.get("decisions", {}) as Dictionary
		print("Sprint 9G sample seed %d: hash=%s platform_track=%s road_access=%s" % [
			seed,
			str(blueprint.get_canonical_hash()),
			str(decisions.get("platform_track", "")),
			str(decisions.get("road_access", "")),
		])


func _make_request(request_script: RefCounted, run_seed: int, sector_index: int) -> RefCounted:
	return request_script.create(
		run_seed,
		sector_index,
		"forward",
		"central_eu_v1",
		"central_eu_small_town_station_v1",
		GENERATOR_VERSION_9G
	)


func _platform_relation_targets_valid_track(data: Dictionary) -> bool:
	var edges: Dictionary = {}
	for edge in ((data.get("rail_graph", {}) as Dictionary).get("edges", []) as Array):
		var edge_dict := edge as Dictionary
		edges[str(edge_dict.get("id", ""))] = str(edge_dict.get("role", ""))
	for relation in ((data.get("world_graph", {}) as Dictionary).get("relations", []) as Array):
		var relation_dict := relation as Dictionary
		if str(relation_dict.get("from_entity", "")) != "platform_01":
			continue
		var edge_id := str(relation_dict.get("to_edge", ""))
		return edges.has(edge_id) and str(edges[edge_id]) != "ABANDONED_TRACK"
	return false


func _relationships_resolve(data: Dictionary) -> bool:
	var edges := _ids_for(((data.get("rail_graph", {}) as Dictionary).get("edges", []) as Array))
	var entities := _ids_for(((data.get("world_graph", {}) as Dictionary).get("entities", []) as Array))
	for relation in ((data.get("world_graph", {}) as Dictionary).get("relations", []) as Array):
		var relation_dict := relation as Dictionary
		if not entities.has(str(relation_dict.get("from_entity", ""))):
			return false
		var to_entity := str(relation_dict.get("to_entity", ""))
		var to_edge := str(relation_dict.get("to_edge", ""))
		if not to_entity.is_empty() and not entities.has(to_entity):
			return false
		if not to_edge.is_empty() and not edges.has(to_edge):
			return false
	return true


func _stage_decisions_contain_actual_choices(trace_data: Dictionary, decisions: Dictionary) -> bool:
	var seen: Dictionary = {}
	for raw_decision in trace_data.get("stage_decisions", []) as Array:
		var decision := raw_decision as Dictionary
		seen[str(decision.get("key", ""))] = decision
	for key in ["archetype", "platform_track", "road_access"]:
		if not seen.has(key):
			return false
		if str((seen[key] as Dictionary).get("value", "")) != str(decisions.get(key, "")):
			return false
	return true


func _ids_for(items: Array) -> Dictionary:
	var ids: Dictionary = {}
	for item in items:
		ids[str((item as Dictionary).get("id", ""))] = true
	return ids


func _has_diagnostic_code(result: Dictionary, code: String) -> bool:
	for diagnostic in result.get("diagnostics", []) as Array:
		if str((diagnostic as Dictionary).get("code", "")) == code:
			return true
	return false


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_expect(false, "can read %s" % path)
		return ""
	return file.get_as_text()


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		_expect(false, "%s loads and can instantiate" % path)
		return null
	return script.new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9G semantic generator acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9G semantic generator acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
