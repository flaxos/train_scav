extends SceneTree

const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Procgen Determinism Tests ---")
	_test_identical_seed_identical_hazards()
	_test_all_archetypes_generate_valid_hazard_definitions()

	if _failures == 0:
		print("\nSprint 14 procgen determinism acceptance passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 procgen determinism acceptance FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _test_identical_seed_identical_hazards() -> void:
	print("Testing identical seed yields identical hazards...")
	var gen := WorldgenProductionSectorGenerator.new()
	var res1 := gen.generate_sector(4242, 1)
	var res2 := gen.generate_sector(4242, 1)

	_expect(bool(res1.get("success", false)), "generation 1 succeeds")
	_expect(bool(res2.get("success", false)), "generation 2 succeeds")
	_expect(str(res1.get("archetype_id", "")) == str(res2.get("archetype_id", "")), "same archetype")

	var hazards1 := res1.get("hazard_definitions", []) as Array
	var hazards2 := res2.get("hazard_definitions", []) as Array
	_expect(hazards1 == hazards2, "hazard definitions match exactly across runs")

	var exits1 := res1.get("route_exits", []) as Array
	var exits2 := res2.get("route_exits", []) as Array
	_expect(exits1 == exits2, "route exits match exactly across runs")


func _test_all_archetypes_generate_valid_hazard_definitions() -> void:
	print("Testing multiple seeds produce valid hazard structures...")
	var gen := WorldgenProductionSectorGenerator.new()
	for seed_val in [101, 202, 303, 404, 505]:
		var res := gen.generate_sector(seed_val, 1)
		_expect(bool(res.get("success", false)), "seed %d succeeds" % seed_val)
		var def = res.get("sector_definition", null)
		_expect(def != null, "seed %d produces SectorDefinition" % seed_val)
		_expect(not def.route_exits.is_empty(), "seed %d has route exits" % seed_val)
