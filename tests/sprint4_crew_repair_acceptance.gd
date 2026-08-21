extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CREW_SCRIPT_PATH := "res://scripts/crew/crew_simulation.gd"
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
	var crew = _make_crew(rail, yard)
	if yard == null or crew == null:
		_finish()
		return
	if _require_crew_methods(crew):
		_shunter_repair_waits_for_physical_arrival()
		_yard_control_repair_and_power_tasks_change_only_targets()
		_repair_reservations_prevent_conflicts()
		_invalidated_or_redundant_repair_is_safe()
		_yard_point_task_uses_authoritative_yard_operation_after_arrival()

	_finish()


func _require_crew_methods(crew: RefCounted) -> bool:
	var methods: Array[String] = [
		"assign_repair_shunter",
		"assign_repair_yard_control",
		"assign_connect_power",
		"assign_repair_point",
		"assign_operate_yard_point",
	]
	var all_present := true
	for method_name in methods:
		if crew.has_method(method_name):
			continue

		_failures += 1
		all_present = false
		printerr("FAIL: missing Sprint 4 crew method %s" % method_name)
	return all_present


func _shunter_repair_waits_for_physical_arrival() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var crew = _make_crew(rail, yard)
	var survivor_id := "marta"
	_force_yard_at(crew, survivor_id, Vector2(160.0, 620.0))
	var start := _survivor_position(crew, survivor_id)

	_expect(str(yard.get_shunter_state().get("condition", "")) == RailMovement.CONDITION_DAMAGED, "shunter starts damaged")
	_expect(crew.assign_repair_shunter(survivor_id), "survivor can be assigned to repair shunter")
	crew.step(0.1)
	_expect(str(yard.get_shunter_state().get("condition", "")) == RailMovement.CONDITION_DAMAGED, "shunter repair does not occur before arrival")
	_expect(_survivor_position(crew, survivor_id).distance_to(start) > 0.1, "repair survivor moves physically toward shunter anchor")
	_step_until_idle(crew, 12.0)
	_expect(str(yard.get_shunter_state().get("condition", "")) == RailMovement.CONDITION_OPERATIONAL, "shunter becomes operational after physical repair interaction")
	_expect(str(crew.get_survivor_state(survivor_id).get("task_status", "")) == "completed", "shunter repair task completes")


func _yard_control_repair_and_power_tasks_change_only_targets() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var crew = _make_crew(rail, yard)
	_force_yard_at(crew, "marta", yard.get_yard_control_state().get("repair_anchor", Vector2.ZERO) as Vector2)
	_force_yard_at(crew, "olek", yard.get_yard_control_state().get("power_anchor", Vector2.ZERO) as Vector2)

	_expect(crew.assign_repair_yard_control("marta"), "yard control repair task can be assigned")
	_step_until_idle(crew, 5.0)
	_expect(str(yard.get_yard_control_state().get("condition", "")) == "repaired", "yard control becomes repaired")
	_expect(not yard.is_remote_control_available(), "yard control remains remote-offline until powered")
	_expect(str(yard.get_shunter_state().get("condition", "")) == RailMovement.CONDITION_DAMAGED, "repairing control does not repair shunter")

	_expect(crew.assign_connect_power("olek"), "power connection task can be assigned")
	_step_until_idle(crew, 5.0)
	_expect(bool(yard.get_yard_control_state().get("powered", false)), "power task connects train auxiliary power")
	_expect(not yard.is_remote_control_available(), "repaired and powered control does not enable remote switching in the Sprint 4 UAT")


func _repair_reservations_prevent_conflicts() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var crew = _make_crew(rail, yard)
	_expect(crew.assign_repair_yard_control("marta"), "first survivor reserves yard control repair")
	_expect(not crew.assign_repair_yard_control("olek"), "second survivor cannot reserve same repair target")
	_expect(str(crew.get_survivor_state("olek").get("task_status", "")) == "blocked", "duplicate repair reservation reports blocked")


func _invalidated_or_redundant_repair_is_safe() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var crew = _make_crew(rail, yard)
	_force_yard_at(crew, "nia", Vector2(120.0, 640.0))
	_expect(crew.assign_repair_point("nia", "P3"), "point repair task can be assigned before external repair")
	_expect(yard.repair_point("P3"), "external repair invalidates original damaged target")
	_step_until_idle(crew, 12.0)
	_expect(str(yard.get_point_state("P3").get("mechanical_state", "")) == "operational", "invalidated repair leaves point operational")
	_expect(str(crew.get_survivor_state("nia").get("task_status", "")) == "completed", "redundant repair completes as safe no-op")


func _yard_point_task_uses_authoritative_yard_operation_after_arrival() -> void:
	var rail = RailMovement.new()
	var yard = _make_yard(rail)
	var crew = _make_crew(rail, yard)
	var survivor_id := "pavel"
	_force_yard_at(crew, survivor_id, Vector2(160.0, 620.0))
	var before: String = rail.points_route

	_expect(crew.assign_operate_yard_point(survivor_id, "P1"), "survivor can be assigned to manually operate yard point P1")
	crew.step(0.1)
	_expect(rail.points_route == before, "yard point operation does not execute before arrival")
	_step_until_idle(crew, 12.0)
	_expect(rail.points_route != before, "yard point operation executes through yard authority after arrival")


func _make_yard(rail: RefCounted) -> RefCounted:
	var script = load(YARD_SCRIPT_PATH)
	if script == null:
		_failures += 1
		printerr("FAIL: cannot load Sprint 4 yard operations script")
		return null
	return script.new(rail)


func _make_crew(rail: RefCounted, yard: RefCounted) -> RefCounted:
	var script = load(CREW_SCRIPT_PATH)
	if script == null:
		_failures += 1
		printerr("FAIL: cannot load crew simulation script")
		return null
	return script.new(rail, yard)


func _step_until_idle(crew: RefCounted, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and bool(crew.has_active_tasks()):
		crew.step(0.1)
		elapsed += 0.1


func _force_yard_at(crew: RefCounted, survivor_id: String, position: Vector2) -> void:
	crew.force_survivor_yard_position(survivor_id, position)


func _survivor_position(crew: RefCounted, survivor_id: String) -> Vector2:
	for state in crew.get_survivor_draw_states():
		if str(state.get("id", "")) == survivor_id:
			return state.get("position", Vector2.ZERO) as Vector2
	return Vector2.ZERO


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 crew repair acceptance passed")
		quit(0)
		return

	printerr("Sprint 4 crew repair acceptance failed with %d failure(s)" % _failures)
	quit(1)
