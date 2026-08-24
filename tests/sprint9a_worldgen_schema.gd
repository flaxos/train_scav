extends SceneTree

const VALIDATOR_SCRIPT_PATH := "res://scripts/worldgen/worldgen_schema_validator.gd"
const SCHEMA_PATH := "res://data/worldgen/schema/semantic_graph_v1.schema.json"
const ARCHETYPE_PATH := "res://data/worldgen/archetypes/central_eu_small_town_station_v1.json"
const HUMAN_ARCHETYPE_PATH := "res://data/worldgen/archetypes/central_eu_small_town_station_v1.yaml"
const TEST_SEEDS_PATH := "res://data/worldgen/tests/test_seeds_v1.json"
const VALID_FIXTURE_PATH := "res://tests/fixtures/worldgen/valid_central_eu_small_town_v1.json"
const INVALID_MISSING_ENTRY_PATH := "res://tests/fixtures/worldgen/invalid_missing_entry_v1.json"
const INVALID_BAD_REFERENCE_PATH := "res://tests/fixtures/worldgen/invalid_bad_reference_v1.json"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9A Worldgen Schema Tests ---")
	_required_files_exist()
	_valid_fixture_validates()
	_invalid_fixtures_fail_predictably()
	_canonical_archetype_validates()
	_test_seed_contract_is_versioned()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(VALIDATOR_SCRIPT_PATH), "worldgen schema validator script exists")
	_expect(FileAccess.file_exists(SCHEMA_PATH), "canonical semantic graph JSON schema exists")
	_expect(FileAccess.file_exists(ARCHETYPE_PATH), "canonical runtime archetype JSON exists")
	_expect(FileAccess.file_exists(HUMAN_ARCHETYPE_PATH), "human-readable YAML reference archetype exists")
	_expect(FileAccess.file_exists(TEST_SEEDS_PATH), "worldgen test-seed contract exists")
	_expect(FileAccess.file_exists(VALID_FIXTURE_PATH), "valid central EU fixture exists")
	_expect(FileAccess.file_exists(INVALID_MISSING_ENTRY_PATH), "invalid missing-entry fixture exists")
	_expect(FileAccess.file_exists(INVALID_BAD_REFERENCE_PATH), "invalid bad-reference fixture exists")


func _valid_fixture_validates() -> void:
	var validator := _load_validator()
	if validator == null:
		return
	var fixture := _read_json(VALID_FIXTURE_PATH)
	if fixture.is_empty():
		return

	var result: Dictionary = validator.validate_semantic_graph(fixture)
	_expect(bool(result.get("valid", false)), "valid central EU fixture validates")
	_expect(_fixture_uses_source_neutral_roles(fixture), "fixture uses source-neutral roles instead of raw OSM service tags")


func _invalid_fixtures_fail_predictably() -> void:
	var validator := _load_validator()
	if validator == null:
		return

	var missing_entry := _read_json(INVALID_MISSING_ENTRY_PATH)
	if not missing_entry.is_empty():
		var missing_result: Dictionary = validator.validate_semantic_graph(missing_entry)
		_expect(not bool(missing_result.get("valid", true)), "missing-entry fixture fails validation")
		_expect(_errors_contain(missing_result, "entry"), "missing-entry failure mentions entry")

	var bad_reference := _read_json(INVALID_BAD_REFERENCE_PATH)
	if not bad_reference.is_empty():
		var bad_result: Dictionary = validator.validate_semantic_graph(bad_reference)
		_expect(not bool(bad_result.get("valid", true)), "bad-reference fixture fails validation")
		_expect(_errors_contain(bad_result, "unknown_node"), "bad-reference failure names the unknown node")


func _canonical_archetype_validates() -> void:
	var validator := _load_validator()
	if validator == null:
		return
	var archetype := _read_json(ARCHETYPE_PATH)
	if archetype.is_empty():
		return

	var result: Dictionary = validator.validate_semantic_graph(archetype)
	_expect(bool(result.get("valid", false)), "canonical central EU archetype validates")
	_expect(str(archetype.get("grammar_version", "")) == "central_eu_small_town_station_v1", "canonical archetype records grammar version")
	_expect(str(archetype.get("generator_version", "")) == "9a_schema_v1", "canonical archetype records generator/schema version")


func _test_seed_contract_is_versioned() -> void:
	var contract := _read_json(TEST_SEEDS_PATH)
	if contract.is_empty():
		return
	_expect(str(contract.get("grammar_version", "")) == "central_eu_small_town_station_v1", "test seed contract records grammar version")
	_expect(contract.has("seeds"), "test seed contract contains seed list")
	var seeds: Array = contract.get("seeds", [])
	_expect(seeds.size() >= 4, "test seed contract includes fixed acceptance seeds")


func _load_validator() -> RefCounted:
	if not ResourceLoader.exists(VALIDATOR_SCRIPT_PATH):
		return null
	var script: Script = load(VALIDATOR_SCRIPT_PATH) as Script
	if script == null:
		_expect(false, "worldgen schema validator script loads")
		return null
	if not script.can_instantiate():
		_expect(false, "worldgen schema validator script can instantiate")
		return null
	return script.new()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_expect(false, "can open %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_expect(false, "%s parses as a JSON object" % path)
		return {}
	return parsed as Dictionary


func _fixture_uses_source_neutral_roles(fixture: Dictionary) -> bool:
	var encoded := JSON.stringify(fixture)
	return not encoded.contains("service=siding") \
		and not encoded.contains("service=yard") \
		and not encoded.contains("service=spur")


func _errors_contain(result: Dictionary, needle: String) -> bool:
	var errors: Array = result.get("errors", [])
	for error in errors:
		if str(error).contains(needle):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9A worldgen schema acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9A worldgen schema acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
