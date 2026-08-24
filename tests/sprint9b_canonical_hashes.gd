extends SceneTree

const CANONICAL_PATH := "res://scripts/worldgen/worldgen_canonical.gd"
const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const REGISTRY_PATH := "res://data/worldgen/archetypes/reference_archetypes_v1.json"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9B Canonical Hash Tests ---")
	_hashes_are_stable_and_key_order_independent()
	_finish()


func _hashes_are_stable_and_key_order_independent() -> void:
	_expect(ResourceLoader.exists(CANONICAL_PATH), "canonical hash helper exists")
	_expect(ResourceLoader.exists(LOADER_PATH), "9B fixture loader exists")
	_expect(FileAccess.file_exists(REGISTRY_PATH), "9B reference archetype registry exists")
	if not ResourceLoader.exists(CANONICAL_PATH) or not ResourceLoader.exists(LOADER_PATH) or not FileAccess.file_exists(REGISTRY_PATH):
		return

	var canonical: RefCounted = (load(CANONICAL_PATH) as Script).new()
	var loader: RefCounted = (load(LOADER_PATH) as Script).new()
	var registry: Array = loader.load_registry(REGISTRY_PATH)
	_expect(registry.size() == 6, "registry contains six fixtures for hash checks")

	var simple_a := {"b": 2, "a": [{"z": true, "y": "same"}]}
	var simple_b := {"a": [{"y": "same", "z": true}], "b": 2}
	_expect(canonical.canonical_stringify(simple_a) == canonical.canonical_stringify(simple_b), "canonical serialization sorts dictionary keys recursively")
	_expect(canonical.hash_dictionary(simple_a) == canonical.hash_dictionary(simple_b), "canonical hash ignores dictionary insertion order")

	var hashes: Dictionary = {}
	for entry in registry:
		var path := str((entry as Dictionary).get("path", ""))
		var first = loader.load_blueprint(path)
		var second = loader.load_blueprint(path)
		_expect(first != null and second != null, "fixture loads twice for stable hash check")
		if first == null or second == null:
			continue
		var first_hash := str(first.get_canonical_hash())
		var second_hash := str(second.get_canonical_hash())
		_expect(first_hash == second_hash, "%s hash is stable across repeated loads" % path)
		_expect(not hashes.has(first_hash), "%s hash is distinct from other reference fixtures" % path)
		hashes[first_hash] = path


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9B canonical hash acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9B canonical hash acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
