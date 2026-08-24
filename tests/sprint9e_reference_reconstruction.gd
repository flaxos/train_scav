extends SceneTree

const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const RECONSTRUCTOR_PATH := "res://scripts/worldgen/worldgen_runtime_reconstructor.gd"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"
const EMBEDDING_REGISTRY_PATH := "res://data/worldgen/embeddings/reference/reference_embeddings_v1.json"
const ROLE_ABANDONED_TRACK := "ABANDONED_TRACK"
const STATUS_DISPLAY_ONLY := "display_only"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9E Reference Reconstruction Tests ---")
	_required_files_exist()
	_all_reference_embeddings_reconstruct()
	_runtime_layouts_are_materially_different()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(LOADER_PATH), "worldgen fixture loader exists")
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "9C semantic validator exists")
	_expect(ResourceLoader.exists(CANONICAL_PATH), "canonical serializer exists")
	_expect(ResourceLoader.exists(RECONSTRUCTOR_PATH), "runtime reconstructor exists")
	_expect(ResourceLoader.exists(RAIL_PATH), "RailMovement exists")
	_expect(FileAccess.file_exists(EMBEDDING_REGISTRY_PATH), "9E embedding registry exists")


func _all_reference_embeddings_reconstruct() -> void:
	var loader := _load_script(LOADER_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	var canonical := _load_script(CANONICAL_PATH)
	var reconstructor := _load_script(RECONSTRUCTOR_PATH)
	var rail_script: Script = load(RAIL_PATH) as Script
	if loader == null or validator == null or canonical == null or reconstructor == null or rail_script == null:
		return

	var registry := _read_embedding_registry(loader)
	_expect(registry.size() == 6, "embedding registry contains all six Sprint 9B archetypes")
	for entry in registry:
		var entry_dict := entry as Dictionary
		var archetype_id := str(entry_dict.get("archetype_id", ""))
		var fixture_path := str(entry_dict.get("fixture_path", ""))
		var embedding_path := str(entry_dict.get("embedding_path", ""))
		_expect(FileAccess.file_exists(fixture_path), "%s semantic fixture exists" % archetype_id)
		_expect(FileAccess.file_exists(embedding_path), "%s authored embedding exists" % archetype_id)
		if not FileAccess.file_exists(fixture_path) or not FileAccess.file_exists(embedding_path):
			continue

		var blueprint = loader.load_blueprint(fixture_path)
		_expect(blueprint != null, "%s constructs SectorBlueprint" % archetype_id)
		if blueprint == null:
			continue

		var before_hash := str(blueprint.get_canonical_hash())
		var before_canonical := str(canonical.canonical_stringify(blueprint.to_dictionary()))
		var semantic_result: Dictionary = validator.validate_blueprint(blueprint)
		_expect(bool(semantic_result.get("valid", false)), "%s semantic validation passes before reconstruction" % archetype_id)

		var embedding: Dictionary = loader.load_json(embedding_path)
		var first_result: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
		var second_result: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
		_expect(bool(first_result.get("valid", false)), "%s runtime reconstruction succeeds" % archetype_id)
		_expect((first_result.get("diagnostics", []) as Array).is_empty(), "%s reconstruction has no diagnostics" % archetype_id)
		if not bool(first_result.get("valid", false)):
			printerr("%s diagnostics: %s" % [archetype_id, str(first_result.get("diagnostics", []))])
			continue

		var first_layout := first_result.get("layout", {}) as Dictionary
		var second_layout := second_result.get("layout", {}) as Dictionary
		_expect((first_layout.get("route_presets", []) as Array).size() >= 1, "%s exposes harness route presets as metadata" % archetype_id)
		_expect(str(canonical.canonical_stringify(first_layout.get("canonical_topology", {}))) == str(canonical.canonical_stringify(second_layout.get("canonical_topology", {}))), "%s reconstructs deterministically" % archetype_id)
		_expect(str(blueprint.get_canonical_hash()) == before_hash, "%s reconstruction leaves blueprint hash unchanged" % archetype_id)
		_expect(str(canonical.canonical_stringify(blueprint.to_dictionary())) == before_canonical, "%s reconstruction does not mutate blueprint data" % archetype_id)
		_expect(_all_semantic_edges_mapped(blueprint.to_dictionary(), first_layout), "%s maps every semantic edge to runtime geometry" % archetype_id)
		_expect(_display_only_edges_are_not_routed(blueprint.to_dictionary(), first_layout), "%s display-only abandoned geometry is excluded from active routing" % archetype_id)

		var rail = rail_script.new()
		var configure_result: Dictionary = rail.configure_track_layout(first_layout)
		_expect(bool(configure_result.get("valid", false)), "%s configures RailMovement" % archetype_id)
		if not bool(configure_result.get("valid", false)):
			printerr("%s RailMovement diagnostics: %s" % [archetype_id, str(configure_result.get("diagnostics", []))])
		if archetype_id == "rural_through":
			_expect((rail.get_point_ids() as Array).is_empty(), "rural through configures with no runtime turnouts")


func _runtime_layouts_are_materially_different() -> void:
	var loader := _load_script(LOADER_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	var reconstructor := _load_script(RECONSTRUCTOR_PATH)
	if loader == null or validator == null or reconstructor == null:
		return

	var signatures: Dictionary = {}
	for entry in _read_embedding_registry(loader):
		var entry_dict := entry as Dictionary
		var archetype_id := str(entry_dict.get("archetype_id", ""))
		var blueprint = loader.load_blueprint(str(entry_dict.get("fixture_path", "")))
		var embedding: Dictionary = loader.load_json(str(entry_dict.get("embedding_path", "")))
		var result: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
		if not bool(result.get("valid", false)):
			continue
		var signature := _runtime_signature(result.get("layout", {}) as Dictionary)
		_expect(not signatures.has(signature), "%s has a materially distinct runtime reconstruction" % archetype_id)
		signatures[signature] = archetype_id


func _all_semantic_edges_mapped(data: Dictionary, layout: Dictionary) -> bool:
	var semantic_map := layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary
	for edge in ((data.get("rail_graph", {}) as Dictionary).get("edges", []) as Array):
		var edge_id := str((edge as Dictionary).get("id", ""))
		if edge_id.is_empty():
			continue
		if not semantic_map.has(edge_id):
			return false
		if (semantic_map.get(edge_id, []) as Array).is_empty():
			return false
	return true


func _display_only_edges_are_not_routed(data: Dictionary, layout: Dictionary) -> bool:
	var display_segments: Dictionary = {}
	var semantic_map := layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary
	var segment_semantics := layout.get("segment_semantics", {}) as Dictionary
	for edge in ((data.get("rail_graph", {}) as Dictionary).get("edges", []) as Array):
		var edge_dict := edge as Dictionary
		if str(edge_dict.get("role", "")) != ROLE_ABANDONED_TRACK:
			continue
		for raw_segment_id in semantic_map.get(str(edge_dict.get("id", "")), []):
			var segment_id := str(raw_segment_id)
			var semantics := segment_semantics.get(segment_id, {}) as Dictionary
			if str(semantics.get("runtime_status", "")) != STATUS_DISPLAY_ONLY:
				return false
			display_segments[segment_id] = true

	for connection_map in [layout.get("next_connections", {}) as Dictionary, layout.get("previous_connections", {}) as Dictionary]:
		for raw_source_id in connection_map.keys():
			if display_segments.has(str(raw_source_id)):
				return false
			var connection := connection_map[raw_source_id] as Dictionary
			if display_segments.has(str(connection.get("segment", ""))):
				return false
			for raw_target_id in (connection.get("routes", {}) as Dictionary).values():
				if display_segments.has(str(raw_target_id)):
					return false
	return true


func _runtime_signature(layout: Dictionary) -> String:
	var segments := layout.get("segments", {}) as Dictionary
	var points := layout.get("points", {}) as Dictionary
	var segment_semantics := layout.get("segment_semantics", {}) as Dictionary
	var roles: Dictionary = {}
	var display_only_count := 0
	for raw_segment_id in segment_semantics.keys():
		var semantics := segment_semantics[raw_segment_id] as Dictionary
		roles[str(semantics.get("semantic_role", ""))] = true
		if str(semantics.get("runtime_status", "active")) == STATUS_DISPLAY_ONLY:
			display_only_count += 1
	var role_ids: Array[String] = []
	for raw_role in roles.keys():
		role_ids.append(str(raw_role))
	role_ids.sort()
	return "%d/%d/%d/%s" % [segments.size(), points.size(), display_only_count, "|".join(role_ids)]


func _read_embedding_registry(loader: RefCounted) -> Array:
	if not FileAccess.file_exists(EMBEDDING_REGISTRY_PATH):
		return []
	var data: Dictionary = loader.load_json(EMBEDDING_REGISTRY_PATH)
	return data.get("embeddings", []) as Array


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
		print("\nSprint 9E reference reconstruction acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9E reference reconstruction acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
