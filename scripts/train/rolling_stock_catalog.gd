extends RefCounted
class_name RollingStockCatalog

const TYPE_LOCOMOTIVE_DIESEL := "locomotive_diesel"
const TYPE_YARD_SHUNTER := "yard_shunter"
const TYPE_BUNK_CAR := "bunk_car"
const TYPE_BOXCAR_STORAGE := "boxcar_storage"
const TYPE_FUEL_TANKER := "fuel_tanker"
const TYPE_WORKSHOP_CAR := "workshop_car"
const TYPE_PARTS_FLATBED := "parts_flatbed"

const PHYSICAL_LOCOMOTIVE := "locomotive"
const PHYSICAL_SHUNTER := "shunter"
const PHYSICAL_FLATBED := "flatbed"
const PHYSICAL_BOXCAR := "boxcar"
const PHYSICAL_TANKER := "tanker"
const PHYSICAL_WORKSHOP := "workshop"

const INTERIOR_LOCOMOTIVE := "locomotive"
const INTERIOR_SHUNTER := "shunter"
const INTERIOR_BUNK := "bunk"
const INTERIOR_STORAGE := "storage"
const INTERIOR_WORKSHOP := "workshop"
const INTERIOR_EXTERNAL := "external"

const RESOURCE_DIESEL := "diesel"
const RESOURCE_FOOD := "food"
const RESOURCE_PARTS := "parts"

const _DEFINITIONS := {
	TYPE_LOCOMOTIVE_DIESEL: {
		"id": TYPE_LOCOMOTIVE_DIESEL,
		"display_name": "Diesel Locomotive",
		"physical_type": PHYSICAL_LOCOMOTIVE,
		"length": 64.0,
		"mass": 90.0,
		"powered": true,
		"traction_rating": 1.0,
		"boardable": true,
		"interior_kind": INTERIOR_LOCOMOTIVE,
		"interior_label": "LOCOMOTIVE",
		"gangway_front": false,
		"gangway_rear": true,
		"resource_capacity": {
			RESOURCE_DIESEL: 120.0,
			RESOURCE_FOOD: 0.0,
			RESOURCE_PARTS: 0.0,
		},
		"capabilities": ["traction", "control_cab", "diesel_storage", "storage_diesel", "powered", "boardable"],
		"salvage_allowed": false,
		"summary": "Powered diesel locomotive with control cab and onboard fuel capacity.",
	},
	TYPE_YARD_SHUNTER: {
		"id": TYPE_YARD_SHUNTER,
		"display_name": "Yard Shunter",
		"physical_type": PHYSICAL_SHUNTER,
		"length": 54.0,
		"mass": 62.0,
		"powered": true,
		"traction_rating": 1.0,
		"boardable": true,
		"interior_kind": INTERIOR_SHUNTER,
		"interior_label": "SHUNTER",
		"gangway_front": false,
		"gangway_rear": false,
		"resource_capacity": {
			RESOURCE_DIESEL: 20.0,
			RESOURCE_FOOD: 0.0,
			RESOURCE_PARTS: 0.0,
		},
		"capabilities": ["traction", "yard_power", "control_cab", "powered", "boardable"],
		"salvage_allowed": false,
		"summary": "Small powered shunter cab for yard work; not procedural Sprint 10 salvage.",
	},
	TYPE_BUNK_CAR: {
		"id": TYPE_BUNK_CAR,
		"display_name": "Bunk Car",
		"physical_type": PHYSICAL_FLATBED,
		"length": 56.0,
		"mass": 35.0,
		"powered": false,
		"boardable": true,
		"interior_kind": INTERIOR_BUNK,
		"interior_label": "BUNK",
		"gangway_front": true,
		"gangway_rear": true,
		"resource_capacity": {
			RESOURCE_DIESEL: 0.0,
			RESOURCE_FOOD: 0.0,
			RESOURCE_PARTS: 0.0,
		},
		"capabilities": ["crew_accommodation", "through_gangway", "boardable"],
		"salvage_allowed": false,
		"summary": "Boardable bunk carriage with through gangways for crew accommodation.",
	},
	TYPE_BOXCAR_STORAGE: {
		"id": TYPE_BOXCAR_STORAGE,
		"display_name": "Storage Boxcar",
		"physical_type": PHYSICAL_BOXCAR,
		"length": 56.0,
		"mass": 42.0,
		"powered": false,
		"boardable": true,
		"interior_kind": INTERIOR_STORAGE,
		"interior_label": "STORAGE",
		"gangway_front": true,
		"gangway_rear": true,
		"resource_capacity": {
			RESOURCE_DIESEL: 20.0,
			RESOURCE_FOOD: 80.0,
			RESOURCE_PARTS: 80.0,
		},
		"capabilities": ["resource_storage", "storage_food", "storage_parts", "through_gangway", "boardable"],
		"salvage_allowed": true,
		"summary": "Boardable storage car that expands food and parts capacity.",
	},
	TYPE_FUEL_TANKER: {
		"id": TYPE_FUEL_TANKER,
		"display_name": "Fuel Tanker",
		"physical_type": PHYSICAL_TANKER,
		"length": 52.0,
		"mass": 50.0,
		"powered": false,
		"boardable": false,
		"interior_kind": INTERIOR_EXTERNAL,
		"interior_label": "NO GANGWAY",
		"gangway_front": false,
		"gangway_rear": false,
		"resource_capacity": {
			RESOURCE_DIESEL: 160.0,
			RESOURCE_FOOD: 0.0,
			RESOURCE_PARTS: 0.0,
		},
		"capabilities": ["diesel_storage", "storage_diesel"],
		"salvage_allowed": true,
		"summary": "Non-boardable tanker that materially expands diesel capacity.",
	},
	TYPE_WORKSHOP_CAR: {
		"id": TYPE_WORKSHOP_CAR,
		"display_name": "Workshop Car",
		"physical_type": PHYSICAL_WORKSHOP,
		"length": 60.0,
		"mass": 48.0,
		"powered": false,
		"boardable": true,
		"interior_kind": INTERIOR_WORKSHOP,
		"interior_label": "WORKSHOP",
		"gangway_front": true,
		"gangway_rear": true,
		"resource_capacity": {
			RESOURCE_DIESEL: 0.0,
			RESOURCE_FOOD: 0.0,
			RESOURCE_PARTS: 20.0,
		},
		"capabilities": ["workshop", "through_gangway", "boardable"],
		"salvage_allowed": false,
		"summary": "Boardable workshop car. Existing authored W activation remains scenario-specific.",
	},
	TYPE_PARTS_FLATBED: {
		"id": TYPE_PARTS_FLATBED,
		"display_name": "Parts Flatbed",
		"physical_type": PHYSICAL_FLATBED,
		"length": 54.0,
		"mass": 38.0,
		"powered": false,
		"boardable": false,
		"interior_kind": INTERIOR_EXTERNAL,
		"interior_label": "NO GANGWAY",
		"gangway_front": false,
		"gangway_rear": false,
		"resource_capacity": {
			RESOURCE_DIESEL: 0.0,
			RESOURCE_FOOD: 0.0,
			RESOURCE_PARTS: 140.0,
		},
		"capabilities": ["storage_parts"],
		"salvage_allowed": true,
		"summary": "Non-boardable flatbed that materially expands parts capacity.",
	},
}


static func get_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id in _DEFINITIONS.keys():
		ids.append(str(type_id))
	ids.sort()
	return ids


static func has_type(type_id: String) -> bool:
	return _DEFINITIONS.has(type_id)


static func get_definition(type_id: String) -> Dictionary:
	if not _DEFINITIONS.has(type_id):
		return {}
	return (_DEFINITIONS[type_id] as Dictionary).duplicate(true)


static func infer_legacy_type_id(unit_id: String) -> String:
	match unit_id:
		"L":
			return TYPE_LOCOMOTIVE_DIESEL
		"S":
			return TYPE_YARD_SHUNTER
		"A":
			return TYPE_BUNK_CAR
		"B":
			return TYPE_BOXCAR_STORAGE
		"C":
			return TYPE_FUEL_TANKER
		"W":
			return TYPE_WORKSHOP_CAR
	if unit_id.begins_with("L"):
		return TYPE_LOCOMOTIVE_DIESEL
	if unit_id.begins_with("S"):
		return TYPE_YARD_SHUNTER
	if unit_id.begins_with("A"):
		return TYPE_BUNK_CAR
	if unit_id.begins_with("B"):
		return TYPE_BOXCAR_STORAGE
	if unit_id.begins_with("C"):
		return TYPE_FUEL_TANKER
	if unit_id.begins_with("W"):
		return TYPE_WORKSHOP_CAR
	return ""


static func get_definition_for_unit(unit_id: String, explicit_type_map: Dictionary = {}) -> Dictionary:
	var type_id := str(explicit_type_map.get(unit_id, ""))
	if type_id == "":
		type_id = infer_legacy_type_id(unit_id)
	return get_definition(type_id)


static func get_resource_capacity_for_units(unit_ids: Array[String], explicit_type_map: Dictionary = {}) -> Dictionary:
	var totals := {
		RESOURCE_DIESEL: 0.0,
		RESOURCE_FOOD: 0.0,
		RESOURCE_PARTS: 0.0,
	}
	for unit_id in unit_ids:
		var definition := get_definition_for_unit(str(unit_id), explicit_type_map)
		var capacity := definition.get("resource_capacity", {}) as Dictionary
		for resource_type in totals.keys():
			totals[resource_type] = float(totals[resource_type]) + float(capacity.get(resource_type, 0.0))
	return totals


static func get_capabilities_for_unit(unit_id: String, explicit_type_map: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	var definition := get_definition_for_unit(unit_id, explicit_type_map)
	for raw_capability in definition.get("capabilities", []) as Array:
		var capability := str(raw_capability)
		if capability == "" or result.has(capability):
			continue
		result.append(capability)
	return result


static func get_capabilities_for_units(unit_ids: Array[String], explicit_type_map: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	for unit_id in unit_ids:
		for capability in get_capabilities_for_unit(str(unit_id), explicit_type_map):
			if result.has(capability):
				continue
			result.append(capability)
	result.sort()
	return result


static func get_capability_summary(type_id: String) -> String:
	return str(get_definition(type_id).get("summary", ""))


static func get_salvage_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id in get_type_ids():
		var definition := get_definition(type_id)
		if bool(definition.get("salvage_allowed", false)):
			ids.append(type_id)
	return ids


static func get_traction_rating_for_unit(unit_id: String, explicit_type_map: Dictionary = {}) -> float:
	var definition := get_definition_for_unit(unit_id, explicit_type_map)
	if not bool(definition.get("powered", false)):
		return 0.0
	return float(definition.get("traction_rating", 1.0))
