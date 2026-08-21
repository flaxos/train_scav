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

	_manual_main_locomotive_path_recovers_salvage()
	_repaired_shunter_path_recovers_same_salvage()
	_repaired_yard_control_does_not_script_a_remote_recovery()
	_p2_route_gates_shunter_between_workshop_siding_and_main()

	_finish()


func _manual_main_locomotive_path_recovers_salvage() -> void:
	var fixture := _make_strategy_fixture()
	var rail: RefCounted = fixture["rail"]
	var yard: RefCounted = fixture["yard"]

	_expect(not yard.is_remote_control_available(), "manual path starts with yard control offline")
	_expect(str(yard.get_shunter_state().get("condition", "")) == RailMovement.CONDITION_DAMAGED, "manual path ignores damaged shunter")
	_expect(yard.manual_operate_point("P1"), "manual path changes P1 through local operation")
	_expect(yard.manual_operate_point("P2"), "manual path changes P2 through local operation")
	_expect(rail.points_route == RailMovement.POINTS_MAIN, "manual path sets route toward salvage using physical point state")
	_expect(rail.get_yard_point_route("P2") == RailMovement.POINTS_SIDING, "manual path routes P2 into the workshop siding")
	_drive_until_can_couple(rail, "W", 120.0)
	_expect(rail.can_couple_unit("W"), "main locomotive physically reaches the salvage wagon")
	_expect(rail.couple_nearest(), "main locomotive couples the contacted salvage wagon")
	_expect(_format_ids(rail.get_active_consist_ids()).contains("[W]"), "manual path recovers W by physical coupling")
	_expect(not yard.is_remote_control_available(), "manual path does not repair remote yard control")


func _repaired_shunter_path_recovers_same_salvage() -> void:
	var fixture := _make_strategy_fixture()
	var rail: RefCounted = fixture["rail"]
	var yard: RefCounted = fixture["yard"]
	var main_before := _find_state(rail.get_unit_draw_states(), "L")

	_expect(yard.repair_shunter(), "shunter strategy repairs local shunter")
	_expect(rail.select_powered_control("S"), "player explicitly switches control to repaired S")
	_expect(rail.get_controlled_power_unit_id() == "S", "S is the selected powered unit")
	_expect(rail.set_direction(-1), "shunter reverses toward the salvage wagon")
	_drive_until_can_couple(rail, "W", 120.0)
	_expect(rail.can_couple_unit("W"), "shunter physically reaches the same salvage wagon")
	_expect(rail.couple_nearest(), "shunter couples the contacted salvage wagon")
	_expect(_format_ids(rail.get_active_consist_ids()).contains("[S]") and _format_ids(rail.get_active_consist_ids()).contains("[W]"), "shunter path recovers W with S")
	_expect(_same_position(main_before, _find_state(rail.get_unit_draw_states(), "L")), "main locomotive remains parked while shunter path executes")
	_expect(rail.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "main locomotive identity survives shunter strategy")
	_expect(rail.get_unit_type("W") != RailMovement.UNIT_LOCOMOTIVE, "salvage wagon is not promoted to locomotive")


func _repaired_yard_control_does_not_script_a_remote_recovery() -> void:
	var fixture := _make_strategy_fixture()
	var rail: RefCounted = fixture["rail"]
	var yard: RefCounted = fixture["yard"]
	var p1_before: String = rail.points_route
	var p2_before: String = rail.get_yard_point_route("P2")

	_expect(yard.repair_yard_control(), "yard-control equipment can still be repaired as infrastructure")
	_expect(yard.connect_power(), "yard-control power can still be connected")
	_expect(not yard.is_remote_control_available(), "repaired and powered yard control does not enable remote point switching in the UAT")
	_expect(not yard.remote_operate_point("P1"), "P1 cannot be thrown remotely")
	_expect(not yard.remote_operate_point("P2"), "P2 cannot be thrown remotely")
	_expect(rail.points_route == p1_before, "rejected remote P1 command leaves route unchanged")
	_expect(rail.get_yard_point_route("P2") == p2_before, "rejected remote P2 command leaves route unchanged")


func _p2_route_gates_shunter_between_workshop_siding_and_main() -> void:
	var straight_fixture := _make_strategy_fixture()
	var straight_rail: RefCounted = straight_fixture["rail"]
	var straight_yard: RefCounted = straight_fixture["yard"]

	_expect(straight_yard.repair_shunter(), "fixture repairs shunter for P2 route gate check")
	_expect(straight_rail.select_powered_control("S"), "fixture selects S for P2 route gate check")
	_remove_detached_unit(straight_rail, "W")
	_expect(straight_rail.get_yard_point_route("P2") == RailMovement.POINTS_MAIN, "P2 starts straight for route gate check")
	_expect(straight_rail.set_direction(-1), "S reverses toward P2 while P2 is straight")
	_drive_for_seconds(straight_rail, 60.0)
	_expect(straight_rail.current_segment == RailMovement.SEGMENT_SIDING_B, "P2 straight blocks S from leaving the workshop siding through the branch")
	_expect(straight_rail.blocked_reason.contains("P2"), "blocked shunter reports P2 route state")

	var branch_fixture := _make_strategy_fixture()
	var branch_rail: RefCounted = branch_fixture["rail"]
	var branch_yard: RefCounted = branch_fixture["yard"]

	_expect(branch_yard.repair_shunter(), "fixture repairs shunter for P2 branch route check")
	_expect(branch_rail.select_powered_control("S"), "fixture selects S for P2 branch route check")
	_remove_detached_unit(branch_rail, "W")
	_expect(branch_yard.manual_operate_point("P2"), "fixture sets P2 to the workshop branch")
	_expect(branch_rail.get_yard_point_route("P2") == RailMovement.POINTS_SIDING, "P2 branch route is active")
	_expect(branch_rail.set_direction(-1), "S reverses toward P2 while branch is active")
	_drive_for_seconds(branch_rail, 60.0)
	_expect(branch_rail.current_segment == RailMovement.SEGMENT_MAIN_EAST, "P2 branch lets S leave the workshop siding onto the main")


func _make_strategy_fixture() -> Dictionary:
	var rail = RailMovement.new()
	rail.set_points_route(RailMovement.POINTS_SIDING)
	var detached_consists: Array[Dictionary] = [
		{
			"units": _typed_units(["W"]),
			"segment": RailMovement.SEGMENT_SIDING_B,
			"distance": 150.0,
		},
		{
			"units": _typed_units(["S"]),
			"segment": RailMovement.SEGMENT_SIDING_B,
			"distance": 240.0,
		},
	]
	rail.detached_consists = detached_consists
	var yard = _make_yard(rail)
	return {
		"rail": rail,
		"yard": yard,
	}


func _drive_until_can_couple(rail: RefCounted, unit_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	rail.max_speed = 10.0
	rail.acceleration = 24.0
	rail.coast_deceleration = 6.0
	rail.set_throttle(1.0)
	while elapsed < max_seconds and not rail.can_couple_unit(unit_id):
		rail.step(0.1, false)
		elapsed += 0.1
	rail.set_throttle(0.0)


func _drive_for_seconds(rail: RefCounted, max_seconds: float) -> void:
	var elapsed := 0.0
	rail.max_speed = 10.0
	rail.acceleration = 24.0
	rail.coast_deceleration = 6.0
	rail.set_throttle(1.0)
	while elapsed < max_seconds:
		rail.step(0.1, false)
		elapsed += 0.1
		if rail.speed <= 0.0 and elapsed > 0.1:
			break
	rail.set_throttle(0.0)


func _remove_detached_unit(rail: RefCounted, unit_id: String) -> void:
	for index in range(rail.detached_consists.size() - 1, -1, -1):
		var consist: Dictionary = rail.detached_consists[index]
		var units: Array = consist.get("units", [])
		if units.has(unit_id):
			rail.detached_consists.remove_at(index)


func _make_yard(rail: RefCounted) -> RefCounted:
	var script = load(YARD_SCRIPT_PATH)
	if script == null:
		_failures += 1
		printerr("FAIL: cannot load Sprint 4 yard operations script")
		return null
	return script.new(rail)


func _typed_units(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	result.assign(values)
	return result


func _find_state(states: Array[Dictionary], unit_id: String) -> Dictionary:
	for state in states:
		if str(state.get("id", "")) == unit_id:
			return state
	return {}


func _same_position(left: Dictionary, right: Dictionary) -> bool:
	if left.is_empty() or right.is_empty():
		return false
	return str(left.get("segment", "")) == str(right.get("segment", "")) \
		and absf(float(left.get("distance", -9999.0)) - float(right.get("distance", 9999.0))) < 0.01


func _format_ids(ids: Array) -> String:
	var text := ""
	for id in ids:
		text += "[%s]" % id
	return text


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 strategy acceptance passed")
		quit(0)
		return

	printerr("Sprint 4 strategy acceptance failed with %d failure(s)" % _failures)
	quit(1)
