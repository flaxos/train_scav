extends RefCounted
class_name SectorPOIs

const TrainResources := preload("res://scripts/train/train_resources.gd")

const POI_FUEL_DEPOT := "fuel_depot"
const POI_MAINTENANCE_SHED := "maintenance_shed"
const POI_SUPPLY_STORE := "supply_store"

var sector_seed: int = 0
var _pois: Dictionary = {}


func _init(seed_value: int = 0, poi_definitions: Array[Dictionary] = []) -> void:
	sector_seed = seed_value
	if not poi_definitions.is_empty():
		_pois = {}
		for definition in poi_definitions:
			_add_poi_from_definition(definition)
		return
	_pois = {
		POI_FUEL_DEPOT: _make_poi(
			POI_FUEL_DEPOT,
			"Fuel Depot",
			"Fuel tank",
			Vector2(285.0, 500.0),
			TrainResources.RESOURCE_DIESEL,
			8.0
		),
		POI_MAINTENANCE_SHED: _make_poi(
			POI_MAINTENANCE_SHED,
			"Maintenance Shed",
			"Tool crate",
			Vector2(760.0, 260.0),
			TrainResources.RESOURCE_PARTS,
			5.0
		),
		POI_SUPPLY_STORE: _make_poi(
			POI_SUPPLY_STORE,
			"Supply Store",
			"Food shelves",
			Vector2(980.0, 265.0),
			TrainResources.RESOURCE_FOOD,
			7.0
		),
	}


func get_poi_ids() -> Array[String]:
	var ids: Array[String] = []
	for poi_id in _pois.keys():
		ids.append(str(poi_id))
	return ids


func get_poi_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for poi_id: String in get_poi_ids():
		states.append(get_poi_state(poi_id))
	return states


func get_poi_state(poi_id: String) -> Dictionary:
	if not _pois.has(poi_id):
		return {}
	return (_pois[poi_id] as Dictionary).duplicate(true)


func get_poi_anchor(poi_id: String) -> Vector2:
	if not _pois.has(poi_id):
		return Vector2.ZERO
	return (_pois[poi_id] as Dictionary).get("position", Vector2.ZERO) as Vector2


func can_search(poi_id: String) -> bool:
	if not _pois.has(poi_id):
		return false
	return not bool((_pois[poi_id] as Dictionary).get("searched", false))


func search_poi(poi_id: String) -> bool:
	if not can_search(poi_id):
		return false

	var poi := _pois[poi_id] as Dictionary
	poi["searched"] = true
	poi["available_type"] = str(poi.get("yield_type", ""))
	poi["available_amount"] = float(poi.get("yield_amount", 0.0))
	poi["status"] = "Searched"
	return true


func has_available_loot(poi_id: String) -> bool:
	if not _pois.has(poi_id):
		return false
	var poi := _pois[poi_id] as Dictionary
	return bool(poi.get("searched", false)) and float(poi.get("available_amount", 0.0)) > 0.0


func take_available_loot(poi_id: String) -> Dictionary:
	if not has_available_loot(poi_id):
		return {}

	var poi := _pois[poi_id] as Dictionary
	var cargo := {
		"resource_type": str(poi.get("available_type", "")),
		"amount": float(poi.get("available_amount", 0.0)),
	}
	poi["available_amount"] = 0.0
	poi["status"] = "Collected"
	return cargo


func _make_poi(poi_id: String, name: String, target_name: String, position: Vector2, resource_type: String, amount: float) -> Dictionary:
	return {
		"id": poi_id,
		"name": name,
		"target_name": target_name,
		"position": position,
		"searched": false,
		"yield_type": resource_type,
		"yield_amount": amount,
		"available_type": "",
		"available_amount": 0.0,
		"status": "Unsearched",
	}


func _add_poi_from_definition(definition: Dictionary) -> void:
	var poi_id := str(definition.get("id", ""))
	if poi_id.is_empty() or _pois.has(poi_id):
		return
	var position := Vector2.ZERO
	var raw_position = definition.get("position", [0.0, 0.0])
	if typeof(raw_position) == TYPE_VECTOR2:
		position = raw_position as Vector2
	elif typeof(raw_position) == TYPE_ARRAY:
		var values := raw_position as Array
		if values.size() >= 2:
			position = Vector2(float(values[0]), float(values[1]))
	_pois[poi_id] = _make_poi(
		poi_id,
		str(definition.get("name", poi_id)),
		str(definition.get("target_name", definition.get("name", poi_id))),
		position,
		str(definition.get("yield_type", TrainResources.RESOURCE_PARTS)),
		float(definition.get("yield_amount", 0.0))
	)
