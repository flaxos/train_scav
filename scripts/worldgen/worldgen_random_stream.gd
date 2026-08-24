extends RefCounted
class_name WorldgenRandomStream

const RNG_MODULUS := 2147483647
const RNG_MULTIPLIER := 48271

var _initial_seed: int = 1
var _state: int = 1
var _draw_count: int = 0


func _init(initial_seed: int = 1) -> void:
	_initial_seed = _normalize_seed(initial_seed)
	reset()


func next_int() -> int:
	_state = int((_state * RNG_MULTIPLIER) % RNG_MODULUS)
	_draw_count += 1
	return _state


func next_float() -> float:
	# Contract: callers may rely on [0.0, 1.0). Park-Miller never produces 0
	# for valid seeds, but the public bound remains the standard half-open range.
	return float(next_int()) / float(RNG_MODULUS)


func range_int(min_value: int, max_value: int) -> int:
	# Contract: inclusive integer bounds [min_value, max_value].
	if max_value < min_value:
		push_error("range_int requires max_value >= min_value")
		return min_value
	if max_value == min_value:
		return min_value
	var span := max_value - min_value + 1
	return min_value + int(next_int() % span)


func range_float(min_value: float, max_value: float) -> float:
	# Contract: half-open float bounds [min_value, max_value).
	if max_value < min_value:
		push_error("range_float requires max_value >= min_value")
		return min_value
	if max_value == min_value:
		return min_value
	return min_value + next_float() * (max_value - min_value)


func get_initial_seed() -> int:
	return _initial_seed


func get_state() -> int:
	return _state


func get_draw_count() -> int:
	return _draw_count


func reset() -> void:
	_state = _initial_seed
	_draw_count = 0


func to_debug_dictionary() -> Dictionary:
	return {
		"algorithm": "park_miller_lcg_48271_v1",
		"modulus": RNG_MODULUS,
		"multiplier": RNG_MULTIPLIER,
		"initial_seed": _initial_seed,
		"state": _state,
		"draw_count": _draw_count,
		"next_int_range": "[1, 2147483646]",
		"next_float_range": "[0.0, 1.0)",
		"range_int_bounds": "inclusive_min_inclusive_max",
		"range_float_bounds": "inclusive_min_exclusive_max",
	}


func _normalize_seed(seed_value: int) -> int:
	if seed_value <= 0:
		return 1
	if seed_value >= RNG_MODULUS:
		return int(((seed_value - 1) % (RNG_MODULUS - 1)) + 1)
	return seed_value
