extends SceneTree

# Sprint 12 — Train Mobility Summary Tests.
# Verifies that RailMovement deterministically exposes mass, length,
# traction authority, unit count, and capability tags for any consist.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 12 Mobility Summary Tests ---")
	test_single_locomotive_mobility()
	test_starter_consist_mobility()
	test_dynamic_shunting_mobility_updates()
	test_unpowered_consist_mobility()
	_finish()


func test_single_locomotive_mobility() -> void:
	print("Testing single locomotive mobility...")
	var rail := RailMovement.new()
	rail.active_units = ["L"]
	rail.controlled_power_unit_id = "L"

	var summary: Dictionary = rail.get_mobility_summary()
	_expect(is_equal_approx(float(summary.get("total_mass", 0.0)), 90.0), "single loco mass is 90.0t")
	_expect(is_equal_approx(float(summary.get("total_length", 0.0)), 64.0), "single loco length is 64.0px")
	_expect(int(summary.get("unit_count", 0)) == 1, "unit count is 1")
	_expect(bool(summary.get("has_traction", false)) == true, "loco has traction authority")
	_expect(str(summary.get("powered_unit_id", "")) == "L", "powered unit id is L")

	var caps: Array = summary.get("capabilities", []) as Array
	_expect(caps.has("traction"), "loco has traction capability")
	_expect(caps.has("control_cab"), "loco has control_cab capability")
	_expect(caps.has("diesel_storage"), "loco has diesel_storage capability")


func test_starter_consist_mobility() -> void:
	print("Testing starter consist [L, A, B] mobility...")
	var rail := RailMovement.new()
	# Starter consist: L (90t, 64px), A (35t, 56px), B (42t, 56px)
	# Expected mass: 90 + 35 + 42 = 167.0
	# Expected length: 64 + 8 (coupler) + 56 + 8 (coupler) + 56 = 192.0
	rail.active_units = ["L", "A", "B"]
	rail.controlled_power_unit_id = "L"

	var summary: Dictionary = rail.get_mobility_summary()
	_expect(is_equal_approx(float(summary.get("total_mass", 0.0)), 167.0), "starter consist mass is 167.0t")
	_expect(is_equal_approx(float(summary.get("total_length", 0.0)), 192.0), "starter consist length is 192.0px")
	_expect(int(summary.get("unit_count", 0)) == 3, "unit count is 3")
	_expect(bool(summary.get("has_traction", false)) == true, "starter consist has traction")

	var caps: Array = summary.get("capabilities", []) as Array
	_expect(caps.has("traction"), "has traction from L")
	_expect(caps.has("crew_accommodation"), "has crew_accommodation from A")
	_expect(caps.has("resource_storage"), "has resource_storage from B")
	_expect(caps.has("storage_food"), "has storage_food from B")
	_expect(caps.has("storage_parts"), "has storage_parts from B")
	_expect(not caps.has("workshop"), "starter consist does not have workshop capability")


func test_dynamic_shunting_mobility_updates() -> void:
	print("Testing mobility updates across coupling and uncoupling...")
	var rail := RailMovement.new()
	rail.active_units = ["L", "A", "B"]
	rail.controlled_power_unit_id = "L"

	# Couple workshop W (48t, 60px)
	rail.active_units.append("W")
	var summary_with_w: Dictionary = rail.get_mobility_summary()
	# Mass: 167 + 48 = 215.0
	# Length: 192 + 8 + 60 = 260.0
	_expect(is_equal_approx(float(summary_with_w.get("total_mass", 0.0)), 215.0), "consist mass with W is 215.0t")
	_expect(is_equal_approx(float(summary_with_w.get("total_length", 0.0)), 260.0), "consist length with W is 260.0px")
	_expect(int(summary_with_w.get("unit_count", 0)) == 4, "unit count with W is 4")
	var caps_with_w: Array = summary_with_w.get("capabilities", []) as Array
	_expect(caps_with_w.has("workshop"), "consist now has workshop capability")

	# Couple tanker C (50t, 52px)
	rail.active_units.append("C")
	var summary_with_c: Dictionary = rail.get_mobility_summary()
	# Mass: 215 + 50 = 265.0
	# Length: 260 + 8 + 52 = 320.0
	_expect(is_equal_approx(float(summary_with_c.get("total_mass", 0.0)), 265.0), "consist mass with C is 265.0t")
	_expect(is_equal_approx(float(summary_with_c.get("total_length", 0.0)), 320.0), "consist length with C is 320.0px")
	_expect(int(summary_with_c.get("unit_count", 0)) == 5, "unit count with C is 5")

	# Uncouple rear two wagons
	rail.active_units.remove_at(4) # remove C
	rail.active_units.remove_at(3) # remove W
	var restored_summary: Dictionary = rail.get_mobility_summary()
	_expect(is_equal_approx(float(restored_summary.get("total_mass", 0.0)), 167.0), "consist mass restored to 167.0t")
	_expect(is_equal_approx(float(restored_summary.get("total_length", 0.0)), 192.0), "consist length restored to 192.0px")
	_expect(int(restored_summary.get("unit_count", 0)) == 3, "unit count restored to 3")
	var restored_caps: Array = restored_summary.get("capabilities", []) as Array
	_expect(not restored_caps.has("workshop"), "workshop capability removed after uncoupling W")


func test_unpowered_consist_mobility() -> void:
	print("Testing unpowered consist mobility...")
	var rail := RailMovement.new()
	rail.active_units = ["A", "B"]
	rail.controlled_power_unit_id = ""

	var summary: Dictionary = rail.get_mobility_summary()
	_expect(bool(summary.get("has_traction", false)) == false, "wagon-only consist has no traction authority")
	_expect(is_equal_approx(float(summary.get("total_mass", 0.0)), 77.0), "unpowered consist mass is 77.0t")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12 mobility summary acceptance passed")
		quit(0)
	else:
		print("\nSprint 12 mobility summary acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
