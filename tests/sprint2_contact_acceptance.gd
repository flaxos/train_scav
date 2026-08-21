extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var method_names: Array[String] = [
		"get_active_occupied_interval",
		"get_detached_occupied_interval",
		"has_any_overlap",
		"get_last_contact",
		"get_condition_state",
	]
	var probe = RailMovement.new()
	for method_name in method_names:
		_expect(probe.has_method(method_name), "missing contact method %s" % method_name)

	if _failures == 0:
		_low_speed_contact_prevents_overlap_and_allows_coupling()
		_excessive_speed_contact_registers_impact()
		_wagon_locomotive_contact_uses_same_rail_interval_logic()
		_wagon_wagon_contact_uses_same_rail_interval_logic()
		_reverse_segment_entry_contact_prevents_cross_boundary_overlap()
		_existing_switch_siding_route_still_operates()
		_existing_coupling_sequence_still_operates()

	_finish()


func _low_speed_contact_prevents_overlap_and_allows_coupling() -> void:
	var sim := _make_contact_fixture(["L"], ["A"], 240.0, 300.0, 8.0, 1)
	sim.step(5.0, false)

	var active_interval: Dictionary = sim.get_active_occupied_interval()
	var wagon_interval: Dictionary = sim.get_detached_occupied_interval("A")
	var contact: Dictionary = sim.get_last_contact()

	_expect(not sim.has_any_overlap(), "low-speed contact prevents rolling stock overlap")
	_expect(is_equal_approx(float(active_interval["front"]), float(wagon_interval["rear"])), "locomotive stops exactly against stationary wagon")
	_expect(contact.get("type", "") == "controlled", "low-speed contact is classified as controlled")
	_expect(float(contact.get("relative_speed", 0.0)) <= sim.safe_contact_speed, "controlled contact records safe relative speed")
	_expect(bool(contact.get("coupling_permitted", false)), "controlled contact permits coupling")
	_expect(sim.can_couple_unit("A"), "valid low-speed contact remains suitable for coupling")


func _excessive_speed_contact_registers_impact() -> void:
	var sim := _make_contact_fixture(["L"], ["A"], 240.0, 300.0, 40.0, 1)
	sim.step(5.0, false)

	var active_interval: Dictionary = sim.get_active_occupied_interval()
	var wagon_interval: Dictionary = sim.get_detached_occupied_interval("A")
	var contact: Dictionary = sim.get_last_contact()

	_expect(not sim.has_any_overlap(), "impact still prevents rolling stock overlap")
	_expect(is_equal_approx(float(active_interval["front"]), float(wagon_interval["rear"])), "impact resolves at physical contact point")
	_expect(contact.get("type", "") == "impact", "excessive speed contact is classified as impact")
	_expect(float(contact.get("relative_speed", 0.0)) > sim.safe_contact_speed, "impact records excessive relative speed")
	_expect(not bool(contact.get("coupling_permitted", true)), "impact does not permit normal coupling")
	_expect(sim.get_condition_state() == "damaged", "impact applies simple damaged condition")
	_expect(not sim.couple_nearest(), "impact does not silently succeed as normal coupling")


func _wagon_wagon_contact_uses_same_rail_interval_logic() -> void:
	var sim := _make_contact_fixture(["A"], ["B"], 240.0, 300.0, 8.0, 1)
	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(not sim.has_any_overlap(), "wagon-to-wagon contact prevents overlap")
	_expect(contact.get("active_unit", "") == "A", "wagon contact records the moving wagon")
	_expect(contact.get("detached_unit", "") == "B", "wagon contact records the contacted wagon")


func _wagon_locomotive_contact_uses_same_rail_interval_logic() -> void:
	var sim := _make_contact_fixture(["A"], ["L"], 240.0, 304.0, 8.0, 1)
	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(not sim.has_any_overlap(), "wagon-to-locomotive contact prevents overlap")
	_expect(contact.get("active_unit", "") == "A", "wagon-to-locomotive contact records the moving wagon")
	_expect(contact.get("detached_unit", "") == "L", "wagon-to-locomotive contact records the contacted locomotive")


func _reverse_segment_entry_contact_prevents_cross_boundary_overlap() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["S"])
	var detached_consists: Array[Dictionary] = [
		{
			"units": _typed_units(["L"]),
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": sim.get_segment_length(RailMovement.SEGMENT_MAIN_WEST) - sim.get_unit_length("L") * 0.5,
		},
	]
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_EAST
	# Keep the shunter fully on MAIN_EAST at fixture start. Its rear coupler is
	# 12 units from P1, so this step must detect the parked locomotive exactly
	# at the cross-segment boundary before any overlap occurs.
	sim.distance = sim.get_unit_length("S") + 12.0
	sim.set_points_route(RailMovement.POINTS_MAIN)
	sim.direction = -1
	sim.speed = sim.safe_contact_speed * 2.0
	sim.throttle = 1.0
	sim.max_speed = sim.speed
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0
	sim.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	sim.controlled_power_unit_id = "S"

	sim.step(1.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(not sim.has_any_overlap(), "reverse entry from P1/main detects parked rolling stock before overlap")
	_expect(is_equal_approx(sim.distance, sim.get_unit_length("S")), "reverse contact stops with shunter rear coupler exactly at P1 boundary")
	_expect(sim.points_route == RailMovement.POINTS_MAIN, "reverse cross-boundary contact uses an aligned P1 route")
	_expect(not contact.is_empty(), "reverse cross-boundary contact is registered")
	_expect(contact.get("active_unit", "") == "S", "reverse contact records moving shunter")
	_expect(contact.get("detached_unit", "") == "L", "reverse contact records parked main locomotive")
	_expect(contact.get("type", "") == RailMovement.CONTACT_IMPACT, "high-speed cross-boundary contact is classified as impact")


func _existing_switch_siding_route_still_operates() -> void:
	var sim = RailMovement.new()
	sim.set_points_route(RailMovement.POINTS_SIDING)
	sim.set_throttle(1.0)
	_step_until_segment(sim, RailMovement.SEGMENT_SIDING, 12.0)
	_expect(sim.current_segment == RailMovement.SEGMENT_SIDING, "switch still routes the active consist into the siding")


func _existing_coupling_sequence_still_operates() -> void:
	var sim = RailMovement.new()
	sim.decouple_rear()
	sim.max_speed = sim.safe_contact_speed * 0.5
	sim.set_points_route(RailMovement.POINTS_SIDING)
	sim.set_throttle(1.0)
	_step_until_can_couple(sim, "C", 45.0)
	sim.speed = 0.0
	sim.set_throttle(0.0)

	_expect(sim.couple_nearest(), "existing low-speed coupling command still couples an aligned wagon")
	_expect(_format_ids(sim.get_active_consist_ids()) == "[C][L][A]", "front endpoint coupling produces [C][L][A]")


func _make_contact_fixture(active: Array[String], detached: Array[String], active_front: float, detached_center: float, contact_speed: float, direction: int) -> RefCounted:
	var sim = RailMovement.new()
	sim.active_units = active.duplicate()
	var detached_consists: Array[Dictionary] = [
		{
			"units": detached.duplicate(),
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": detached_center,
		},
	]
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = active_front
	sim.direction = direction
	sim.speed = contact_speed
	sim.throttle = 1.0
	sim.max_speed = contact_speed
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0
	return sim


func _step_until_segment(sim: RefCounted, segment: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and sim.current_segment != segment:
		sim.step(0.1, false)
		elapsed += 0.1


func _step_until_can_couple(sim: RefCounted, unit_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and not sim.can_couple_unit(unit_id):
		sim.step(0.1, false)
		elapsed += 0.1


func _format_ids(ids: Array) -> String:
	var text := ""
	for id in ids:
		text += "[%s]" % id
	return text


func _typed_units(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	result.assign(values)
	return result


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 2 contact acceptance passed")
		quit(0)
		return

	printerr("Sprint 2 contact acceptance failed with %d failure(s)" % _failures)
	quit(1)
