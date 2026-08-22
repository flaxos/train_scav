extends RefCounted
class_name CrewSimulation

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const TrainInterior := preload("res://scripts/colony/train_interior.gd")
const SurvivorNeeds := preload("res://scripts/colony/survivor_needs.gd")
const SurvivorSkills := preload("res://scripts/colony/survivor_skills.gd")

const SPATIAL_ABOARD := "aboard"
const SPATIAL_YARD := "yard"

const TASK_NONE := "none"
const TASK_MOVE := "move"
const TASK_BOARD := "board"
const TASK_DISEMBARK := "disembark"
const TASK_OPERATE_POINTS := "operate_points"
const TASK_UNCOUPLE := "uncouple"
const TASK_COUPLE := "couple"
const TASK_OPERATE_YARD_POINT := "operate_yard_point"
const TASK_REPAIR_SHUNTER := "repair_shunter"
const TASK_REPAIR_YARD_CONTROL := "repair_yard_control"
const TASK_CONNECT_POWER := "connect_power"
const TASK_REPAIR_POINT := "repair_point"
const TASK_MOVE_ABOARD := "move_aboard"

const STATUS_IDLE := "idle"
const STATUS_ASSIGNED := "assigned"
const STATUS_MOVING := "moving"
const STATUS_INTERACTING := "interacting"
const STATUS_COMPLETED := "completed"
const STATUS_BLOCKED := "blocked"
const STATUS_CANCELLED := "cancelled"

const STAGE_ABOARD_TO_EXIT := "aboard_to_exit"
const STAGE_YARD_TO_TARGET := "yard_to_target"
const STAGE_ABOARD_ROUTE := "aboard_route"

const BOARDING_LOCAL_OFFSET := Vector2(0.0, 36.0)
const DEFAULT_ABOARD_LOCAL_OFFSET := Vector2(-10.0, 0.0)

var rail: RefCounted
var yard: RefCounted
var interior: RefCounted
var needs: RefCounted
var skills: RefCounted
var survivors: Array[Dictionary] = []
var selected_survivor_id: String = "marta"
var reservations: Dictionary = {}

var yard_walk_speed: float = 180.0
var aboard_walk_speed: float = 90.0
var points_interaction_duration: float = 0.45
var uncouple_interaction_duration: float = 0.55
var couple_interaction_duration: float = 0.55
var board_interaction_duration: float = 0.25
var repair_interaction_duration: float = 0.75
var power_interaction_duration: float = 0.5
var move_arrival_epsilon: float = 2.0


func _init(rail_model: RefCounted = null, yard_model: RefCounted = null) -> void:
	if rail_model == null:
		rail = RailMovement.new()
	else:
		rail = rail_model
	yard = yard_model
	interior = TrainInterior.new(rail)
	needs = SurvivorNeeds.new()
	skills = SurvivorSkills.new()

	survivors = [
		_make_survivor("marta", "Marta", "L", Vector2(-14.0, -5.0)),
		_make_survivor("olek", "Olek", "A", Vector2(-10.0, 5.0)),
		_make_survivor("nia", "Nia", "B", Vector2(-8.0, -5.0)),
		_make_survivor("pavel", "Pavel", "A", Vector2(12.0, -5.0)),
		_make_survivor("iris", "Iris", "L", Vector2(12.0, 5.0)),
	]
	for survivor in survivors:
		needs.init_survivor(str(survivor["id"]))

	# Sprint 5C: Each survivor has a distinct skill profile and job.
	# Marta: experienced engineer, strong at repairs and mechanical work
	skills.init_survivor("marta", {
		SurvivorSkills.SKILL_ENGINEERING: 75.0,
		SurvivorSkills.SKILL_RAILWAY: 50.0,
		SurvivorSkills.SKILL_SCAVENGING: 30.0,
		SurvivorSkills.SKILL_MEDICAL: 15.0,
	}, SurvivorSkills.JOB_ENGINEER)
	# Olek: experienced rail worker, good at points and coupling ops
	skills.init_survivor("olek", {
		SurvivorSkills.SKILL_ENGINEERING: 30.0,
		SurvivorSkills.SKILL_RAILWAY: 80.0,
		SurvivorSkills.SKILL_SCAVENGING: 40.0,
		SurvivorSkills.SKILL_MEDICAL: 10.0,
	}, SurvivorSkills.JOB_RAIL_WORKER)
	# Nia: scavenger, good at finding and recovering things
	skills.init_survivor("nia", {
		SurvivorSkills.SKILL_ENGINEERING: 20.0,
		SurvivorSkills.SKILL_RAILWAY: 15.0,
		SurvivorSkills.SKILL_SCAVENGING: 85.0,
		SurvivorSkills.SKILL_MEDICAL: 25.0,
	}, SurvivorSkills.JOB_SCAVENGER)
	# Pavel: generalist with decent all-round skills
	skills.init_survivor("pavel", {
		SurvivorSkills.SKILL_ENGINEERING: 45.0,
		SurvivorSkills.SKILL_RAILWAY: 40.0,
		SurvivorSkills.SKILL_SCAVENGING: 50.0,
		SurvivorSkills.SKILL_MEDICAL: 35.0,
	}, SurvivorSkills.JOB_GENERALIST)
	# Iris: medic, trained in medical skills
	skills.init_survivor("iris", {
		SurvivorSkills.SKILL_ENGINEERING: 15.0,
		SurvivorSkills.SKILL_RAILWAY: 20.0,
		SurvivorSkills.SKILL_SCAVENGING: 30.0,
		SurvivorSkills.SKILL_MEDICAL: 80.0,
	}, SurvivorSkills.JOB_MEDIC)


func get_survivor_ids() -> Array[String]:
	var ids: Array[String] = []
	for survivor in survivors:
		ids.append(str(survivor["id"]))
	return ids


func select_survivor(survivor_id: String) -> bool:
	if _find_survivor_index(survivor_id) < 0:
		return false

	selected_survivor_id = survivor_id
	return true


func select_next_survivor() -> String:
	var ids := get_survivor_ids()
	if ids.is_empty():
		selected_survivor_id = ""
		return selected_survivor_id

	var current_index := ids.find(selected_survivor_id)
	if current_index < 0:
		selected_survivor_id = ids[0]
	else:
		selected_survivor_id = ids[(current_index + 1) % ids.size()]
	return selected_survivor_id


func get_selected_survivor_id() -> String:
	return selected_survivor_id


func get_survivor_state(survivor_id: String) -> Dictionary:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return {}

	return survivors[index].duplicate(true)


func get_survivor_world_position(survivor_id: String) -> Vector2:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return Vector2.ZERO
	return _get_survivor_world_position(survivors[index])


func get_survivor_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for survivor in survivors:
		var position := _get_survivor_world_position(survivor)
		var angle := _get_survivor_angle(survivor)
		var task_target := _get_task_target_position(survivor)
		var survivor_id := str(survivor["id"])
		states.append({
			"id": survivor_id,
			"name": str(survivor["name"]),
			"position": position,
			"angle": angle,
			"spatial_state": str(survivor["spatial_state"]),
			"host_unit": str(survivor.get("host_unit", "")),
			"selected": survivor_id == selected_survivor_id,
			"task_type": str(survivor["task_type"]),
			"task_status": str(survivor["task_status"]),
			"status_text": str(survivor["status_text"]),
			"target_position": task_target,
			"has_target": task_target != Vector2.INF,
			"health": needs.get_need(survivor_id, SurvivorNeeds.NEED_HEALTH),
			"hunger": needs.get_need(survivor_id, SurvivorNeeds.NEED_HUNGER),
			"rest": needs.get_need(survivor_id, SurvivorNeeds.NEED_REST),
			"performance": needs.get_performance_multiplier(survivor_id),
			"job": skills.get_job(survivor_id),
			"job_label": skills.get_job_label(skills.get_job(survivor_id)),
			"skills": skills.get_all_skills(survivor_id),
		})
	return states


func get_interaction_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	states.append({
		"id": "points",
		"type": TASK_OPERATE_POINTS,
		"position": rail.get_points_operator_anchor(),
		"reserved": reservations.has(_points_reservation_key()),
	})
	for joint in rail.get_coupled_joints():
		states.append({
			"id": str(joint.get("id", "")),
			"type": TASK_UNCOUPLE,
			"position": joint.get("anchor", Vector2.ZERO) as Vector2,
			"reserved": reservations.has(_joint_reservation_key(str(joint.get("front_unit", "")), str(joint.get("rear_unit", "")))),
		})
	if rail.has_method("get_last_contact_anchor"):
		var contact_anchor: Dictionary = rail.get_last_contact_anchor()
		if not contact_anchor.is_empty():
			states.append({
				"id": str(contact_anchor.get("id", "")),
				"type": TASK_COUPLE,
				"position": contact_anchor.get("anchor", Vector2.ZERO) as Vector2,
				"reserved": reservations.has(_couple_reservation_key(
					str(contact_anchor.get("active_unit", "")),
					str(contact_anchor.get("detached_unit", ""))
				)),
			})
	if yard != null and yard.has_method("get_interaction_draw_states"):
		for state in yard.get_interaction_draw_states():
			var target_id := str(state.get("id", ""))
			var target_type := str(state.get("type", ""))
			var enriched: Dictionary = state.duplicate(true)
			enriched["reserved"] = reservations.has(_yard_reservation_key(target_type, target_id))
			states.append(enriched)
	return states


func has_active_tasks() -> bool:
	for survivor in survivors:
		if _is_task_active(survivor):
			return true
	return false


func assign_move_aboard(survivor_id: String, target_unit: String, target_local: Vector2 = Vector2.ZERO) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false

	var survivor := survivors[index]
	if str(survivor.get("spatial_state", "")) != SPATIAL_ABOARD:
		_fail_survivor(index, TASK_MOVE_ABOARD, "Must be aboard to move through train")
		return false

	var host_unit := str(survivor.get("host_unit", ""))
	if not interior.can_walk_between(host_unit, target_unit):
		_fail_survivor(index, TASK_MOVE_ABOARD, "No connected interior route")
		return false

	_release_reservation(survivor)
	survivor["task_type"] = TASK_MOVE_ABOARD
	survivor["task_status"] = STATUS_ASSIGNED
	survivor["task_stage"] = STAGE_ABOARD_ROUTE
	survivor["task_target"] = target_unit
	survivor["task_target_position"] = Vector2.INF
	survivor["task_data"] = {
		"target_unit": target_unit,
		"target_local": interior.clamp_local_position(target_unit, target_local),
	}
	survivor["interaction_remaining"] = 0.0
	survivor["reservation_key"] = ""
	survivor["status_text"] = "Walking through train"
	survivors[index] = survivor
	return true


func assign_move(survivor_id: String, target_position: Vector2) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false

	var survivor := survivors[index]
	if str(survivor["spatial_state"]) == SPATIAL_ABOARD and not rail.is_stopped():
		_fail_survivor(index, TASK_MOVE, "Cannot leave moving train")
		return false

	_assign_travel_task(index, TASK_MOVE, target_position, "", {}, 0.0, "")
	return true


func assign_disembark(survivor_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false

	var survivor := survivors[index]
	if str(survivor["spatial_state"]) != SPATIAL_ABOARD:
		_fail_survivor(index, TASK_DISEMBARK, "Already in yard")
		return false
	if not rail.is_stopped():
		_fail_survivor(index, TASK_DISEMBARK, "Cannot leave moving train")
		return false

	var host_unit := str(survivor["host_unit"])
	_assign_travel_task(index, TASK_DISEMBARK, _get_boarding_anchor(host_unit), host_unit, {}, board_interaction_duration, "")
	return true


func assign_board(survivor_id: String, unit_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false

	var survivor := survivors[index]
	if str(survivor["spatial_state"]) != SPATIAL_YARD:
		_fail_survivor(index, TASK_BOARD, "Already aboard")
		return false
	if not rail.is_stopped():
		_fail_survivor(index, TASK_BOARD, "Cannot board moving train")
		return false
	if _get_unit_draw_state(unit_id).is_empty():
		_fail_survivor(index, TASK_BOARD, "Boarding target missing")
		return false
	if not interior.is_boardable_unit(unit_id):
		_fail_survivor(index, TASK_BOARD, "%s has no boardable interior" % unit_id)
		return false

	_assign_travel_task(index, TASK_BOARD, _get_boarding_anchor(unit_id), unit_id, {"unit": unit_id}, board_interaction_duration, "")
	return true


func assign_board_nearest(survivor_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false

	var survivor := survivors[index]
	var current_position := _get_survivor_world_position(survivor)
	var best_unit := ""
	var best_distance := INF
	for state in rail.get_unit_draw_states():
		var unit_id := str(state.get("id", ""))
		if not interior.is_boardable_unit(unit_id):
			continue
		var anchor := _get_boarding_anchor(unit_id)
		var distance_to_anchor := current_position.distance_to(anchor)
		if distance_to_anchor >= best_distance:
			continue

		best_distance = distance_to_anchor
		best_unit = unit_id

	if best_unit == "":
		_fail_survivor(index, TASK_BOARD, "No boarding target")
		return false

	return assign_board(survivor_id, best_unit)


func assign_operate_points(survivor_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false
	if str(survivors[index]["spatial_state"]) == SPATIAL_ABOARD and not rail.is_stopped():
		_fail_survivor(index, TASK_OPERATE_POINTS, "Cannot leave moving train")
		return false

	var reservation_key := _points_reservation_key()
	if not _reserve_target(index, TASK_OPERATE_POINTS, reservation_key):
		return false

	_assign_travel_task(index, TASK_OPERATE_POINTS, rail.get_points_operator_anchor(), "Points 01", {}, points_interaction_duration, reservation_key)
	return true


func assign_operate_yard_point(survivor_id: String, point_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false
	if yard == null:
		return assign_operate_points(survivor_id)
	if str(survivors[index]["spatial_state"]) == SPATIAL_ABOARD and not rail.is_stopped():
		_fail_survivor(index, TASK_OPERATE_YARD_POINT, "Cannot leave moving train")
		return false
	if yard.get_point_state(point_id).is_empty():
		_fail_survivor(index, TASK_OPERATE_YARD_POINT, "Unknown point")
		return false

	var reservation_key := _yard_reservation_key("yard_point", point_id)
	if not _reserve_target(index, TASK_OPERATE_YARD_POINT, reservation_key):
		return false

	_assign_travel_task(index, TASK_OPERATE_YARD_POINT, yard.get_point_anchor(point_id), point_id, {
		"point_id": point_id,
	}, points_interaction_duration, reservation_key)
	return true


func assign_repair_shunter(survivor_id: String) -> bool:
	return _assign_yard_task(
		survivor_id,
		TASK_REPAIR_SHUNTER,
		"repair_shunter",
		"S",
		yard.get_repair_anchor("shunter") if yard != null else Vector2.ZERO,
		"Shunter S",
		{},
		repair_interaction_duration
	)


func assign_repair_yard_control(survivor_id: String) -> bool:
	return _assign_yard_task(
		survivor_id,
		TASK_REPAIR_YARD_CONTROL,
		"repair_yard_control",
		"yard_control",
		yard.get_repair_anchor("yard_control") if yard != null else Vector2.ZERO,
		"Yard control",
		{},
		repair_interaction_duration
	)


func assign_connect_power(survivor_id: String) -> bool:
	return _assign_yard_task(
		survivor_id,
		TASK_CONNECT_POWER,
		"connect_power",
		"yard_power",
		yard.get_repair_anchor("power") if yard != null else Vector2.ZERO,
		"Yard power",
		{},
		power_interaction_duration
	)


func assign_repair_point(survivor_id: String, point_id: String) -> bool:
	if yard == null:
		var index := _find_survivor_index(survivor_id)
		if index >= 0:
			_fail_survivor(index, TASK_REPAIR_POINT, "No yard system")
		return false
	if yard.get_point_state(point_id).is_empty():
		var index := _find_survivor_index(survivor_id)
		if index >= 0:
			_fail_survivor(index, TASK_REPAIR_POINT, "Unknown point")
		return false

	return _assign_yard_task(
		survivor_id,
		TASK_REPAIR_POINT,
		"repair_point",
		point_id,
		yard.get_repair_anchor("point", point_id),
		point_id,
		{"point_id": point_id},
		repair_interaction_duration
	)


func assign_uncouple(survivor_id: String, front_unit: String, rear_unit: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false
	if not rail.is_stopped():
		_fail_survivor(index, TASK_UNCOUPLE, "Train must be stopped")
		return false
	if not rail.has_coupled_joint(front_unit, rear_unit):
		_fail_survivor(index, TASK_UNCOUPLE, "Joint no longer coupled")
		return false

	var reservation_key := _joint_reservation_key(front_unit, rear_unit)
	if not _reserve_target(index, TASK_UNCOUPLE, reservation_key):
		return false

	var joint: Dictionary = rail.get_joint_anchor(front_unit, rear_unit)
	_assign_travel_task(index, TASK_UNCOUPLE, joint.get("anchor", Vector2.ZERO) as Vector2, "%s/%s" % [front_unit, rear_unit], {
		"front_unit": front_unit,
		"rear_unit": rear_unit,
	}, uncouple_interaction_duration, reservation_key)
	return true


func assign_couple_contact(survivor_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false
	if not rail.is_stopped():
		_fail_survivor(index, TASK_COUPLE, "Train must be stopped")
		return false
	if not rail.has_method("get_last_contact_anchor"):
		_fail_survivor(index, TASK_COUPLE, "No compatible couplers in contact")
		return false

	var contact_anchor: Dictionary = rail.get_last_contact_anchor()
	if contact_anchor.is_empty():
		_fail_survivor(index, TASK_COUPLE, "No compatible couplers in contact")
		return false

	var active_unit := str(contact_anchor.get("active_unit", ""))
	var detached_unit := str(contact_anchor.get("detached_unit", ""))
	var reservation_key := _couple_reservation_key(active_unit, detached_unit)
	if not _reserve_target(index, TASK_COUPLE, reservation_key):
		return false

	var target_label := "%s/%s" % [active_unit, detached_unit]
	_assign_travel_task(index, TASK_COUPLE, contact_anchor.get("anchor", Vector2.ZERO) as Vector2, target_label, {
		"active_unit": active_unit,
		"detached_unit": detached_unit,
		"active_end": str(contact_anchor.get("active_end", "")),
		"detached_end": str(contact_anchor.get("detached_end", "")),
	}, couple_interaction_duration, reservation_key)
	return true


func cancel_task(survivor_id: String) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false

	_release_reservation(survivors[index])
	survivors[index]["task_status"] = STATUS_CANCELLED
	survivors[index]["status_text"] = "Cancelled"
	return true


func force_survivor_yard_position(survivor_id: String, position: Vector2) -> void:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return

	_release_reservation(survivors[index])
	survivors[index]["spatial_state"] = SPATIAL_YARD
	survivors[index]["host_unit"] = ""
	survivors[index]["yard_position"] = position
	survivors[index]["task_type"] = TASK_NONE
	survivors[index]["task_status"] = STATUS_IDLE
	survivors[index]["task_stage"] = ""
	survivors[index]["task_target"] = ""
	survivors[index]["task_target_position"] = Vector2.INF
	survivors[index]["task_data"] = {}
	survivors[index]["interaction_remaining"] = 0.0
	survivors[index]["status_text"] = "Idle"
	survivors[index]["reservation_key"] = ""


func force_survivor_aboard_unit(survivor_id: String, unit_id: String, local_offset: Vector2 = DEFAULT_ABOARD_LOCAL_OFFSET) -> void:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return

	_release_reservation(survivors[index])
	survivors[index]["spatial_state"] = SPATIAL_ABOARD
	survivors[index]["host_unit"] = unit_id
	survivors[index]["local_offset"] = local_offset
	survivors[index]["task_type"] = TASK_NONE
	survivors[index]["task_status"] = STATUS_IDLE
	survivors[index]["task_stage"] = ""
	survivors[index]["task_target"] = ""
	survivors[index]["task_target_position"] = Vector2.INF
	survivors[index]["task_data"] = {}
	survivors[index]["interaction_remaining"] = 0.0
	survivors[index]["reservation_key"] = ""
	survivors[index]["status_text"] = "Idle"


func has_survivor_aboard_unit(unit_id: String) -> bool:
	for survivor in survivors:
		if str(survivor.get("spatial_state", "")) != SPATIAL_ABOARD:
			continue
		if str(survivor.get("host_unit", "")) == unit_id:
			return true
	return false


func step(delta: float) -> void:
	needs.step(delta)
	for index in survivors.size():
		if not _is_task_active(survivors[index]):
			continue
		_step_survivor(index, delta)


func get_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	var selected := get_survivor_state(selected_survivor_id)
	if selected.is_empty():
		lines.append("Selected survivor: none")
	else:
		lines.append("Selected survivor: %s" % str(selected["name"]))
		lines.append("Crew state: %s host %s" % [str(selected["spatial_state"]), str(selected.get("host_unit", "-"))])
		lines.append("Crew task: %s / %s" % [str(selected["task_type"]), str(selected["task_status"])])
		lines.append("Crew target: %s" % str(selected.get("task_target", "")))
		if str(selected["status_text"]) != "":
			lines.append("Crew status: %s" % str(selected["status_text"]))
		lines.append("Needs: %s" % needs.get_debug_summary(selected_survivor_id))
		lines.append("Skills: %s" % skills.get_debug_summary(selected_survivor_id))

	var summaries: Array[String] = []
	for survivor in survivors:
		summaries.append("%s:%s:%s" % [
			str(survivor["name"]),
			str(survivor["spatial_state"]),
			str(survivor["task_status"]),
		])
	lines.append("Crew: %s" % "; ".join(summaries))
	return lines


func _make_survivor(survivor_id: String, display_name: String, host_unit: String, local_offset: Vector2) -> Dictionary:
	return {
		"id": survivor_id,
		"name": display_name,
		"spatial_state": SPATIAL_ABOARD,
		"host_unit": host_unit,
		"local_offset": local_offset,
		"yard_position": Vector2.ZERO,
		"task_type": TASK_NONE,
		"task_status": STATUS_IDLE,
		"task_stage": "",
		"task_target": "",
		"task_target_position": Vector2.INF,
		"task_target_local": BOARDING_LOCAL_OFFSET,
		"task_data": {},
		"interaction_remaining": 0.0,
		"reservation_key": "",
		"status_text": "Idle",
	}


func _assign_travel_task(index: int, task_type: String, target_position: Vector2, target_label: String, data: Dictionary, interaction_duration: float, reservation_key: String) -> void:
	var survivor := survivors[index]
	_release_reservation(survivor)
	if reservation_key != "":
		reservations[reservation_key] = str(survivor["id"])
	survivor["task_type"] = task_type
	survivor["task_status"] = STATUS_ASSIGNED
	survivor["task_stage"] = STAGE_YARD_TO_TARGET
	if str(survivor["spatial_state"]) == SPATIAL_ABOARD:
		survivor["task_stage"] = STAGE_ABOARD_TO_EXIT
	survivor["task_target"] = target_label
	survivor["task_target_position"] = target_position
	survivor["task_target_local"] = BOARDING_LOCAL_OFFSET
	survivor["task_data"] = data.duplicate(true)
	var speed_mult: float = skills.get_task_speed_multiplier(str(survivor["id"]), task_type)
	survivor["interaction_remaining"] = interaction_duration / maxf(speed_mult, 0.1)
	survivor["reservation_key"] = reservation_key
	survivor["status_text"] = "Assigned"
	survivors[index] = survivor


func _assign_yard_task(survivor_id: String, task_type: String, target_type: String, target_id: String, target_position: Vector2, target_label: String, data: Dictionary, interaction_duration: float) -> bool:
	var index := _find_survivor_index(survivor_id)
	if index < 0:
		return false
	if yard == null:
		_fail_survivor(index, task_type, "No yard system")
		return false
	if str(survivors[index]["spatial_state"]) == SPATIAL_ABOARD and not rail.is_stopped():
		_fail_survivor(index, task_type, "Cannot leave moving train")
		return false

	var reservation_key := _yard_reservation_key(target_type, target_id)
	if not _reserve_target(index, task_type, reservation_key):
		return false

	_assign_travel_task(index, task_type, target_position, target_label, data, interaction_duration, reservation_key)
	return true


func _reserve_target(index: int, task_type: String, reservation_key: String) -> bool:
	if reservations.has(reservation_key):
		_fail_survivor(index, task_type, "Target reserved")
		return false

	reservations[reservation_key] = str(survivors[index]["id"])
	return true


func _step_survivor(index: int, delta: float) -> void:
	var survivor := survivors[index]
	# Apply needs-based performance multiplier to effective delta.
	# This makes degraded survivors walk slower without adding complexity.
	var performance: float = needs.get_performance_multiplier(str(survivor["id"]))
	var effective_delta: float = delta * performance
	if str(survivor["task_status"]) == STATUS_ASSIGNED:
		survivor["task_status"] = STATUS_MOVING
		survivor["status_text"] = "Walking"

	if str(survivor["task_status"]) == STATUS_MOVING:
		match str(survivor["task_stage"]):
			STAGE_ABOARD_TO_EXIT:
				_step_aboard_to_exit(survivor, effective_delta)
			STAGE_ABOARD_ROUTE:
				_step_aboard_route(survivor, effective_delta)
			_:
				_step_yard_to_target(survivor, effective_delta)

	if str(survivor["task_status"]) == STATUS_INTERACTING:
		var remaining := float(survivor["interaction_remaining"]) - delta
		survivor["interaction_remaining"] = remaining
		if remaining <= 0.0:
			survivors[index] = survivor
			_execute_task(index)
			return

	survivors[index] = survivor


func _step_aboard_route(survivor: Dictionary, delta: float) -> void:
	var data := survivor.get("task_data", {}) as Dictionary
	var target_unit := str(data.get("target_unit", ""))
	var target_local := data.get("target_local", Vector2.ZERO) as Vector2
	var current_unit := str(survivor.get("host_unit", ""))

	# A survivor may be physically between two gangway doors for a short time.
	# Keep the source host until the crossing completes, but render their world
	# position as interpolation between the moving door anchors. If the joint is
	# uncoupled during the crossing, snap safely back to the source door and block.
	var crossing_to := str(data.get("crossing_to_unit", ""))
	if crossing_to != "":
		if not _can_cross_current_joint(current_unit, crossing_to):
			survivor["local_offset"] = data.get("crossing_from_local", survivor.get("local_offset", Vector2.ZERO)) as Vector2
			_clear_crossing_data(data)
			survivor["task_data"] = data
			survivor["task_status"] = STATUS_BLOCKED
			survivor["status_text"] = "Interior route disconnected"
			return

		var from_local := data.get("crossing_from_local", Vector2.ZERO) as Vector2
		var to_local := data.get("crossing_to_local", Vector2.ZERO) as Vector2
		var from_world := _world_from_unit_local(current_unit, from_local)
		var to_world := _world_from_unit_local(crossing_to, to_local)
		var gap := maxf(from_world.distance_to(to_world), 1.0)
		var progress := clampf(float(data.get("crossing_progress", 0.0)) + aboard_walk_speed * delta / gap, 0.0, 1.0)
		data["crossing_progress"] = progress
		survivor["task_data"] = data
		survivor["status_text"] = "Crossing gangway to %s" % crossing_to
		if progress < 1.0:
			return

		survivor["host_unit"] = crossing_to
		survivor["local_offset"] = to_local
		_clear_crossing_data(data)
		survivor["task_data"] = data
		# Return after completing the gangway crossing. Continuing in the same
		# frame would add a full delta of walking inside the next carriage on
		# top of the crossing movement, producing a spatial teleport.
		return

	# Revalidate against authoritative rail topology every step. If a joint is
	# uncoupled while someone is walking through the train, the survivor remains
	# in the carriage they physically reached and the now-impossible task blocks.
	if not interior.can_walk_between(current_unit, target_unit):
		survivor["task_status"] = STATUS_BLOCKED
		survivor["status_text"] = "Interior route disconnected"
		return

	if current_unit == target_unit:
		var current_local := survivor.get("local_offset", Vector2.ZERO) as Vector2
		var next_local := current_local.move_toward(target_local, aboard_walk_speed * delta)
		survivor["local_offset"] = interior.clamp_local_position(current_unit, next_local)
		if next_local.distance_to(target_local) <= move_arrival_epsilon:
			survivor["local_offset"] = target_local
			survivor["task_status"] = STATUS_COMPLETED
			survivor["status_text"] = "Arrived in %s" % target_unit
		return

	var units: Array[String] = interior.get_consist_units_for(current_unit)
	var current_index: int = units.find(current_unit)
	var target_index: int = units.find(target_unit)
	if current_index < 0 or target_index < 0:
		survivor["task_status"] = STATUS_BLOCKED
		survivor["status_text"] = "Interior route disconnected"
		return

	var moving_rearward: bool = target_index > current_index
	var door_local: Vector2 = interior.get_rear_door_local(current_unit) if moving_rearward else interior.get_front_door_local(current_unit)
	var local_position := survivor.get("local_offset", Vector2.ZERO) as Vector2
	var next_position := local_position.move_toward(door_local, aboard_walk_speed * delta)
	survivor["local_offset"] = interior.clamp_local_position(current_unit, next_position)
	if next_position.distance_to(door_local) > move_arrival_epsilon:
		return

	var next_index: int = current_index + (1 if moving_rearward else -1)
	var next_unit: String = units[next_index]
	if not _can_cross_current_joint(current_unit, next_unit):
		survivor["task_status"] = STATUS_BLOCKED
		survivor["status_text"] = "No compatible gangway to %s" % next_unit
		return

	var next_door: Vector2 = interior.get_front_door_local(next_unit) if moving_rearward else interior.get_rear_door_local(next_unit)
	# Use the survivor's actual clamped position as the crossing origin rather
	# than the ideal door coordinate.  The survivor arrives within
	# move_arrival_epsilon of the door, so they may be a few pixels short; using
	# the raw door_local here would create a one-frame spatial jump equal to
	# that epsilon gap.
	var actual_local: Vector2 = survivor.get("local_offset", door_local) as Vector2
	data["crossing_to_unit"] = next_unit
	data["crossing_from_local"] = actual_local
	data["crossing_to_local"] = next_door
	data["crossing_progress"] = 0.0
	survivor["task_data"] = data
	survivor["status_text"] = "Entering gangway to %s" % next_unit


func _can_cross_current_joint(from_unit: String, to_unit: String) -> bool:
	var units: Array[String] = interior.get_consist_units_for(from_unit)
	var from_index: int = units.find(from_unit)
	var to_index: int = units.find(to_unit)
	if from_index < 0 or to_index < 0 or absi(from_index - to_index) != 1:
		return false
	var front_index := mini(from_index, to_index)
	return interior.can_walk_joint(units[front_index], units[front_index + 1])


func _clear_crossing_data(data: Dictionary) -> void:
	data.erase("crossing_to_unit")
	data.erase("crossing_from_local")
	data.erase("crossing_to_local")
	data.erase("crossing_progress")


func _step_aboard_to_exit(survivor: Dictionary, delta: float) -> void:
	var current := survivor["local_offset"] as Vector2
	var target := survivor["task_target_local"] as Vector2
	var next := current.move_toward(target, aboard_walk_speed * delta)
	survivor["local_offset"] = next
	if next.distance_to(target) > move_arrival_epsilon:
		return

	if str(survivor["task_type"]) == TASK_DISEMBARK:
		survivor["task_status"] = STATUS_INTERACTING
		survivor["status_text"] = "Disembarking"
		return

	survivor["yard_position"] = _get_boarding_anchor(str(survivor["host_unit"]))
	survivor["spatial_state"] = SPATIAL_YARD
	survivor["host_unit"] = ""
	survivor["task_stage"] = STAGE_YARD_TO_TARGET


func _step_yard_to_target(survivor: Dictionary, delta: float) -> void:
	var current := survivor["yard_position"] as Vector2
	var target := survivor["task_target_position"] as Vector2
	var next := current.move_toward(target, yard_walk_speed * delta)
	survivor["yard_position"] = next
	if next.distance_to(target) > move_arrival_epsilon:
		return

	survivor["task_status"] = STATUS_INTERACTING
	survivor["status_text"] = "Interacting"
	if float(survivor["interaction_remaining"]) <= 0.0:
		survivor["interaction_remaining"] = 0.001


func _execute_task(index: int) -> void:
	var survivor := survivors[index]
	var task_type := str(survivor["task_type"])
	var succeeded := true
	var failure_reason := ""

	match task_type:
		TASK_MOVE:
			survivor["status_text"] = "Arrived"
		TASK_DISEMBARK:
			survivor["yard_position"] = _get_boarding_anchor(str(survivor["host_unit"]))
			survivor["spatial_state"] = SPATIAL_YARD
			survivor["host_unit"] = ""
			survivor["status_text"] = "Disembarked"
		TASK_BOARD:
			var unit_id := str((survivor["task_data"] as Dictionary).get("unit", ""))
			if not rail.is_stopped():
				succeeded = false
				failure_reason = "Cannot board moving train"
			elif _get_unit_draw_state(unit_id).is_empty():
				succeeded = false
				failure_reason = "Boarding target missing"
			elif not interior.is_boardable_unit(unit_id):
				succeeded = false
				failure_reason = "%s has no boardable interior" % unit_id
			else:
				survivor["spatial_state"] = SPATIAL_ABOARD
				survivor["host_unit"] = unit_id
				survivor["local_offset"] = DEFAULT_ABOARD_LOCAL_OFFSET
				survivor["status_text"] = "Boarded"
		TASK_OPERATE_POINTS:
			if not rail.request_points_toggle():
				succeeded = false
				failure_reason = rail.blocked_reason
			else:
				survivor["status_text"] = "Operated points"
		TASK_OPERATE_YARD_POINT:
			var point_data := survivor["task_data"] as Dictionary
			var point_id := str(point_data.get("point_id", ""))
			if yard == null:
				succeeded = false
				failure_reason = "No yard system"
			elif not yard.manual_operate_point(point_id):
				succeeded = false
				failure_reason = yard.last_status
			else:
				survivor["status_text"] = "Operated %s" % point_id
		TASK_UNCOUPLE:
			var uncouple_data := survivor["task_data"] as Dictionary
			var front_unit := str(uncouple_data.get("front_unit", ""))
			var rear_unit := str(uncouple_data.get("rear_unit", ""))
			if not rail.decouple_joint(front_unit, rear_unit):
				succeeded = false
				failure_reason = rail.blocked_reason
			else:
				survivor["status_text"] = "Uncoupled %s/%s" % [front_unit, rear_unit]
		TASK_COUPLE:
			if not rail.couple_nearest():
				succeeded = false
				failure_reason = rail.blocked_reason
			else:
				survivor["status_text"] = "Coupled %s" % rail.get_consist_summary()
		TASK_REPAIR_SHUNTER:
			if yard == null:
				succeeded = false
				failure_reason = "No yard system"
			elif not yard.repair_shunter():
				succeeded = false
				failure_reason = yard.last_status
			else:
				survivor["status_text"] = "Repaired shunter"
		TASK_REPAIR_YARD_CONTROL:
			if yard == null:
				succeeded = false
				failure_reason = "No yard system"
			elif not yard.repair_yard_control():
				succeeded = false
				failure_reason = yard.last_status
			else:
				survivor["status_text"] = "Repaired yard control"
		TASK_CONNECT_POWER:
			if yard == null:
				succeeded = false
				failure_reason = "No yard system"
			elif not yard.connect_power():
				succeeded = false
				failure_reason = yard.last_status
			else:
				survivor["status_text"] = "Connected power"
		TASK_REPAIR_POINT:
			var repair_data := survivor["task_data"] as Dictionary
			var repair_point_id := str(repair_data.get("point_id", ""))
			if yard == null:
				succeeded = false
				failure_reason = "No yard system"
			elif not yard.repair_point(repair_point_id):
				succeeded = false
				failure_reason = yard.last_status
			else:
				survivor["status_text"] = "Repaired %s" % repair_point_id
		_:
			succeeded = false
			failure_reason = "Unknown task"

	_release_reservation(survivor)
	if succeeded:
		survivor["task_status"] = STATUS_COMPLETED
	else:
		survivor["task_status"] = STATUS_BLOCKED
		survivor["status_text"] = failure_reason
	survivor["reservation_key"] = ""
	survivors[index] = survivor


func _fail_survivor(index: int, task_type: String, reason: String) -> void:
	var survivor := survivors[index]
	_release_reservation(survivor)
	survivor["task_type"] = task_type
	survivor["task_status"] = STATUS_BLOCKED
	survivor["task_stage"] = ""
	survivor["task_target"] = ""
	survivor["task_target_position"] = Vector2.INF
	survivor["reservation_key"] = ""
	survivor["status_text"] = reason
	survivors[index] = survivor


func _release_reservation(survivor: Dictionary) -> void:
	var reservation_key := str(survivor.get("reservation_key", ""))
	if reservation_key != "":
		reservations.erase(reservation_key)


func _is_task_active(survivor: Dictionary) -> bool:
	var status := str(survivor["task_status"])
	return status == STATUS_ASSIGNED or status == STATUS_MOVING or status == STATUS_INTERACTING


func _find_survivor_index(survivor_id: String) -> int:
	for index in survivors.size():
		if str(survivors[index]["id"]) == survivor_id:
			return index
	return -1


func _get_survivor_world_position(survivor: Dictionary) -> Vector2:
	if str(survivor["spatial_state"]) == SPATIAL_ABOARD:
		var data := survivor.get("task_data", {}) as Dictionary
		var crossing_to := str(data.get("crossing_to_unit", ""))
		if crossing_to != "":
			var from_unit := str(survivor.get("host_unit", ""))
			var from_local := data.get("crossing_from_local", survivor.get("local_offset", Vector2.ZERO)) as Vector2
			var to_local := data.get("crossing_to_local", Vector2.ZERO) as Vector2
			var progress := clampf(float(data.get("crossing_progress", 0.0)), 0.0, 1.0)
			return _world_from_unit_local(from_unit, from_local).lerp(_world_from_unit_local(crossing_to, to_local), progress)
		return _world_from_unit_local(str(survivor["host_unit"]), survivor["local_offset"] as Vector2)
	return survivor["yard_position"] as Vector2


func _get_survivor_angle(survivor: Dictionary) -> float:
	if str(survivor["spatial_state"]) != SPATIAL_ABOARD:
		return 0.0

	var from_state := _get_unit_draw_state(str(survivor["host_unit"]))
	if from_state.is_empty():
		return 0.0
	var from_angle := float(from_state.get("angle", 0.0))
	var data := survivor.get("task_data", {}) as Dictionary
	var crossing_to := str(data.get("crossing_to_unit", ""))
	if crossing_to == "":
		return from_angle
	var to_state := _get_unit_draw_state(crossing_to)
	if to_state.is_empty():
		return from_angle
	return lerp_angle(from_angle, float(to_state.get("angle", from_angle)), clampf(float(data.get("crossing_progress", 0.0)), 0.0, 1.0))


func _get_task_target_position(survivor: Dictionary) -> Vector2:
	if str(survivor.get("task_stage", "")) == STAGE_ABOARD_ROUTE:
		var data := survivor.get("task_data", {}) as Dictionary
		var target_unit := str(data.get("target_unit", ""))
		var target_local := data.get("target_local", Vector2.ZERO) as Vector2
		if target_unit != "":
			return _world_from_unit_local(target_unit, target_local)

	var target := survivor.get("task_target_position", Vector2.INF) as Vector2
	if target == Vector2.INF:
		return target
	if str(survivor["task_stage"]) == STAGE_ABOARD_TO_EXIT:
		return _get_boarding_anchor(str(survivor["host_unit"]))
	return target


func _world_from_unit_local(unit_id: String, local_offset: Vector2) -> Vector2:
	var state := _get_unit_draw_state(unit_id)
	if state.is_empty():
		return Vector2.ZERO

	var transform := Transform2D(float(state.get("angle", 0.0)), state.get("position", Vector2.ZERO) as Vector2)
	return transform * local_offset


func _get_boarding_anchor(unit_id: String) -> Vector2:
	return _world_from_unit_local(unit_id, BOARDING_LOCAL_OFFSET)


func _get_unit_draw_state(unit_id: String) -> Dictionary:
	for state in rail.get_unit_draw_states():
		if str(state.get("id", "")) == unit_id:
			return state
	return {}


func _points_reservation_key() -> String:
	return "points:main"


func _joint_reservation_key(front_unit: String, rear_unit: String) -> String:
	return "joint:%s/%s" % [front_unit, rear_unit]


func _couple_reservation_key(active_unit: String, detached_unit: String) -> String:
	return "couple:%s/%s" % [active_unit, detached_unit]


func _yard_reservation_key(target_type: String, target_id: String) -> String:
	return "yard:%s:%s" % [target_type, target_id]


func are_all_survivors_aboard() -> bool:
	for s in survivors:
		if str(s.get("spatial_state", "")) == SPATIAL_YARD:
			return false
	return true


func get_unboarded_survivor_names() -> Array[String]:
	var list: Array[String] = []
	for s in survivors:
		if str(s.get("spatial_state", "")) == SPATIAL_YARD:
			list.append(str(s.get("name", s.get("id", "Survivor"))))
	return list


func reset_for_new_sector(new_rail: RefCounted, new_yard: RefCounted) -> void:
	rail = new_rail
	yard = new_yard
	interior = TrainInterior.new(rail)
	reservations.clear()

	for s in survivors:
		var t_type := str(s.get("task_type", TASK_NONE))
		if t_type != TASK_NONE:
			s["task_status"] = STATUS_CANCELLED
			s["task_status_reason"] = "Sector transition"
			s["task_type"] = TASK_NONE
			s["task_stage"] = ""
			s["task_target"] = ""

