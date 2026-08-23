extends SceneTree

# Sprint 7A — train resources and deterministic local POIs.

const TRAIN_RESOURCES_PATH := "res://scripts/train/train_resources.gd"
const SECTOR_POIS_PATH := "res://scripts/sector/sector_pois.gd"
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 7A Resource / POI Tests ---")
	test_resource_store()
	test_sector_exposes_deterministic_pois()
	_finish()


func test_resource_store() -> void:
	print("Testing train resource store...")
	_expect(ResourceLoader.exists(TRAIN_RESOURCES_PATH), "TrainResources script exists")
	if not ResourceLoader.exists(TRAIN_RESOURCES_PATH):
		return

	var TrainResources = load(TRAIN_RESOURCES_PATH)
	var resources = TrainResources.new({
		"diesel": 6.0,
		"food": 12.0,
		"parts": 0.0,
	})

	_expect(resources.get_amount("diesel") == 6.0, "diesel amount is readable")
	_expect(resources.get_amount("food") == 12.0, "food amount is readable")
	_expect(resources.get_amount("parts") == 0.0, "parts amount is readable")
	_expect(resources.can_afford("diesel", 6.0), "affordability succeeds at exact amount")
	_expect(not resources.can_afford("diesel", 7.0), "affordability fails above amount")
	_expect(resources.consume("diesel", 4.0), "consume succeeds when affordable")
	_expect(resources.get_amount("diesel") == 2.0, "consume subtracts resource")
	_expect(not resources.consume("diesel", 8.0), "consume refuses unaffordable spend")
	_expect(resources.get_amount("diesel") == 2.0, "failed consume leaves amount unchanged")
	resources.add("diesel", 9.0)
	_expect(resources.get_amount("diesel") == 11.0, "add increases resource")
	resources.add("diesel", -50.0)
	_expect(resources.get_amount("diesel") == 11.0, "negative add is ignored")
	_expect(resources.get_all().has("food"), "get_all exposes food key")


func test_sector_exposes_deterministic_pois() -> void:
	print("Testing sector POIs...")
	_expect(ResourceLoader.exists(SECTOR_POIS_PATH), "SectorPOIs script exists")
	if not ResourceLoader.exists(SECTOR_POIS_PATH):
		return

	var def := SectorDefinition.create_for_index(12345, 0)
	var sector := SectorInstance.new(def)
	_expect(sector.has_method("get_poi_states"), "SectorInstance exposes POI states")
	_expect(sector.has_method("search_poi"), "SectorInstance exposes authoritative POI search")
	if not sector.has_method("get_poi_states"):
		return

	var pois: Array[Dictionary] = sector.get_poi_states()
	_expect(pois.size() >= 3, "sector exposes at least three deterministic POIs")
	_expect(_has_poi(pois, "fuel_depot"), "sector includes fuel depot")
	_expect(_has_poi(pois, "maintenance_shed"), "sector includes maintenance shed")
	_expect(_has_poi(pois, "supply_store"), "sector includes food/supply POI")

	var fuel_before: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(not bool(fuel_before.get("searched", true)), "fuel depot starts unsearched")
	_expect(float(fuel_before.get("available_amount", -1.0)) == 0.0, "unsearched fuel has no available loot")
	_expect(sector.search_poi("fuel_depot"), "fuel depot can be searched once")
	var fuel_after: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(bool(fuel_after.get("searched", false)), "fuel depot becomes searched")
	_expect(str(fuel_after.get("available_type", "")) == "diesel", "fuel depot reveals diesel")
	_expect(float(fuel_after.get("available_amount", 0.0)) > 0.0, "fuel depot reveals positive diesel amount")
	_expect(not sector.search_poi("fuel_depot"), "repeat search cannot duplicate loot")
	var fuel_repeat: Dictionary = sector.get_poi_state("fuel_depot")
	_expect(float(fuel_repeat.get("available_amount", 0.0)) == float(fuel_after.get("available_amount", 0.0)), "repeat search leaves available amount unchanged")


func _has_poi(pois: Array[Dictionary], poi_id: String) -> bool:
	for poi in pois:
		if str(poi.get("id", "")) == poi_id:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 7A resource / POI acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 7A resource / POI acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
