extends RefCounted
class_name FirstRunScenario

const PHASE_OPENING := "opening"
const PHASE_INDUSTRIAL := "industrial"
const PHASE_NEXT_ROUTE := "next_route"

const STATE_ACTIVE := "active"
const STATE_CLEARED := "cleared"
const STATE_REPAIRED := "repaired"
const STATE_OFFLINE := "offline"
const STATE_ONLINE := "online"

const OBSTRUCTION_ID := "opening_obstruction"
const ONBOARD_FAULT_ID := "locomotive_fault"
const WORKSHOP_ACTIVATION_ID := "workshop_activation"
const ROUTE_DECISION_ID := "route_decision"
const WORKSHOP_ID := "W"
const SEGMENT_MAIN_WEST := "main_west"
const SEGMENT_MAIN_EAST := "main_east"
const SEGMENT_MAIN_EXIT := "main_exit"
const SEGMENT_SIDING := "siding"
const SEGMENT_SIDING_B := "siding_b"
const SEGMENT_INDUSTRIAL_EXIT := "industrial_exit"
const SEGMENT_SETTLEMENT_EXIT := "settlement_exit"
const POINTS_MAIN := "main"
const POINT_P2 := "P2"
const POINT_P3 := "P3"
const RESOURCE_PARTS := "parts"
const ACTION_CLEAR_OBSTRUCTION := "clear_obstruction"
const ACTION_REPAIR_ONBOARD_FAULT := "repair_onboard_fault"
const ACTION_ACTIVATE_WORKSHOP := "activate_workshop"

const OBSTRUCTION_ANCHOR := Vector2(850.0, 325.0)
const OBSTRUCTION_SEGMENT := SEGMENT_MAIN_EAST
const OBSTRUCTION_DISTANCE := 310.0
const OBSTRUCTION_STOP_CLEARANCE := 52.0
const ROUTE_DECISION_ANCHOR := Vector2(470.0, 548.0)
const ONBOARD_FAULT_LOCAL := Vector2(18.0, -3.0)
const WORKSHOP_ACTIVATION_PARTS_COST := 2.0

var lifecycle: RefCounted
var crew: RefCounted
var task_broker: RefCounted

var obstruction_state: String = STATE_ACTIVE
var onboard_fault_state: String = STATE_ACTIVE
var workshop_state: String = STATE_OFFLINE
var selected_route: String = ""
var last_status: String = "First run started"


func attach(lifecycle_model: RefCounted, crew_sim: RefCounted, broker: RefCounted = null) -> void:
	lifecycle = lifecycle_model
	crew = crew_sim
	task_broker = broker
	if crew != null and crew.has_method("set_scenario_context"):
		crew.set_scenario_context(self)
	if task_broker != null:
		task_broker.scenario = self
	if lifecycle != null and lifecycle.current_sector != null:
		configure_sector(lifecycle.current_sector)


func detach() -> void:
	if crew != null and crew.has_method("set_scenario_context"):
		crew.set_scenario_context(null)
	if task_broker != null:
		task_broker.scenario = null
	if lifecycle != null and lifecycle.has_method("clear_scenario_coordinator"):
		lifecycle.clear_scenario_coordinator()
	lifecycle = null
	crew = null
	task_broker = null


func configure_sector(sector: RefCounted) -> void:
	if sector == null or sector.rail == null:
		return
	if sector.definition != null and sector.definition.has_method("is_procedural") and sector.definition.is_procedural():
		last_status = "Entered generated %s" % str(sector.definition.archetype_id)
		return

	var rail: RefCounted = sector.rail
	if int(sector.definition.sector_index) == 0:
		_configure_opening_sector(rail)
	elif int(sector.definition.sector_index) == 1:
		_configure_industrial_sector(rail, sector.yard)
	else:
		_configure_chosen_route_sector(sector)


func get_state() -> Dictionary:
	var sector_index := 0
	if lifecycle != null and lifecycle.current_sector != null and lifecycle.current_sector.definition != null:
		sector_index = int(lifecycle.current_sector.definition.sector_index)
	var phase := PHASE_OPENING
	if sector_index == 1:
		phase = PHASE_INDUSTRIAL
	elif sector_index > 1:
		phase = PHASE_NEXT_ROUTE

	return {
		"phase": phase,
		"sector_index": sector_index,
		"obstruction_state": obstruction_state,
		"obstruction_active": obstruction_state == STATE_ACTIVE,
		"onboard_fault_state": onboard_fault_state,
		"onboard_fault_active": onboard_fault_state == STATE_ACTIVE,
		"workshop_state": workshop_state,
		"workshop_online": workshop_state == STATE_ONLINE,
		"workshop_recovered": is_workshop_recovered(),
		"selected_route": selected_route,
		"last_status": last_status,
	}


func get_departure_blocked_reason() -> String:
	var state := get_state()
	var phase := str(state.get("phase", ""))
	if phase == PHASE_OPENING:
		if obstruction_state == STATE_ACTIVE:
			return "Departure blocked: opening obstruction still blocks the route"
		if onboard_fault_state == STATE_ACTIVE:
			return "Departure blocked: onboard fault needs engineer response"
	elif phase == PHASE_INDUSTRIAL:
		if not is_workshop_recovered():
			return "Departure blocked: recover workshop wagon W first"
		if workshop_state != STATE_ONLINE:
			return "Departure blocked: workshop wagon W is not online"
		if selected_route == "":
			return "Departure blocked: choose the next route by driving onto a marked exit branch"
	return ""


func apply_movement_constraints(rail_model: RefCounted) -> bool:
	var state := get_state()
	if str(state.get("phase", "")) != PHASE_OPENING or obstruction_state != STATE_ACTIVE:
		return false
	if rail_model == null:
		return false
	if rail_model.current_segment != OBSTRUCTION_SEGMENT or rail_model.direction < 0:
		return false

	var stop_distance := maxf(OBSTRUCTION_DISTANCE - OBSTRUCTION_STOP_CLEARANCE, 0.0)
	if rail_model.distance < stop_distance:
		return false

	rail_model.distance = stop_distance
	rail_model.speed = 0.0
	rail_model.set_throttle(0.0)
	rail_model.brake_active = true
	rail_model.blocked_reason = "Stopped by track obstruction"
	last_status = "Track obstruction blocks the route"
	return true


func get_interaction_state(target_id: String) -> Dictionary:
	match target_id:
		OBSTRUCTION_ID:
			if obstruction_state != STATE_ACTIVE:
				return {}
			return {
				"id": OBSTRUCTION_ID,
				"action_id": ACTION_CLEAR_OBSTRUCTION,
				"label": "Clear track obstruction",
				"position": OBSTRUCTION_ANCHOR,
				"spatial_state": "yard",
				"duration": 0.7,
				"status": obstruction_state,
			}
		ONBOARD_FAULT_ID:
			if onboard_fault_state != STATE_ACTIVE:
				return {}
			return {
				"id": ONBOARD_FAULT_ID,
				"action_id": ACTION_REPAIR_ONBOARD_FAULT,
				"label": "Repair locomotive fault",
				"position": _unit_local_to_world("L", ONBOARD_FAULT_LOCAL),
				"spatial_state": "aboard",
				"host_unit": "L",
				"local_offset": ONBOARD_FAULT_LOCAL,
				"duration": 0.85,
				"status": onboard_fault_state,
			}
		WORKSHOP_ACTIVATION_ID:
			if not is_workshop_recovered() or workshop_state == STATE_ONLINE:
				return {}
			return {
				"id": WORKSHOP_ACTIVATION_ID,
				"action_id": ACTION_ACTIVATE_WORKSHOP,
				"label": "Activate workshop W",
				"position": _unit_local_to_world(WORKSHOP_ID, Vector2(0.0, 34.0)),
				"spatial_state": "yard",
				"duration": 0.9,
				"parts_cost": WORKSHOP_ACTIVATION_PARTS_COST,
				"status": workshop_state,
			}
	return {}


func get_world_interaction_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	var obstruction := get_interaction_state(OBSTRUCTION_ID)
	if not obstruction.is_empty():
		states.append(obstruction)
	var fault := get_interaction_state(ONBOARD_FAULT_ID)
	if not fault.is_empty():
		states.append(fault)
	var workshop := get_interaction_state(WORKSHOP_ACTIVATION_ID)
	if not workshop.is_empty():
		states.append(workshop)
	if workshop_state == STATE_ONLINE and selected_route == "":
		states.append({
			"id": ROUTE_DECISION_ID,
			"action_id": "route_intel",
			"label": "Route map intel",
			"position": ROUTE_DECISION_ANCHOR,
			"spatial_state": "yard",
			"duration": 0.0,
			"status": "Main=Direct  North=Industrial  Yard=Settlement",
		})
	return states


func get_open_work_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	var fault := get_interaction_state(ONBOARD_FAULT_ID)
	if not fault.is_empty():
		targets.append({
			"type": ACTION_REPAIR_ONBOARD_FAULT,
			"target_id": ONBOARD_FAULT_ID,
			"position": fault.get("position", Vector2.ZERO),
			"reservation_key": "scenario:%s" % ONBOARD_FAULT_ID,
			"priority": 120,
		})
	return targets


func get_route_options() -> Array[Dictionary]:
	return [
		{
			"id": "industrial",
			"label": "Industrial route",
			"profile": "industrial",
			"summary": "More parts opportunity; higher operational risk later.",
			"exit_id": "industrial_exit",
			"exit_segment": SEGMENT_INDUSTRIAL_EXIT,
		},
		{
			"id": "settlement",
			"label": "Settlement route",
			"profile": "settlement",
			"summary": "Possible recruit lead; safer supplies later.",
			"exit_id": "settlement_exit",
			"exit_segment": SEGMENT_SETTLEMENT_EXIT,
		},
		{
			"id": "direct",
			"label": "Direct route",
			"profile": "direct",
			"summary": "Cheaper and faster; fewer opportunities.",
			"exit_id": "direct_exit",
			"exit_segment": SEGMENT_MAIN_EXIT,
		},
	]


func prepare_departure_for_exit(exit_state: Dictionary) -> void:
	if exit_state.is_empty():
		return
	var state := get_state()
	if str(state.get("phase", "")) != PHASE_INDUSTRIAL:
		return
	if not bool(state.get("workshop_recovered", false)) or workshop_state != STATE_ONLINE:
		return
	var route_id := str(exit_state.get("route_id", exit_state.get("id", "")))
	_apply_route_from_exit(route_id)


func clear_pending_route_selection() -> void:
	var state := get_state()
	if str(state.get("phase", "")) != PHASE_INDUSTRIAL:
		return
	if selected_route == "":
		return
	selected_route = ""
	if lifecycle != null and lifecycle.run_state != null:
		lifecycle.run_state.route_choice = ""
		lifecycle.run_state.next_sector_profile = ""
	last_status = "Route selection cancelled; drive onto a marked branch to choose again"


func _apply_route_from_exit(route_id: String) -> bool:
	for option in get_route_options():
		var route := str(option.get("id", ""))
		if route != route_id:
			continue
		selected_route = route
		if lifecycle != null and lifecycle.run_state != null:
			lifecycle.run_state.route_choice = route
			lifecycle.run_state.next_sector_profile = str(option.get("profile", route))
		last_status = "Route selected by track branch: %s" % str(option.get("label", route))
		return true

	return false


func dispatch_task(crew_sim: RefCounted, survivor_id: String, task_type: String, target_id: String) -> bool:
	var interaction := get_interaction_state(target_id)
	if interaction.is_empty():
		return false
	if task_type != str(interaction.get("action_id", "")):
		return false
	if not crew_sim.has_method("assign_scenario_interaction"):
		return false

	return crew_sim.assign_scenario_interaction(
		survivor_id,
		str(interaction.get("action_id", "")),
		str(interaction.get("id", "")),
		interaction.get("position", Vector2.ZERO) as Vector2,
		str(interaction.get("label", "")),
		float(interaction.get("duration", 0.0)),
		{},
		str(interaction.get("host_unit", "")),
		interaction.get("local_offset", Vector2.ZERO) as Vector2
	)


func execute_scenario_interaction(action_id: String, target_id: String, survivor_id: String) -> bool:
	match action_id:
		ACTION_CLEAR_OBSTRUCTION:
			if target_id != OBSTRUCTION_ID or obstruction_state != STATE_ACTIVE:
				last_status = "Obstruction already cleared"
				return false
			obstruction_state = STATE_CLEARED
			last_status = "%s cleared the track obstruction" % _survivor_label(survivor_id)
			return true
		ACTION_REPAIR_ONBOARD_FAULT:
			if target_id != ONBOARD_FAULT_ID or onboard_fault_state != STATE_ACTIVE:
				last_status = "Onboard fault already resolved"
				return false
			onboard_fault_state = STATE_REPAIRED
			last_status = "%s repaired the locomotive fault" % _survivor_label(survivor_id)
			return true
		ACTION_ACTIVATE_WORKSHOP:
			if target_id != WORKSHOP_ACTIVATION_ID:
				last_status = "Unknown workshop activation target"
				return false
			if not is_workshop_recovered():
				last_status = "Workshop wagon W must be coupled first"
				return false
			if workshop_state == STATE_ONLINE:
				last_status = "Workshop already online"
				return false
			var resources := _get_resources()
			if resources == null:
				last_status = "No train resource store"
				return false
			if not resources.can_afford(RESOURCE_PARTS, WORKSHOP_ACTIVATION_PARTS_COST):
				last_status = "Need %.0f parts to activate workshop" % WORKSHOP_ACTIVATION_PARTS_COST
				return false
			if not resources.consume(RESOURCE_PARTS, WORKSHOP_ACTIVATION_PARTS_COST):
				last_status = "Cannot consume workshop activation parts"
				return false
			workshop_state = STATE_ONLINE
			last_status = "%s brought workshop W online" % _survivor_label(survivor_id)
			return true

	last_status = "Unknown scenario action"
	return false


func is_workshop_recovered() -> bool:
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.rail == null:
		return false
	var rail: RefCounted = lifecycle.current_sector.rail
	return rail.active_units.has("L") and rail.active_units.has(WORKSHOP_ID)


func _configure_opening_sector(rail: RefCounted) -> void:
	var opening_units: Array[String] = ["L", "A", "B"]
	rail.active_units = opening_units
	rail.controlled_power_unit_id = "L"
	rail.current_segment = SEGMENT_MAIN_WEST
	rail.distance = 336.0
	rail.speed = 0.0
	rail.throttle = 0.0
	rail.direction = 1
	rail.points_route = POINTS_MAIN
	rail.set_yard_point_route(POINT_P2, POINTS_MAIN)
	var opening_detached: Array[Dictionary] = [
		{
			"units": ["C"],
			"segment": SEGMENT_SIDING,
			"distance": 220.0,
		},
	]
	rail.detached_consists = opening_detached


func _configure_industrial_sector(rail: RefCounted, yard: RefCounted) -> void:
	rail.points_route = POINTS_MAIN
	rail.set_yard_point_route(POINT_P2, POINTS_MAIN)
	rail.set_yard_point_route(POINT_P3, POINTS_MAIN)
	var industrial_detached: Array[Dictionary] = [
		{
			"units": ["W"],
			"segment": SEGMENT_SIDING_B,
			"distance": 150.0,
		},
		{
			"units": ["S"],
			"segment": SEGMENT_SIDING_B,
			"distance": 240.0,
		},
	]
	rail.detached_consists = industrial_detached
	if yard != null and yard.has_method("repair_point"):
		yard.repair_point(POINT_P3)


func _configure_chosen_route_sector(sector: RefCounted) -> void:
	var rail: RefCounted = sector.rail
	var no_detached: Array[Dictionary] = []
	rail.detached_consists = no_detached
	if selected_route == "":
		return
	var route_label := "Chosen Route"
	match selected_route:
		"industrial":
			route_label = "Industrial Route"
			sector.definition.accent_color = Color(0.96, 0.67, 0.24, 0.92)
		"settlement":
			route_label = "Settlement Route"
			sector.definition.accent_color = Color(0.42, 0.78, 0.48, 0.92)
		"direct":
			route_label = "Direct Route"
			sector.definition.accent_color = Color(0.65, 0.72, 0.82, 0.92)
	sector.definition.template_name = route_label
	sector.definition.display_name = "Sector %d: %s" % [int(sector.definition.sector_index), route_label]
	sector.definition.entry_label = "Sector %d entry - %s selected" % [
		int(sector.definition.sector_index),
		selected_route,
	]


func _unit_local_to_world(unit_id: String, local_offset: Vector2) -> Vector2:
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.rail == null:
		return Vector2.ZERO
	for state in lifecycle.current_sector.rail.get_unit_draw_states():
		if str(state.get("id", "")) != unit_id:
			continue
		var transform := Transform2D(float(state.get("angle", 0.0)), state.get("position", Vector2.ZERO) as Vector2)
		return transform * local_offset
	return Vector2.ZERO


func _survivor_label(survivor_id: String) -> String:
	if crew != null and crew.has_method("get_survivor_state"):
		var state: Dictionary = crew.get_survivor_state(survivor_id)
		if not state.is_empty():
			return str(state.get("name", survivor_id))
	return survivor_id


func _get_resources() -> RefCounted:
	if lifecycle == null or not lifecycle.has_method("get_train_resources"):
		return null
	return lifecycle.get_train_resources()
