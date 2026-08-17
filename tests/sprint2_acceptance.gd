extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var sim = RailMovement.new()

	if not _require_methods(sim):
		_finish()
		return

	_expect_units(sim, ["L", "A", "B"], "yard starts with [L][A][B] coupled on the main line")
	_expect(sim.has_detached_consist(["C"], RailMovement.SEGMENT_SIDING), "wagon C starts detached on the siding")
	_expect(sim.get_wagon_type_count() >= 2, "minimum two wagon types exist")
	_expect(sim.get_coupler_status_lines().size() >= 3, "rolling stock exposes front/rear coupler state")

	var starting_mass: float = sim.get_total_mass()
	_expect(sim.decouple_rear(), "player can decouple B from [L][A][B]")
	_expect_units(sim, ["L", "A"], "decoupling leaves active consist [L][A]")
	_expect(sim.has_detached_consist(["B"], RailMovement.SEGMENT_MAIN_WEST), "decoupled B remains physically parked on the main line")
	_expect(sim.get_total_mass() < starting_mass, "active consist mass drops after decoupling B")

	sim.set_points_route(RailMovement.POINTS_SIDING)
	sim.set_throttle(1.0)
	_step_until_can_couple(sim, "C", 12.0)
	_expect(sim.can_couple_unit("C"), "player can move [L][A] through points to align with C")

	sim.speed = sim.max_coupling_speed + 5.0
	_expect(not sim.couple_nearest(), "coupling is blocked above the low-speed limit")

	sim.speed = 0.0
	sim.set_throttle(0.0)
	var mass_after_decouple: float = sim.get_total_mass()
	_expect(sim.couple_nearest(), "player can couple C at low speed")
	_expect_units(sim, ["L", "A", "C"], "coupling C produces [L][A][C]")
	_expect(sim.get_total_mass() > mass_after_decouple, "active consist mass increases after coupling C")

	_expect(sim.set_direction(-1), "player can reverse while stopped")
	sim.set_points_route(RailMovement.POINTS_MAIN)
	sim.set_throttle(1.0)
	_step_until_can_couple(sim, "B", 12.0)
	_expect(sim.can_couple_unit("B"), "player can return to the main line and align with B")

	sim.speed = 0.0
	sim.set_throttle(0.0)
	_expect(sim.couple_nearest(), "player can recouple B")
	_expect_units(sim, ["L", "A", "C", "B"], "final consist order is [L][A][C][B]")
	_expect(sim.get_total_mass() > starting_mass, "final mass reflects recovered wagon C")
	_expect(_debug_has_required_state(sim), "debug state reports Sprint 2 consist and movement data")

	_finish()


func _require_methods(sim: RefCounted) -> bool:
	var methods: Array[String] = [
		"get_active_consist_ids",
		"has_detached_consist",
		"get_wagon_type_count",
		"get_coupler_status_lines",
		"get_total_mass",
		"decouple_rear",
		"can_couple_unit",
		"couple_nearest",
	]

	var all_present := true
	for method_name in methods:
		if sim.has_method(method_name):
			continue

		_failures += 1
		all_present = false
		printerr("FAIL: missing Sprint 2 method %s" % method_name)

	return all_present


func _step_until_can_couple(sim: RefCounted, unit_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and not sim.can_couple_unit(unit_id):
		sim.step(0.1, false)
		elapsed += 0.1


func _expect_units(sim: RefCounted, expected: Array[String], message: String) -> void:
	var actual: Array = sim.get_active_consist_ids()
	if actual.size() != expected.size():
		_failures += 1
		printerr("FAIL: %s; got %s" % [message, _format_ids(actual)])
		return

	for index in expected.size():
		if actual[index] == expected[index]:
			continue

		_failures += 1
		printerr("FAIL: %s; got %s" % [message, _format_ids(actual)])
		return


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _debug_has_required_state(sim: RefCounted) -> bool:
	var debug_text := "\n".join(sim.get_debug_lines())
	return debug_text.contains("Consist:") \
		and debug_text.contains("Speed:") \
		and debug_text.contains("Direction:") \
		and debug_text.contains("Throttle:") \
		and debug_text.contains("Brake:") \
		and debug_text.contains("Points:") \
		and debug_text.contains("Mass:") \
		and debug_text.contains("Couplers:")


func _format_ids(ids: Array) -> String:
	var pieces: Array[String] = []
	for id in ids:
		pieces.append(str(id))
	return "[" + ",".join(pieces) + "]"


func _finish() -> void:
	if _failures == 0:
		print("Sprint 2 acceptance simulation passed")
		quit(0)
		return

	printerr("Sprint 2 acceptance simulation failed with %d failure(s)" % _failures)
	quit(1)
