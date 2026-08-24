extends SceneTree

# Sprint 7 playable scene smoke test for the mouse-first scavenging flow.

const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7 Scene Scavenging Flow Tests ---")
	await test_scene_exposes_resources_pois_and_context_actions()
	_finish()


func test_scene_exposes_resources_pois_and_context_actions() -> void:
	print("Testing scene-level scavenging affordances...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("get_train_resource_state"), "scene exposes train resource state")
	_expect(scene.has_method("get_sector_poi_states"), "scene exposes active-sector POIs")
	_expect(scene.has_method("get_sector_poi_state"), "scene exposes specific POI state")
	if not scene.has_method("get_train_resource_state") or not scene.has_method("get_sector_poi_state"):
		scene.queue_free()
		return

	var resources: Dictionary = scene.get_train_resource_state()
	_expect(float(resources.get(TrainResources.RESOURCE_DIESEL, -1.0)) >= TrainResources.DEPARTURE_DIESEL_COST, "Sprint 8 scene starts with enough diesel to begin travel")
	_expect(is_equal_approx(float(resources.get("departure_cost", -1.0)), TrainResources.DEPARTURE_DIESEL_COST), "resource state exposes departure cost")
	_expect(not scene.lifecycle.can_depart(), "scene fixture cannot depart before resolving the opening blocker")

	var pois: Array[Dictionary] = scene.get_sector_poi_states()
	_expect(pois.size() >= 3, "scene exposes deterministic local POIs")
	var fuel: Dictionary = scene.get_sector_poi_state("fuel_depot")
	_expect(str(fuel.get("status", "")) == "Unsearched", "fuel depot starts unsearched")

	scene.crew.select_survivor("nia")
	scene.survivor_selection_confirmed = true
	scene._open_context_menu(scene.world_to_screen_position(fuel.get("position", Vector2.ZERO) as Vector2))
	var search_labels: Array[String] = scene.get_context_menu_labels()
	_expect(_labels_contain(search_labels, "Search Fuel Depot"), "right-click fuel depot offers Search")
	scene._close_context_menu()

	scene.lifecycle.current_sector.search_poi("fuel_depot")
	scene._open_context_menu(scene.world_to_screen_position(fuel.get("position", Vector2.ZERO) as Vector2))
	var haul_labels: Array[String] = scene.get_context_menu_labels()
	_expect(_labels_contain(haul_labels, "Haul 8 diesel"), "searched fuel depot offers hauling discovered diesel")
	scene._close_context_menu()

	scene.queue_free()


func _labels_contain(labels: Array[String], needle: String) -> bool:
	for label in labels:
		if label.contains(needle):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 7 scene scavenging flow acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 7 scene scavenging flow acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
