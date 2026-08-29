extends SceneTree

# Sprint 13 — Consist Operations Tests
# Verifies that coupling/uncoupling second powered units remains physical,
# consist order remains correct, and movement in forward/reverse works across reordered consists.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 13 Consist Operations Tests ---")
	_test_physical_coupling_and_uncoupling()
	_test_reordered_push_pull_movement()
	_finish()


func _expect(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 13 consist operations acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 13 consist operations acceptance FAILED with %d failure(s)" % _failures)
		quit(1)


func _test_physical_coupling_and_uncoupling() -> void:
	print("Testing physical coupling and uncoupling of second locomotive...")
	var rail := RailMovement.new()
	rail.detached_consists.clear()
	var units: Array[String] = ["L", "A", "B"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.current_segment = RailMovement.SEGMENT_MAIN_WEST
	rail.distance = 180.0
	rail.speed = 0.0

	# 1. Manually add S to consist to test uncoupling
	var four_units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = four_units
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	_expect(rail.has_coupled_joint("B", "S"), "joint B/S is coupled")
	_expect(is_equal_approx(rail.get_available_traction(), 2.0), "traction is 2.0 with both locos coupled")

	# 2. Uncouple joint B/S
	_expect(rail.decouple_joint("B", "S"), "successfully uncoupled joint B/S")
	_expect(rail.active_units == ["L", "A", "B"], "active units are now [L, A, B]")
	_expect(rail.get_controlled_power_unit_id() == "L", "controlled power unit remains L")
	_expect(is_equal_approx(rail.get_available_traction(), 1.0), "traction drops to 1.0 after uncoupling S")
	_expect(rail.detached_consists.size() == 1, "S is now in detached_consists")
	_expect(rail.detached_consists[0].get("units", []) == ["S"], "detached consist contains S")


func _test_reordered_push_pull_movement() -> void:
	print("Testing push/pull movement with reordered consists...")
	var rail := RailMovement.new()

	# Config: [S][A][B][L] with L controlling
	var units: Array[String] = ["S", "A", "B", "L"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	rail.current_segment = RailMovement.SEGMENT_MAIN_WEST
	rail.distance = 300.0
	rail.speed = 0.0

	_expect(is_equal_approx(rail.get_available_traction(), 2.0), "reordered consist provides 2.0 traction")

	# Step forward
	rail.set_direction(1)
	rail.set_throttle(1.0)
	rail.step(0.5, false)
	_expect(rail.speed > 0.0, "reordered multi-loco consist accelerates forward under throttle")

	# Brake to stop
	rail.step(2.0, true)
	_expect(is_equal_approx(rail.speed, 0.0), "train stops with brake")

	# Step reverse
	rail.set_direction(-1)
	rail.set_throttle(1.0)
	rail.step(0.5, false)
	_expect(rail.speed > 0.0, "reordered multi-loco consist accelerates in reverse")
