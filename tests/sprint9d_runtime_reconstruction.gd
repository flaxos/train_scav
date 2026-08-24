extends SceneTree

const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const VALIDATOR_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const RECONSTRUCTOR_PATH := "res://scripts/worldgen/worldgen_runtime_reconstructor.gd"
const GOODS_FIXTURE := "res://data/worldgen/archetypes/reference/small_town_goods_station_v1.json"
const GOODS_EMBEDDING := "res://data/worldgen/embeddings/reference/small_town_goods_station_embedding_v1.json"
const RAIL_PATH := "res://scripts/rail/rail_movement.gd"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9D Runtime Reconstruction Tests ---")
	_required_files_exist()
	_small_town_fixture_reconstructs_deterministically()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(LOADER_PATH), "worldgen fixture loader exists")
	_expect(ResourceLoader.exists(VALIDATOR_PATH), "9C semantic validator exists")
	_expect(ResourceLoader.exists(RECONSTRUCTOR_PATH), "9D runtime reconstructor exists")
	_expect(ResourceLoader.exists(RAIL_PATH), "RailMovement exists")
	_expect(FileAccess.file_exists(GOODS_FIXTURE), "small-town goods fixture exists")
	_expect(FileAccess.file_exists(GOODS_EMBEDDING), "small-town goods embedding exists")


func _small_town_fixture_reconstructs_deterministically() -> void:
	if not ResourceLoader.exists(RECONSTRUCTOR_PATH) or not FileAccess.file_exists(GOODS_EMBEDDING):
		return

	var loader := _load_script(LOADER_PATH)
	var validator := _load_script(VALIDATOR_PATH)
	var canonical := _load_script(CANONICAL_PATH)
	var reconstructor := _load_script(RECONSTRUCTOR_PATH)
	if loader == null or validator == null or canonical == null or reconstructor == null:
		return

	var blueprint = loader.load_blueprint(GOODS_FIXTURE)
	_expect(blueprint != null, "small-town goods blueprint constructs")
	if blueprint == null:
		return

	var before_hash := str(blueprint.get_canonical_hash())
	var before_canonical := str(canonical.canonical_stringify(blueprint.to_dictionary()))
	var semantic_result: Dictionary = validator.validate_blueprint(blueprint)
	_expect(bool(semantic_result.get("valid", false)), "small-town goods blueprint validates before reconstruction")

	var embedding: Dictionary = loader.load_json(GOODS_EMBEDDING)
	var first_result: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	var second_result: Dictionary = reconstructor.reconstruct_runtime_layout(blueprint, embedding, validator)
	_expect(bool(first_result.get("valid", false)), "small-town goods runtime reconstruction succeeds")
	_expect((first_result.get("diagnostics", []) as Array).is_empty(), "small-town goods reconstruction reports no diagnostics")
	if not bool(first_result.get("valid", false)):
		return

	var first_layout := first_result.get("layout", {}) as Dictionary
	var second_layout := second_result.get("layout", {}) as Dictionary
	var semantic_map := first_layout.get("semantic_edge_to_runtime_segments", {}) as Dictionary
	_expect((semantic_map.get("main_west", []) as Array).has("main_west"), "main_west semantic edge maps to runtime segment")
	_expect((semantic_map.get("platform_main", []) as Array).has("platform_main"), "platform_main semantic edge maps to runtime segment")
	_expect((semantic_map.get("passing_loop", []) as Array).has("passing_loop"), "passing_loop semantic edge maps to runtime segment")
	_expect((semantic_map.get("goods_yard_lead", []) as Array).has("goods_yard_lead"), "goods yard lead semantic edge maps to runtime segment")
	_expect((semantic_map.get("goods_loading", []) as Array).has("goods_loading"), "loading track semantic edge maps to runtime segment")
	_expect((semantic_map.get("yard_headshunt", []) as Array).has("yard_headshunt"), "headshunt semantic edge maps to runtime segment")
	_expect((first_layout.get("segments", {}) as Dictionary).has("west_station_throat"), "embedding decomposes west station throat with a runtime connector")
	_expect((first_layout.get("points", {}) as Dictionary).has("west_yard_switch"), "embedding includes west yard turnout")
	_expect((first_layout.get("points", {}) as Dictionary).has("west_loop_switch"), "embedding includes west loop turnout")
	_expect((first_layout.get("points", {}) as Dictionary).has("east_loop_switch"), "embedding includes east loop turnout")
	_expect((first_layout.get("points", {}) as Dictionary).has("yard_switch"), "embedding includes yard turnout")
	_expect(str(canonical.canonical_stringify(first_layout.get("canonical_topology", {}))) == str(canonical.canonical_stringify(second_layout.get("canonical_topology", {}))), "same blueprint and embedding reconstruct to equivalent topology")
	_expect(str(blueprint.get_canonical_hash()) == before_hash, "reconstruction leaves blueprint hash unchanged")
	_expect(str(canonical.canonical_stringify(blueprint.to_dictionary())) == before_canonical, "reconstruction does not mutate blueprint data")


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
		_expect(false, "%s exists" % path)
		return null
	return (load(path) as Script).new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9D runtime reconstruction acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9D runtime reconstruction acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
