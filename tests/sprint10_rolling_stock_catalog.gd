extends SceneTree

const CATALOG_PATH := "res://scripts/train/rolling_stock_catalog.gd"

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Rolling-Stock Catalogue Tests ---")
	_catalog_definitions_are_complete_and_unique()
	_legacy_units_map_to_formal_types()
	_salvage_catalog_excludes_powered_and_unactivated_workshop_stock()
	_finish()


func _catalog_definitions_are_complete_and_unique() -> void:
	var catalog := _load_catalog()
	if catalog == null:
		return

	var expected := [
		"locomotive_diesel",
		"yard_shunter",
		"bunk_car",
		"boxcar_storage",
		"fuel_tanker",
		"workshop_car",
		"parts_flatbed",
	]
	for type_id in expected:
		_expect(catalog.has_type(type_id), "catalog contains %s" % type_id)

	var seen: Dictionary = {}
	for type_id in catalog.get_type_ids():
		_expect(not seen.has(type_id), "catalog type id %s is unique" % type_id)
		seen[type_id] = true
		var definition: Dictionary = catalog.get_definition(type_id)
		_expect(str(definition.get("id", "")) == type_id, "%s definition echoes id" % type_id)
		_expect(str(definition.get("display_name", "")) != "", "%s has display name" % type_id)
		_expect(str(definition.get("physical_type", "")) != "", "%s has physical type" % type_id)
		_expect(float(definition.get("length", 0.0)) > 0.0, "%s has positive length" % type_id)
		_expect(float(definition.get("mass", 0.0)) > 0.0, "%s has positive mass" % type_id)
		_expect(str(definition.get("summary", "")) != "", "%s exposes inspection summary" % type_id)

	_expect(catalog.get_definition("missing_type").is_empty(), "unknown type fails clearly with empty definition")


func _legacy_units_map_to_formal_types() -> void:
	var catalog := _load_catalog()
	if catalog == null:
		return

	var expected := {
		"L": "locomotive_diesel",
		"S": "yard_shunter",
		"A": "bunk_car",
		"B": "boxcar_storage",
		"C": "fuel_tanker",
		"W": "workshop_car",
		"C002": "fuel_tanker",
		"B017": "boxcar_storage",
	}
	for unit_id in expected.keys():
		_expect(
			str(catalog.infer_legacy_type_id(str(unit_id))) == str(expected[unit_id]),
			"legacy unit %s maps to %s" % [str(unit_id), str(expected[unit_id])]
		)

	var explicit := {"A900": "fuel_tanker"}
	_expect(
		str(catalog.get_definition_for_unit("A900", explicit).get("id", "")) == "fuel_tanker",
		"explicit unit metadata overrides legacy prefix inference"
	)


func _salvage_catalog_excludes_powered_and_unactivated_workshop_stock() -> void:
	var catalog := _load_catalog()
	if catalog == null:
		return

	var salvage: Array[String] = catalog.get_salvage_type_ids()
	_expect(salvage.has("fuel_tanker"), "fuel tanker is valid procedural salvage")
	_expect(salvage.has("boxcar_storage"), "storage boxcar is valid procedural salvage")
	_expect(salvage.has("parts_flatbed"), "parts flatbed is valid procedural salvage")
	_expect(not salvage.has("locomotive_diesel"), "locomotives are not Sprint 10 procedural salvage")
	_expect(not salvage.has("yard_shunter"), "shunters are not Sprint 10 procedural salvage")
	_expect(not salvage.has("workshop_car"), "workshop cars are not procedural salvage without a generic activation path")


func _load_catalog() -> RefCounted:
	_expect(ResourceLoader.exists(CATALOG_PATH), "RollingStockCatalog script exists")
	if not ResourceLoader.exists(CATALOG_PATH):
		return null
	var script := load(CATALOG_PATH) as Script
	_expect(script != null and script.can_instantiate(), "RollingStockCatalog loads and instantiates")
	if script == null or not script.can_instantiate():
		return null
	return script.new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 rolling-stock catalogue acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 rolling-stock catalogue FAILED with %d failure(s)" % _failures)
		quit(1)
