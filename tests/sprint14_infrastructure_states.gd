extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Infrastructure State Tests ---")
	_test_point_conditions()
	_test_track_conditions()
	_test_mobility_summary_infrastructure_fields()
	_test_yard_operations_sync_and_anchors()

	if _failures == 0:
		print("\nSprint 14 infrastructure state acceptance passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 infrastructure state acceptance FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _test_point_conditions() -> void:
	print("Testing point conditions...")
	var rail := RailMovement.new()
	_expect(rail.get_point_condition("P1") == RailMovement.CONDITION_OPERATIONAL, "default point condition is operational")
	_expect(rail.get_damaged_point_ids().is_empty(), "no damaged points by default")

	_expect(rail.set_point_condition("P1", RailMovement.CONDITION_DAMAGED), "set_point_condition damaged returns true")
	_expect(rail.get_point_condition("P1") == RailMovement.CONDITION_DAMAGED, "point condition is now damaged")
	_expect(rail.get_damaged_point_ids() == ["P1"], "get_damaged_point_ids returns P1")

	_expect(not rail.set_point_condition("P1", "invalid_state"), "reject invalid condition")
	_expect(rail.set_point_condition("P1", RailMovement.CONDITION_OPERATIONAL), "restore point condition to operational")
	_expect(rail.get_damaged_point_ids().is_empty(), "damaged points empty after restoration")


func _test_track_conditions() -> void:
	print("Testing track conditions...")
	var rail := RailMovement.new()
	_expect(rail.get_track_condition("main_west") == RailMovement.CONDITION_OPERATIONAL, "default track condition is operational")
	_expect(rail.get_damaged_track_ids().is_empty(), "no damaged tracks by default")

	_expect(rail.set_track_condition("main_west", RailMovement.CONDITION_DAMAGED), "set_track_condition damaged returns true")
	_expect(rail.get_track_condition("main_west") == RailMovement.CONDITION_DAMAGED, "track condition is now damaged")
	_expect(rail.get_damaged_track_ids() == ["main_west"], "get_damaged_track_ids returns main_west")

	_expect(not rail.set_track_condition("main_west", "invalid_state"), "reject invalid condition")
	_expect(rail.set_track_condition("main_west", RailMovement.CONDITION_OPERATIONAL), "restore track condition to operational")
	_expect(rail.get_damaged_track_ids().is_empty(), "damaged tracks empty after restoration")


func _test_mobility_summary_infrastructure_fields() -> void:
	print("Testing mobility summary infrastructure fields...")
	var rail := RailMovement.new()
	rail.set_point_condition("P1", RailMovement.CONDITION_DAMAGED)
	rail.set_track_condition("siding", RailMovement.CONDITION_DAMAGED)

	var summary := rail.get_mobility_summary()
	_expect(summary.has("damaged_points"), "summary has damaged_points")
	_expect(summary.has("damaged_tracks"), "summary has damaged_tracks")
	_expect((summary.get("damaged_points", []) as Array) == ["P1"], "summary damaged_points matches")
	_expect((summary.get("damaged_tracks", []) as Array) == ["siding"], "summary damaged_tracks matches")


func _test_yard_operations_sync_and_anchors() -> void:
	print("Testing yard operations sync and anchors...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)

	rail.set_point_condition("P1", RailMovement.CONDITION_DAMAGED)
	yard.sync_points_from_rail_layout()
	var p1_state: Dictionary = yard.get_point_state("P1")
	_expect(str(p1_state.get("mechanical_state", "")) == YardOperations.MECHANICAL_DAMAGED, "yard point state synced damaged")

	_expect(yard.repair_point("P1"), "yard repair_point returns true")
	_expect(rail.get_point_condition("P1") == RailMovement.CONDITION_OPERATIONAL, "rail point condition restored by yard repair")

	rail.set_track_condition("main_west", RailMovement.CONDITION_DAMAGED)
	var track_anchor := yard.get_repair_anchor("track", "main_west")
	_expect(track_anchor != Vector2.ZERO, "track repair anchor exists")

	_expect(yard.repair_track("main_west"), "yard repair_track returns true")
	_expect(rail.get_track_condition("main_west") == RailMovement.CONDITION_OPERATIONAL, "rail track condition restored by yard repair")
