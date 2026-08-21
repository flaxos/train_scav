extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var sim = RailMovement.new()

	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_WEST, "locomotive starts on the main line")
	sim.set_points_route(RailMovement.POINTS_SIDING)
	_expect(sim.points_route == RailMovement.POINTS_SIDING, "points can be changed to the siding")

	sim.set_throttle(1.0)
	_step_until_segment(sim, RailMovement.SEGMENT_SIDING, 12.0)
	_expect(sim.current_segment == RailMovement.SEGMENT_SIDING, "locomotive can drive from main line into siding")

	sim.set_throttle(0.0)
	_brake_until_stopped(sim, 4.0)
	_expect(sim.is_stopped(), "locomotive can stop under braking")

	_expect(sim.set_direction(-1), "locomotive can reverse when stopped")

	# A trailing move out of the siding must have P1 aligned with the siding leg.
	# Setting P1 to MAIN while the locomotive is still on the siding must block
	# the reverse move rather than teleporting the locomotive onto another route.
	sim.set_points_route(RailMovement.POINTS_MAIN)
	_expect(sim.points_route == RailMovement.POINTS_MAIN, "points can be changed away from the occupied siding route")
	sim.set_throttle(1.0)
	_step_for_seconds(sim, 12.0)
	_expect(sim.current_segment == RailMovement.SEGMENT_SIDING, "misaligned points block the locomotive on the siding")
	_expect(sim.blocked_reason.contains("P1"), "misaligned siding exit reports the P1 route block")

	# Align P1 with the siding path, then the locomotive may trail through P1
	# onto the common main-west leg.
	sim.set_points_route(RailMovement.POINTS_SIDING)
	_expect(sim.points_route == RailMovement.POINTS_SIDING, "points can be aligned with the siding before returning")
	sim.set_throttle(1.0)
	_step_until_segment(sim, RailMovement.SEGMENT_MAIN_WEST, 12.0)
	_expect(sim.current_segment == RailMovement.SEGMENT_MAIN_WEST, "locomotive can return from siding to main line")

	# Once clear of the turnout, P1 can be restored for the straight main route.
	sim.set_throttle(0.0)
	_brake_until_stopped(sim, 4.0)
	sim.set_points_route(RailMovement.POINTS_MAIN)
	_expect(sim.points_route == RailMovement.POINTS_MAIN, "points can be restored to the main route after the locomotive clears the turnout")

	_expect(_debug_has_required_state(sim), "debug state reports track, speed, direction, throttle and points")

	if _failures == 0:
		print("Sprint 1 acceptance simulation passed")
		quit(0)
		return

	printerr("Sprint 1 acceptance simulation failed with %d failure(s)" % _failures)
	quit(1)


func _step_until_segment(sim: RefCounted, segment: String, max_seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < max_seconds and sim.current_segment != segment:
		sim.step(0.1, false)
		elapsed += 0.1


func _step_for_seconds(sim: RefCounted, seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		sim.step(0.1, false)
		elapsed += 0.1


func _brake_until_stopped(sim: RefCounted, max_seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < max_seconds and not sim.is_stopped():
		sim.step(0.1, true)
		elapsed += 0.1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _debug_has_required_state(sim: RefCounted) -> bool:
	var debug_text := "\n".join(sim.get_debug_lines())
	return debug_text.contains("Track:") \
		and debug_text.contains("Speed:") \
		and debug_text.contains("Direction:") \
		and debug_text.contains("Throttle:") \
		and debug_text.contains("Brake:") \
		and debug_text.contains("Points:")
