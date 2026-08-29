extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Wagon Inspection UI Tests ---")
	await _normal_scene_exposes_wagon_function_and_resource_capacity()
	await _normal_scene_exposes_sprint10_load_check()
	await _normal_scene_reports_current_generated_stock()
	_finish()


func _normal_scene_exposes_wagon_function_and_resource_capacity() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var resources: Dictionary = scene.get_train_resource_state()
	_expect(resources.has("capacity_diesel"), "normal scene resource state exposes diesel capacity")
	_expect(resources.has("capacity_food"), "normal scene resource state exposes food capacity")
	_expect(resources.has("capacity_parts"), "normal scene resource state exposes parts capacity")
	_expect(
		float(resources.get("capacity_diesel", 0.0)) >= float(resources.get(TrainResources.RESOURCE_DIESEL, 0.0)),
		"normal scene starting diesel amount fits current train capacity"
	)

	var unit_id := "sector_020_salvage_01"
	_expect(scene.rail.set_unit_type(unit_id, "fuel_tanker"), "fixture assigns generated tanker type for inspection")
	var detached: Array[Dictionary] = [
		{
			"units": [unit_id],
			"segment": RailMovement.SEGMENT_SIDING,
			"distance": 140.0,
		},
	]
	scene.rail.detached_consists = detached
	var state: Dictionary = scene._get_unit_draw_state(unit_id)
	_expect(not state.is_empty(), "normal scene can draw explicitly typed generated salvage")
	if not state.is_empty():
		var label: String = scene._describe_context_target(state.get("position", Vector2.ZERO) as Vector2)
		_expect(label.contains("Fuel Tanker"), "wagon inspection label includes catalogue display name")
		_expect(label.contains("salvage"), "wagon inspection label identifies detached salvage ownership")
		_expect(label.contains("diesel"), "wagon inspection label includes functional capability summary")

	scene.queue_free()


func _normal_scene_reports_current_generated_stock() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var unit_id := "sector_030_salvage_01"
	_expect(scene.rail.set_unit_type(unit_id, "parts_flatbed"), "fixture assigns current generated stock type")
	var detached: Array[Dictionary] = [
		{
			"units": [unit_id],
			"segment": RailMovement.SEGMENT_SIDING,
			"distance": 140.0,
		},
	]
	scene.rail.detached_consists = detached
	var joined := "\n".join(scene.get_compact_debug_lines())
	_expect(joined.contains("Generated stock:"), "normal debug panel reports current generated stock")
	_expect(joined.contains(unit_id), "normal debug panel reports current generated stock ID")
	_expect(joined.contains("parts_flatbed"), "normal debug panel reports current generated stock type")
	_expect(joined.contains("salvage"), "normal debug panel reports current generated stock ownership state")
	_expect(joined.contains("parts capacity"), "normal debug panel reports current generated stock capability")

	scene.queue_free()


func _normal_scene_exposes_sprint10_load_check() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("get_sprint10_preflight_state"), "normal scene exposes Sprint 10 preflight state")
	_expect(scene.has_method("get_sprint10_preflight_lines"), "normal scene exposes Sprint 10 preflight lines")
	if not scene.has_method("get_sprint10_preflight_state") or not scene.has_method("get_sprint10_preflight_lines"):
		scene.queue_free()
		return

	var state: Dictionary = scene.get_sprint10_preflight_state()
	var catalog_types := state.get("catalog_type_ids", []) as Array
	_expect(catalog_types.has("fuel_tanker"), "load check confirms fuel tanker catalogue entry")
	_expect(catalog_types.has("parts_flatbed"), "load check confirms parts flatbed catalogue entry")
	_expect(catalog_types.has("boxcar_storage"), "load check confirms boxcar storage catalogue entry")
	var salvage_types := state.get("salvage_type_ids", []) as Array
	_expect(salvage_types.has("fuel_tanker"), "load check confirms tanker is generated salvage")
	_expect(salvage_types.has("parts_flatbed"), "load check confirms parts flatbed is generated salvage")
	_expect(salvage_types.has("boxcar_storage"), "load check confirms boxcar storage is generated salvage")

	var samples := state.get("seed_samples", []) as Array
	_expect(samples.size() == 3, "load check exposes three known Sprint 10 seed samples")
	for raw_sample in samples:
		var sample := raw_sample as Dictionary
		_expect(bool(sample.get("seeded", false)), "seed %d is seeded into normal generator" % int(sample.get("seed", 0)))
		_expect(str(sample.get("unit_id", "")) == "sector_002_salvage_01", "seed %d uses expected generated unit ID" % int(sample.get("seed", 0)))
		_expect(str(sample.get("actual_type_id", "")) == str(sample.get("expected_type_id", "")), "seed %d resolves expected wagon type" % int(sample.get("seed", 0)))

	var lines: Array[String] = scene.get_sprint10_preflight_lines()
	var joined := "\n".join(lines)
	_expect(joined.contains("Sprint 10 Load Check"), "load check lines have visible title")
	_expect(joined.contains("fuel_tanker"), "load check lines mention tanker seed")
	_expect(joined.contains("parts_flatbed"), "load check lines mention flatbed seed")
	_expect(joined.contains("boxcar_storage"), "load check lines mention boxcar seed")
	var guide := "\n".join(scene.get_uat_tutorial_lines())
	_expect(guide.contains("Train Scav - Sprint 12 UAT"), "normal startup guide names current Sprint 12 UAT")
	_expect(guide.contains("Sprint 10 salvage seeds remain active"), "normal startup guide keeps Sprint 10 salvage compatibility visible")

	scene.queue_free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 wagon inspection UI acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 wagon inspection UI FAILED with %d failure(s)" % _failures)
		quit(1)
