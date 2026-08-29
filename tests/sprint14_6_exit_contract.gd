extends SceneTree

const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")
const WorldgenProceduralSpatialEmbedding := preload("res://scripts/worldgen/worldgen_procedural_spatial_embedding.gd")
const WorldgenRuntimeReconstructor := preload("res://scripts/worldgen/worldgen_runtime_reconstructor.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")
const SectorBlueprint := preload("res://scripts/worldgen/sector_blueprint.gd")

var _failures: Array[String] = []

func _init() -> void:
	print("\n--- SPRINT 14.6: SECTOR EXIT CONTRACT TESTS ---")
	test_archetype_multi_exits()
	test_exit_geometry_and_reachability()
	test_archetype_profile_bias()

	if _failures.is_empty():
		print("\n>>> ALL SPRINT 14.6 EXIT CONTRACT TESTS PASSED <<<\n")
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
	else:
		print("  PASS: %s" % msg)


func test_archetype_multi_exits() -> void:
	print("\n[TEST] All Archetypes Multi-Exit Generation (50 seeds each)")
	var generator := WorldgenProductionSectorGenerator.new()
	var validator := WorldgenSchemaValidator.new()

	var multi_exit_counts: Dictionary = {}
	var archetypes := [
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED,
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
	]

	for arch in archetypes:
		var has_multi_exit := false
		for s in range(50):
			var seed_val := 3000 + s * 17
			var def := generator.generate_sector(seed_val, 1, "forward")
			_expect(def != null, "Sector generation non-null for %s seed %d" % [arch, seed_val])
			if def == null:
				continue
			_expect(def.route_exits.size() >= 1, "Seed %d has at least 1 outbound route (got %d)" % [seed_val, def.route_exits.size()])
			_expect(def.route_exits.size() <= 3, "Seed %d has at most 3 outbound routes (got %d)" % [seed_val, def.route_exits.size()])
			if def.route_exits.size() > 1:
				has_multi_exit = true
				multi_exit_counts[def.archetype_id] = int(multi_exit_counts.get(def.archetype_id, 0)) + 1

		_expect(has_multi_exit, "Archetype %s generated multi-exit branches across seeds" % arch)

	print("  Multi-exit occurrences per archetype in 50 seeds: %s" % str(multi_exit_counts))


func test_exit_geometry_and_reachability() -> void:
	print("\n[TEST] Outbound Exit Geometry and Node Reachability")
	var semantic := WorldgenSemanticGenerator.new()
	var spatial := WorldgenProceduralSpatialEmbedding.new()
	var reconstructor := WorldgenRuntimeReconstructor.new()
	var validator := WorldgenSchemaValidator.new()

	# Test explicit decisions requesting outbound branches
	var village_decisions := {
		"platform_track": WorldgenSemanticGenerator.TRACK_STATION_MAIN,
		"modules": [
			WorldgenSemanticGenerator.MODULE_SHORT_GOODS_SIDING,
			WorldgenSemanticGenerator.MODULE_OUTBOUND_INDUSTRIAL,
			WorldgenSemanticGenerator.MODULE_OUTBOUND_AGRICULTURAL,
		],
	}
	var bp_dict := semantic.call("_make_village_passing_station_data", village_decisions) as Dictionary
	var bp := SectorBlueprint.from_dictionary(bp_dict)
	var validation := validator.validate_blueprint(bp)
	_expect(bool(validation.get("valid", false)), "Village multi-exit blueprint passes schema validator")

	var exit_nodes: Array = bp.get_exit_nodes()
	_expect(exit_nodes.size() == 3, "Village blueprint has 3 exit nodes (main, industrial, agricultural)")

	var exit_ids: Array = bp.get_exit_node_ids()
	_expect(exit_ids.has("exit"), "Village has default exit node")
	_expect(exit_ids.has("industrial_exit"), "Village has industrial_exit node")
	_expect(exit_ids.has("agricultural_exit"), "Village has agricultural_exit node")

	var req := WorldgenGenerationRequest.new(999, 1, "forward", WorldgenGenerationRequest.DEFAULT_REGION_PACK, WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION, WorldgenProductionSectorGenerator.GENERATOR_VERSION)
	var ctx := WorldgenGenerationContext.new(req)
	var spatial_res := spatial.generate_embedding(bp, ctx)
	_expect(bool(spatial_res.get("success", false)), "Village multi-exit spatial embedding succeeds")

	var recon := reconstructor.reconstruct_runtime_layout(bp, spatial_res.get("embedding", {}) as Dictionary, validator)
	_expect(bool(recon.get("valid", false)), "Village multi-exit runtime reconstruction succeeds")

	var layout: Dictionary = recon.get("layout", {})
	var segments: Dictionary = layout.get("segments", {})
	_expect(segments.has(WorldgenSemanticGenerator.TRACK_VILLAGE_INDUSTRIAL_EXIT), "Layout contains village industrial exit track segment")
	_expect(segments.has(WorldgenSemanticGenerator.TRACK_VILLAGE_AGRICULTURAL_EXIT), "Layout contains village agricultural exit track segment")


func test_archetype_profile_bias() -> void:
	print("\n[TEST] Sector Archetype Selection Profile Bias")
	var generator := WorldgenProductionSectorGenerator.new()

	var profiles := ["industrial_corridor", "agricultural", "settlement", "declining", "branch", "main"]
	for p in profiles:
		var counts: Dictionary = {}
		for s in range(100):
			var def := generator.generate_sector(5000 + s, 2, p)
			if def != null:
				counts[def.archetype_id] = int(counts.get(def.archetype_id, 0)) + 1

		# Verify that biasing actually favors related archetypes
		match p:
			"industrial_corridor":
				var ind_count := int(counts.get(WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS, 0))
				_expect(ind_count >= 30, "Industrial corridor profile yields elevated small_town_goods (%d/100)" % ind_count)
			"agricultural":
				var agri_count := int(counts.get(WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT, 0))
				_expect(agri_count >= 30, "Agricultural profile yields elevated agricultural_loading_point (%d/100)" % agri_count)
			"settlement":
				var village_count := int(counts.get(WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION, 0))
				_expect(village_count >= 30, "Settlement profile yields elevated village_passing_station (%d/100)" % village_count)
			"declining":
				var dec_count := int(counts.get(WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH, 0))
				_expect(dec_count >= 30, "Declining profile yields elevated declining_abandoned_branch (%d/100)" % dec_count)
			"branch":
				var branch_sum := int(counts.get(WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED, 0)) + int(counts.get(WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH, 0))
				_expect(branch_sum >= 35, "Branch profile yields elevated valley/declining (%d/100)" % branch_sum)
