extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CREW_SCRIPT_PATH := "res://scripts/crew/crew_simulation.gd"

var _failures: int = 0


func _init() -> void:
	if not ResourceLoader.exists(CREW_SCRIPT_PATH):
		_failures += 1
		printerr("FAIL: missing Sprint 3 crew simulation script")
		_finish()
		return

	var rail_probe = RailMovement.new()
	if not _require_rail_methods(rail_probe):
		_finish()
		return

	var crew_probe = _make_crew(rail_probe)
	if crew_probe == null:
		_finish()
		return
	if _require_crew_methods(crew_probe):
		_survivor_identity_selection_and_task_ownership()
		_boarding_and_disembarking_rules()
		_onboard_survivor_follows_host_transform()
		_move_and_points_task_waits_for_physical_arrival()
		_occupied_points_task_fails_without_route_change()
		_uncouple_task_targets_exact_joint_after_arrival()
		_invalidated_uncouple_target_fails_safely()
		_reservation_blocks_duplicate_target()

	_finish()


func _require_rail_methods(sim: RefCounted) -> bool:
	var methods: Array[String] = [
		"request_points_toggle",
		"is_switch_occupied",
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
		printerr("FAIL: missing rail method required by crew %s" % method_name)
	return all_present


func _require_crew_methods(crew: RefCounted) -> bool:
	var methods: Array[String] = [
		"get_survivor_ids",
		"select_survivor",
		"get_selected_survivor_id",
		"get_survivor_state",
		"get_survivor_draw_states",
		"assign_move",
		"assign_disembark",
		"assign_board",
		"assign_operate_points",
		"assign_uncouple",
		"step",
		"get_debug_lines",
	]
	var all_present := true
	for method_name in methods:
		if crew.has_method(method_name):
			continue

		_failures += 1
		all_present = false
		printerr("FAIL: missing crew method %s" % method_name)
	return all_present


func _survivor_identity_selection_and_task_ownership() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	var ids: Array = crew.get_survivor_ids()
	_expect(ids.size() == 5, "five survivors exist")
	_expect(_unique_count(ids) == 5, "survivors have stable unique IDs")

	_expect(crew.select_survivor(str(ids[1])), "can select a specific survivor")
	_expect(crew.get_selected_survivor_id() == str(ids[1]), "selection records the chosen survivor")
	_expect(crew.assign_move(str(ids[1]), Vector2(500.0, 520.0)), "move task can be assigned to selected survivor")
	_expect(str(crew.get_survivor_state(str(ids[1])).get("task_type", "")) == "move", "task belongs to selected survivor")
	_expect(str(crew.get_survivor_state(str(ids[0])).get("task_type", "")) == "none", "assigning one survivor does not alter another")


func _boarding_and_disembarking_rules() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	var survivor_id := "marta"

	rail.speed = 4.0
	_expect(not crew.assign_disembark(survivor_id), "survivor cannot disembark while train is moving")
	_expect(str(crew.get_survivor_state(survivor_id).get("spatial_state", "")) == "aboard", "moving-train disembark rejection leaves survivor aboard")

	rail.speed = 0.0
	_expect(crew.assign_disembark(survivor_id), "survivor can disembark when train is stopped")
	_step_until_idle(crew, 8.0)
	_expect(str(crew.get_survivor_state(survivor_id).get("spatial_state", "")) == "yard", "disembark task leaves survivor in yard")

	rail.speed = 3.0
	_expect(not crew.assign_board(survivor_id, "L"), "yard survivor cannot board while train is moving")
	_expect(str(crew.get_survivor_state(survivor_id).get("spatial_state", "")) == "yard", "moving-train board rejection leaves survivor in yard")

	rail.speed = 0.0
	_expect(crew.assign_board(survivor_id, "L"), "yard survivor can board a stopped train")
	_step_until_idle(crew, 8.0)
	var state: Dictionary = crew.get_survivor_state(survivor_id)
	_expect(str(state.get("spatial_state", "")) == "aboard", "board task leaves survivor aboard")
	_expect(str(state.get("host_unit", "")) == "L", "board task records host rolling stock")


func _onboard_survivor_follows_host_transform() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	var before := _survivor_position(crew, "marta")

	rail.distance += 40.0
	var after := _survivor_position(crew, "marta")
	_expect(before.distance_to(after) > 20.0, "aboard survivor world position follows host vehicle movement")

	rail.current_segment = RailMovement.SEGMENT_SIDING
	rail.distance = 220.0
	var siding_state := _survivor_draw_state(crew, "marta")
	_expect(absf(float(siding_state.get("angle", 0.0))) > 0.05, "aboard survivor rotation follows host rail tangent")


func _move_and_points_task_waits_for_physical_arrival() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	var survivor_id := "marta"
	_expect(crew.assign_disembark(survivor_id), "fixture disembarks survivor for points task")
	_step_until_idle(crew, 8.0)

	var before_route: String = rail.points_route
	var start := _survivor_position(crew, survivor_id)
	_expect(crew.assign_operate_points(survivor_id), "points task can be assigned")
	crew.step(0.1)
	_expect(rail.points_route == before_route, "points do not change before survivor arrives")
	_expect(_survivor_position(crew, survivor_id).distance_to(start) > 0.1, "survivor moves physically toward points target")

	_step_until_idle(crew, 10.0)
	_expect(rail.points_route != before_route, "points change after survivor arrives and interacts")
	_expect(str(crew.get_survivor_state(survivor_id).get("task_status", "")) == "completed", "points task completes")


func _occupied_points_task_fails_without_route_change() -> void:
	var rail = RailMovement.new()
	rail.current_segment = RailMovement.SEGMENT_MAIN_WEST
	rail.distance = rail.get_segment_length(RailMovement.SEGMENT_MAIN_WEST)
	var crew = _make_crew(rail)
	var survivor_id := "marta"
	_force_yard_at(crew, survivor_id, rail.get_points_operator_anchor())
	var before_route: String = rail.points_route

	_expect(crew.assign_operate_points(survivor_id), "occupied points task can be assigned before final validation")
	_step_until_idle(crew, 4.0)
	_expect(rail.points_route == before_route, "occupied points task leaves route unchanged")
	_expect(str(crew.get_survivor_state(survivor_id).get("task_status", "")) == "blocked", "occupied points task reports blocked")


func _uncouple_task_targets_exact_joint_after_arrival() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	var survivor_id := "olek"

	_expect(crew.assign_uncouple(survivor_id, "A", "B"), "uncouple A/B task can be assigned")
	crew.step(0.1)
	_expect(_format_ids(rail.get_active_consist_ids()) == "[L][A][B]", "joint is not uncoupled before survivor arrives")
	_step_until_idle(crew, 10.0)
	_expect(_format_ids(rail.get_active_consist_ids()) == "[L][A]", "A/B task leaves active [L][A]")
	_expect(rail.has_detached_consist(_typed_units(["B"]), RailMovement.SEGMENT_MAIN_WEST), "A/B task detaches B")
	_expect(rail.get_controlled_locomotive_id() == "L", "crew uncoupling preserves controlled locomotive")


func _invalidated_uncouple_target_fails_safely() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	var survivor_id := "nia"

	_expect(crew.assign_uncouple(survivor_id, "A", "B"), "uncouple task can be assigned before invalidation")
	_expect(rail.decouple_joint("A", "B"), "external rail change removes target joint before survivor arrives")
	_step_until_idle(crew, 10.0)
	_expect(_format_ids(rail.get_active_consist_ids()) == "[L][A]", "invalidated task does not mutate active consist again")
	_expect(str(crew.get_survivor_state(survivor_id).get("task_status", "")) == "blocked", "invalidated joint task reports blocked")


func _reservation_blocks_duplicate_target() -> void:
	var rail = RailMovement.new()
	var crew = _make_crew(rail)
	_expect(crew.assign_operate_points("marta"), "first survivor reserves points")
	_expect(not crew.assign_operate_points("olek"), "second survivor cannot reserve the same points")
	_expect(str(crew.get_survivor_state("olek").get("task_status", "")) == "blocked", "duplicate points reservation reports blocked")

	var rail2 = RailMovement.new()
	var crew2 = _make_crew(rail2)
	_expect(crew2.assign_uncouple("marta", "A", "B"), "first survivor reserves A/B joint")
	_expect(not crew2.assign_uncouple("olek", "A", "B"), "second survivor cannot reserve the same joint")
	_expect(str(crew2.get_survivor_state("olek").get("task_status", "")) == "blocked", "duplicate joint reservation reports blocked")


func _make_crew(rail: RefCounted) -> RefCounted:
	var script = load(CREW_SCRIPT_PATH)
	if script == null:
		_failures += 1
		printerr("FAIL: cannot load Sprint 3 crew simulation script")
		return null
	return script.new(rail)


func _step_until_idle(crew: RefCounted, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and bool(crew.has_active_tasks()):
		crew.step(0.1)
		elapsed += 0.1


func _force_yard_at(crew: RefCounted, survivor_id: String, position: Vector2) -> void:
	crew.force_survivor_yard_position(survivor_id, position)


func _survivor_position(crew: RefCounted, survivor_id: String) -> Vector2:
	var state := _survivor_draw_state(crew, survivor_id)
	return state.get("position", Vector2.ZERO) as Vector2


func _survivor_draw_state(crew: RefCounted, survivor_id: String) -> Dictionary:
	for state in crew.get_survivor_draw_states():
		if str(state.get("id", "")) == survivor_id:
			return state
	return {}


func _unique_count(values: Array) -> int:
	var seen := {}
	for value in values:
		seen[str(value)] = true
	return seen.size()


func _typed_units(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	result.assign(values)
	return result


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
		print("Sprint 3 crew acceptance passed")
		quit(0)
		return

	printerr("Sprint 3 crew acceptance failed with %d failure(s)" % _failures)
	quit(1)
