extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YARD_SCRIPT_PATH := "res://scripts/yard/yard_operations.gd"

var _failures: int = 0


func _init() -> void:
	if not ResourceLoader.exists(YARD_SCRIPT_PATH):
		_failures += 1
		printerr("FAIL: missing Sprint 4 yard operations script")
		_finish()
		return

	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	if yard == null:
		_finish()
		return
	if _require_yard_methods(yard):
		_point_mechanics_are_independent_from_remote_control()
		_yard_control_requires_repair_and_power()
		_power_connection_does_not_mutate_point_route()
		_occupied_points_reject_manual_and_remote_operation()

	_finish()


func _require_yard_methods(yard: RefCounted) -> bool:
	var methods: Array[String] = [
		"get_point_state",
		"get_point_anchor",
		"manual_operate_point",
		"remote_operate_point",
		"repair_point",
		"repair_yard_control",
		"connect_power",
		"disconnect_power",
		"is_remote_control_available",
		"get_yard_control_state",
		"get_shunter_state",
		"repair_shunter",
	]
	var all_present := true
	for method_name in methods:
		if yard.has_method(method_name):
			continue

		_failures += 1
		all_present = false
		printerr("FAIL: missing yard method %s" % method_name)
	return all_present


func _point_mechanics_are_independent_from_remote_control() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var p1_before: String = rail.points_route
	_expect(not yard.is_remote_control_available(), "yard control starts without remote authority")
	_expect(yard.manual_operate_point("P1"), "mechanically operational point can be operated manually while remote control is offline")
	_expect(rail.points_route != p1_before, "manual P1 operation uses the authoritative rail route")

	var p2: Dictionary = yard.get_point_state("P2")
	_expect(not p2.is_empty(), "Sprint 4 yard exposes a second point")
	_expect(str(p2.get("mechanical_state", "")) == "operational", "P2 starts mechanically operational for the workshop siding route")

	var p3: Dictionary = yard.get_point_state("P3")
	_expect(not p3.is_empty(), "Sprint 4 yard exposes a third point")
	_expect(str(p3.get("mechanical_state", "")) == "damaged", "P3 starts mechanically damaged for repair coverage")
	var p3_route := str(p3.get("route", ""))
	_expect(not yard.manual_operate_point("P3"), "damaged point cannot be thrown manually")
	_expect(str(yard.get_point_state("P3").get("route", "")) == p3_route, "damaged point leaves route unchanged")
	_expect(yard.repair_point("P3"), "repair task can restore damaged point mechanics")
	_expect(str(yard.get_point_state("P3").get("mechanical_state", "")) == "operational", "repaired point becomes mechanically operational")
	_expect(yard.manual_operate_point("P3"), "repaired point can be manually operated")


func _yard_control_requires_repair_and_power() -> void:
	var powered_only = _make_yard(RailMovement.new())
	_expect(powered_only.connect_power(), "power can be connected before repair")
	_expect(not powered_only.is_remote_control_available(), "powered but unrepaired yard control has no remote authority")

	var repaired_only = _make_yard(RailMovement.new())
	_expect(repaired_only.repair_yard_control(), "yard control can be repaired")
	_expect(not repaired_only.is_remote_control_available(), "repaired but unpowered yard control has no remote authority")

	var restored = _make_yard(RailMovement.new())
	_expect(restored.repair_yard_control(), "yard control repair succeeds")
	_expect(restored.connect_power(), "train auxiliary power connection succeeds")
	_expect(not restored.is_remote_control_available(), "repaired and powered yard control still does not grant remote switch authority in this UAT")
	var p2_before: String = RailMovement.POINTS_MAIN
	_expect(not restored.remote_operate_point("P2"), "remote point operation is rejected even after repair and power")
	_expect(restored.get_point_state("P2").get("route", "") == p2_before, "rejected remote operation leaves P2 route unchanged")
	_expect(restored.disconnect_power(), "yard power can be disconnected")
	_expect(not restored.is_remote_control_available(), "power loss disables remote authority without damaging mechanics")


func _power_connection_does_not_mutate_point_route() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var before: String = rail.points_route
	_expect(yard.connect_power(), "valid power connection supplies abstract yard power")
	_expect(rail.points_route == before, "connecting power does not directly mutate physical point route")
	_expect(yard.disconnect_power(), "power disconnection succeeds")
	_expect(rail.points_route == before, "disconnecting power does not directly mutate physical point route")


func _occupied_points_reject_manual_and_remote_operation() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	rail.current_segment = RailMovement.SEGMENT_MAIN_WEST
	rail.distance = rail.get_segment_length(RailMovement.SEGMENT_MAIN_WEST)
	rail.speed = 0.0
	var before: String = rail.points_route

	_expect(rail.is_switch_occupied(), "fixture places rolling stock in the switch zone")
	_expect(not yard.manual_operate_point("P1"), "occupied point rejects manual crew operation")
	_expect(rail.points_route == before, "occupied manual rejection leaves route unchanged")

	_expect(yard.repair_yard_control(), "remote rejection fixture repairs yard control")
	_expect(yard.connect_power(), "remote rejection fixture powers yard control")
	_expect(not yard.remote_operate_point("P1"), "occupied point rejects remote operation")
	_expect(rail.points_route == before, "occupied remote rejection leaves route unchanged")


func _make_yard(rail: RefCounted) -> RefCounted:
	var script = load(YARD_SCRIPT_PATH)
	if script == null:
		_failures += 1
		printerr("FAIL: cannot load Sprint 4 yard operations script")
		return null
	return script.new(rail)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 yard infrastructure acceptance passed")
		quit(0)
		return

	printerr("Sprint 4 yard infrastructure acceptance failed with %d failure(s)" % _failures)
	quit(1)
