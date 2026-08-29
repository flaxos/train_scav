extends SceneTree

# Sprint 13 — Aggregate Traction Tests
# Verifies that aggregate traction is the sum of operational coupled powered units,
# detached/damaged units do not contribute, and damaging the primary cab removes traction authority.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 13 Aggregate Traction Tests ---")
	_test_single_loco_baseline()
	_test_multi_loco_addition()
	_test_damaged_unit_does_not_contribute()
	_test_detached_unit_does_not_contribute()
	_test_damaged_primary_loco()
	_finish()


func _expect(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 13 aggregate traction acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 13 aggregate traction acceptance FAILED with %d failure(s)" % _failures)
		quit(1)


func _test_single_loco_baseline() -> void:
	print("Testing single loco baseline traction...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"

	_expect(rail.has_traction_authority(), "single operational L has traction authority")
	_expect(is_equal_approx(rail.get_available_traction(), 1.0), "single L provides exactly 1.0 traction")

	var summary := rail.get_mobility_summary()
	_expect(bool(summary.get("has_traction", false)) == true, "summary has_traction is true")
	_expect(is_equal_approx(float(summary.get("traction", 0.0)), 1.0), "summary traction is 1.0")


func _test_multi_loco_addition() -> void:
	print("Testing multi-loco aggregate traction addition...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	_expect(rail.has_traction_authority(), "train with L and S has traction authority")
	_expect(is_equal_approx(rail.get_available_traction(), 2.0), "coupled operational L and S provide 2.0 traction")

	var summary := rail.get_mobility_summary()
	_expect(is_equal_approx(float(summary.get("traction", 0.0)), 2.0), "summary traction reports 2.0")
	_expect(int(summary.get("operational_loco_count", 0)) == 2, "operational loco count is 2")


func _test_damaged_unit_does_not_contribute() -> void:
	print("Testing damaged powered unit does not contribute traction...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_DAMAGED)

	_expect(rail.has_traction_authority(), "train still has traction authority through operational L")
	_expect(is_equal_approx(rail.get_available_traction(), 1.0), "damaged S does not contribute traction; total is 1.0")

	var operational_ids := rail.get_operational_powered_unit_ids()
	_expect(operational_ids.has("L") and not operational_ids.has("S"), "only L is in operational powered units")


func _test_detached_unit_does_not_contribute() -> void:
	print("Testing detached powered unit does not contribute...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"

	# S is detached on a siding
	var detached: Array[Dictionary] = [
		{
			"units": ["S"],
			"segment": RailMovement.SEGMENT_SIDING_B,
			"distance": 200.0,
		}
	]
	rail.detached_consists = detached
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	_expect(is_equal_approx(rail.get_available_traction(), 1.0), "detached S does not contribute to active train traction")


func _test_damaged_primary_loco() -> void:
	print("Testing damaged primary locomotive removes traction authority until switched...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("L", RailMovement.CONDITION_DAMAGED)
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	_expect(not rail.has_traction_authority(), "train loses traction authority when controlled L is damaged")
	_expect(is_equal_approx(rail.get_available_traction(), 0.0), "available traction is 0.0 when traction authority is lost")

	# Switch control to operational S
	_expect(rail.select_powered_control("S"), "Can transfer control to operational S")
	_expect(rail.has_traction_authority(), "train regains traction authority under S")
	_expect(is_equal_approx(rail.get_available_traction(), 1.0), "available traction is 1.0 (from S alone, since L is damaged)")
