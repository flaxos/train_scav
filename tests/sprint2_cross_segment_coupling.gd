extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	_front_contact_can_couple_across_aligned_turnout()
	_rear_contact_can_couple_across_aligned_turnout()
	_finish()


func _front_contact_can_couple_across_aligned_turnout() -> void:
	var sim = RailMovement.new()
	var west_length := sim.get_segment_length(RailMovement.SEGMENT_MAIN_WEST)

	# C is being pushed by repaired shunter S towards B. C's front coupler
	# reaches B's rear coupler exactly across P1: active consist remains on the
	# common leg while B is already on the selected main-east branch.
	var active: Array[String] = ["C", "S"]
	var target_units: Array[String] = ["B"]
	var detached: Array[Dictionary] = [
		{
			"units": target_units,
			"segment": RailMovement.SEGMENT_MAIN_EAST,
			"distance": sim.get_unit_length("B") * 0.5,
		},
	]
	sim.active_units = active
	sim.detached_consists = detached
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = west_length - 20.0
	sim.points_route = RailMovement.POINTS_MAIN
	sim.controlled_power_unit_id = "S"
	sim.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	sim.direction = 1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0

	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(contact.get("type", "") == RailMovement.CONTACT_CONTROLLED, "front cross-segment contact is controlled")
	_expect(contact.get("active_unit", "") == "C", "front cross-segment contact records C")
	_expect(contact.get("detached_unit", "") == "B", "front cross-segment contact records B")
	_expect(sim.can_couple_unit("B"), "C can couple to B when exposed couplers meet across aligned P1")
	_expect(not sim.get_last_contact_anchor().is_empty(), "crew coupling anchor exists for cross-segment C/B contact")
	_expect(sim.couple_nearest(), "cross-segment C/B contact couples successfully")
	_expect_units(sim, ["B", "C", "S"], "front cross-segment coupling produces [B][C][S]")
	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_EAST, "new consist front transfers to B's main-east segment")


func _rear_contact_can_couple_across_aligned_turnout() -> void:
	var sim = RailMovement.new()
	var west_length := sim.get_segment_length(RailMovement.SEGMENT_MAIN_WEST)

	# L reverses from main east. Its rear coupler reaches C's front coupler
	# across P1 while the active reference/front remains on main east.
	var active: Array[String] = ["L"]
	var target_units: Array[String] = ["C"]
	var detached: Array[Dictionary] = [
		{
			"units": target_units,
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": west_length - sim.get_unit_length("C") * 0.5,
		},
	]
	sim.active_units = active
	sim.detached_consists = detached
	sim.current_segment = RailMovement.SEGMENT_MAIN_EAST
	sim.distance = sim.get_unit_length("L") + 20.0
	sim.points_route = RailMovement.POINTS_MAIN
	sim.controlled_power_unit_id = "L"
	sim.direction = -1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0

	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(contact.get("type", "") == RailMovement.CONTACT_CONTROLLED, "rear cross-segment contact is controlled")
	_expect(contact.get("active_unit", "") == "L", "rear cross-segment contact records L")
	_expect(contact.get("detached_unit", "") == "C", "rear cross-segment contact records C")
	_expect(sim.can_couple_unit("C"), "L can couple to C when exposed couplers meet across aligned P1")
	_expect(not sim.get_last_contact_anchor().is_empty(), "crew coupling anchor exists for reverse cross-segment contact")
	_expect(sim.couple_nearest(), "reverse cross-segment contact couples successfully")
	_expect_units(sim, ["L", "C"], "rear cross-segment coupling produces [L][C]")
	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_EAST, "rear coupling preserves active front segment")


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


func _format_ids(ids: Array) -> String:
	var text := ""
	for id in ids:
		text += "[%s]" % id
	return text


func _finish() -> void:
	if _failures == 0:
		print("Sprint 2 cross-segment coupling acceptance passed")
		quit(0)
		return

	printerr("Sprint 2 cross-segment coupling acceptance failed with %d failure(s)" % _failures)
	quit(1)
