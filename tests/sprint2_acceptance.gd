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

	var decouple_probe = RailMovement.new()
	var starting_decouple_mass: float = decouple_probe.get_total_mass()
	_expect(decouple_probe.decouple_rear(), "player can decouple B from [L][A][B]")
	_expect_units(decouple_probe, ["L", "A"], "decoupling leaves active consist [L][A]")
	_expect(decouple_probe.has_detached_consist(["B"], RailMovement.SEGMENT_MAIN_WEST), "decoupled B remains physically parked on the main line")
	_expect(decouple_probe.get_total_mass() < starting_decouple_mass, "active consist mass drops after decoupling B")

	var starting_mass: float = sim.get_total_mass()
	sim.max_speed = sim.safe_contact_speed * 0.5
	sim.set_points_route(RailMovement.POINTS_SIDING)
	sim.set_throttle(1.0)
	_step_until_can_couple(sim, "C", 45.0)
	_expect(sim.current_segment == RailMovement.SEGMENT_SIDING, "player can move the active consist through points onto the siding")
	_expect(sim.can_couple_unit("C"), "player can align the active front endpoint with C on the siding")
	var contact: Dictionary = sim.get_last_contact()
	_expect(contact.get("active_unit", "") == "L", "contact identifies the active locomotive endpoint")
	_expect(contact.get("active_end", "") == "front", "contact identifies the active front coupler")
	_expect(contact.get("detached_unit", "") == "C", "contact identifies the target wagon")
	_expect(contact.get("detached_end", "") == "rear", "contact identifies C's rear coupler")

	sim.speed = sim.max_coupling_speed + 5.0
	_expect(not sim.couple_nearest(), "coupling is blocked above the low-speed limit")

	sim.speed = 0.0
	sim.set_throttle(0.0)
	var mass_before_coupling: float = sim.get_total_mass()
	_expect(sim.couple_nearest(), "player can couple C at low speed")
	_expect_units(sim, ["C", "L", "A", "B"], "front endpoint coupling produces [C][L][A][B]")
	_expect(sim.get_total_mass() > mass_before_coupling, "active consist mass increases after coupling C")
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
		"decouple_front",
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
		and debug_text.contains("Couplers:") \
		and debug_text.contains("Contact:") \
		and debug_text.contains("Coupling permitted:") \
		and debug_text.contains("Resulting consist:")


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
