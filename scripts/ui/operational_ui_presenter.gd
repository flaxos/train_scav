extends RefCounted
class_name OperationalUIPresenter

# Sprint 12.5 — Pure presentation helper for the player-facing operational UI.
# Reads domain state from RailMovement, RouteRequirementEvaluator, SectorLifecycle,
# CrewSimulation, and TrainResources, formatting it into structured, player-friendly
# views without duplicating simulation rules.

const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")


# --- Sector & Location Presentation ---

static func present_sector_name(definition: SectorDefinition) -> String:
	if definition == null:
		return "Unknown Sector"

	if definition.is_procedural():
		var loc_name := _friendly_archetype_name(definition.archetype_id)
		return "Sector %d — %s" % [definition.sector_index, loc_name]

	if definition.sector_index == 0:
		return "Sector 0 — Departure Yard"
	elif definition.sector_index == 1:
		return "Sector 1 — Forward Industrial Yard"

	if definition.display_name != "":
		return definition.display_name
	return "Sector %d" % definition.sector_index


static func _friendly_archetype_name(archetype_id: String) -> String:
	match archetype_id:
		"rural_through":
			return "Rural Line"
		"village_passing_station":
			return "Village Passing Station"
		"small_town_goods":
			return "Small Town Goods Yard"
		"agricultural_loading_point":
			return "Agricultural Loading Point"
		"river_valley_constrained":
			return "River Valley Line"
		"declining_abandoned_branch":
			return "Declining Branch Line"
	return "Forward Railway"


# --- Objective Presentation ---

static func present_objective(scenario_state: Dictionary, sector_index: int, departure_blocker: String = "") -> String:
	if not scenario_state.is_empty():
		var phase := str(scenario_state.get("phase", ""))
		if phase == FirstRunScenario.PHASE_OPENING:
			if bool(scenario_state.get("obstruction_active", false)):
				return "Clear the track obstruction ahead"
			if bool(scenario_state.get("onboard_fault_active", false)):
				return "Repair the locomotive fault"
			return "Depart east toward Forward Industrial Yard"
		elif phase == FirstRunScenario.PHASE_INDUSTRIAL:
			var recovered := bool(scenario_state.get("workshop_recovered", false))
			var online := bool(scenario_state.get("workshop_online", false))
			if not recovered:
				return "Recover workshop wagon W from yard siding"
			if not online:
				return "Activate workshop wagon W (needs 2 parts)"
			return "Choose an eligible route exit and depart"

	if sector_index >= 2:
		return "Scavenge supplies and continue east"

	if departure_blocker != "":
		return "Clear departure blocker to proceed"

	return "Explore sector and advance"


# --- Route Decision UI Presentation ---

static func clean_route_label(route_id_or_exit: Variant) -> String:
	var id := ""
	if typeof(route_id_or_exit) == TYPE_STRING:
		id = str(route_id_or_exit)
	elif typeof(route_id_or_exit) == TYPE_DICTIONARY:
		var dict: Dictionary = route_id_or_exit
		id = str(dict.get("route_id", dict.get("id", "")))

	match id:
		"direct", "direct_exit":
			return "Direct Line"
		"industrial", "industrial_exit":
			return "Industrial Line"
		"settlement", "settlement_exit":
			return "Settlement Line"
		"forward", "forward_exit":
			return "Forward Line"
	if typeof(route_id_or_exit) == TYPE_DICTIONARY:
		var label := str((route_id_or_exit as Dictionary).get("label", ""))
		if label != "":
			return label
	return id.capitalize()


static func present_route_option(exit_def: Dictionary, mobility: Dictionary, active_switches: Dictionary = {}) -> Dictionary:
	var clean_name := clean_route_label(exit_def)
	var requirements: Dictionary = exit_def.get("requirements", {})
	var eval_result := RouteRequirementEvaluator.evaluate(mobility, requirements, clean_name)
	var can_take := bool(eval_result.get("can_take_route", true))
	var details: Dictionary = eval_result.get("details", {})

	var reasons: Array[String] = []
	var action_hint := ""

	var max_mass := float(details.get("max_mass", 0.0))
	var total_mass := float(details.get("total_mass", 0.0))
	var max_length := float(details.get("max_length", 0.0))
	var total_length := float(details.get("total_length", 0.0))
	var missing_caps: Array = details.get("missing_capabilities", []) as Array
	var require_traction := bool(details.get("require_traction", true))
	var has_traction := bool(details.get("has_traction", false))

	if max_mass > 0.0:
		if total_mass > max_mass:
			var over := total_mass - max_mass
			reasons.append("Bridge limit: %.0ft (Train: %.1ft, %.1ft too heavy)" % [max_mass, total_mass, over])
			if action_hint == "":
				action_hint = "Leave rolling stock behind to reduce train mass below %.0ft." % max_mass
		else:
			reasons.append("Bridge limit: %.0ft (Train: %.1ft ✓)" % [max_mass, total_mass])

	if max_length > 0.0:
		if total_length > max_length:
			reasons.append("Consist too long for route clearance")
			if action_hint == "":
				action_hint = "Shorten consist to meet route length clearance."
		else:
			reasons.append("Length clearance ✓")

	for cap in missing_caps:
		var cap_name := _friendly_capability_name(str(cap))
		reasons.append("Requires %s (not present)" % cap_name)
		if action_hint == "":
			action_hint = "Recover and attach rolling stock with %s." % cap_name

	var required_caps: Array = details.get("required_capabilities", []) as Array
	for cap in required_caps:
		if not missing_caps.has(cap):
			reasons.append("Requires %s ✓" % _friendly_capability_name(str(cap)))

	var min_traction := float(details.get("min_traction", 0.0))
	var available_traction := float(mobility.get("traction", 1.0 if has_traction else 0.0))
	if min_traction > 1.0:
		if available_traction < min_traction:
			reasons.append("Traction required: %.0f units (Train: %.0f)" % [min_traction, available_traction])
			if action_hint == "":
				action_hint = "Recover and couple a second operational locomotive/shunter."
		else:
			reasons.append("Traction required: %.0f units (Train: %.0f ✓)" % [min_traction, available_traction])

	var damaged_segs: Array = details.get("damaged_segments", []) as Array
	for damaged_seg in damaged_segs:
		reasons.append("Track section damaged: %s" % str(damaged_seg))
		if action_hint == "":
			action_hint = "Assign crew to repair damaged track section."

	var damaged_sws: Array = details.get("damaged_switches", []) as Array
	for damaged_sw in damaged_sws:
		reasons.append("Switch damaged / jammed: %s" % str(damaged_sw))
		if action_hint == "":
			action_hint = "Assign crew to repair switch %s." % str(damaged_sw)

	if require_traction and not has_traction:
		reasons.append("Requires crewed operational locomotive")
		if action_hint == "":
			action_hint = "Board a survivor on an operational locomotive."

	# Route switch alignment check
	var switch_aligned := _is_route_switch_aligned(str(exit_def.get("route_id", exit_def.get("id", ""))), active_switches)
	if can_take:
		if switch_aligned:
			action_hint = "Switch aligned. Drive forward to depart."
		else:
			action_hint = _get_switch_alignment_hint(str(exit_def.get("route_id", exit_def.get("id", ""))))

	return {
		"id": str(exit_def.get("route_id", exit_def.get("id", ""))),
		"label": clean_name,
		"available": can_take,
		"status_label": "AVAILABLE" if can_take else "BLOCKED",
		"reasons": reasons,
		"action_hint": action_hint,
		"switch_aligned": switch_aligned,
		"primary_reason": str(eval_result.get("primary_reason", "")),
	}


static func _friendly_capability_name(cap: String) -> String:
	match cap:
		"workshop":
			return "Workshop"
		"crew_accommodation":
			return "Crew Accommodation"
		"storage":
			return "Cargo Storage"
		"fuel_storage":
			return "Fuel Storage"
	return cap.capitalize()


static func _is_route_switch_aligned(route_id: String, active_switches: Dictionary) -> bool:
	if active_switches.is_empty():
		return true

	var p1 := str(active_switches.get("P1", "main"))
	var p2 := str(active_switches.get("P2", "main"))
	var p3 := str(active_switches.get("P3", "siding"))

	match route_id:
		"direct", "direct_exit":
			return p1 == "main" and p2 == "main"
		"industrial", "industrial_exit":
			return p1 == "main" and p2 == "siding"
		"settlement", "settlement_exit":
			return p1 == "siding" and p3 == "main"
		"forward", "forward_exit":
			return true
	return true


static func _get_switch_alignment_hint(route_id: String) -> String:
	match route_id:
		"direct", "direct_exit":
			return "Set switch P1 and P2 to Main Line, then drive forward."
		"industrial", "industrial_exit":
			return "Set switch P2 toward Industrial Line (North), then drive forward."
		"settlement", "settlement_exit":
			return "Set switch P1 to Siding and P3 to Storage, then drive forward."
	return "Align track switches toward this branch and drive forward."


static func present_all_routes(route_exits: Array, mobility: Dictionary, active_switches: Dictionary = {}) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for exit_item in route_exits:
		results.append(present_route_option(exit_item as Dictionary, mobility, active_switches))
	return results


# --- Crew Presentation ---

static func present_crew_summary(crew: CrewSimulation) -> String:
	if crew == null:
		return "No crew assigned"

	var parts: Array[String] = []
	for survivor_id in crew.get_survivor_ids():
		var st := crew.get_survivor_state(survivor_id)
		var s_name := str(st.get("name", survivor_id))
		var spatial := str(st.get("spatial_state", ""))
		var host := str(st.get("host_unit", ""))
		var task_type := str(st.get("task_type", "none"))
		var task_status := str(st.get("task_status", "idle"))

		var loc := "Yard"
		if spatial == CrewSimulation.SPATIAL_ABOARD:
			loc = host

		var activity := "Idle"
		if task_status == CrewSimulation.STATUS_MOVING:
			activity = "Moving"
		elif task_status == CrewSimulation.STATUS_INTERACTING or task_status == CrewSimulation.STATUS_ASSIGNED:
			activity = _friendly_task_name(task_type)
		elif task_type != "none" and task_type != "":
			activity = _friendly_task_name(task_type)

		if activity != "Idle":
			parts.append("%s: %s (Task: %s)" % [s_name, loc, activity])
		else:
			parts.append("%s: %s (Idle)" % [s_name, loc])

	if parts.is_empty():
		return "No crew assigned"
	return " | ".join(parts)


static func _friendly_task_name(task_type: String) -> String:
	match task_type:
		"board_nearest", "board":
			return "Boarding"
		"disembark":
			return "Disembarking"
		"operate_points", "yard_point":
			return "Operating Switch"
		"couple_contact", "couple":
			return "Coupling"
		"uncouple":
			return "Uncoupling"
		"repair_shunter":
			return "Repairing Shunter"
		"repair_yard_control":
			return "Repairing Yard Control"
		"repair_point":
			return "Repairing Switch"
		"connect_power":
			return "Connecting Power"
		"search_poi":
			return "Searching POI"
		"haul_cargo":
			return "Hauling Cargo"
		"clear_obstruction":
			return "Clearing Obstruction"
		"repair_onboard_fault":
			return "Repairing Engine"
		"activate_workshop":
			return "Activating Workshop"
	return task_type.capitalize()


# --- Message Priority & Status Hierarchy ---

static func get_top_priority_status_message(
	departure_blocker: String,
	departure_confirmation_open: bool,
	recent_command_result: String,
	crew_active_feedback: String,
	objective_text: String,
	scenario_status: String,
	idle_status: String = ""
) -> String:
	# 1. Active Departure Confirmation Modal
	if departure_confirmation_open:
		return "Confirm departure: press Enter / Y to leave sector, or Esc / N to cancel"

	# 2. Active Command Result / Specific Yard Feedback (e.g. "Points P2 changed...", "Coupled...")
	if recent_command_result != "" \
			and not recent_command_result.begins_with("Route selected") \
			and not recent_command_result.begins_with("Entered ") \
			and not recent_command_result.begins_with("Use right-click") \
			and not recent_command_result.begins_with("Assigned "):
		return recent_command_result

	# 3. Active Specific Scenario Feedback (e.g. "Need 2 parts to activate workshop", "Opening obstruction cleared")
	if scenario_status != "" and scenario_status != "First run started" and not scenario_status.begins_with("Route selected") and not scenario_status.begins_with("Entered "):
		return scenario_status

	# 4. Critical Departure / Route Requirement Blocker (Outranks generic "Route selected..." text!)
	if departure_blocker != "":
		return departure_blocker

	# 5. Generic Route Selection Status (e.g. "Route selected by track branch: Direct route")
	if scenario_status != "" and scenario_status != "First run started":
		return scenario_status

	# 6. Active Crew Action Feedback
	if crew_active_feedback != "" and crew_active_feedback != "Idle":
		return crew_active_feedback

	# 7. Idle / Yard Status
	if idle_status != "":
		return idle_status

	return objective_text


# --- Formatted Player Side Panels ---

static func format_player_routes_panel(
	sector_def: SectorDefinition,
	mobility: Dictionary,
	scenario_state: Dictionary,
	active_switches: Dictionary = {},
	departure_blocker: String = ""
) -> Array[String]:
	var lines: Array[String] = []

	# Sector Header
	lines.append(present_sector_name(sector_def))
	lines.append("──────────────────────────────────────────")

	# Objective
	var sec_idx := 0
	if sector_def != null:
		sec_idx = sector_def.sector_index
	lines.append("Objective: %s" % present_objective(scenario_state, sec_idx, departure_blocker))
	lines.append("")

	# Routes Section
	if sector_def != null and not sector_def.route_exits.is_empty():
		lines.append("AVAILABLE ROUTES:")
		var route_views := present_all_routes(sector_def.route_exits, mobility, active_switches)
		for rv in route_views:
			var available := bool(rv.get("available", false))
			var badge := "[AVAILABLE ✓]" if available else "[BLOCKED ✕]"
			var aligned_badge := " (Aligned)" if bool(rv.get("switch_aligned", false)) and available else ""
			lines.append("• %s %s%s" % [str(rv.get("label", "")), badge, aligned_badge])

			var reasons: Array = rv.get("reasons", []) as Array
			for r in reasons:
				lines.append("    - %s" % str(r))

			var hint := str(rv.get("action_hint", ""))
			if hint != "":
				lines.append("    → %s" % hint)
			lines.append("")
	else:
		lines.append("ROUTE: Forward Line [AVAILABLE ✓]")
		lines.append("  → Drive forward across exit boundary to advance.")
		lines.append("")

	lines.append("──────────────────────────────────────────")
	lines.append("Drive remains keyboard: W/S throttle, Space brake, R reverse")
	lines.append("Mouse-first: 1-5 or Left click survivor | Right click menu (Left click menu item)")
	lines.append("Note: Coupled W != online | Dev / Debug: [F3] Toggle Debug Overlay (Sprint 12.5)")
	return lines


static func format_player_status_panel(
	mobility: Dictionary,
	consist_summary: String,
	controlled_power_id: String,
	has_driver: bool,
	workshop_online: bool,
	resources: TrainResources,
	crew: CrewSimulation,
	top_status_message: String,
	auto_dispatch_enabled: bool = false,
	speed: float = 0.0,
	throttle: float = 0.0,
	brake_active: bool = false,
	direction: int = 1,
	active_switches: Dictionary = {},
	yard_control_state: Dictionary = {}
) -> Array[String]:
	var lines: Array[String] = []

	# Line 1: Consist & Control
	var total_mass := float(mobility.get("total_mass", 0.0))
	var unit_count := int(mobility.get("unit_count", 0))
	var driver_text := "Driver aboard ✓" if has_driver else "No driver ✕"
	var traction := float(mobility.get("traction", 1.0 if mobility.get("has_traction", false) else 0.0))
	lines.append("Consist: %s (%.1ft, %d units)  Traction: %.0f  Control: %s: (%s)" % [
		consist_summary, total_mass, unit_count, traction, controlled_power_id, driver_text
	])

	# Line 2: Movement
	var dir_str := "Fwd" if direction >= 0 else "Rev"
	var brake_str := "on" if brake_active else "off"
	lines.append("Speed: %.1f  Throttle: %d%%  Brake: %s  Dir: %s" % [
		speed, roundi(throttle * 100.0), brake_str, dir_str
	])

	# Line 3: Active Route Switches
	var p1 := str(active_switches.get("P1", "main"))
	var p2 := str(active_switches.get("P2", "main"))
	var p3 := str(active_switches.get("P3", "siding"))
	lines.append("Route: P1 %s  P2 %s  P3 %s" % [p1, p2, p3])

	# Line 4: Capabilities
	var caps: Array = mobility.get("capabilities", []) as Array
	var cap_parts: Array[String] = []
	if caps.has("workshop"):
		cap_parts.append("Workshop ✓" if workshop_online else "Workshop (Offline)")
	if caps.has("storage"):
		cap_parts.append("Storage ✓")
	if caps.has("fuel_storage"):
		cap_parts.append("Fuel Tanker ✓")
	if caps.has("crew_accommodation"):
		cap_parts.append("Accommodation ✓")
	if cap_parts.is_empty():
		cap_parts.append("Standard Stock")
	lines.append("Capabilities: " + " | ".join(cap_parts))

	# Line 5: Supplies
	if resources != null:
		lines.append("Supplies: Diesel %.0f/%.0f (Depart: %.0f)  Food %.0f/%.0f  Parts %.0f/%.0f" % [
			resources.get_amount(TrainResources.RESOURCE_DIESEL),
			resources.get_capacity(TrainResources.RESOURCE_DIESEL),
			TrainResources.DEPARTURE_DIESEL_COST,
			resources.get_amount(TrainResources.RESOURCE_FOOD),
			resources.get_capacity(TrainResources.RESOURCE_FOOD),
			resources.get_amount(TrainResources.RESOURCE_PARTS),
			resources.get_capacity(TrainResources.RESOURCE_PARTS),
		])
	else:
		lines.append("Supplies: Diesel --  Food --  Parts --")

	# Line 6: Yard Infrastructure
	var y_cond := str(yard_control_state.get("condition", "damaged"))
	var y_power := "on" if bool(yard_control_state.get("powered", false)) else "off"
	var y_remote := "yes" if bool(yard_control_state.get("remote_control", false)) else "no"
	lines.append("Yard: Control %s  Power %s  Remote %s  Auto: %s [V]" % [
		y_cond, y_power, y_remote, "ON" if auto_dispatch_enabled else "OFF"
	])

	# Line 7: Crew
	lines.append("Crew: " + present_crew_summary(crew))

	# Line 8: Status
	if top_status_message != "":
		lines.append("Status: " + top_status_message)
	else:
		lines.append("Status: Ready for orders")

	return lines
