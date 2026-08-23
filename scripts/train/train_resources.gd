extends RefCounted
class_name TrainResources

const RESOURCE_DIESEL := "diesel"
const RESOURCE_FOOD := "food"
const RESOURCE_PARTS := "parts"

const DEPARTURE_DIESEL_COST := 10.0

var _amounts: Dictionary = {
	RESOURCE_DIESEL: 12.0,
	RESOURCE_FOOD: 12.0,
	RESOURCE_PARTS: 0.0,
}


func _init(initial_amounts: Dictionary = {}) -> void:
	for resource_type: String in [RESOURCE_DIESEL, RESOURCE_FOOD, RESOURCE_PARTS]:
		if not initial_amounts.has(resource_type):
			continue
		_amounts[resource_type] = maxf(float(initial_amounts.get(resource_type, 0.0)), 0.0)


func get_amount(resource_type: String) -> float:
	if not _amounts.has(resource_type):
		return 0.0
	return float(_amounts.get(resource_type, 0.0))


func set_amount(resource_type: String, amount: float) -> bool:
	if not _amounts.has(resource_type):
		return false
	_amounts[resource_type] = maxf(amount, 0.0)
	return true


func add(resource_type: String, amount: float) -> bool:
	if not _amounts.has(resource_type):
		return false
	if amount <= 0.0:
		return false
	_amounts[resource_type] = get_amount(resource_type) + amount
	return true


func consume(resource_type: String, amount: float) -> bool:
	if not can_afford(resource_type, amount):
		return false
	_amounts[resource_type] = maxf(get_amount(resource_type) - amount, 0.0)
	return true


func can_afford(resource_type: String, amount: float) -> bool:
	if amount < 0.0:
		return false
	return get_amount(resource_type) + 0.001 >= amount


func get_all() -> Dictionary:
	return _amounts.duplicate()


func get_debug_summary() -> String:
	return "Diesel: %.0f  Food: %.0f  Parts: %.0f" % [
		get_amount(RESOURCE_DIESEL),
		get_amount(RESOURCE_FOOD),
		get_amount(RESOURCE_PARTS),
	]
