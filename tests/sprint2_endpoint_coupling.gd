extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	_rear_endpoint_coupling_appends_to_contacted_end()
	_front_endpoint_coupling_prepends_to_contacted_end()
	_visual_proximity_on_different_branches_is_not_contact()
	_internal_couplers_are_not_coupling_targets()
	_high_speed_endpoint_contact_rejects_coupling()

	_finish()


func _rear_endpoint_coupling_appends_to_contacted_end() -> void:
	var sim := _make_contact_fixture(["L", "A", "B"], ["C"], 420.0, 200.0, 8.0, -1)
	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(contact.get("type", "") == RailMovement.CONTACT_CONTROLLED, "rear contact is controlled at low speed")
	_expect(contact.get("active_unit", "") == "B", "rear contact records B as the active exposed unit")
	_expect(contact.get("active_end", "") == "rear", "rear contact records active rear coupler")
	_expect(contact.get("detached_unit", "") == "C", "rear contact records C as the target unit")
	_expect(contact.get("detached_end", "") == "front", "rear contact records C front coupler")
	_expect(sim.can_couple_unit("C"), "rear endpoint contact is a valid coupling candidate")
	_expect(sim.couple_nearest(), "rear endpoint contact can be coupled")
	_expect_units(sim, ["L", "A", "B", "C"], "rear endpoint coupling produces [L][A][B][C]")


func _front_endpoint_coupling_prepends_to_contacted_end() -> void:
	var sim := _make_contact_fixture(["L", "A", "B"], ["C"], 240.0, 300.0, 8.0, 1)
	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(contact.get("type", "") == RailMovement.CONTACT_CONTROLLED, "front contact is controlled at low speed")
	_expect(contact.get("active_unit", "") == "L", "front contact records L as the active exposed unit")
	_expect(contact.get("active_end", "") == "front", "front contact records active front coupler")
	_expect(contact.get("detached_unit", "") == "C", "front contact records C as the target unit")
	_expect(contact.get("detached_end", "") == "rear", "front contact records C rear coupler")
	_expect(sim.can_couple_unit("C"), "front endpoint contact is a valid coupling candidate")
	_expect(sim.couple_nearest(), "front endpoint contact can be coupled")
	_expect_units(sim, ["C", "L", "A", "B"], "front endpoint coupling produces [C][L][A][B]")


func _visual_proximity_on_different_branches_is_not_contact() -> void:
	var sim = RailMovement.new()
	var active: Array[String] = ["L"]
	var detached_consists: Array[Dictionary] = [
		{
			"units": ["C"],
			"segment": RailMovement.SEGMENT_SIDING,
			"distance": sim.get_unit_length("C") * 0.5,
		},
	]
	sim.active_units = active
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = sim.get_segment_length(RailMovement.SEGMENT_MAIN_WEST)
	sim.direction = 1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0

	sim.step(1.0, false)

	_expect(sim.get_last_contact().is_empty(), "visually close rolling stock on different branches does not create contact")
	_expect(not sim.can_couple_unit("C"), "visually close rolling stock on different branches is not a coupling candidate")
	_expect(not sim.couple_nearest(), "branch proximity cannot be coupled")
	_expect(sim.blocked_reason.contains("No compatible couplers"), "branch proximity reports no compatible couplers in contact")
	_expect_units(sim, ["L"], "invalid branch proximity leaves active consist unchanged")


func _internal_couplers_are_not_coupling_targets() -> void:
	var sim = RailMovement.new()
	var active: Array[String] = ["L", "A", "B"]
	var detached_consists: Array[Dictionary] = [
		{
			"units": ["C"],
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": 264.0,
		},
	]
	sim.active_units = active
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = 420.0
	sim.speed = 0.0
	sim.throttle = 0.0

	_expect(not sim.can_couple_unit("C"), "wagon near an internal coupler is not a valid coupling candidate")
	_expect(not sim.couple_nearest(), "coupling command rejects occupied/internal coupler proximity")
	_expect(sim.blocked_reason.contains("No compatible couplers"), "internal-coupler rejection reports no compatible couplers in contact")
	_expect_units(sim, ["L", "A", "B"], "internal-coupler rejection leaves active consist unchanged")


func _high_speed_endpoint_contact_rejects_coupling() -> void:
	var sim := _make_contact_fixture(["L", "A", "B"], ["C"], 240.0, 300.0, 40.0, 1)
	sim.step(5.0, false)

	var contact: Dictionary = sim.get_last_contact()
	_expect(not sim.has_any_overlap(), "high-speed endpoint contact still prevents overlap")
	_expect(contact.get("type", "") == RailMovement.CONTACT_IMPACT, "high-speed endpoint contact records impact")
	_expect(contact.get("active_end", "") == "front", "impact records active endpoint")
	_expect(contact.get("detached_end", "") == "rear", "impact records detached endpoint")
	_expect(not bool(contact.get("coupling_permitted", true)), "impact endpoint contact rejects coupling")
	_expect(not sim.can_couple_unit("C"), "impact is not a valid coupling candidate")
	_expect(not sim.couple_nearest(), "impact cannot be coupled by pressing C")
	_expect(sim.blocked_reason.contains("Impact contact"), "impact coupling rejection reports impact contact")
	_expect_units(sim, ["L", "A", "B"], "impact leaves active consist order unchanged")


func _make_contact_fixture(active: Array[String], detached: Array[String], active_front: float, detached_center: float, contact_speed: float, direction: int) -> RefCounted:
	var sim = RailMovement.new()
	var active_copy: Array[String] = []
	active_copy.assign(active)
	var detached_copy: Array[String] = []
	detached_copy.assign(detached)
	var detached_consists: Array[Dictionary] = [
		{
			"units": detached_copy,
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": detached_center,
		},
	]
	sim.active_units = active_copy
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
		print("Sprint 2 endpoint coupling acceptance passed")
		quit(0)
		return

	printerr("Sprint 2 endpoint coupling acceptance failed with %d failure(s)" % _failures)
	quit(1)
