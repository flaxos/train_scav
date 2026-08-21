extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	_require_locomotive_authority_api()
	_front_coupled_wagon_does_not_become_locomotive()
	_rear_decoupling_keeps_controlled_locomotive_in_active_consist()
	_front_decoupling_removes_front_wagon_without_changing_control()
	_front_decoupling_rejects_controlled_locomotive_end()
	_passive_wagon_consist_has_no_traction_authority()
	_locomotive_visual_identity_survives_reordering()

	_finish()


func _require_locomotive_authority_api() -> void:
	var sim = RailMovement.new()
	_expect(sim.has_method("get_controlled_locomotive_id"), "rail model exposes controlled locomotive identity")
	_expect(sim.has_method("get_powered_unit_ids"), "rail model exposes powered units")
	_expect(sim.has_method("has_traction_authority"), "rail model exposes active traction authority")
	_expect(sim.has_method("decouple_front"), "rail model exposes front decoupling")


func _front_coupled_wagon_does_not_become_locomotive() -> void:
	var sim := _make_front_coupled_fixture()
	_expect_units(sim, ["C", "L", "A", "B"], "front coupling produces [C][L][A][B]")
	if sim.has_method("get_controlled_locomotive_id"):
		_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after front coupling")
	if sim.has_method("get_powered_unit_ids"):
		_expect(_format_ids(sim.get_powered_unit_ids()) == "[L]", "only L provides traction authority")
	if sim.has_method("has_traction_authority"):
		_expect(sim.has_traction_authority(), "front-coupled consist still has locomotive traction")
	var debug_text := "\n".join(sim.get_debug_lines())
	_expect(debug_text.contains("Controlled locomotive: L"), "debug overlay reports controlled locomotive identity")
	_expect(debug_text.contains("Powered units: [L]"), "debug overlay reports powered units")
	_expect(sim.get_unit_type("C") != RailMovement.UNIT_LOCOMOTIVE, "C remains a wagon after becoming physical front")
	_expect(sim.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "L remains the locomotive after reordering")

	var start_distance: float = sim.distance
	sim.max_speed = 150.0
	sim.acceleration = 95.0
	sim.set_throttle(1.0)
	sim.step(0.5, false)
	_expect(sim.distance != start_distance or sim.current_segment != RailMovement.SEGMENT_MAIN_WEST, "throttle still moves consist because L supplies traction")


func _rear_decoupling_keeps_controlled_locomotive_in_active_consist() -> void:
	var sim := _make_front_coupled_fixture()

	_expect(sim.decouple_rear(), "rear decouple removes B from [C][L][A][B]")
	_expect_units(sim, ["C", "L", "A"], "active consist remains [C][L][A]")
	_expect(sim.has_detached_consist(_typed_units(["B"]), RailMovement.SEGMENT_MAIN_WEST), "B becomes detached passive rolling stock")
	if sim.has_method("get_controlled_locomotive_id"):
		_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after B decouples")

	_expect(sim.decouple_rear(), "rear decouple removes A from [C][L][A]")
	_expect_units(sim, ["C", "L"], "active consist remains [C][L]")
	_expect(sim.has_detached_consist(_typed_units(["A"]), RailMovement.SEGMENT_MAIN_WEST), "A becomes detached passive rolling stock")
	if sim.has_method("get_controlled_locomotive_id"):
		_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after A decouples")

	_expect(not sim.decouple_rear(), "rear decouple rejects removing the controlled locomotive from [C][L]")
	_expect_units(sim, ["C", "L"], "invalid decouple leaves [C][L] active")
	_expect(sim.get_unit_type("C") != RailMovement.UNIT_LOCOMOTIVE, "C is not promoted to locomotive after rejected decouple")
	if sim.has_method("get_controlled_locomotive_id"):
		_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after rejected decouple")
	if sim.has_method("has_traction_authority"):
		_expect(sim.has_traction_authority(), "active [C][L] still has controlled locomotive traction")


func _front_decoupling_removes_front_wagon_without_changing_control() -> void:
	var sim := _make_front_coupled_fixture()

	_expect(sim.decouple_rear(), "rear decouple removes B before front decouple test")
	_expect(sim.decouple_rear(), "rear decouple removes A before front decouple test")
	_expect_units(sim, ["C", "L"], "front decouple fixture reaches [C][L]")

	var l_state_before := _find_state(sim.get_unit_draw_states(), "L")
	_expect(not l_state_before.is_empty(), "L draw state exists before front decouple")
	var l_distance_before := float(l_state_before.get("distance", -1.0))

	_expect(sim.decouple_front(), "front decouple removes C from [C][L]")
	_expect_units(sim, ["L"], "active consist becomes [L] after front decouple")
	_expect(sim.has_detached_consist(_typed_units(["C"]), RailMovement.SEGMENT_MAIN_WEST), "C becomes detached passive rolling stock")
	_expect(sim.get_unit_type("C") != RailMovement.UNIT_LOCOMOTIVE, "front-decoupled C remains a wagon")
	_expect(sim.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "L remains the locomotive after front decouple")
	if sim.has_method("get_controlled_locomotive_id"):
		_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after front decouple")
	if sim.has_method("has_traction_authority"):
		_expect(sim.has_traction_authority(), "active [L] retains locomotive traction after front decouple")

	var l_state_after := _find_state(sim.get_unit_draw_states(), "L")
	_expect(not l_state_after.is_empty(), "L draw state exists after front decouple")
	if not l_state_before.is_empty() and not l_state_after.is_empty():
		_expect(is_equal_approx(float(l_state_after.get("distance", -2.0)), l_distance_before), "front decouple preserves L rail position")


func _front_decoupling_rejects_controlled_locomotive_end() -> void:
	var sim = RailMovement.new()
	_expect(not sim.decouple_front(), "front decouple rejects removing controlled locomotive from [L][A][B]")
	_expect_units(sim, ["L", "A", "B"], "invalid front decouple leaves [L][A][B] active")
	_expect(sim.blocked_reason.contains("front"), "invalid front decouple explains front endpoint is not detachable")
	if sim.has_method("get_controlled_locomotive_id"):
		_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after rejected front decouple")
	if sim.has_method("has_traction_authority"):
		_expect(sim.has_traction_authority(), "rejected front decouple leaves traction authority intact")


func _passive_wagon_consist_has_no_traction_authority() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["C"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = 260.0
	sim.speed = 0.0
	sim.throttle = 0.0

	if sim.has_method("has_traction_authority"):
		_expect(not sim.has_traction_authority(), "wagon-only active consist has no traction authority")
	if sim.has_method("get_powered_unit_ids"):
		_expect(sim.get_powered_unit_ids().is_empty(), "wagon-only active consist exposes no powered units")

	var start_distance: float = sim.distance
	sim.set_throttle(1.0)
	sim.step(1.0, false)
	_expect(is_equal_approx(sim.distance, start_distance), "throttle input cannot move a wagon-only consist")
	_expect(sim.get_unit_type("C") != RailMovement.UNIT_LOCOMOTIVE, "wagon-only consist does not promote C to locomotive")


func _locomotive_visual_identity_survives_reordering() -> void:
	var sim := _make_front_coupled_fixture()
	var c_state := _find_state(sim.get_unit_draw_states(), "C")
	var l_state := _find_state(sim.get_unit_draw_states(), "L")

	_expect(not c_state.is_empty(), "C draw state exists when C is first")
	_expect(not l_state.is_empty(), "L draw state exists when L is internal")
	if not c_state.is_empty():
		_expect(str(c_state["type"]) == RailMovement.UNIT_TANKER, "C keeps tanker wagon rendering type when first")
	if not l_state.is_empty():
		_expect(str(l_state["type"]) == RailMovement.UNIT_LOCOMOTIVE, "L keeps locomotive rendering type when internal")
		_expect(bool(l_state.get("controlled", false)), "L draw state identifies the controlled locomotive")


func _make_front_coupled_fixture() -> RefCounted:
	var sim := _make_contact_fixture(["L", "A", "B"], ["C"], 240.0, 300.0, 8.0, 1)
	sim.step(5.0, false)
	sim.speed = 0.0
	sim.throttle = 0.0
	_expect(sim.couple_nearest(), "fixture can couple C to L front")
	return sim


func _make_contact_fixture(active: Array[String], detached: Array[String], active_front: float, detached_center: float, contact_speed: float, direction: int) -> RefCounted:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(active)
	var detached_consists: Array[Dictionary] = [
		{
			"units": _typed_units(detached),
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


func _typed_units(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	result.assign(values)
	return result


func _find_state(states: Array[Dictionary], unit_id: String) -> Dictionary:
	for state in states:
		if str(state["id"]) == unit_id:
			return state
	return {}


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


func _format_ids(ids: Array) -> String:
	var text := ""
	for id in ids:
		text += "[%s]" % id
	return text


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 2 locomotive authority acceptance passed")
		quit(0)
		return

	printerr("Sprint 2 locomotive authority acceptance failed with %d failure(s)" % _failures)
	quit(1)
