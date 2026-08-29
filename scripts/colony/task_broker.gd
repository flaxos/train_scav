extends RefCounted
class_name TaskBroker

# Sprint 5D — Automatic task assignment.
#
# Scans the yard/world for available maintenance/repair work and matches open
# tasks to eligible, idle survivors based on job eligibility, skill suitability,
# and physical proximity.
#
# Uses existing physical CrewSimulation task assignment APIs so survivors
# physically travel to the work location.

const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var crew: RefCounted
var yard: RefCounted
var rail: RefCounted
var scenario: RefCounted
var enabled: bool = false


func _init(crew_sim: RefCounted, yard_ops: RefCounted, rail_mov: RefCounted) -> void:
	crew = crew_sim
	yard = yard_ops
	rail = rail_mov


func dispose() -> void:
	enabled = false
	crew = null
	yard = null
	rail = null
	scenario = null


func step(_delta: float) -> void:
	if not enabled or crew == null or yard == null:
		return
	evaluate_and_assign()


func evaluate_and_assign() -> int:
	if not enabled or crew == null or yard == null:
		return 0

	var open_tasks := _get_open_work_targets()
	if open_tasks.is_empty():
		return 0

	var assigned_count := 0
	for task in open_tasks:
		var task_type := str(task["type"])
		var target_id := str(task.get("target_id", ""))
		var target_pos := task.get("position", Vector2.ZERO) as Vector2

		# Skip if target is already reserved in crew simulation
		var res_key: String = task.get("reservation_key", "")
		if res_key != "" and crew.reservations.has(res_key):
			continue

		var best_candidate := _find_best_candidate(task_type, target_pos)
		if best_candidate == "":
			continue

		if _dispatch_task(best_candidate, task_type, target_id):
			assigned_count += 1

	return assigned_count


func _get_open_work_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if scenario != null and scenario.has_method("get_open_work_targets"):
		for target in scenario.get_open_work_targets():
			targets.append(target)
	if yard == null:
		return targets

	# 1. Shunter repair
	if rail != null \
			and rail.get_powered_unit_condition("S") == RailMovement.CONDITION_DAMAGED \
			and not rail.get_consist_containing_unit("S").is_empty():
		targets.append({
			"type": "repair_shunter",
			"target_id": "S",
			"position": yard.get_repair_anchor("shunter"),
			"reservation_key": "yard:repair_shunter:S",
			"priority": 100,
		})

	# 2. Yard control repair
	var ctrl_state: Dictionary = yard.get_yard_control_state()
	if str(ctrl_state.get("condition", "")) != YardOperations.CONTROL_REPAIRED:
		targets.append({
			"type": "repair_yard_control",
			"target_id": "yard_control",
			"position": yard.get_repair_anchor("yard_control"),
			"reservation_key": "yard:repair_yard_control:yard_control",
			"priority": 90,
		})

	# 3. Connect power
	if bool(ctrl_state.get("powered", false)) == false:
		targets.append({
			"type": "connect_power",
			"target_id": "yard_power",
			"position": yard.get_repair_anchor("power"),
			"reservation_key": "yard:connect_power:yard_power",
			"priority": 80,
		})

	# 4. Point repairs
	for point_id: String in yard.get_point_ids():
		var point_state: Dictionary = yard.get_point_state(point_id)
		if str(point_state.get("mechanical_state", "")) == YardOperations.MECHANICAL_DAMAGED:
			targets.append({
				"type": "repair_point",
				"target_id": point_id,
				"position": yard.get_repair_anchor("point", point_id),
				"reservation_key": "yard:repair_point:%s" % point_id,
				"priority": 70,
			})

	# 5. Track repairs
	if rail != null and rail.has_method("get_damaged_track_ids"):
		for segment_id in rail.get_damaged_track_ids():
			targets.append({
				"type": "repair_track",
				"target_id": segment_id,
				"position": yard.get_repair_anchor("track", segment_id),
				"reservation_key": "yard:repair_track:%s" % segment_id,
				"priority": 65,
			})

	return targets


func _find_best_candidate(task_type: String, target_pos: Vector2) -> String:
	var best_id := ""
	var best_score := -INF

	for survivor_id: String in crew.get_survivor_ids():
		var state: Dictionary = crew.get_survivor_state(survivor_id)
		if state.is_empty():
			continue

		# Survivor must be idle
		if str(state.get("task_status", "")) != CrewSimulation.STATUS_IDLE:
			continue

		# Survivor must be job-eligible
		if not crew.skills.is_job_eligible(survivor_id, task_type):
			continue

		# Calculate score based on skill suitability and physical distance
		var suitability: float = crew.skills.get_task_suitability(survivor_id, task_type)
		var current_pos: Vector2 = crew.get_survivor_world_position(survivor_id)
		var distance: float = current_pos.distance_to(target_pos)

		# Score formula: suitability is primary (weight 1000), distance is secondary penalty
		var score: float = suitability * 1000.0 - (distance * 0.1)
		if score > best_score:
			best_score = score
			best_id = survivor_id

	return best_id


func _dispatch_task(survivor_id: String, task_type: String, target_id: String) -> bool:
	if scenario != null and scenario.has_method("dispatch_task"):
		if scenario.dispatch_task(crew, survivor_id, task_type, target_id):
			return true

	match task_type:
		"repair_shunter":
			return crew.assign_repair_shunter(survivor_id)
		"repair_yard_control":
			return crew.assign_repair_yard_control(survivor_id)
		"connect_power":
			return crew.assign_connect_power(survivor_id)
		"repair_point":
			return crew.assign_repair_point(survivor_id, target_id)
		"repair_track":
			return crew.assign_repair_track(survivor_id, target_id)
	return false
