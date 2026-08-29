extends SceneTree

const SectorDefinitionProvider := preload("res://scripts/sector/sector_definition_provider.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")

var _failures: Array[String] = []

func _init() -> void:
	print("\n--- SPRINT 14.6: LARGE SCALE GENERATION & DETERMINISM SWEEP (600 SECTORS) ---")
	test_large_sweep_and_determinism()

	if _failures.is_empty():
		print("\n>>> ALL SPRINT 14.6 LARGE SWEEP TESTS PASSED <<<\n")
		quit(0)
	else:
		printerr("\n>>> FAILED with %d error(s): <<<" % _failures.size())
		for f in _failures:
			printerr("  - %s" % f)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		printerr("FAIL: %s" % msg)


func test_large_sweep_and_determinism() -> void:
	var provider := SectorDefinitionProvider.new()
	var canonical := WorldgenCanonical.new()

	var profiles := ["forward", "industrial", "agricultural", "settlement", "declining", "branch", "main"]
	var exit_distribution: Dictionary = {}
	var archetype_distribution: Dictionary = {}
	var total_sectors := 600

	for i in range(total_sectors):
		var seed_val := 10000 + i * 29
		var profile: String = str(profiles[i % profiles.size()])
		var sec_idx := 2 + (i % 5)

		var def1 := provider.create_definition(seed_val, sec_idx, profile)
		_expect(def1 != null, "Sector %d generated (seed %d, profile %s)" % [i, seed_val, profile])
		if def1 == null:
			continue

		var exit_count := def1.route_exits.size()
		exit_distribution[exit_count] = int(exit_distribution.get(exit_count, 0)) + 1
		archetype_distribution[def1.archetype_id] = int(archetype_distribution.get(def1.archetype_id, 0)) + 1

		_expect(exit_count >= 1 and exit_count <= 3, "Valid exit count (%d) for sector %d" % [exit_count, i])
		_expect(not def1.runtime_layout.is_empty(), "Non-empty runtime layout")
		_expect(not def1.route_exits.is_empty(), "Non-empty route exits")

		# Determinism check: generate again with same inputs
		var def2 := provider.create_definition(seed_val, sec_idx, profile)
		if def1.blueprint_hash != def2.blueprint_hash or def1.runtime_topology_hash != def2.runtime_topology_hash or def1.route_exits != def2.route_exits:
			_expect(false, "Determinism failed on seed %d profile %s" % [seed_val, profile])

	print("  Archetype distribution across 600 sectors:")
	for arch in archetype_distribution.keys():
		print("    - %s: %d (%.1f%%)" % [arch, archetype_distribution[arch], float(archetype_distribution[arch]) / float(total_sectors) * 100.0])

	print("  Outbound exit count distribution:")
	for ex in exit_distribution.keys():
		print("    - %d exit(s): %d (%.1f%%)" % [ex, exit_distribution[ex], float(exit_distribution[ex]) / float(total_sectors) * 100.0])

	_expect(int(exit_distribution.get(1, 0)) > 0, "Single-exit sectors present")
	_expect(int(exit_distribution.get(2, 0)) > 0, "Double-exit sectors present")
	_expect(int(exit_distribution.get(3, 0)) > 0, "Triple-exit sectors present")
