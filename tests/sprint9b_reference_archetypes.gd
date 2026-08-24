extends SceneTree

const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const REGISTRY_PATH := "res://data/worldgen/archetypes/reference_archetypes_v1.json"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9B Reference Archetype Tests ---")
	_all_reference_archetypes_share_schema_and_blueprint_api()
	_finish()


func _all_reference_archetypes_share_schema_and_blueprint_api() -> void:
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "9A validator exists")
	_expect(ResourceLoader.exists(LOADER_PATH), "9B fixture loader exists")
	_expect(FileAccess.file_exists(REGISTRY_PATH), "9B reference archetype registry exists")
	if not ResourceLoader.exists(VALIDATOR_PATH) or not ResourceLoader.exists(LOADER_PATH) or not FileAccess.file_exists(REGISTRY_PATH):
		return

	var validator: RefCounted = (load(VALIDATOR_PATH) as Script).new()
	var loader: RefCounted = (load(LOADER_PATH) as Script).new()
	var registry: Array = loader.load_registry(REGISTRY_PATH)
	_expect(registry.size() == 6, "registry contains six researched reference archetypes")

	var hashes: Dictionary = {}
	var signatures: Dictionary = {}
	for entry in registry:
		var path := str((entry as Dictionary).get("path", ""))
		var expected_id := str((entry as Dictionary).get("archetype_id", ""))
		var data: Dictionary = loader.load_json(path)
		_expect(str(data.get("archetype_id", "")) == expected_id, "fixture ID matches registry for %s" % expected_id)

		var result: Dictionary = validator.validate_semantic_graph(data)
		_expect(bool(result.get("valid", false)), "%s validates against the 9A semantic contract" % expected_id)

		var blueprint = loader.load_blueprint(path)
		_expect(blueprint != null, "%s constructs a SectorBlueprint" % expected_id)
		if blueprint == null:
			continue

		_expect(str(blueprint.get_archetype_id()) == expected_id, "%s exposes archetype ID through common API" % expected_id)
		_expect(blueprint.has_rail_path(), "%s has default entry-to-exit rail path" % expected_id)
		_expect(not blueprint.get_station().is_empty(), "%s exposes station query through common API" % expected_id)
		_expect_archetype_queries(blueprint, expected_id)
		_expect(_relationships_resolve(blueprint.to_dictionary()), "%s relationship references resolve" % expected_id)

		var hash := str(blueprint.get_canonical_hash())
		_expect(not hash.is_empty(), "%s has stable canonical hash" % expected_id)
		_expect(not hashes.has(hash), "%s has a distinct graph hash" % expected_id)
		hashes[hash] = expected_id

		var signature := _graph_signature(blueprint)
		_expect(not signatures.has(signature), "%s has materially different semantic graph shape" % expected_id)
		signatures[signature] = expected_id


func _expect_archetype_queries(blueprint: RefCounted, archetype_id: String) -> void:
	match archetype_id:
		"rural_through":
			_expect(blueprint.get_tracks_by_role("THROUGH_MAIN").size() == 1, "rural through exposes only its through main")
			_expect(blueprint.get_tracks_by_role("PASSING_LOOP").is_empty(), "rural through has no passing loop")
			_expect(blueprint.get_goods_yards().is_empty(), "rural through has no goods yard")
			_expect(blueprint.get_industries().is_empty(), "rural through has no industry")
			_expect(blueprint.get_water_crossings().is_empty(), "rural through has no water crossing")
		"village_passing_station":
			_expect(blueprint.get_tracks_by_role("PASSING_LOOP").size() == 1, "village station exposes one passing loop")
			_expect(blueprint.get_entities_by_type("PLATFORM").size() == 1, "village station exposes platform entity")
			_expect(blueprint.get_goods_yards().is_empty(), "village station has no goods yard")
		"small_town_goods_station":
			_expect(blueprint.get_tracks_by_role("PASSING_LOOP").size() == 1, "small-town goods station exposes one passing loop")
			_expect(blueprint.get_goods_yards().size() == 1, "small-town goods station exposes goods yard")
			_expect(blueprint.get_industries().size() >= 1, "small-town goods station exposes served industry")
			_expect(blueprint.get_tracks_by_role("LOADING_TRACK").size() >= 1, "small-town goods station exposes loading track")
		"agricultural_loading_point":
			_expect(blueprint.get_tracks_by_role("AGRICULTURAL_SPUR").size() == 1, "agricultural loading point exposes agricultural spur")
			_expect(blueprint.get_tracks_by_role("LOADING_TRACK").size() == 1, "agricultural loading point exposes loading track")
			_expect(blueprint.get_industries().size() >= 1, "agricultural loading point exposes agricultural facilities")
			_expect(blueprint.get_goods_yards().is_empty(), "agricultural loading point has no goods yard")
		"river_valley_constrained":
			_expect(blueprint.get_tracks_by_role("PASSING_LOOP").size() == 1, "river-valley fixture exposes passing loop")
			_expect(blueprint.get_entities_by_type("CREEK").size() == 1, "river-valley fixture exposes creek entity")
			_expect(blueprint.get_entities_by_type("BRIDGE").size() == 1, "river-valley fixture exposes bridge entity")
			_expect(blueprint.get_water_crossings().size() >= 2, "river-valley fixture exposes water crossing and bridge relations")
		"declining_abandoned_branch":
			_expect(blueprint.get_tracks_by_role("PASSING_LOOP").size() == 1, "declining branch exposes remnant passing loop")
			_expect(blueprint.get_tracks_by_role("ABANDONED_TRACK").size() >= 2, "declining branch exposes abandoned tracks")
			_expect(blueprint.get_tracks_by_role("STORAGE_TRACK").size() == 1, "declining branch exposes storage track")
			_expect(blueprint.get_goods_yards().size() == 1, "declining branch exposes goods yard")
		_:
			_expect(false, "unknown Sprint 9B archetype ID %s" % archetype_id)


func _relationships_resolve(data: Dictionary) -> bool:
	var edges := _ids_for((data.get("rail_graph", {}) as Dictionary).get("edges", []))
	var entities := _ids_for((data.get("world_graph", {}) as Dictionary).get("entities", []))
	for relation in (data.get("world_graph", {}) as Dictionary).get("relations", []):
		var rel := relation as Dictionary
		var from_entity := str(rel.get("from_entity", ""))
		var to_entity := str(rel.get("to_entity", ""))
		var to_edge := str(rel.get("to_edge", ""))
		if not entities.has(from_entity):
			return false
		if not to_entity.is_empty() and not entities.has(to_entity):
			return false
		if not to_edge.is_empty() and not edges.has(to_edge):
			return false
	return true


func _graph_signature(blueprint: RefCounted) -> String:
	var data: Dictionary = blueprint.to_dictionary()
	var rail_graph := data.get("rail_graph", {}) as Dictionary
	var world_graph := data.get("world_graph", {}) as Dictionary
	return "%d/%d/%d/%d/%d/%d/%d/%d" % [
		(rail_graph.get("nodes", []) as Array).size(),
		(rail_graph.get("edges", []) as Array).size(),
		(world_graph.get("entities", []) as Array).size(),
		(world_graph.get("relations", []) as Array).size(),
		blueprint.get_tracks_by_role("PASSING_LOOP").size(),
		blueprint.get_tracks_by_role("GOODS_YARD_TRACK").size(),
		blueprint.get_tracks_by_role("AGRICULTURAL_SPUR").size(),
		blueprint.get_tracks_by_role("ABANDONED_TRACK").size(),
	]


func _ids_for(items: Array) -> Dictionary:
	var ids: Dictionary = {}
	for item in items:
		ids[str((item as Dictionary).get("id", ""))] = true
	return ids


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9B reference archetype acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9B reference archetype acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
