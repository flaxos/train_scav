extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	_require_orientation_api()
	_straight_main_line_has_straight_unit_angles()
	_diverging_siding_has_nonzero_local_tangent()
	_consist_spanning_switch_uses_per_unit_angles()
	_reverse_direction_does_not_flip_physical_unit_orientation()
	_reverse_p1_misaligned_route_blocks_without_teleport()
	_reverse_p1_aligned_route_crosses_continuously()
	_reverse_p2_misaligned_route_blocks_without_teleport()
	_reverse_p2_aligned_route_crosses_continuously()
	_visual_orientation_queries_do_not_change_contact_results()

	_finish()


func _require_orientation_api() -> void:
	var sim = RailMovement.new()
	_expect(sim.has_method("get_position_at_distance"), "rail model exposes position sampling by segment and distance")
	_expect(sim.has_method("get_tangent_at_distance"), "rail model exposes tangent sampling by segment and distance")


func _straight_main_line_has_straight_unit_angles() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["L", "A", "B"])
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = 336.0

	for state in sim.get_unit_draw_states():
		if not bool(state["active"]):
			continue
		_expect(is_equal_approx(float(state["angle"]), 0.0), "straight main-line vehicle angle is horizontal")


func _diverging_siding_has_nonzero_local_tangent() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["L"])
	sim.current_segment = RailMovement.SEGMENT_SIDING
	sim.distance = 220.0

	var state := _find_state(sim.get_unit_draw_states(), "L")
	_expect(not state.is_empty(), "locomotive draw state exists on siding")
	if not state.is_empty():
		_expect(absf(float(state["angle"])) > 0.05, "siding vehicle angle follows the diverging rail tangent")


func _consist_spanning_switch_uses_per_unit_angles() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["L", "A", "B", "C"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_SIDING
	sim.distance = 130.0

	var active_states := _active_states(sim.get_unit_draw_states())
	_expect(active_states.size() == 4, "spanning consist has four active draw states")
	_expect(_count_distinct_angles(active_states) >= 2, "spanning consist has different local rotations for different vehicles")
	_expect(_state_segments(active_states).has(RailMovement.SEGMENT_MAIN_WEST), "trailing vehicles can still render on the main-side switch approach")
	_expect(_state_segments(active_states).has(RailMovement.SEGMENT_SIDING), "leading vehicles render on the diverging siding")


func _reverse_direction_does_not_flip_physical_unit_orientation() -> void:
	var forward = RailMovement.new()
	forward.active_units = _typed_units(["L", "A"])
	forward.current_segment = RailMovement.SEGMENT_SIDING
	forward.distance = 220.0
	forward.direction = 1

	var reverse = RailMovement.new()
	reverse.active_units = _typed_units(["L", "A"])
	reverse.current_segment = RailMovement.SEGMENT_SIDING
	reverse.distance = 220.0
	reverse.direction = -1

	var forward_l := _find_state(forward.get_unit_draw_states(), "L")
	var reverse_l := _find_state(reverse.get_unit_draw_states(), "L")
	_expect(not forward_l.is_empty() and not reverse_l.is_empty(), "locomotive draw states exist for forward and reverse")
	if not forward_l.is_empty() and not reverse_l.is_empty():
		_expect(is_equal_approx(float(forward_l["angle"]), float(reverse_l["angle"])), "reverse travel preserves physical orientation from track tangent")


func _reverse_p1_misaligned_route_blocks_without_teleport() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["L", "A", "B"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_EAST
	# Three-unit consist length is 192. Rear coupler starts 45 units clear of P1,
	# just outside the 44-unit route-stop clearance.
	sim.distance = 237.0
	sim.direction = -1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0
	sim.set_points_route(RailMovement.POINTS_SIDING)

	var before_states := _active_states(sim.get_unit_draw_states())
	sim.step(0.25, false)

	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_EAST, "misaligned P1 keeps the consist on main-east")
	_expect(float(sim.get_active_occupied_interval()["rear"]) > RailMovement.SWITCH_OCCUPANCY_CLEARANCE, "misaligned P1 stops clear of the turnout")
	_expect(not sim.is_switch_occupied(), "misaligned P1 stop leaves the points free to be changed")
	_expect(sim.speed == 0.0, "misaligned P1 stops reverse movement")
	_expect(sim.blocked_reason.contains("P1"), "misaligned P1 reports a route block")
	var after_states := _active_states(sim.get_unit_draw_states())
	_expect(not _state_segments(after_states).has(RailMovement.SEGMENT_SIDING), "misaligned P1 never teleports stock onto the selected siding")
	_expect(_max_unit_displacement(before_states, after_states) <= 12.0, "misaligned P1 stop is spatially continuous")


func _reverse_p1_aligned_route_crosses_continuously() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["L"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_EAST
	# Front coupler is just about to clear P1; the locomotive is already
	# straddling the correctly aligned turnout.
	sim.distance = 1.0
	sim.direction = -1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0
	sim.set_points_route(RailMovement.POINTS_MAIN)

	var before_states := _active_states(sim.get_unit_draw_states())
	sim.step(0.25, false)

	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_WEST, "aligned P1 reverse move enters main-west")
	var after_states := _active_states(sim.get_unit_draw_states())
	_expect(not _state_segments(after_states).has(RailMovement.SEGMENT_SIDING), "aligned P1 reverse move never jumps onto siding")
	_expect(_max_unit_displacement(before_states, after_states) <= 12.0, "aligned P1 reverse crossing is spatially continuous")


func _reverse_p2_misaligned_route_blocks_without_teleport() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["S", "W"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.controlled_power_unit_id = "S"
	sim.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	sim.current_segment = RailMovement.SEGMENT_SIDING_B
	# S + gap + W = 122. Rear coupler starts 45 units clear of P2, just
	# outside the 44-unit route-stop clearance.
	sim.distance = 167.0
	sim.direction = -1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0
	sim.set_yard_point_route("P2", RailMovement.POINTS_MAIN)

	var before_states := _active_states(sim.get_unit_draw_states())
	sim.step(0.25, false)

	_expect(sim.current_segment == RailMovement.SEGMENT_SIDING_B, "P2 straight keeps S/W on the workshop siding")
	_expect(float(sim.get_active_occupied_interval()["rear"]) > RailMovement.SWITCH_OCCUPANCY_CLEARANCE, "P2 straight stops clear of the turnout")
	_expect(not sim.is_yard_point_occupied("P2"), "blocked P2 stop leaves the points free to be changed")
	_expect(sim.speed == 0.0, "P2 straight blocks reverse exit from workshop siding")
	_expect(sim.blocked_reason.contains("P2"), "blocked workshop exit reports P2 route state")
	var after_states := _active_states(sim.get_unit_draw_states())
	_expect(_max_unit_displacement(before_states, after_states) <= 12.0, "P2 blocked reverse stop is spatially continuous")


func _reverse_p2_aligned_route_crosses_continuously() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["S"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.controlled_power_unit_id = "S"
	sim.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	sim.current_segment = RailMovement.SEGMENT_SIDING_B
	sim.distance = 1.0
	sim.direction = -1
	sim.speed = 8.0
	sim.throttle = 1.0
	sim.max_speed = 8.0
	sim.acceleration = 0.0
	sim.coast_deceleration = 0.0
	sim.set_yard_point_route("P2", RailMovement.POINTS_SIDING)

	var before_states := _active_states(sim.get_unit_draw_states())
	sim.step(0.25, false)

	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_EAST, "aligned P2 reverse move enters main-east")
	var after_states := _active_states(sim.get_unit_draw_states())
	_expect(_max_unit_displacement(before_states, after_states) <= 12.0, "aligned P2 reverse crossing is spatially continuous")


func _max_unit_displacement(before_states: Array[Dictionary], after_states: Array[Dictionary]) -> float:
	var maximum := 0.0
	for before_state in before_states:
		var unit_id := str(before_state.get("id", ""))
		var after_state := _find_state(after_states, unit_id)
		if after_state.is_empty():
			continue
		var before_position := before_state.get("position", Vector2.ZERO) as Vector2
		var after_position := after_state.get("position", Vector2.ZERO) as Vector2
		maximum = maxf(maximum, before_position.distance_to(after_position))
	return maximum


func _visual_orientation_queries_do_not_change_contact_results() -> void:
	var sim := _make_contact_fixture(["L"], ["A"], 240.0, 300.0, 8.0, 1)
	var before_interval: Dictionary = sim.get_active_occupied_interval()
	var draw_states: Array[Dictionary] = sim.get_unit_draw_states()
	_expect(draw_states.size() >= 2, "draw-state query returns active and detached vehicles")
	var after_interval: Dictionary = sim.get_active_occupied_interval()
	_expect(is_equal_approx(float(before_interval["front"]), float(after_interval["front"])), "draw-state query does not change active interval front")
	_expect(is_equal_approx(float(before_interval["rear"]), float(after_interval["rear"])), "draw-state query does not change active interval rear")

	sim.step(5.0, false)
	var contact: Dictionary = sim.get_last_contact()
	_expect(contact.get("type", "") == RailMovement.CONTACT_CONTROLLED, "contact classification remains deterministic after orientation query")
	_expect(not sim.has_any_overlap(), "orientation query does not introduce overlap")


func _active_states(states: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for state in states:
		if bool(state["active"]):
			result.append(state)
	return result


func _find_state(states: Array[Dictionary], unit_id: String) -> Dictionary:
	for state in states:
		if str(state["id"]) == unit_id:
			return state
	return {}


func _count_distinct_angles(states: Array[Dictionary]) -> int:
	var angles: Array[float] = []
	for state in states:
		var angle := snappedf(float(state["angle"]), 0.001)
		if not angles.has(angle):
			angles.append(angle)
	return angles.size()


func _state_segments(states: Array[Dictionary]) -> Array[String]:
	var segments: Array[String] = []
	for state in states:
		var segment_id := str(state["segment"])
		if not segments.has(segment_id):
			segments.append(segment_id)
	return segments


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 2 orientation acceptance passed")
		quit(0)
		return

	printerr("Sprint 2 orientation acceptance failed with %d failure(s)" % _failures)
	quit(1)
