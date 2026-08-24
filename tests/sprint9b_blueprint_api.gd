extends SceneTree

const LOADER_PATH := "res://scripts/worldgen/worldgen_fixture_loader.gd"
const GOODS_FIXTURE := "res://data/worldgen/archetypes/reference/small_town_goods_station_v1.json"
const RURAL_FIXTURE := "res://data/worldgen/archetypes/reference/rural_through_v1.json"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9B Blueprint API Tests ---")
	_blueprint_queries_are_source_neutral_and_defensive()
	_finish()


func _blueprint_queries_are_source_neutral_and_defensive() -> void:
	_expect(ResourceLoader.exists(LOADER_PATH), "9B fixture loader exists")
	_expect(FileAccess.file_exists(GOODS_FIXTURE), "small-town goods station fixture exists")
	_expect(FileAccess.file_exists(RURAL_FIXTURE), "rural through fixture exists")
	if not ResourceLoader.exists(LOADER_PATH) or not FileAccess.file_exists(GOODS_FIXTURE) or not FileAccess.file_exists(RURAL_FIXTURE):
		return

	var loader: RefCounted = (load(LOADER_PATH) as Script).new()
	var goods = loader.load_blueprint(GOODS_FIXTURE)
	var rural = loader.load_blueprint(RURAL_FIXTURE)
	_expect(goods != null, "goods station blueprint constructs")
	_expect(rural != null, "rural through blueprint constructs")
	if goods == null or rural == null:
		return

	_expect(goods.get_tracks_by_role("THROUGH_MAIN").size() >= 2, "goods station exposes through-main tracks")
	_expect(goods.get_tracks_by_role("PASSING_LOOP").size() == 1, "goods station exposes one passing loop")
	_expect(goods.get_tracks_by_role("GOODS_YARD_TRACK").size() >= 1, "goods station exposes goods yard")
	_expect(goods.get_tracks_by_role("LOADING_TRACK").size() >= 1, "goods station exposes loading track")
	_expect(goods.get_nodes_by_type("ENTRY").size() == 1, "goods station exposes entry node")
	_expect(goods.get_nodes_by_type("EXIT").size() == 1, "goods station exposes exit node")
	_expect(not goods.get_station().is_empty(), "goods station exposes station entity")
	_expect(goods.get_goods_yards().size() >= 1, "goods station exposes goods-yard entities")
	_expect(goods.get_industries().size() >= 1, "goods station exposes industry/agricultural entities")
	_expect(goods.has_rail_path("west_entry", "east_exit"), "goods station has explicit west-entry to east-exit path")
	_expect(not goods.has_rail_path("west_entry", "missing_exit"), "unknown rail node path fails")

	_expect(rural.get_tracks_by_role("PASSING_LOOP").is_empty(), "rural through has no passing loop")
	_expect(rural.get_goods_yards().is_empty(), "rural through has no goods yard")

	var track_copy: Array[Dictionary] = goods.get_tracks_by_role("GOODS_YARD_TRACK")
	var original_id := str(track_copy[0].get("id", ""))
	track_copy[0]["id"] = "mutated"
	_expect(str(goods.get_tracks_by_role("GOODS_YARD_TRACK")[0].get("id", "")) == original_id, "track query returns defensive copies")

	var station_copy: Dictionary = goods.get_station()
	var station_id := str(station_copy.get("id", ""))
	station_copy["id"] = "mutated_station"
	_expect(str(goods.get_station().get("id", "")) == station_id, "entity query returns defensive copy")

	var dict_copy: Dictionary = goods.to_dictionary()
	((dict_copy.get("rail_graph", {}) as Dictionary).get("edges", []) as Array)[0]["id"] = "mutated_edge"
	_expect(str(((goods.to_dictionary().get("rail_graph", {}) as Dictionary).get("edges", []) as Array)[0].get("id", "")) != "mutated_edge", "to_dictionary returns defensive deep copy")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9B blueprint API acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9B blueprint API acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
