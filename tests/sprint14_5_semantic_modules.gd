extends SceneTree

const WorldgenGenerationContext := preload("res://scripts/worldgen/worldgen_generation_context.gd")
const WorldgenGenerationRequest := preload("res://scripts/worldgen/worldgen_generation_request.gd")
const WorldgenSchemaValidator := preload("res://scripts/worldgen/worldgen_schema_validator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")
const SectorBlueprint := preload("res://scripts/worldgen/sector_blueprint.gd")
const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")

func _init() -> void:
	print("--- SPRINT 14.5: SEMANTIC MODULES & TOPOLOGY SIGNATURE TESTS ---")
	var failures: Array[String] = []

	test_all_archetype_base_and_modules(failures)
	test_module_resolutions_and_trace(failures)
	test_module_skip_resolution_is_non_error(failures)
	test_topology_signature_geometry_independence(failures)
	test_topology_signature_connectivity_sensitivity(failures)
	test_archetype_topology_variety(failures)

	if failures.is_empty():
		print("\n>>> ALL SPRINT 14.5 SEMANTIC MODULE TESTS PASSED <<<")
		quit(0)
	else:
		print("\n>>> FAILED with %d errors: <<<" % failures.size())
		for f in failures:
			print("  - ", f)
		quit(1)


func test_all_archetype_base_and_modules(failures: Array[String]) -> void:
	print("\n[TEST] All Archetypes & Composed Modules Schema Validation")
	var generator := WorldgenSemanticGenerator.new()
	var validator := WorldgenSchemaValidator.new()

	var archetypes := [
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION,
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS,
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT,
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED,
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH,
	]

	for arch in archetypes:
		for seed_val in [1001, 2002, 3003, 4004, 5005, 6006, 7007, 8008, 9009, 10010]:
			var req := WorldgenGenerationRequest.new(
				seed_val, 0,
				WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE,
				WorldgenGenerationRequest.DEFAULT_REGION_PACK,
				WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION,
				WorldgenSemanticGenerator.PRODUCTION_GENERATOR_VERSION
			)
			var ctx := WorldgenGenerationContext.new(req)
			var res := generator.generate_blueprint_for_archetype(ctx, arch)
			if not bool(res.get("success", false)):
				failures.append("Archetype %s seed %d failed semantic generation: %s" % [arch, seed_val, str(res.get("diagnostics", []))])
				continue
			var blueprint: RefCounted = res.get("blueprint", null)
			if blueprint == null:
				failures.append("Archetype %s seed %d returned null blueprint" % [arch, seed_val])
				continue
			var val: Dictionary = validator.validate_blueprint(blueprint)
			if not bool(val.get("valid", false)):
				failures.append("Archetype %s seed %d failed schema validation: %s" % [arch, seed_val, str(val.get("diagnostics", []))])
	print("  Passed schema validation sweep across all 6 archetypes.")


func test_module_resolutions_and_trace(failures: Array[String]) -> void:
	print("\n[TEST] Module Resolutions & Generation Trace")
	var generator := WorldgenSemanticGenerator.new()
	var req := WorldgenGenerationRequest.new(
		4242, 1,
		WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE,
		WorldgenGenerationRequest.DEFAULT_REGION_PACK,
		WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION,
		WorldgenSemanticGenerator.PRODUCTION_GENERATOR_VERSION
	)
	var ctx := WorldgenGenerationContext.new(req)
	var res := generator.generate_blueprint_for_archetype(ctx, WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS)
	if not bool(res.get("success", false)):
		failures.append("Small town goods failed generation: %s" % str(res.get("diagnostics", [])))
		return

	var decisions: Dictionary = res.get("decisions", {})
	if not decisions.has("module_resolutions"):
		failures.append("Decisions dictionary missing module_resolutions")
	else:
		var resolutions: Array = decisions.get("module_resolutions", [])
		print("  Module resolutions recorded: %s" % str(resolutions))
		for resolution_v in resolutions:
			var resolution := resolution_v as Dictionary
			if not resolution.has("module_requested"):
				failures.append("Module resolution missing module_requested: %s" % str(resolution))
			if not ["applied", "skipped"].has(str(resolution.get("status", ""))):
				failures.append("Module resolution has invalid status: %s" % str(resolution))
			if str(resolution.get("status", "")) == "skipped" and str(resolution.get("skip_reason", "")).is_empty():
				failures.append("Skipped module resolution missing skip_reason: %s" % str(resolution))

	var trace: RefCounted = res.get("generation_trace", null)
	if trace == null:
		failures.append("Generation trace is null")
	else:
		var trace_dict: Dictionary = trace.to_dictionary()
		var stage_decisions: Array = trace_dict.get("stage_decisions", [])
		var found_resolutions := false
		for sd_v in stage_decisions:
			var sd := sd_v as Dictionary
			if str(sd.get("key", "")) == "module_resolutions":
				found_resolutions = true
				break
		if not found_resolutions:
			failures.append("GenerationTrace missing module_resolutions stage decision")
		else:
			print("  GenerationTrace contains module_resolutions.")


func test_module_skip_resolution_is_non_error(failures: Array[String]) -> void:
	print("\n[TEST] Optional Module Skip Resolution Is Non-Error")
	var generator := WorldgenSemanticGenerator.new()
	var validator := WorldgenSchemaValidator.new()
	var decisions := {
		"archetype": WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH,
		"wayside_stop": false,
		"modules": ["unsupported_future_module"],
	}
	var data: Dictionary = generator.call("_make_rural_through_data", decisions)
	var blueprint := SectorBlueprint.from_dictionary(data)
	var validation := validator.validate_blueprint(blueprint)
	if not bool(validation.get("valid", false)):
		failures.append("Skipped unsupported optional module should leave rural blueprint valid: %s" % str(validation.get("diagnostics", [])))

	var resolutions: Array = decisions.get("module_resolutions", [])
	if resolutions.size() != 1:
		failures.append("Expected exactly one module resolution for skipped optional module, got %s" % str(resolutions))
		return

	var resolution := resolutions[0] as Dictionary
	if str(resolution.get("module_requested", "")) != "unsupported_future_module":
		failures.append("Skipped resolution did not record requested module: %s" % str(resolution))
	if str(resolution.get("status", "")) != "skipped":
		failures.append("Unsupported optional module should be skipped, got: %s" % str(resolution))
	if str(resolution.get("skip_reason", "")).is_empty():
		failures.append("Skipped optional module should include a skip reason: %s" % str(resolution))
	else:
		print("  Skipped optional module recorded without invalidating blueprint.")


func test_topology_signature_geometry_independence(failures: Array[String]) -> void:
	print("\n[TEST] Topology Signature Geometry Independence & Spatial Separation")
	var canonical := WorldgenCanonical.new()
	var base_data := {
		"archetype_id": "village_passing_station",
		"grammar_version": "central_eu_small_town_station_v1",
		"generator_version": "9a_schema_v1",
		"title": "Layout A - standard geometry",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "w_sw", "type": "SWITCH"},
				{"id": "e_sw", "type": "SWITCH"},
				{"id": "exit", "type": "EXIT"},
			],
			"edges": [
				{"id": "app", "role": "THROUGH_MAIN", "from": "entry", "to": "w_sw", "bidirectional": true, "length": 120.0, "side": "north", "offset": 56.0},
				{"id": "main", "role": "PLATFORM_TRACK", "from": "w_sw", "to": "e_sw", "bidirectional": true, "length": 230.0},
				{"id": "loop", "role": "PASSING_LOOP", "from": "w_sw", "to": "e_sw", "bidirectional": true, "side": "south", "offset": 68.0},
				{"id": "ext", "role": "THROUGH_MAIN", "from": "e_sw", "to": "exit", "bidirectional": true, "length": 160.0},
			],
		},
		"world_graph": {"entities": [], "relations": []},
	}

	var bp_a := SectorBlueprint.from_dictionary(base_data)
	var sig_a: String = bp_a.get_topology_signature()

	var modified_meta_data := base_data.duplicate(true)
	modified_meta_data["title"] = "Layout B - different metadata / spatial geometry representation"
	var modified_edges := ((modified_meta_data["rail_graph"] as Dictionary)["edges"] as Array)
	(modified_edges[0] as Dictionary)["length"] = 68.0
	(modified_edges[0] as Dictionary)["side"] = "south"
	(modified_edges[1] as Dictionary)["length"] = 320.0
	(modified_edges[2] as Dictionary)["offset"] = 120.0
	(modified_edges[3] as Dictionary)["length"] = 260.0
	var bp_b := SectorBlueprint.from_dictionary(modified_meta_data)
	var sig_b: String = bp_b.get_topology_signature()

	var spatial_a := {
		"segments": {
			"app": {"points": [[0.0, 0.0], [120.0, 0.0]]},
			"main": {"points": [[120.0, 0.0], [350.0, 0.0]]},
			"loop": {"points": [[120.0, 0.0], [180.0, 68.0], [290.0, 68.0], [350.0, 0.0]]},
			"ext": {"points": [[350.0, 0.0], [510.0, 0.0]]},
		},
	}
	var spatial_b := {
		"segments": {
			"app": {"points": [[0.0, 12.0], [68.0, 12.0]]},
			"main": {"points": [[68.0, 12.0], [388.0, 12.0]]},
			"loop": {"points": [[68.0, 12.0], [160.0, -120.0], [310.0, -120.0], [388.0, 12.0]]},
			"ext": {"points": [[388.0, 12.0], [648.0, 12.0]]},
		},
	}
	var spatial_sig_a := canonical.hash_dictionary(spatial_a)
	var spatial_sig_b := canonical.hash_dictionary(spatial_b)

	if sig_a != sig_b:
		failures.append("Topology signature differed across identical topologies: '%s' vs '%s'" % [sig_a, sig_b])
	elif spatial_sig_a == spatial_sig_b:
		failures.append("Spatial signatures should differ across different geometry: %s" % spatial_sig_a)
	else:
		print("  Identical topology signature confirmed: %s" % sig_a)
		print("  Distinct spatial hashes confirmed: %s vs %s" % [spatial_sig_a.substr(0, 10), spatial_sig_b.substr(0, 10)])


func test_topology_signature_connectivity_sensitivity(failures: Array[String]) -> void:
	print("\n[TEST] Topology Signature Connectivity Sensitivity")
	# Layout 1: main + storage off west switch
	var data_1 := {
		"archetype_id": "village_passing_station",
		"grammar_version": "central_eu_small_town_station_v1",
		"generator_version": "9a_schema_v1",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "w_sw", "type": "SWITCH"},
				{"id": "e_sw", "type": "SWITCH"},
				{"id": "exit", "type": "EXIT"},
				{"id": "storage_buf", "type": "BUFFER_STOP"},
			],
			"edges": [
				{"id": "app", "role": "THROUGH_MAIN", "from": "entry", "to": "w_sw", "bidirectional": true},
				{"id": "main", "role": "PLATFORM_TRACK", "from": "w_sw", "to": "e_sw", "bidirectional": true},
				{"id": "loop", "role": "PASSING_LOOP", "from": "w_sw", "to": "e_sw", "bidirectional": true},
				{"id": "ext", "role": "THROUGH_MAIN", "from": "e_sw", "to": "exit", "bidirectional": true},
				{"id": "storage", "role": "STORAGE_TRACK", "from": "w_sw", "to": "storage_buf", "bidirectional": true},
			],
		},
		"world_graph": {"entities": [], "relations": []},
	}

	# Layout 2: main + storage off EAST switch (different connectivity!)
	var data_2 := {
		"archetype_id": "village_passing_station",
		"grammar_version": "central_eu_small_town_station_v1",
		"generator_version": "9a_schema_v1",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "w_sw", "type": "SWITCH"},
				{"id": "e_sw", "type": "SWITCH"},
				{"id": "exit", "type": "EXIT"},
				{"id": "storage_buf", "type": "BUFFER_STOP"},
			],
			"edges": [
				{"id": "app", "role": "THROUGH_MAIN", "from": "entry", "to": "w_sw", "bidirectional": true},
				{"id": "main", "role": "PLATFORM_TRACK", "from": "w_sw", "to": "e_sw", "bidirectional": true},
				{"id": "loop", "role": "PASSING_LOOP", "from": "w_sw", "to": "e_sw", "bidirectional": true},
				{"id": "ext", "role": "THROUGH_MAIN", "from": "e_sw", "to": "exit", "bidirectional": true},
				{"id": "storage", "role": "STORAGE_TRACK", "from": "e_sw", "to": "storage_buf", "bidirectional": true},
			],
		},
		"world_graph": {"entities": [], "relations": []},
	}

	# Layout 3: plain base passing loop (no storage)
	var data_3 := {
		"archetype_id": "village_passing_station",
		"grammar_version": "central_eu_small_town_station_v1",
		"generator_version": "9a_schema_v1",
		"rail_graph": {
			"entry_node": "entry",
			"exit_node": "exit",
			"nodes": [
				{"id": "entry", "type": "ENTRY"},
				{"id": "w_sw", "type": "SWITCH"},
				{"id": "e_sw", "type": "SWITCH"},
				{"id": "exit", "type": "EXIT"},
			],
			"edges": [
				{"id": "app", "role": "THROUGH_MAIN", "from": "entry", "to": "w_sw", "bidirectional": true},
				{"id": "main", "role": "PLATFORM_TRACK", "from": "w_sw", "to": "e_sw", "bidirectional": true},
				{"id": "loop", "role": "PASSING_LOOP", "from": "w_sw", "to": "e_sw", "bidirectional": true},
				{"id": "ext", "role": "THROUGH_MAIN", "from": "e_sw", "to": "exit", "bidirectional": true},
			],
		},
		"world_graph": {"entities": [], "relations": []},
	}

	var sig_1: String = SectorBlueprint.from_dictionary(data_1).get_topology_signature()
	var sig_2: String = SectorBlueprint.from_dictionary(data_2).get_topology_signature()
	var sig_3: String = SectorBlueprint.from_dictionary(data_3).get_topology_signature()

	if sig_1 == sig_2:
		failures.append("Topology signature failed to distinguish storage off west switch vs east switch!")
	if sig_1 == sig_3 or sig_2 == sig_3:
		failures.append("Topology signature failed to distinguish storage track presence vs absence!")

	print("  Sig 1 (storage west): %s" % sig_1)
	print("  Sig 2 (storage east): %s" % sig_2)
	print("  Sig 3 (base loop):    %s" % sig_3)
	print("  Distinct connectivity verified successfully.")


func test_archetype_topology_variety(failures: Array[String]) -> void:
	print("\n[TEST] Archetype Topology Variety Sweep (50 seeds per archetype)")
	var generator := WorldgenSemanticGenerator.new()

	var targets := {
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH: 2,
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION: 3,
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS: 3,
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT: 3,
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED: 2,
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH: 3,
	}

	for arch in targets.keys():
		var signatures: Dictionary = {}
		var target_count: int = targets[arch]
		for seed_val in range(1, 51):
			var req := WorldgenGenerationRequest.new(
				seed_val * 77 + 13, 0,
				WorldgenGenerationRequest.DEFAULT_ROUTE_PROFILE,
				WorldgenGenerationRequest.DEFAULT_REGION_PACK,
				WorldgenGenerationRequest.DEFAULT_GRAMMAR_VERSION,
				WorldgenSemanticGenerator.PRODUCTION_GENERATOR_VERSION
			)
			var ctx := WorldgenGenerationContext.new(req)
			var res := generator.generate_blueprint_for_archetype(ctx, arch)
			if not bool(res.get("success", false)):
				failures.append("Generation failed for %s seed %d" % [arch, seed_val])
				continue
			var blueprint: RefCounted = res.get("blueprint", null)
			var sig := str(blueprint.get_topology_signature())
			signatures[sig] = true

		var count := signatures.size()
		print("  Archetype '%s': generated %d distinct topologies (target: >= %d)" % [arch, count, target_count])
		if count < target_count:
			failures.append("Archetype '%s' produced only %d topology variants (target >= %d)" % [arch, count, target_count])
