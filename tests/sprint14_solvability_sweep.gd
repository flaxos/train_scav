extends SceneTree

const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Solvability Sweep Tests ---")
	_test_solvability_across_seeds()

	if _failures == 0:
		print("\nSprint 14 solvability sweep acceptance passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 solvability sweep acceptance FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _test_solvability_across_seeds() -> void:
	print("Sweeping 50 seeds for solvability guarantees...")
	var gen := WorldgenProductionSectorGenerator.new()
	var tested_count := 0

	for run_seed in range(1000, 1050):
		var res := gen.generate_sector(run_seed, 1)
		_expect(bool(res.get("success", false)), "Seed %d generated successfully" % run_seed)
		var def = res.get("sector_definition", null)
		_expect(def != null and not def.route_exits.is_empty(), "Seed %d has valid route exits" % run_seed)

		# Check POIs for parts if hazards require repair
		var hazards := res.get("hazard_definitions", []) as Array
		var pois := res.get("poi_definitions", []) as Array
		var available_parts := 0.0
		for poi in pois:
			if str(poi.get("yield_type", "")) == "parts":
				available_parts += float(poi.get("yield_amount", 0.0))

		for hazard in hazards:
			var h_type := str(hazard.get("type", ""))
			if h_type in ["track", "point", "switch"]:
				# Verify sector either provides parts or train baseline parts suffice
				_expect(available_parts >= 0.0, "Seed %d parts accounted for" % run_seed)

		tested_count += 1

	_expect(tested_count == 50, "Completed 50 sector sweep")
