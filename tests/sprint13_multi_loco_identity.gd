extends SceneTree

# Sprint 13 — Multiple Powered Unit Identities & Control Authority Tests
# Verifies that multiple locomotives retain distinct identities, independent of consist position,
# and control authority remains explicit.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 13 Multi-Loco Identity Tests ---")
	_test_distinct_powered_identities()
	_test_consist_position_independence()
	_test_wagon_never_inherits_locomotive_authority()
	_test_explicit_control_selection()
	_finish()


func _expect(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 13 multi-loco identity acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 13 multi-loco identity acceptance FAILED with %d failure(s)" % _failures)
		quit(1)


func _test_distinct_powered_identities() -> void:
	print("Testing distinct powered identities in one consist...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	_expect(rail.is_powered_unit("L"), "L is recognised as a powered unit")
	_expect(rail.is_powered_unit("S"), "S is recognised as a powered unit")
	_expect(not rail.is_powered_unit("A"), "A is not a powered unit")
	_expect(not rail.is_powered_unit("B"), "B is not a powered unit")

	_expect(rail.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "L has locomotive physical type")
	_expect(rail.get_unit_type("S") == RailMovement.UNIT_SHUNTER, "S has shunter physical type")

	_expect(rail.get_controlled_power_unit_id() == "L", "L is the explicit controlled power unit")

	var operational_ids := rail.get_operational_powered_unit_ids()
	_expect(operational_ids.has("L"), "operational powered units includes L")
	_expect(operational_ids.has("S"), "operational powered units includes S")
	_expect(operational_ids.size() == 2, "exactly two operational powered units exist in consist")


func _test_consist_position_independence() -> void:
	print("Testing consist position independence...")
	var rail := RailMovement.new()

	# Config 1: [L][A][B][S]
	var conf1: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = conf1
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	_expect(rail.get_controlled_power_unit_id() == "L", "Config 1 has L as control authority")
	_expect(rail.get_operational_powered_unit_ids().size() == 2, "Config 1 has 2 operational locos")

	# Config 2: [S][A][B][L] (reordered: S at front, L at rear, but L remains control authority!)
	var conf2: Array[String] = ["S", "A", "B", "L"]
	rail.active_units = conf2
	rail.controlled_power_unit_id = "L"
	_expect(rail.get_controlled_power_unit_id() == "L", "Config 2 maintains L as control authority even at index 3")
	_expect(rail.get_unit_type("S") == RailMovement.UNIT_SHUNTER, "S at index 0 remains shunter")
	_expect(rail.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "L at index 3 remains locomotive")

	# Config 3: [A][L][B][S] (wagon A at front!)
	var conf3: Array[String] = ["A", "L", "B", "S"]
	rail.active_units = conf3
	rail.controlled_power_unit_id = "L"
	_expect(rail.get_controlled_power_unit_id() == "L", "Config 3 maintains L as control authority when wagon A is at front")
	_expect(not rail.is_powered_unit("A"), "Wagon A at index 0 is not powered")
	_expect(rail.has_traction_authority(), "Train has traction authority through L")


func _test_wagon_never_inherits_locomotive_authority() -> void:
	print("Testing wagon never inherits locomotive authority...")
	var rail := RailMovement.new()
	var units: Array[String] = ["W", "A", "B"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L" # L is not in active units

	_expect(not rail.has_traction_authority(), "Wagon-only consist has no traction authority")
	_expect(not rail.select_powered_control("W"), "Cannot select wagon W for control")
	_expect(not rail.select_powered_control("A"), "Cannot select wagon A for control")
	_expect(rail.get_operational_powered_unit_ids().is_empty(), "No operational powered units in wagon consist")


func _test_explicit_control_selection() -> void:
	print("Testing explicit control selection between coupled locomotives...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	_expect(rail.select_powered_control("S"), "Can explicitly transfer control to S")
	_expect(rail.get_controlled_power_unit_id() == "S", "Control authority is now S")
	_expect(rail.active_units == units, "Consist order is unchanged by control transfer")

	_expect(rail.select_powered_control("L"), "Can explicitly transfer control back to L")
	_expect(rail.get_controlled_power_unit_id() == "L", "Control authority is back to L")
