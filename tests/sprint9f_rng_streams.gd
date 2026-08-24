extends SceneTree

const REQUEST_PATH := "res://scripts/worldgen/worldgen_generation_request.gd"
const CONTEXT_PATH := "res://scripts/worldgen/worldgen_generation_context.gd"
const RANDOM_STREAM_PATH := "res://scripts/worldgen/worldgen_random_stream.gd"

const GOLDEN_TOPOLOGY_SEQUENCE := [81807787, 1868743091, 1047153426, 1820427007, 948703304]

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 9F RNG Stream Tests ---")
	_required_files_exist()
	_stream_sequences_are_reproducible()
	_stream_consumption_is_independent()
	_stream_creation_order_is_independent()
	_stream_ranges_have_documented_bounds()
	_small_context_sweep_is_stable()
	_finish()


func _required_files_exist() -> void:
	_expect(ResourceLoader.exists(REQUEST_PATH), "generation request class exists")
	_expect(ResourceLoader.exists(CONTEXT_PATH), "generation context class exists")
	_expect(ResourceLoader.exists(RANDOM_STREAM_PATH), "worldgen random stream class exists")


func _stream_sequences_are_reproducible() -> void:
	var context := _make_context(12345, 7, "industrial")
	if context == null:
		return

	var first_rng: RefCounted = context.make_rng("topology")
	var second_rng: RefCounted = context.make_rng("topology")
	_expect(first_rng != null and second_rng != null, "topology RNG streams can be recreated")
	if first_rng == null or second_rng == null:
		return

	for i in range(GOLDEN_TOPOLOGY_SEQUENCE.size()):
		var expected := int(GOLDEN_TOPOLOGY_SEQUENCE[i])
		_expect(first_rng.next_int() == expected, "topology next_int %d matches golden sequence" % i)
		_expect(second_rng.next_int() == expected, "recreated topology next_int %d matches golden sequence" % i)
	_expect(first_rng.get_draw_count() == GOLDEN_TOPOLOGY_SEQUENCE.size(), "draw count tracks next_int calls")
	first_rng.reset()
	_expect(first_rng.next_int() == int(GOLDEN_TOPOLOGY_SEQUENCE[0]), "reset returns stream to initial subseed")


func _stream_consumption_is_independent() -> void:
	var context := _make_context(12345, 7, "industrial")
	if context == null:
		return

	var topology_before := _draw_ints(context.make_rng("topology"), 6)
	var decoration: RefCounted = context.make_rng("decoration")
	for _i in range(100):
		decoration.next_int()
	var topology_after := _draw_ints(context.make_rng("topology"), 6)
	_expect(topology_before == topology_after, "consuming decoration does not perturb topology sequence")


func _stream_creation_order_is_independent() -> void:
	var context := _make_context(12345, 7, "industrial")
	if context == null:
		return

	var terrain: RefCounted = context.make_rng("terrain")
	for _i in range(24):
		terrain.next_int()
	var topology_after_terrain := _draw_ints(context.make_rng("topology"), 6)

	var topology_first := _draw_ints(context.make_rng("topology"), 6)
	_expect(topology_after_terrain == topology_first, "creating and consuming terrain before topology does not perturb topology")


func _stream_ranges_have_documented_bounds() -> void:
	var context := _make_context(12345, 7, "industrial")
	if context == null:
		return

	var rng: RefCounted = context.make_rng("topology")
	_expect(rng.range_int(3, 3) == 3, "range_int uses inclusive bounds when min equals max")
	for _i in range(200):
		var int_value: int = rng.range_int(-2, 2)
		_expect(int_value >= -2 and int_value <= 2, "range_int returns values within inclusive min/max")
		var float_value: float = rng.next_float()
		_expect(float_value >= 0.0 and float_value < 1.0, "next_float returns [0.0, 1.0)")
		var ranged_float: float = rng.range_float(-4.0, 4.0)
		_expect(ranged_float >= -4.0 and ranged_float < 4.0, "range_float returns [min, max)")

	_expect(rng.range_float(2.5, 2.5) == 2.5, "range_float returns min when min equals max")


func _small_context_sweep_is_stable() -> void:
	var signatures: Dictionary = {}
	for seed in [1, 2, 3, 9001, 12345]:
		for index in range(0, 6):
			var context := _make_context(seed, index, "forward")
			if context == null:
				return
			var trace_hash := str(context.get_generation_trace().get_canonical_hash())
			var repeat_context := _make_context(seed, index, "forward")
			_expect(trace_hash == str(repeat_context.get_generation_trace().get_canonical_hash()), "context %d/%d trace is stable" % [seed, index])
			_expect(not signatures.has(trace_hash), "context %d/%d has distinct trace identity in small sweep" % [seed, index])
			signatures[trace_hash] = true


func _draw_ints(rng: RefCounted, count: int) -> Array[int]:
	var values: Array[int] = []
	if rng == null:
		_expect(false, "rng exists for draw")
		return values
	for _i in range(count):
		values.append(rng.next_int())
	return values


func _make_context(run_seed: int, sector_index: int, route_profile: String) -> RefCounted:
	var request_script := _load_script(REQUEST_PATH)
	var context_script := _load_script(CONTEXT_PATH)
	if request_script == null or context_script == null:
		return null
	return context_script.create(request_script.create(run_seed, sector_index, route_profile, "central_eu_v1"))


func _load_script(path: String) -> RefCounted:
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		_expect(false, "%s loads and can instantiate" % path)
		return null
	return script.new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 9F RNG stream acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 9F RNG stream acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
