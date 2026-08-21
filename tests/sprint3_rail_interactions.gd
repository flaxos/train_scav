extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var probe = RailMovement.new()
	if _require_methods(probe):
		_clear_points_toggle_uses_rail_authority()
		_occupied_points_reject_without_route_change()
		_exact_joint_uncoupling_splits_a_b()
		_exact_joint_uncoupling_preserves_target_identity()
		_front_joint_uncoupling_keeps_locomotive_controlled()
		_moving_train_rejects_joint_uncoupling()

	_finish()


func _require_methods(sim: RefCounted) -> bool:
	var methods: Array[String] = [
		"get_points_operator_anchor",
		"is_switch_occupied",
		"request_points_toggle",
		"get_coupled_joints",
		"has_coupled_joint",
		"get_joint_anchor",
		"decouple_joint",
	]
	var all_present := true
	for method_name in methods:
		if sim.has_method(method_name):
			continue

		_failures += 1
		all_present = false
		printerr("FAIL: missing Sprint 3 rail method %s" % method_name)
	return all_present


func _clear_points_toggle_uses_rail_authority() -> void:
	var sim = RailMovement.new()
	var before: String = sim.points_route
	_expect(not sim.is_switch_occupied(), "default start leaves points clear")
	_expect(sim.request_points_toggle(), "clear stopped points can be changed through rail authority")
	_expect(sim.points_route != before, "points route changes after authorized operation")


func _occupied_points_reject_without_route_change() -> void:
	var sim = RailMovement.new()
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = sim.get_segment_length(RailMovement.SEGMENT_MAIN_WEST)
	sim.speed = 0.0
	var before: String = sim.points_route

	_expect(sim.is_switch_occupied(), "rolling stock occupying the switch zone is detected")
	_expect(not sim.request_points_toggle(), "occupied points reject crew operation")
	_expect(sim.points_route == before, "occupied points leave route unchanged")
	_expect(sim.blocked_reason.contains("occupied"), "occupied points report a clear blocked reason")


func _exact_joint_uncoupling_splits_a_b() -> void:
	var sim = RailMovement.new()
	var joints: Array[Dictionary] = sim.get_coupled_joints()
	_expect(_joint_ids(joints).has("L/A"), "joint list includes L/A")
	_expect(_joint_ids(joints).has("A/B"), "joint list includes A/B")
	_expect(sim.has_coupled_joint("A", "B"), "A/B is an existing coupled joint")
	_expect(not sim.get_joint_anchor("A", "B").is_empty(), "A/B exposes a physical interaction anchor")

	_expect(sim.decouple_joint("A", "B"), "exact A/B joint can be uncoupled")
	_expect_units(sim, ["L", "A"], "A/B split leaves active [L][A]")
	_expect(sim.has_detached_consist(_typed_units(["B"]), RailMovement.SEGMENT_MAIN_WEST), "A/B split detaches [B]")
	_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after exact joint split")


func _exact_joint_uncoupling_preserves_target_identity() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["L", "A", "B", "C"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = 360.0

	_expect(sim.decouple_joint("A", "B"), "targeting A/B in [L][A][B][C] succeeds")
	_expect_units(sim, ["L", "A"], "targeting A/B keeps [L][A] active")
	_expect(sim.has_detached_consist(_typed_units(["B", "C"]), RailMovement.SEGMENT_MAIN_WEST), "targeting A/B detaches [B][C], not an arbitrary rear wagon")
	_expect(not sim.has_detached_consist(_typed_units(["C"]), RailMovement.SEGMENT_MAIN_WEST), "targeting A/B does not accidentally split B/C")


func _front_joint_uncoupling_keeps_locomotive_controlled() -> void:
	var sim = RailMovement.new()
	sim.active_units = _typed_units(["C", "L", "A", "B"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = 360.0

	_expect(sim.decouple_joint("C", "L"), "front C/L joint can be uncoupled")
	_expect_units(sim, ["L", "A", "B"], "C/L split keeps locomotive-containing segment active")
	_expect(sim.has_detached_consist(_typed_units(["C"]), RailMovement.SEGMENT_MAIN_WEST), "C/L split detaches C as passive rolling stock")
	_expect(sim.get_unit_type("C") != RailMovement.UNIT_LOCOMOTIVE, "C remains a wagon after crew-valid joint split")
	_expect(sim.get_controlled_locomotive_id() == "L", "controlled locomotive remains L after front joint split")


func _moving_train_rejects_joint_uncoupling() -> void:
	var sim = RailMovement.new()
	sim.speed = 2.0
	_expect(not sim.decouple_joint("A", "B"), "moving train rejects exact joint uncoupling")
	_expect_units(sim, ["L", "A", "B"], "moving-train rejection leaves consist unchanged")
	_expect(sim.blocked_reason.contains("Stop"), "moving-train rejection explains train must stop")


func _joint_ids(joints: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for joint in joints:
		ids.append(str(joint.get("id", "")))
	return ids


func _typed_units(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	result.assign(values)
	return result


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
		print("Sprint 3 rail interaction acceptance passed")
		quit(0)
		return

	printerr("Sprint 3 rail interaction acceptance failed with %d failure(s)" % _failures)
	quit(1)
