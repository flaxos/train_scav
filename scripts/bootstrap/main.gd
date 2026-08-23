extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const TrainInterior := preload("res://scripts/colony/train_interior.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")

const BACKGROUND_COLOR := Color(0.055, 0.062, 0.071, 1.0)
const ROUTE_MAIN_COLOR := Color(0.30, 0.75, 0.95, 1.0)
const ROUTE_SIDING_COLOR := Color(0.95, 0.58, 0.20, 1.0)
const ROUTE_INACTIVE_COLOR := Color(0.42, 0.45, 0.48, 1.0)
const ROUTE_CURRENT_COLOR := Color(0.92, 0.80, 0.32, 1.0)
const TRACK_BED_COLOR := Color(0.095, 0.102, 0.112, 1.0)
const TRACK_SLEEPER_COLOR := Color(0.37, 0.31, 0.24, 1.0)
const TRACK_RAIL_COLOR := Color(0.72, 0.75, 0.76, 1.0)
const TRACK_INACTIVE_RAIL_COLOR := Color(0.47, 0.50, 0.53, 1.0)
const TRACK_SLEEPER_SPACING := 22.0
const TRACK_SLEEPER_LENGTH := 24.0
const TRACK_RAIL_OFFSET := 5.5
const COUPLER_COLOR := Color(0.05, 0.05, 0.05, 1.0)
const ACTIVE_COUPLING_ZONE_COLOR := Color(0.35, 0.82, 0.95, 0.18)
const DETACHED_COUPLING_ZONE_COLOR := Color(0.95, 0.68, 0.28, 0.18)
const UNIT_WIDTH := 30.0
const LOCOMOTIVE_HEADLIGHT_COLOR := Color(1.0, 0.94, 0.58, 1.0)
const LOCOMOTIVE_CAB_COLOR := Color(0.08, 0.10, 0.12, 1.0)
const UNIT_LABEL_COLOR := Color(0.98, 0.98, 0.95, 1.0)
const SURVIVOR_ABOARD_COLOR := Color(0.42, 0.78, 1.0, 1.0)
const SURVIVOR_YARD_COLOR := Color(0.96, 0.84, 0.34, 1.0)
const SURVIVOR_SELECTED_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const SURVIVOR_SELECTED_HALO_COLOR := Color(1.0, 1.0, 1.0, 0.14)
const INTERIOR_FLOOR_COLOR := Color(0.12, 0.15, 0.17, 0.92)
const INTERIOR_WALKWAY_COLOR := Color(0.68, 0.72, 0.74, 0.62)
const INTERIOR_FIXTURE_COLOR := Color(0.82, 0.72, 0.46, 0.78)
const INTERIOR_DOOR_COLOR := Color(0.40, 0.88, 0.72, 0.95)
const INTERIOR_LABEL_COLOR := Color(0.92, 0.94, 0.93, 0.95)
const TASK_TARGET_COLOR := Color(0.98, 0.88, 0.18, 0.9)
const POINTS_ANCHOR_COLOR := Color(0.95, 0.48, 0.20, 1.0)
const JOINT_ANCHOR_COLOR := Color(0.56, 0.85, 0.48, 1.0)
const RESERVED_ANCHOR_COLOR := Color(1.0, 0.25, 0.22, 1.0)
const REPAIR_ANCHOR_COLOR := Color(0.74, 0.54, 1.0, 1.0)
const POWER_ANCHOR_COLOR := Color(0.35, 0.95, 0.72, 1.0)
const PANEL_BACKGROUND_COLOR := Color(0.075, 0.083, 0.095, 1.0)
const PANEL_BORDER_COLOR := Color(0.23, 0.25, 0.28, 1.0)
const PANEL_SECTION_COLOR := Color(0.105, 0.115, 0.13, 1.0)
const MENU_BACKGROUND_COLOR := Color(0.12, 0.13, 0.145, 0.96)
const MENU_BORDER_COLOR := Color(0.55, 0.58, 0.62, 1.0)
const MENU_ITEM_COLOR := Color(0.17, 0.18, 0.20, 1.0)
const MENU_TEXT_COLOR := Color(0.98, 0.98, 0.95, 1.0)
const MODAL_BACKGROUND_COLOR := Color(0.06, 0.065, 0.075, 0.98)
const MODAL_BUTTON_COLOR := Color(0.18, 0.20, 0.23, 1.0)
const MODAL_CONFIRM_COLOR := Color(0.28, 0.62, 0.40, 1.0)
const MODAL_CANCEL_COLOR := Color(0.72, 0.30, 0.24, 1.0)
const ICON_BACKGROUND_COLOR := Color(0.92, 0.90, 0.84, 1.0)
const ICON_STROKE_COLOR := Color(0.06, 0.065, 0.07, 1.0)
const ICON_LABEL_COLOR := Color(0.96, 0.96, 0.92, 1.0)
const ROUTE_LABEL_BACKGROUND_COLOR := Color(0.09, 0.10, 0.11, 0.92)
const ROUTE_LABEL_ACTIVE_BACKGROUND_COLOR := Color(0.18, 0.15, 0.07, 0.95)
const ROUTE_LABEL_TEXT_COLOR := Color(0.98, 0.96, 0.86, 1.0)
const ROUTE_LABEL_DIM_TEXT_COLOR := Color(0.70, 0.72, 0.72, 1.0)
const UI_MARGIN := 16.0
const UI_PANEL_WIDTH := 360.0
const UI_PANEL_GAP := 16.0
const INSTRUCTION_PANEL_HEIGHT := 310.0
const WORLD_BOUNDS := Rect2(Vector2(120.0, 250.0), Vector2(1700.0, 360.0))
const CONTEXT_MENU_WIDTH := 250.0
const CONTEXT_MENU_ITEM_HEIGHT := 30.0
const CONTEXT_MENU_HEADER_HEIGHT := 50.0
const CONTEXT_MENU_PADDING := 8.0
const CONTEXT_TARGET_RADIUS := 56.0

@onready var instruction_label: Label = %InstructionLabel
@onready var debug_label: Label = %DebugLabel

var rail: RailMovement
var crew: CrewSimulation
var yard: YardOperations
var interior: TrainInterior
var task_broker: RefCounted
var lifecycle: RefCounted
var _throttle_up_held: bool = false
var _throttle_down_held: bool = false
var _brake_held: bool = false
var context_menu_open: bool = false
var context_menu_position: Vector2 = Vector2.ZERO
var context_menu_items: Array[Dictionary] = []
var context_menu_actor_id: String = ""
var context_menu_actor_name: String = ""
var context_menu_target_label: String = ""
var survivor_selection_confirmed: bool = false
var departure_confirmation_open: bool = false
var departure_confirmation_lines: Array[String] = []


func _ready() -> void:
	rail = RailMovement.new()
	yard = YardOperations.new(rail)
	interior = TrainInterior.new(rail)
	crew = CrewSimulation.new(rail, yard)
	task_broker = TaskBroker.new(crew, yard, rail)
	lifecycle = SectorLifecycle.new(12345, crew, task_broker)
	_refresh_instruction_text()
	_layout_ui()
	queue_redraw()


func get_playfield_rect() -> Rect2:
	var canvas_size := _get_canvas_size()
	var ui_panel := get_ui_panel_rect()
	var width := maxf(ui_panel.position.x - UI_PANEL_GAP - UI_MARGIN, 320.0)
	return Rect2(Vector2(UI_MARGIN, UI_MARGIN), Vector2(width, maxf(canvas_size.y - UI_MARGIN * 2.0, 320.0)))


func get_ui_panel_rect() -> Rect2:
	var canvas_size := _get_canvas_size()
	var panel_width := minf(UI_PANEL_WIDTH, maxf(canvas_size.x * 0.34, 300.0))
	return Rect2(
		Vector2(maxf(canvas_size.x - panel_width - UI_MARGIN, UI_MARGIN), UI_MARGIN),
		Vector2(panel_width, maxf(canvas_size.y - UI_MARGIN * 2.0, 320.0))
	)


func get_instruction_panel_rect() -> Rect2:
	var panel := get_ui_panel_rect()
	return Rect2(panel.position + Vector2(12.0, 12.0), Vector2(panel.size.x - 24.0, INSTRUCTION_PANEL_HEIGHT))


func get_debug_panel_rect() -> Rect2:
	var panel := get_ui_panel_rect()
	var top := panel.position.y + INSTRUCTION_PANEL_HEIGHT + 32.0
	return Rect2(Vector2(panel.position.x + 12.0, top), Vector2(panel.size.x - 24.0, panel.end.y - top - 12.0))


func get_compact_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	if rail == null or yard == null or crew == null:
		return lines
	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	var yard_control := yard.get_yard_control_state()
	var shunter := yard.get_shunter_state()
	var p1 := yard.get_point_state(YardOperations.POINT_P1)
	var p2 := yard.get_point_state(YardOperations.POINT_P2)
	var direction_label := "Fwd"
	if rail.direction < 0:
		direction_label = "Rev"

	var auto_label := "ON [V]" if task_broker != null and task_broker.enabled else "OFF [V]"
	var sector_visual := get_sector_visual_state()
	var sec_id: String = str(sector_visual.get("sector_id", "sector_a"))
	var sec_name: String = str(sector_visual.get("display_name", sec_id))
	lines.append("Sector: %s  Auto: %s" % [sec_name, auto_label])
	var controlled_power := rail.get_controlled_power_unit_id()
	lines.append("Consist: %s  Control: %s (%s)" % [
		rail.get_consist_summary(),
		controlled_power,
		"driver" if _controlled_power_has_crew() else "no driver",
	])
	lines.append("Speed: %.1f  Throttle: %d%%  Brake: %s  Dir: %s" % [
		rail.speed,
		roundi(rail.throttle * 100.0),
		_on_off(rail.brake_active),
		direction_label,
	])
	var p3 := yard.get_point_state(YardOperations.POINT_P3)
	lines.append("Route: P1 %s  P2 %s  P3 %s" % [
		str(p1.get("route", "")),
		str(p2.get("route", "")),
		str(p3.get("route", "")),
	])
	lines.append("Yard: control %s  power %s  remote %s" % [
		str(yard_control.get("condition", "")),
		_on_off(bool(yard_control.get("powered", false))),
		_yes_no(bool(yard_control.get("remote_control", false))),
	])
	lines.append("Shunter S: %s  selectable %s" % [
		str(shunter.get("condition", "")),
		_yes_no(bool(shunter.get("controllable", false))),
	])

	if selected.is_empty():
		lines.append("Crew: none")
	else:
		var crew_location := str(selected.get("spatial_state", ""))
		if crew_location == CrewSimulation.SPATIAL_ABOARD:
			var host_unit := str(selected.get("host_unit", ""))
			crew_location = "%s %s %s" % [crew_location, host_unit, interior.get_unit_interior_label(host_unit)]
		lines.append("Crew: %s  %s  %s" % [
			str(selected.get("name", "")),
			crew_location,
			str(selected.get("task_status", "")),
		])
		lines.append("Task: %s  target %s" % [
			str(selected.get("task_type", "")),
			str(selected.get("task_target", "")),
		])
		lines.append("Needs: %s" % crew.needs.get_debug_summary(crew.get_selected_survivor_id()))

	var status := _latest_status_line()
	if status != "":
		lines.append("Status: %s" % status)
	return lines


func get_sector_state() -> Dictionary:
	if lifecycle != null:
		return lifecycle.get_sector_state()
	return {}


func get_sector_visual_state() -> Dictionary:
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.definition == null:
		return {
			"sector_id": "",
			"template_name": "",
			"sector_index": 0,
			"display_name": "",
			"entry_label": "",
			"accent_color": Color(0.35, 0.95, 0.85, 0.9),
		}

	var def: SectorDefinition = lifecycle.current_sector.definition
	return {
		"sector_id": def.sector_id,
		"template_name": def.template_name,
		"sector_index": def.sector_index,
		"display_name": def.display_name,
		"entry_label": def.entry_label,
		"accent_color": def.accent_color,
		"entry_segment": def.entry_segment,
		"entry_distance": def.entry_distance,
		"exit_segment": def.exit_segment,
		"exit_distance": def.exit_distance,
	}


func is_context_menu_open() -> bool:
	return context_menu_open


func get_context_menu_labels() -> Array[String]:
	var labels: Array[String] = []
	for item in context_menu_items:
		labels.append(str(item.get("label", "")))
	return labels


func get_context_menu_actor_id() -> String:
	return context_menu_actor_id


func get_context_menu_actor_name() -> String:
	return context_menu_actor_name


func get_context_menu_target_label() -> String:
	return context_menu_target_label


func is_departure_confirmation_open() -> bool:
	return departure_confirmation_open


func get_departure_confirmation_lines() -> Array[String]:
	return departure_confirmation_lines.duplicate()


func confirm_sector_departure() -> bool:
	if not departure_confirmation_open or lifecycle == null:
		return false
	if not lifecycle.request_transition():
		if yard != null:
			yard.last_status = lifecycle.transition_blocked_reason
		departure_confirmation_lines = _build_departure_confirmation_lines()
		_hard_brake_before_exit(false)
		return false

	departure_confirmation_open = false
	departure_confirmation_lines.clear()
	rail = lifecycle.current_sector.rail
	yard = lifecycle.current_sector.yard
	interior = crew.interior
	yard.last_status = "Entered %s" % lifecycle.current_sector.definition.display_name
	_refresh_instruction_text()
	if debug_label != null:
		debug_label.text = "\n".join(get_compact_debug_lines())
	queue_redraw()
	return true


func cancel_sector_departure() -> bool:
	if not departure_confirmation_open:
		return false
	departure_confirmation_open = false
	departure_confirmation_lines.clear()
	_hard_brake_before_exit(true)
	if yard != null:
		yard.last_status = "Departure cancelled - train stopped before sector exit"
	_refresh_instruction_text()
	if debug_label != null:
		debug_label.text = "\n".join(get_compact_debug_lines())
	queue_redraw()
	return true


func get_context_menu_header_lines() -> Array[String]:
	var lines: Array[String] = []
	if context_menu_actor_name != "":
		lines.append("CREW: %s" % context_menu_actor_name)
	if context_menu_target_label != "":
		lines.append("TARGET: %s" % context_menu_target_label)
	return lines


func get_context_menu_option_position(label_fragment: String) -> Vector2:
	for index in context_menu_items.size():
		var label := str(context_menu_items[index].get("label", ""))
		if not label.contains(label_fragment):
			continue

		var rect := _get_context_menu_option_rect(index)
		return rect.position + rect.size * 0.5
	return Vector2.INF


func world_to_screen_position(world_position: Vector2) -> Vector2:
	return _get_world_draw_offset() + world_position * _get_world_draw_scale()


func get_world_bounds() -> Rect2:
	return WORLD_BOUNDS


func get_anchor_icon_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for state in crew.get_interaction_draw_states():
		var anchor_id := str(state.get("id", ""))
		var anchor_type := str(state.get("type", ""))
		states.append({
			"id": anchor_id,
			"type": anchor_type,
			"icon": _get_anchor_icon_kind(anchor_type),
			"label": _get_anchor_label(anchor_id, anchor_type, state),
			"position": state.get("position", Vector2.ZERO),
			"reserved": bool(state.get("reserved", false)),
		})
	return states


func get_task_target_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for state in crew.get_survivor_draw_states():
		var task_status := str(state.get("task_status", ""))
		if task_status != CrewSimulation.STATUS_ASSIGNED \
				and task_status != CrewSimulation.STATUS_MOVING \
				and task_status != CrewSimulation.STATUS_INTERACTING:
			continue
		if not bool(state.get("has_target", false)):
			continue

		states.append({
			"id": str(state.get("id", "")),
			"position": state.get("position", Vector2.ZERO),
			"target_position": state.get("target_position", Vector2.ZERO),
			"task_status": task_status,
			"task_type": str(state.get("task_type", "")),
		})
	return states


func get_yard_track_connection_report() -> Array[Dictionary]:
	var report: Array[Dictionary] = []
	for segment in yard.get_yard_track_draw_segments():
		var points: Array = segment.get("points", [])
		if points.size() < 2:
			continue
		var first := points[0] as Vector2
		var last := points[points.size() - 1] as Vector2
		var first_connected := _is_point_on_modeled_rail(first, 8.0)
		var last_connected := _is_point_on_modeled_rail(last, 8.0)
		report.append({
			"id": str(segment.get("id", "")),
			"connected_to_model": first_connected or last_connected,
			"has_buffer_or_join": last_connected or str(segment.get("end_condition", "")) == "buffer",
		})
	return report


func get_train_interior_draw_states() -> Array[Dictionary]:
	return interior.get_draw_states()


func get_track_visual_style() -> Dictionary:
	return {
		"draws_sleepers": true,
		"draws_parallel_rails": true,
		"straight_branch_labels": true,
		"route_color_overlay": true,
		"switch_control_labels": true,
	}


func get_switch_route_visual_states() -> Array[Dictionary]:
	var p1_active_kind := _route_kind_from_route(rail.points_route)
	var p2_active_kind := _route_kind_from_route(rail.get_yard_point_route(YardOperations.POINT_P2))
	var p3_active_kind := _route_kind_from_route(rail.get_yard_point_route(YardOperations.POINT_P3))
	var p2_state := yard.get_point_state(YardOperations.POINT_P2)
	var p3_state := yard.get_point_state(YardOperations.POINT_P3)
	var p2_position := p2_state.get("track_position", YardOperations.POINT_P2_TRACK_POSITION) as Vector2
	var p3_position := p3_state.get("track_position", YardOperations.POINT_P3_TRACK_POSITION) as Vector2

	return [
		{
			"point_id": YardOperations.POINT_P1,
			"position": RailMovement.SWITCH_POSITION,
			"control_label": "P1 controls main / siding A",
			"label_position": RailMovement.SWITCH_POSITION + Vector2(-82.0, -42.0),
			"active_kind": p1_active_kind,
			"options": [
				{
					"kind": "straight",
					"route": RailMovement.POINTS_MAIN,
					"label": _format_route_option_label("straight", "MAIN", p1_active_kind == "straight"),
					"target_segment": RailMovement.SEGMENT_MAIN_EAST,
					"active": p1_active_kind == "straight",
					"guide_start": RailMovement.SWITCH_POSITION + Vector2(10.0, -6.0),
					"guide_end": RailMovement.SWITCH_POSITION + Vector2(126.0, -6.0),
					"label_position": RailMovement.SWITCH_POSITION + Vector2(70.0, -48.0),
				},
				{
					"kind": "branch",
					"route": RailMovement.POINTS_SIDING,
					"label": _format_route_option_label("branch", "SIDING A", p1_active_kind == "branch"),
					"target_segment": RailMovement.SEGMENT_SIDING,
					"active": p1_active_kind == "branch",
					"guide_start": RailMovement.SWITCH_POSITION + Vector2(8.0, 8.0),
					"guide_end": RailMovement.SWITCH_POSITION + Vector2(132.0, 48.0),
					"label_position": RailMovement.SWITCH_POSITION + Vector2(78.0, 28.0),
				},
			],
		},
		{
			"point_id": YardOperations.POINT_P2,
			"position": p2_position,
			"control_label": "P2 controls north workshop branch",
			"label_position": p2_position + Vector2(-92.0, -102.0),
			"active_kind": p2_active_kind,
			"options": [
				{
					"kind": "straight",
					"route": RailMovement.POINTS_MAIN,
					"label": _format_route_option_label("straight", "MAIN", p2_active_kind == "straight"),
					"target_segment": RailMovement.SEGMENT_MAIN_EXIT,
					"active": p2_active_kind == "straight",
					"guide_start": p2_position + Vector2(-126.0, 8.0),
					"guide_end": p2_position + Vector2(142.0, 8.0),
					"label_position": p2_position + Vector2(44.0, 20.0),
				},
				{
					"kind": "branch",
					"route": RailMovement.POINTS_SIDING,
					"label": _format_route_option_label("branch", "NORTH W", p2_active_kind == "branch"),
					"target_segment": RailMovement.SEGMENT_SIDING_B,
					"active": p2_active_kind == "branch",
					"guide_start": p2_position + Vector2(8.0, -7.0),
					"guide_end": p2_position + Vector2(142.0, -63.0),
					"label_position": p2_position + Vector2(58.0, -92.0),
				},
			],
		},
		{
			"point_id": YardOperations.POINT_P3,
			"position": p3_position,
			"control_label": "P3 yard ladder: storage / repair",
			"label_position": p3_position + Vector2(-85.0, -72.0),
			"active_kind": p3_active_kind,
			"options": [
				{
					"kind": "straight",
					"route": RailMovement.POINTS_MAIN,
					"label": _format_route_option_label("straight", "STORAGE", p3_active_kind == "straight"),
					"target_segment": RailMovement.SEGMENT_YARD_STORAGE,
					"active": p3_active_kind == "straight",
					"guide_start": p3_position + Vector2(10.0, 0.0),
					"guide_end": p3_position + Vector2(130.0, 30.0),
					"label_position": p3_position + Vector2(60.0, -18.0),
				},
				{
					"kind": "branch",
					"route": RailMovement.POINTS_SIDING,
					"label": _format_route_option_label("branch", "REPAIR", p3_active_kind == "branch"),
					"target_segment": RailMovement.SEGMENT_YARD_REPAIR,
					"active": p3_active_kind == "branch",
					"guide_start": p3_position + Vector2(8.0, 8.0),
					"guide_end": p3_position + Vector2(104.0, 58.0),
					"label_position": p3_position + Vector2(40.0, 46.0),
				},
			],
		},
	]


func get_current_uat_step_index() -> int:
	var steps := _get_uat_step_states()
	for index in steps.size():
		if not bool(steps[index].get("done", false)):
			return index
	return max(steps.size() - 1, 0)


func get_uat_tutorial_lines() -> Array[String]:
	var lines: Array[String] = [
		"Train Scav - Sprint 6B UAT Guide",
		"Sector 0 -> Sector 1 should be obvious.",
		"Mouse-first operations",
		"Left click survivor: select",
		"Right click survivor: select + options",
		"Right click object: options for selected crew",
		"Left click menu item: confirm",
		"Drive remains keyboard: W/S Space R",
		"S starts damaged; repair before control.",
		"A survivor must be aboard L or S to drive.",
		"Coupling and uncoupling are crew tasks.",
		"Carriages now show cutaway prototype interiors.",
		"Right click connected carriage: walk inside train.",
		"P2 straight blocks the north workshop branch.",
		"Operate P2 to reach the north workshop siding.",
		"Switch labels show ACTIVE straight/branch.",
	]
	var steps := _get_uat_step_states()
	var current_step := get_current_uat_step_index()
	for index in steps.size():
		var prefix := "[ ]"
		if bool(steps[index].get("done", false)):
			prefix = "[x]"
		elif index == current_step:
			prefix = ">"
		lines.append("%s %s" % [prefix, str(steps[index].get("label", ""))])

	lines.append("Dev shortcuts remain for tests.")
	return lines


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and instruction_label != null and debug_label != null:
		_layout_ui()


func _process(delta: float) -> void:
	if rail == null:
		return
	var missing_driver := ""
	var report_missing_driver := false
	if departure_confirmation_open:
		_hard_brake_before_exit(false)
	elif not _controlled_power_has_crew():
		missing_driver = "No crew aboard %s" % rail.get_controlled_power_unit_id()
		rail.set_throttle(0.0)
		report_missing_driver = _throttle_up_held or _throttle_down_held or yard.last_status == missing_driver
	elif yard.last_status.begins_with("No crew aboard "):
		yard.last_status = ""

	if _throttle_up_held and missing_driver == "" and not departure_confirmation_open:
		rail.adjust_throttle(delta * 0.65)
	if _throttle_down_held and missing_driver == "" and not departure_confirmation_open:
		rail.adjust_throttle(-delta * 0.9)

	if not departure_confirmation_open:
		rail.step(delta, _brake_held)
	if report_missing_driver:
		rail.blocked_reason = missing_driver
		yard.last_status = missing_driver
	crew.step(delta)
	task_broker.step(delta)
	if lifecycle != null and not departure_confirmation_open:
		_check_departure_boundary()
	_refresh_instruction_text()
	debug_label.text = "\n".join(get_compact_debug_lines())
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.echo:
		return

	if departure_confirmation_open:
		match key_event.keycode:
			KEY_W, KEY_UP:
				if not key_event.pressed:
					_throttle_up_held = false
			KEY_S, KEY_DOWN:
				if not key_event.pressed:
					_throttle_down_held = false
			KEY_ENTER, KEY_KP_ENTER, KEY_Y:
				if key_event.pressed:
					confirm_sector_departure()
			KEY_ESCAPE, KEY_N:
				if key_event.pressed:
					cancel_sector_departure()
		return

	match key_event.keycode:
		KEY_1:
			if key_event.pressed:
				if crew.select_survivor("marta"):
					survivor_selection_confirmed = true
		KEY_2:
			if key_event.pressed:
				if crew.select_survivor("olek"):
					survivor_selection_confirmed = true
		KEY_3:
			if key_event.pressed:
				if crew.select_survivor("nia"):
					survivor_selection_confirmed = true
		KEY_4:
			if key_event.pressed:
				if crew.select_survivor("pavel"):
					survivor_selection_confirmed = true
		KEY_5:
			if key_event.pressed:
				if crew.select_survivor("iris"):
					survivor_selection_confirmed = true
		KEY_W, KEY_UP:
			_throttle_up_held = key_event.pressed
		KEY_S, KEY_DOWN:
			_throttle_down_held = key_event.pressed
		KEY_SPACE:
			_brake_held = key_event.pressed
		KEY_E:
			if key_event.pressed:
				crew.assign_operate_points(crew.get_selected_survivor_id())
		KEY_R:
			if key_event.pressed:
				rail.reverse_direction()
		KEY_D:
			if key_event.pressed:
				crew.assign_disembark(crew.get_selected_survivor_id())
		KEY_B:
			if key_event.pressed:
				crew.assign_board_nearest(crew.get_selected_survivor_id())
		KEY_P:
			if key_event.pressed:
				crew.assign_operate_yard_point(crew.get_selected_survivor_id(), YardOperations.POINT_P2)
		KEY_O:
			if key_event.pressed:
				crew.assign_operate_yard_point(crew.get_selected_survivor_id(), YardOperations.POINT_P1)
		KEY_U:
			if key_event.pressed:
				crew.assign_uncouple(crew.get_selected_survivor_id(), "A", "B")
		KEY_G:
			if key_event.pressed:
				crew.assign_repair_shunter(crew.get_selected_survivor_id())
		KEY_H:
			if key_event.pressed:
				crew.assign_repair_yard_control(crew.get_selected_survivor_id())
		KEY_J:
			if key_event.pressed:
				crew.assign_connect_power(crew.get_selected_survivor_id())
		KEY_K:
			if key_event.pressed:
				crew.assign_repair_point(crew.get_selected_survivor_id(), YardOperations.POINT_P3)
		KEY_Y:
			if key_event.pressed:
				yard.remote_operate_point(YardOperations.POINT_P2)
		KEY_T:
			if key_event.pressed:
				yard.remote_operate_point(YardOperations.POINT_P1)
		KEY_X:
			if key_event.pressed:
				_toggle_controlled_power_unit()
		KEY_Q:
			if key_event.pressed:
				yard.last_status = "Use right-click joint menu for crew uncoupling"
		KEY_F:
			if key_event.pressed:
				yard.last_status = "Use right-click joint menu for crew uncoupling"
		KEY_C:
			if key_event.pressed:
				crew.assign_couple_contact(crew.get_selected_survivor_id())
		KEY_V:
			if key_event.pressed and task_broker != null:
				task_broker.enabled = not task_broker.enabled
				yard.last_status = "Auto dispatch: %s" % ("ENABLED" if task_broker.enabled else "DISABLED")


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if departure_confirmation_open:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_confirm_departure_modal_at(mouse_event.position)
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if context_menu_open and _confirm_context_menu_at(mouse_event.position):
			return
		_close_context_menu()
		_select_survivor_at(mouse_event.position)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_open_context_menu(mouse_event.position)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR, true)
	draw_rect(get_playfield_rect(), BACKGROUND_COLOR.lightened(0.02), true)
	draw_set_transform(_get_world_draw_offset(), 0.0, Vector2(_get_world_draw_scale(), _get_world_draw_scale()))
	_draw_track()
	_draw_sector_entry()
	_draw_sector_exit()
	_draw_yard_auxiliary_tracks()
	_draw_switch()
	_draw_coupling_zones()
	_draw_rolling_stock()
	_draw_train_interiors()
	_draw_couplers()
	_draw_crew_interaction_anchors()
	_draw_task_targets()
	_draw_survivors()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_ui_panels()
	_draw_context_menu()
	_draw_departure_confirmation()


func _draw_sector_exit() -> void:
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.definition == null:
		return
	var def: SectorDefinition = lifecycle.current_sector.definition
	var exit_pos: Vector2 = rail.get_point_on_segment(def.exit_segment, def.exit_distance)
	var exit_color := Color(0.95, 0.35, 0.35, 0.9) if lifecycle.transition_blocked_reason != "" else Color(0.35, 0.95, 0.85, 0.9)
	draw_line(exit_pos + Vector2(0.0, -32.0), exit_pos + Vector2(0.0, 32.0), exit_color, 4.0)
	draw_string(get_theme_default_font(), exit_pos + Vector2(-36.0, -38.0), "EXIT BOUNDARY", HORIZONTAL_ALIGNMENT_CENTER, -1.0, 11, exit_color)


func _draw_sector_entry() -> void:
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.definition == null:
		return
	var def: SectorDefinition = lifecycle.current_sector.definition
	var entry_pos: Vector2 = rail.get_point_on_segment(def.entry_segment, def.entry_distance)
	var entry_color := def.accent_color
	draw_line(entry_pos + Vector2(0.0, -26.0), entry_pos + Vector2(0.0, 26.0), entry_color, 3.0)
	draw_circle(entry_pos + Vector2(0.0, -34.0), 6.0, entry_color)
	draw_string(get_theme_default_font(), entry_pos + Vector2(-44.0, -46.0), def.entry_label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 11, entry_color)


func _draw_track() -> void:
	var segments := rail.get_track_segments()
	for segment_id: String in segments:
		var points: Array = segments[segment_id]
		var color := _get_track_color(segment_id)
		_draw_track_polyline(points, color, segment_id == rail.current_segment)


func _draw_yard_auxiliary_tracks() -> void:
	for segment in yard.get_yard_track_draw_segments():
		var points: Array = segment.get("points", [])
		_draw_track_polyline(points, ROUTE_INACTIVE_COLOR.darkened(0.12), false)
		if str(segment.get("end_condition", "")) == "buffer" and points.size() >= 2:
			_draw_track_buffer_stop(points[points.size() - 2] as Vector2, points[points.size() - 1] as Vector2)


func _draw_switch() -> void:
	var switch_color := ROUTE_MAIN_COLOR
	if rail.points_route == RailMovement.POINTS_SIDING:
		switch_color = ROUTE_SIDING_COLOR

	_draw_track_switch_icon(RailMovement.SWITCH_POSITION, switch_color, "P1")
	for point_id in yard.get_point_ids():
		if point_id == YardOperations.POINT_P1:
			continue
		var point_state := yard.get_point_state(point_id)
		var color := ROUTE_MAIN_COLOR
		if str(point_state.get("route", "")) != YardOperations.ROUTE_MAIN:
			color = ROUTE_SIDING_COLOR
		if str(point_state.get("mechanical_state", "")) == YardOperations.MECHANICAL_DAMAGED:
			color = Color(0.72, 0.20, 0.18, 1.0)
		_draw_track_switch_icon(point_state.get("track_position", point_state.get("anchor", Vector2.ZERO)) as Vector2, color, point_id)
	_draw_switch_route_labels()


func _draw_track_polyline(points: Array, route_color: Color, highlighted: bool) -> void:
	if points.size() < 2:
		return

	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		draw_line(start, end, TRACK_BED_COLOR, 21.0, true)

	_draw_track_sleepers(points)
	_draw_parallel_rails(points, highlighted)
	_draw_route_centerline(points, route_color, highlighted)


func _draw_track_sleepers(points: Array) -> void:
	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		var segment := end - start
		var length := segment.length()
		if length <= 0.001:
			continue

		var tangent := segment / length
		var normal := Vector2(-tangent.y, tangent.x)
		var sleeper_distance := 0.0
		while sleeper_distance <= length:
			var center := start + tangent * sleeper_distance
			draw_line(
				center - normal * (TRACK_SLEEPER_LENGTH * 0.5),
				center + normal * (TRACK_SLEEPER_LENGTH * 0.5),
				TRACK_SLEEPER_COLOR,
				3.0,
				true
			)
			sleeper_distance += TRACK_SLEEPER_SPACING


func _draw_parallel_rails(points: Array, highlighted: bool) -> void:
	var rail_color := TRACK_INACTIVE_RAIL_COLOR
	if highlighted:
		rail_color = TRACK_RAIL_COLOR

	for index in range(points.size() - 1):
		var start := points[index] as Vector2
		var end := points[index + 1] as Vector2
		var segment := end - start
		if segment.length() <= 0.001:
			continue

		var tangent := segment.normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		draw_line(start + normal * TRACK_RAIL_OFFSET, end + normal * TRACK_RAIL_OFFSET, rail_color, 2.2, true)
		draw_line(start - normal * TRACK_RAIL_OFFSET, end - normal * TRACK_RAIL_OFFSET, rail_color, 2.2, true)


func _draw_route_centerline(points: Array, route_color: Color, highlighted: bool) -> void:
	var line_width := 1.4
	var color := route_color
	if highlighted:
		line_width = 2.6
	else:
		color = route_color.darkened(0.15)

	for index in range(points.size() - 1):
		draw_line(points[index] as Vector2, points[index + 1] as Vector2, color, line_width, true)


func _draw_switch_route_labels() -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	for switch_state in get_switch_route_visual_states():
		var control_position := switch_state.get("label_position", Vector2.ZERO) as Vector2
		_draw_route_label(font, control_position, str(switch_state.get("control_label", "")), true)
		var options: Array = switch_state.get("options", [])
		for option in options:
			var option_state := option as Dictionary
			var active := bool(option_state.get("active", false))
			var color := ROUTE_INACTIVE_COLOR
			if active:
				color = ROUTE_CURRENT_COLOR
			_draw_route_indicator(
				option_state.get("guide_start", Vector2.ZERO) as Vector2,
				option_state.get("guide_end", Vector2.ZERO) as Vector2,
				color,
				active
			)
			_draw_route_label(
				font,
				option_state.get("label_position", Vector2.ZERO) as Vector2,
				str(option_state.get("label", "")),
				active
			)


func _draw_route_indicator(start: Vector2, end: Vector2, color: Color, active: bool) -> void:
	var width := 1.8
	if active:
		width = 3.2
	draw_line(start, end, color, width, true)
	var direction_vector := (end - start).normalized()
	if direction_vector.length() <= 0.001:
		direction_vector = Vector2.RIGHT
	var normal := Vector2(-direction_vector.y, direction_vector.x)
	var arrow_size := 8.0
	var arrow := PackedVector2Array([
		end,
		end - direction_vector * arrow_size + normal * (arrow_size * 0.55),
		end - direction_vector * arrow_size - normal * (arrow_size * 0.55),
	])
	draw_colored_polygon(arrow, color)
	if active:
		draw_circle(end, 4.0, color)


func _draw_route_label(font: Font, position: Vector2, label: String, active: bool) -> void:
	if label == "":
		return

	var font_size := 12
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var padding := Vector2(6.0, 4.0)
	var rect := Rect2(position, text_size + padding * 2.0)
	var background := ROUTE_LABEL_BACKGROUND_COLOR
	var text_color := ROUTE_LABEL_DIM_TEXT_COLOR
	if active:
		background = ROUTE_LABEL_ACTIVE_BACKGROUND_COLOR
		text_color = ROUTE_LABEL_TEXT_COLOR
	draw_rect(rect, background, true)
	draw_rect(rect, ICON_STROKE_COLOR, false, 1.2)
	draw_string(
		font,
		rect.position + Vector2(padding.x, padding.y + font_size),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x - padding.x * 2.0,
		font_size,
		text_color
	)


func _draw_ui_panels() -> void:
	var playfield := get_playfield_rect()
	var panel := get_ui_panel_rect()
	var instruction_panel := get_instruction_panel_rect()
	var debug_panel := get_debug_panel_rect()

	draw_rect(playfield, PANEL_BORDER_COLOR, false, 2.0)
	draw_rect(panel, PANEL_BACKGROUND_COLOR, true)
	draw_rect(panel, PANEL_BORDER_COLOR, false, 2.0)
	draw_rect(instruction_panel, PANEL_SECTION_COLOR, true)
	draw_rect(debug_panel, PANEL_SECTION_COLOR, true)
	draw_line(
		Vector2(panel.position.x + 12.0, debug_panel.position.y - 12.0),
		Vector2(panel.end.x - 12.0, debug_panel.position.y - 12.0),
		PANEL_BORDER_COLOR,
		1.0,
		true
	)


func _draw_context_menu() -> void:
	if not context_menu_open or context_menu_items.is_empty():
		return

	var font := get_theme_default_font()
	if font == null:
		return

	var menu_rect := _get_context_menu_rect()
	draw_rect(menu_rect, MENU_BACKGROUND_COLOR, true)
	draw_rect(menu_rect, MENU_BORDER_COLOR, false, 1.5)

	var header_rect := Rect2(
		context_menu_position + Vector2(CONTEXT_MENU_PADDING, CONTEXT_MENU_PADDING),
		Vector2(CONTEXT_MENU_WIDTH - CONTEXT_MENU_PADDING * 2.0, CONTEXT_MENU_HEADER_HEIGHT)
	)
	draw_rect(header_rect, PANEL_SECTION_COLOR, true)
	draw_line(
		Vector2(header_rect.position.x, header_rect.end.y),
		Vector2(header_rect.end.x, header_rect.end.y),
		MENU_BORDER_COLOR,
		1.0,
		true
	)
	draw_string(font, header_rect.position + Vector2(10.0, 19.0), "CREW: %s" % context_menu_actor_name, HORIZONTAL_ALIGNMENT_LEFT, header_rect.size.x - 20.0, 13, SURVIVOR_SELECTED_COLOR)
	draw_string(font, header_rect.position + Vector2(10.0, 38.0), "TARGET: %s" % context_menu_target_label, HORIZONTAL_ALIGNMENT_LEFT, header_rect.size.x - 20.0, 12, MENU_TEXT_COLOR)

	for index in context_menu_items.size():
		var option_rect := _get_context_menu_option_rect(index)
		draw_rect(option_rect, MENU_ITEM_COLOR, true)
		var label := str(context_menu_items[index].get("label", ""))
		draw_string(
			font,
			option_rect.position + Vector2(10.0, 20.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			option_rect.size.x - 20.0,
			14,
			MENU_TEXT_COLOR
		)


func _draw_departure_confirmation() -> void:
	if not departure_confirmation_open:
		return

	var font := get_theme_default_font()
	if font == null:
		return

	var modal_rect := _get_departure_modal_rect()
	draw_rect(modal_rect, MODAL_BACKGROUND_COLOR, true)
	draw_rect(modal_rect, MENU_BORDER_COLOR, false, 2.0)

	var title := "Confirm Sector Departure"
	draw_string(
		font,
		modal_rect.position + Vector2(18.0, 30.0),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		modal_rect.size.x - 36.0,
		18,
		MENU_TEXT_COLOR
	)

	var y := modal_rect.position.y + 62.0
	for line in departure_confirmation_lines:
		draw_string(
			font,
			Vector2(modal_rect.position.x + 18.0, y),
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			modal_rect.size.x - 36.0,
			13,
			MENU_TEXT_COLOR
		)
		y += 20.0

	_draw_departure_button(_get_departure_confirm_rect(), "Yes - leave sector", MODAL_CONFIRM_COLOR)
	_draw_departure_button(_get_departure_cancel_rect(), "No - hard brake", MODAL_CANCEL_COLOR)


func _draw_departure_button(rect: Rect2, label: String, color: Color) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	draw_rect(rect, MODAL_BUTTON_COLOR, true)
	draw_rect(rect, color, false, 2.0)
	draw_string(
		font,
		rect.position + Vector2(12.0, 22.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x - 24.0,
		14,
		MENU_TEXT_COLOR
	)


func _draw_locomotive() -> void:
	_draw_rolling_stock()


func _draw_rolling_stock() -> void:
	for state in rail.get_unit_draw_states():
		_draw_unit(state)


func _draw_train_interiors() -> void:
	var font := get_theme_default_font()
	for state in interior.get_draw_states():
		_draw_unit_interior(state, font)


func _draw_unit_interior(state: Dictionary, font: Font) -> void:
	var unit_id := str(state.get("id", ""))
	var kind := str(state.get("interior_kind", ""))
	var position := state.get("position", Vector2.ZERO) as Vector2
	var angle := float(state.get("angle", 0.0))
	var length := float(state.get("length", 48.0))
	var transform := Transform2D(angle, position)
	var half_length := maxf(length * 0.5 - 5.0, 4.0)

	var floor_local := PackedVector2Array([
		Vector2(-half_length, -10.0),
		Vector2(half_length, -10.0),
		Vector2(half_length, 10.0),
		Vector2(-half_length, 10.0),
	])
	var floor_world := PackedVector2Array()
	for point in floor_local:
		floor_world.append(transform * point)
	draw_colored_polygon(floor_world, INTERIOR_FLOOR_COLOR)

	var aisle_start := transform * Vector2(-half_length + 3.0, 0.0)
	var aisle_end := transform * Vector2(half_length - 3.0, 0.0)
	draw_line(aisle_start, aisle_end, INTERIOR_WALKWAY_COLOR, 2.0, true)

	if bool(state.get("walkable", false)):
		draw_circle(transform * interior.get_front_door_local(unit_id), 3.6, INTERIOR_DOOR_COLOR)
		draw_circle(transform * interior.get_rear_door_local(unit_id), 3.6, INTERIOR_DOOR_COLOR)
	else:
		draw_line(transform * Vector2(-8.0, -7.0), transform * Vector2(8.0, 7.0), INTERIOR_FIXTURE_COLOR, 2.5, true)
		draw_line(transform * Vector2(-8.0, 7.0), transform * Vector2(8.0, -7.0), INTERIOR_FIXTURE_COLOR, 2.5, true)

	match kind:
		TrainInterior.KIND_BUNK:
			_draw_interior_bunk_fixtures(transform, length)
		TrainInterior.KIND_STORAGE:
			_draw_interior_storage_fixtures(transform, length)
		TrainInterior.KIND_WORKSHOP:
			_draw_interior_workshop_fixtures(transform, length)
		TrainInterior.KIND_LOCOMOTIVE, TrainInterior.KIND_SHUNTER:
			_draw_interior_controls(transform, length)

	if font != null:
		var normal := Vector2.UP.rotated(angle)
		var label_position := position + normal * 23.0
		var label := "%s %s" % [unit_id, str(state.get("interior_label", ""))]
		draw_string(font, label_position + Vector2(-24.0, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, 90.0, 10, INTERIOR_LABEL_COLOR)


func _draw_interior_bunk_fixtures(transform: Transform2D, length: float) -> void:
	var usable := maxf(length * 0.5 - 12.0, 8.0)
	for x in [-usable * 0.55, usable * 0.35]:
		draw_line(transform * Vector2(x - 7.0, -7.0), transform * Vector2(x + 7.0, -7.0), INTERIOR_FIXTURE_COLOR, 4.0, true)
		draw_line(transform * Vector2(x - 7.0, 7.0), transform * Vector2(x + 7.0, 7.0), INTERIOR_FIXTURE_COLOR, 4.0, true)


func _draw_interior_storage_fixtures(transform: Transform2D, length: float) -> void:
	var usable := maxf(length * 0.5 - 12.0, 8.0)
	for x in [-usable * 0.55, 0.0, usable * 0.55]:
		draw_circle(transform * Vector2(x, -6.5), 3.5, INTERIOR_FIXTURE_COLOR)
		draw_circle(transform * Vector2(x, 6.5), 3.5, INTERIOR_FIXTURE_COLOR)


func _draw_interior_workshop_fixtures(transform: Transform2D, length: float) -> void:
	var half := maxf(length * 0.5 - 12.0, 8.0)
	draw_line(transform * Vector2(-half, -7.0), transform * Vector2(half, -7.0), INTERIOR_FIXTURE_COLOR, 4.0, true)
	for x in [-half * 0.55, 0.0, half * 0.55]:
		draw_circle(transform * Vector2(x, 7.0), 2.8, INTERIOR_FIXTURE_COLOR)


func _draw_interior_controls(transform: Transform2D, length: float) -> void:
	var panel_x := maxf(length * 0.5 - 14.0, 6.0)
	draw_line(transform * Vector2(panel_x - 7.0, -7.0), transform * Vector2(panel_x + 1.0, -7.0), INTERIOR_FIXTURE_COLOR, 3.0, true)
	draw_circle(transform * Vector2(panel_x - 2.0, 6.0), 3.0, INTERIOR_FIXTURE_COLOR)


func _draw_couplers() -> void:
	var active_states: Array[Dictionary] = []
	for state in rail.get_unit_draw_states():
		var ends := _get_unit_endpoints(state)
		draw_circle(ends["front"], 5.0, COUPLER_COLOR)
		draw_circle(ends["rear"], 5.0, COUPLER_COLOR)
		if bool(state["active"]):
			active_states.append(state)

	for index in active_states.size() - 1:
		var left_ends := _get_unit_endpoints(active_states[index])
		var right_ends := _get_unit_endpoints(active_states[index + 1])
		draw_line(left_ends["rear"], right_ends["front"], COUPLER_COLOR, 3.0, true)


func _draw_coupling_zones() -> void:
	var active_states: Array[Dictionary] = []
	var detached_states: Array[Dictionary] = []
	for state in rail.get_unit_draw_states():
		if bool(state["active"]):
			active_states.append(state)
		else:
			detached_states.append(state)

	if not active_states.is_empty():
		var active_front := _get_unit_endpoints(active_states[0])["front"] as Vector2
		var active_rear := _get_unit_endpoints(active_states[active_states.size() - 1])["rear"] as Vector2
		draw_circle(active_front, RailMovement.COUPLING_RANGE, ACTIVE_COUPLING_ZONE_COLOR)
		draw_circle(active_rear, RailMovement.COUPLING_RANGE, ACTIVE_COUPLING_ZONE_COLOR)

	for state in detached_states:
		var detached_rear := _get_unit_endpoints(state)["rear"] as Vector2
		var detached_front := _get_unit_endpoints(state)["front"] as Vector2
		draw_circle(detached_rear, RailMovement.COUPLING_RANGE, DETACHED_COUPLING_ZONE_COLOR)
		draw_circle(detached_front, RailMovement.COUPLING_RANGE, DETACHED_COUPLING_ZONE_COLOR)


func _draw_unit(state: Dictionary) -> void:
	var pos := state["position"] as Vector2
	var angle := float(state["angle"])
	var unit_length := float(state["length"])
	var transform := Transform2D(angle, pos)
	var body := _get_unit_polygon(str(state["type"]), unit_length)
	var transformed_body := PackedVector2Array()
	for point in body:
		transformed_body.append(transform * point)

	draw_colored_polygon(transformed_body, _get_unit_color(str(state["type"]), bool(state["active"])))
	var outline := PackedVector2Array(transformed_body)
	outline.append(transformed_body[0])
	draw_polyline(outline, Color(0.08, 0.08, 0.08, 1.0), 2.5, true)
	if str(state["type"]) == RailMovement.UNIT_LOCOMOTIVE or str(state["type"]) == RailMovement.UNIT_SHUNTER:
		_draw_locomotive_indicator(state)
	_draw_unit_label(state)


func _draw_locomotive_indicator(state: Dictionary) -> void:
	var ends := _get_unit_endpoints(state)
	var pos := state["position"] as Vector2
	var angle := float(state["angle"])
	var tangent := Vector2.RIGHT.rotated(angle)
	var normal := Vector2.UP.rotated(angle)
	var cab_center := pos - tangent * 12.0
	var cab_half_length := 10.0
	var cab_half_width := 9.0
	var cab := PackedVector2Array([
		cab_center - tangent * cab_half_length - normal * cab_half_width,
		cab_center + tangent * cab_half_length - normal * cab_half_width,
		cab_center + tangent * cab_half_length + normal * cab_half_width,
		cab_center - tangent * cab_half_length + normal * cab_half_width,
	])

	draw_colored_polygon(cab, LOCOMOTIVE_CAB_COLOR)
	draw_circle(ends["front"], 6.5, LOCOMOTIVE_HEADLIGHT_COLOR)


func _draw_unit_label(state: Dictionary) -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	var pos := state["position"] as Vector2
	var unit_id := str(state["id"])
	draw_string(font, pos + Vector2(-7.0, 6.0), unit_id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, UNIT_LABEL_COLOR)


func _draw_crew_interaction_anchors() -> void:
	for state in get_anchor_icon_states():
		var position := state.get("position", Vector2.ZERO) as Vector2
		var icon := str(state.get("icon", ""))
		var color := _get_anchor_icon_color(icon)
		if bool(state.get("reserved", false)):
			color = RESERVED_ANCHOR_COLOR

		_draw_anchor_icon(position, icon, color)
		_draw_anchor_label(position, str(state.get("label", "")))


func _draw_task_targets() -> void:
	for state in get_task_target_draw_states():
		var position := state.get("position", Vector2.ZERO) as Vector2
		var target := state.get("target_position", Vector2.ZERO) as Vector2
		draw_line(position, target, TASK_TARGET_COLOR, 2.0, true)
		draw_circle(target, 5.0, TASK_TARGET_COLOR)


func _draw_survivors() -> void:
	var font := get_theme_default_font()
	for state in crew.get_survivor_draw_states():
		_draw_survivor(state, font)


func _draw_survivor(state: Dictionary, font: Font) -> void:
	var position := state.get("position", Vector2.ZERO) as Vector2
	var color := SURVIVOR_ABOARD_COLOR
	if str(state.get("spatial_state", "")) == CrewSimulation.SPATIAL_YARD:
		color = SURVIVOR_YARD_COLOR

	draw_circle(position, 8.0, color)
	draw_arc(position, 9.5, 0.0, TAU, 24, Color(0.05, 0.05, 0.05, 1.0), 2.0)
	var selected := bool(state.get("selected", false))
	if selected:
		draw_circle(position, 17.0, SURVIVOR_SELECTED_HALO_COLOR)
		draw_arc(position, 15.0, 0.0, TAU, 28, SURVIVOR_SELECTED_COLOR, 3.0)

	if font != null:
		var name := str(state.get("name", "?"))
		draw_string(font, position + Vector2(-10.0, -13.0), name.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, UNIT_LABEL_COLOR)
		if selected:
			draw_string(font, position + Vector2(14.0, 5.0), name, HORIZONTAL_ALIGNMENT_LEFT, 90.0, 12, SURVIVOR_SELECTED_COLOR)


func _draw_anchor_icon(position: Vector2, icon: String, color: Color) -> void:
	draw_circle(position, 14.0, ICON_BACKGROUND_COLOR)
	draw_arc(position, 15.0, 0.0, TAU, 28, ICON_STROKE_COLOR, 2.0)
	match icon:
		"switch":
			_draw_switch_anchor_icon(position, color)
		"power":
			_draw_power_anchor_icon(position, color)
		"repair":
			_draw_repair_anchor_icon(position, color)
		"joint":
			_draw_joint_anchor_icon(position, color)
		_:
			draw_circle(position, 6.0, color)


func _draw_switch_anchor_icon(position: Vector2, color: Color) -> void:
	draw_line(position + Vector2(-8.0, 7.0), position + Vector2(8.0, -7.0), color, 3.0, true)
	draw_line(position + Vector2(-7.0, 5.0), position + Vector2(8.0, 7.0), ICON_STROKE_COLOR, 2.0, true)
	draw_circle(position + Vector2(8.0, -7.0), 3.0, color)


func _draw_power_anchor_icon(position: Vector2, color: Color) -> void:
	var bolt := PackedVector2Array([
		position + Vector2(-2.0, -10.0),
		position + Vector2(-8.0, 2.0),
		position + Vector2(-1.0, 2.0),
		position + Vector2(-4.0, 10.0),
		position + Vector2(8.0, -3.0),
		position + Vector2(1.0, -3.0),
	])
	draw_colored_polygon(bolt, color)
	draw_polyline(PackedVector2Array([position + Vector2(-7.0, -11.0), position + Vector2(7.0, -11.0)]), ICON_STROKE_COLOR, 2.0, true)


func _draw_repair_anchor_icon(position: Vector2, color: Color) -> void:
	draw_line(position + Vector2(-7.0, 8.0), position + Vector2(8.0, -7.0), color, 4.0, true)
	draw_line(position + Vector2(5.0, -10.0), position + Vector2(11.0, -4.0), color, 3.0, true)
	draw_line(position + Vector2(-10.0, 6.0), position + Vector2(-5.0, 11.0), ICON_STROKE_COLOR, 2.0, true)


func _draw_joint_anchor_icon(position: Vector2, color: Color) -> void:
	draw_arc(position + Vector2(-5.0, 0.0), 5.0, -PI * 0.45, PI * 0.45, 12, color, 2.5)
	draw_arc(position + Vector2(5.0, 0.0), 5.0, PI * 0.55, PI * 1.45, 12, color, 2.5)
	draw_line(position + Vector2(-2.0, -8.0), position + Vector2(2.0, 8.0), ICON_STROKE_COLOR, 2.0, true)


func _draw_anchor_label(position: Vector2, label: String) -> void:
	if label == "":
		return
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(font, position + Vector2(16.0, -9.0), label, HORIZONTAL_ALIGNMENT_LEFT, 84.0, 12, ICON_LABEL_COLOR)


func _draw_track_switch_icon(position: Vector2, color: Color, label: String) -> void:
	draw_rect(Rect2(position - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), color, true)
	draw_rect(Rect2(position - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), ICON_STROKE_COLOR, false, 2.0)
	draw_line(position + Vector2(-6.0, 5.0), position + Vector2(7.0, -6.0), ICON_STROKE_COLOR, 2.0, true)
	draw_line(position + Vector2(-6.0, 5.0), position + Vector2(7.0, 6.0), ICON_STROKE_COLOR, 2.0, true)
	_draw_anchor_label(position + Vector2(8.0, 4.0), label)


func _draw_track_buffer_stop(previous: Vector2, end: Vector2) -> void:
	var tangent := (end - previous).normalized()
	if tangent.length() <= 0.001:
		tangent = Vector2.RIGHT
	var normal := Vector2(-tangent.y, tangent.x)
	draw_line(end - normal * 14.0, end + normal * 14.0, Color(0.70, 0.34, 0.22, 1.0), 5.0, true)
	draw_line(end - normal * 10.0 - tangent * 8.0, end + normal * 10.0 - tangent * 8.0, Color(0.18, 0.12, 0.10, 1.0), 3.0, true)


func _get_anchor_icon_color(icon: String) -> Color:
	match icon:
		"switch":
			return POINTS_ANCHOR_COLOR
		"power":
			return POWER_ANCHOR_COLOR
		"repair":
			return REPAIR_ANCHOR_COLOR
		"joint":
			return JOINT_ANCHOR_COLOR
	return ROUTE_INACTIVE_COLOR


func _get_unit_polygon(unit_type: String, unit_length: float) -> PackedVector2Array:
	var half_length := unit_length * 0.5
	var half_width := UNIT_WIDTH * 0.5
	if unit_type == RailMovement.UNIT_LOCOMOTIVE or unit_type == RailMovement.UNIT_SHUNTER:
		return PackedVector2Array([
			Vector2(-half_length, -half_width),
			Vector2(half_length - 12.0, -half_width),
			Vector2(half_length, 0.0),
			Vector2(half_length - 12.0, half_width),
			Vector2(-half_length, half_width),
		])

	return PackedVector2Array([
		Vector2(-half_length, -half_width),
		Vector2(half_length, -half_width),
		Vector2(half_length, half_width),
		Vector2(-half_length, half_width),
	])


func _get_unit_color(unit_type: String, active: bool) -> Color:
	var color := Color(0.78, 0.78, 0.78, 1.0)
	match unit_type:
		RailMovement.UNIT_LOCOMOTIVE:
			color = Color(0.82, 0.18, 0.16, 1.0)
		RailMovement.UNIT_SHUNTER:
			color = Color(0.18, 0.42, 0.84, 1.0)
		RailMovement.UNIT_FLATBED:
			color = Color(0.58, 0.62, 0.68, 1.0)
		RailMovement.UNIT_BOXCAR:
			color = Color(0.38, 0.72, 0.40, 1.0)
		RailMovement.UNIT_TANKER:
			color = Color(0.78, 0.68, 0.28, 1.0)
		RailMovement.UNIT_WORKSHOP:
			color = Color(0.66, 0.36, 0.78, 1.0)

	if not active:
		color = color.darkened(0.35)
	return color


func _get_unit_endpoints(state: Dictionary) -> Dictionary:
	var pos := state["position"] as Vector2
	var angle := float(state["angle"])
	var tangent := Vector2.RIGHT.rotated(angle)
	var half_length := float(state["length"]) * 0.5
	return {
		"front": pos + tangent * half_length,
		"rear": pos - tangent * half_length,
	}


func _get_track_color(segment_id: String) -> Color:
	if segment_id == rail.current_segment:
		return ROUTE_CURRENT_COLOR
	if segment_id == RailMovement.SEGMENT_MAIN_EAST and rail.points_route == RailMovement.POINTS_MAIN:
		return ROUTE_MAIN_COLOR
	if segment_id == RailMovement.SEGMENT_MAIN_EXIT and rail.get_yard_point_route(YardOperations.POINT_P2) == RailMovement.POINTS_MAIN:
		return ROUTE_MAIN_COLOR
	if segment_id == RailMovement.SEGMENT_SIDING and rail.points_route == RailMovement.POINTS_SIDING:
		return ROUTE_SIDING_COLOR
	if segment_id == RailMovement.SEGMENT_SIDING_B and rail.get_yard_point_route(YardOperations.POINT_P2) == RailMovement.POINTS_SIDING:
		return ROUTE_SIDING_COLOR
	return ROUTE_INACTIVE_COLOR


func _route_kind_from_route(route: String) -> String:
	if route == RailMovement.POINTS_MAIN or route == YardOperations.ROUTE_MAIN:
		return "straight"
	return "branch"


func _format_route_option_label(kind: String, destination: String, active: bool) -> String:
	var prefix := kind.to_upper()
	if active:
		prefix = "ACTIVE %s" % prefix
	return "%s: %s" % [prefix, destination]


func _refresh_instruction_text() -> void:
	if instruction_label == null:
		return
	instruction_label.text = "\n".join(get_uat_tutorial_lines())


func _get_uat_step_states() -> Array[Dictionary]:
	return [
		{
			"label": "Select a survivor",
			"done": survivor_selection_confirmed,
		},
		{
			"label": "Right click P2 -> Operate P2",
			"done": rail.get_yard_point_route(YardOperations.POINT_P2) == RailMovement.POINTS_SIDING,
		},
		{
			"label": "Drive to W contact",
			"done": rail.get_active_consist_ids().has("W") or not rail.get_last_contact_anchor().is_empty(),
		},
		{
			"label": "Right click W -> crew coupling",
			"done": rail.get_active_consist_ids().has("W"),
		},
		{
			"label": "Repair shunter S",
			"done": rail.get_powered_unit_condition("S") == RailMovement.CONDITION_OPERATIONAL,
		},
		{
			"label": "Board shunter S",
			"done": crew.has_survivor_aboard_unit("S"),
		},
		{
			"label": "Right click S -> Control shunter S",
			"done": rail.get_controlled_power_unit_id() == "S",
		},
	]


func _get_anchor_icon_kind(anchor_type: String) -> String:
	if anchor_type == CrewSimulation.TASK_UNCOUPLE or anchor_type == CrewSimulation.TASK_COUPLE:
		return "joint"
	if anchor_type == CrewSimulation.TASK_OPERATE_POINTS or anchor_type == "yard_point":
		return "switch"
	if anchor_type == CrewSimulation.TASK_CONNECT_POWER or anchor_type == "connect_power":
		return "power"
	if anchor_type == CrewSimulation.TASK_REPAIR_SHUNTER \
			or anchor_type == CrewSimulation.TASK_REPAIR_YARD_CONTROL \
			or anchor_type == CrewSimulation.TASK_REPAIR_POINT \
			or anchor_type == "repair_shunter" \
			or anchor_type == "repair_yard_control":
		return "repair"
	return ""


func _get_anchor_label(anchor_id: String, anchor_type: String, state: Dictionary) -> String:
	if anchor_type == CrewSimulation.TASK_UNCOUPLE:
		return anchor_id
	if anchor_type == CrewSimulation.TASK_COUPLE:
		return "Couple"
	if anchor_id == YardOperations.POINT_P1 or anchor_id == YardOperations.POINT_P2 or anchor_id == YardOperations.POINT_P3:
		return anchor_id
	if anchor_id == "yard_control":
		return "Control"
	if anchor_id == "yard_power":
		return "Power"
	if anchor_id == "shunter":
		if str(state.get("condition", "")) == RailMovement.CONDITION_OPERATIONAL:
			return "S"
		return "Fix S"
	if anchor_type == CrewSimulation.TASK_OPERATE_POINTS:
		return "P1"
	return anchor_id


func _open_context_menu(screen_position: Vector2) -> void:
	if not get_playfield_rect().has_point(screen_position):
		_close_context_menu()
		queue_redraw()
		return

	# Right-clicking a survivor means "this is the actor". Select them BEFORE
	# building the menu so the visible selection, menu header and task actor can
	# never silently refer to different people.
	var clicked_survivor_id := _get_survivor_id_at_screen_position(screen_position, 11.0)
	if clicked_survivor_id != "":
		if crew.select_survivor(clicked_survivor_id):
			survivor_selection_confirmed = true

	context_menu_actor_id = crew.get_selected_survivor_id()
	var actor_state := crew.get_survivor_state(context_menu_actor_id)
	context_menu_actor_name = str(actor_state.get("name", "survivor"))
	var world_position := _screen_to_world(screen_position)
	context_menu_target_label = _describe_context_target(world_position, clicked_survivor_id)

	context_menu_items = _build_context_menu_items(world_position)
	context_menu_open = not context_menu_items.is_empty()
	context_menu_position = _clamp_context_menu_position(screen_position)
	if not context_menu_open:
		_close_context_menu()
	queue_redraw()


func _confirm_context_menu_at(screen_position: Vector2) -> bool:
	if not context_menu_open:
		return false

	for index in context_menu_items.size():
		if not _get_context_menu_option_rect(index).has_point(screen_position):
			continue

		# The item carries the actor captured when the menu was opened. This avoids
		# a stale/global-selection race if selection changes before confirmation.
		var item := context_menu_items[index].duplicate(true)
		_close_context_menu()
		_execute_context_action(item)
		queue_redraw()
		return true

	if _get_context_menu_rect().has_point(screen_position):
		return true

	_close_context_menu()
	queue_redraw()
	return false


func _build_context_menu_items(world_position: Vector2) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	_add_survivor_context_items(items)
	_add_point_context_items(items, world_position)
	_add_infrastructure_context_items(items, world_position)
	_add_shunter_context_items(items, world_position)
	_add_powered_control_context_items(items, world_position)
	_add_interior_context_items(items, world_position)
	_add_joint_context_items(items, world_position)
	_add_coupling_context_item(items, world_position)
	if _get_unit_id_near_world_position(world_position) == "":
		_add_context_item(items, "Move %s here" % _get_selected_survivor_name(), "move", {
			"target_position": world_position,
		})
	return items


func _add_survivor_context_items(items: Array[Dictionary]) -> void:
	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	if selected.is_empty():
		return

	var selected_name := str(selected.get("name", _get_selected_survivor_name()))
	if str(selected.get("spatial_state", "")) == CrewSimulation.SPATIAL_ABOARD:
		_add_context_item(items, "Disembark %s" % selected_name, "disembark", {})
	else:
		_add_context_item(items, "Board nearest train", "board_nearest", {})


func _add_point_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	for point_id in yard.get_point_ids():
		var point_state := yard.get_point_state(point_id)
		var anchor := point_state.get("anchor", Vector2.ZERO) as Vector2
		if world_position.distance_to(anchor) > CONTEXT_TARGET_RADIUS:
			continue

		if str(point_state.get("mechanical_state", "")) == YardOperations.MECHANICAL_DAMAGED:
			_add_context_item(items, "Repair %s" % point_id, "repair_point", {
				"point_id": point_id,
			})
		else:
			_add_context_item(items, "Operate %s" % point_id, "operate_yard_point", {
				"point_id": point_id,
			})


func _add_infrastructure_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	var yard_control := yard.get_yard_control_state()
	var repair_anchor := yard_control.get("repair_anchor", Vector2.ZERO) as Vector2
	if world_position.distance_to(repair_anchor) <= CONTEXT_TARGET_RADIUS:
		if str(yard_control.get("condition", "")) != YardOperations.CONTROL_REPAIRED:
			_add_context_item(items, "Repair yard control", "repair_yard_control", {})

	var power_anchor := yard_control.get("power_anchor", Vector2.ZERO) as Vector2
	if world_position.distance_to(power_anchor) <= CONTEXT_TARGET_RADIUS:
		if bool(yard_control.get("powered", false)):
			_add_context_item(items, "Disconnect yard power", "disconnect_power", {})
		else:
			_add_context_item(items, "Connect train power", "connect_power", {})


func _add_shunter_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	var shunter_anchor := yard.get_repair_anchor("shunter")
	var near_shunter_anchor := world_position.distance_to(shunter_anchor) <= CONTEXT_TARGET_RADIUS
	var shunter_state := _get_unit_draw_state("S")
	var near_shunter_unit := false
	if not shunter_state.is_empty():
		near_shunter_unit = world_position.distance_to(shunter_state.get("position", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS
	if not near_shunter_anchor and not near_shunter_unit:
		return

	var shunter := yard.get_shunter_state()
	if str(shunter.get("condition", "")) != RailMovement.CONDITION_OPERATIONAL:
		_add_context_item(items, "Repair shunter S", "repair_shunter", {})
	elif crew.has_survivor_aboard_unit("S"):
		_add_context_item(items, "Control shunter S", "select_power", {
			"unit_id": "S",
		})
	else:
		_add_board_unit_context_item(items, "S")


func _add_powered_control_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	for unit_id in ["L", "S"]:
		var unit_state := _get_unit_draw_state(unit_id)
		if unit_state.is_empty():
			continue
		if world_position.distance_to(unit_state.get("position", Vector2.ZERO) as Vector2) > CONTEXT_TARGET_RADIUS:
			continue
		if not rail.is_powered_unit(unit_id):
			continue
		if rail.get_powered_unit_condition(unit_id) != RailMovement.CONDITION_OPERATIONAL:
			continue

		if not crew.has_survivor_aboard_unit(unit_id):
			_add_board_unit_context_item(items, unit_id)
			continue

		var label := "Control %s" % unit_id
		if unit_id == "L":
			label = "Control main locomotive L"
		elif unit_id == "S":
			label = "Control shunter S"
		_add_context_item(items, label, "select_power", {
			"unit_id": unit_id,
		})


func _add_interior_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	if selected.is_empty() or str(selected.get("spatial_state", "")) != CrewSimulation.SPATIAL_ABOARD:
		return

	var target_unit := _get_unit_id_near_world_position(world_position)
	if target_unit == "" or not interior.is_walkable_unit(target_unit):
		return

	var host_unit := str(selected.get("host_unit", ""))
	if not interior.can_walk_between(host_unit, target_unit):
		return

	var selected_name := str(selected.get("name", _get_selected_survivor_name()))
	var destination := interior.get_unit_interior_label(target_unit)
	var label := "Walk %s to %s %s" % [selected_name, target_unit, destination]
	if host_unit == target_unit:
		label = "Move %s inside %s %s" % [selected_name, target_unit, destination]
	_add_context_item(items, label, "move_aboard", {
		"unit_id": target_unit,
		"target_local": _get_unit_local_position_for_world(target_unit, world_position),
	})


func _add_board_unit_context_item(items: Array[Dictionary], unit_id: String) -> void:
	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	if selected.is_empty():
		return
	if str(selected.get("spatial_state", "")) != CrewSimulation.SPATIAL_YARD:
		return
	if not interior.is_boardable_unit(unit_id):
		return

	var label := "Board %s" % unit_id
	if unit_id == "S":
		label = "Board shunter S"
	elif unit_id == "L":
		label = "Board main locomotive L"
	_add_context_item(items, label, "board_unit", {
		"unit_id": unit_id,
	})


func _add_joint_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	for joint in rail.get_coupled_joints():
		var anchor := joint.get("anchor", Vector2.ZERO) as Vector2
		var joint_position := joint.get("position", anchor) as Vector2
		if world_position.distance_to(anchor) > CONTEXT_TARGET_RADIUS \
				and world_position.distance_to(joint_position) > CONTEXT_TARGET_RADIUS:
			continue

		var front_unit := str(joint.get("front_unit", ""))
		var rear_unit := str(joint.get("rear_unit", ""))
		_add_context_item(items, "Uncouple %s/%s" % [front_unit, rear_unit], "uncouple", {
			"front_unit": front_unit,
			"rear_unit": rear_unit,
		})


func _add_coupling_context_item(items: Array[Dictionary], world_position: Vector2) -> void:
	var contact_anchor := rail.get_last_contact_anchor()
	if contact_anchor.is_empty():
		return

	var anchor := contact_anchor.get("anchor", Vector2.ZERO) as Vector2
	var position := contact_anchor.get("position", anchor) as Vector2
	var active_state := _get_unit_draw_state(str(contact_anchor.get("active_unit", "")))
	var detached_state := _get_unit_draw_state(str(contact_anchor.get("detached_unit", "")))
	var near_contact := world_position.distance_to(anchor) <= CONTEXT_TARGET_RADIUS \
		or world_position.distance_to(position) <= CONTEXT_TARGET_RADIUS
	if not active_state.is_empty():
		near_contact = near_contact or world_position.distance_to(active_state.get("position", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS
	if not detached_state.is_empty():
		near_contact = near_contact or world_position.distance_to(detached_state.get("position", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS
	if not near_contact:
		return

	_add_context_item(items, _get_coupling_context_label(contact_anchor), "couple", {})


func _add_context_item(items: Array[Dictionary], label: String, action: String, data: Dictionary) -> void:
	for item in items:
		if str(item.get("label", "")) == label:
			return

	var next_item := data.duplicate(true)
	next_item["label"] = label
	next_item["action"] = action
	next_item["actor_id"] = context_menu_actor_id
	items.append(next_item)


func _get_coupling_context_label(contact: Dictionary) -> String:
	var active_unit := str(contact.get("active_unit", "?"))
	var detached_unit := str(contact.get("detached_unit", "?"))
	var active_end := str(contact.get("active_end", "coupler"))
	var detached_end := str(contact.get("detached_end", "coupler"))
	return "Couple %s %s / %s %s" % [active_unit, active_end, detached_unit, detached_end]


func _execute_context_action(item: Dictionary) -> void:
	var selected_id := str(item.get("actor_id", crew.get_selected_survivor_id()))
	match str(item.get("action", "")):
		"move":
			crew.assign_move(selected_id, item.get("target_position", Vector2.ZERO) as Vector2)
		"disembark":
			crew.assign_disembark(selected_id)
		"board_nearest":
			crew.assign_board_nearest(selected_id)
		"board_unit":
			crew.assign_board(selected_id, str(item.get("unit_id", "")))
		"move_aboard":
			crew.assign_move_aboard(selected_id, str(item.get("unit_id", "")), item.get("target_local", Vector2.ZERO) as Vector2)
		"operate_yard_point":
			crew.assign_operate_yard_point(selected_id, str(item.get("point_id", "")))
		"repair_point":
			crew.assign_repair_point(selected_id, str(item.get("point_id", "")))
		"repair_yard_control":
			crew.assign_repair_yard_control(selected_id)
		"connect_power":
			crew.assign_connect_power(selected_id)
		"disconnect_power":
			yard.disconnect_power()
		"repair_shunter":
			crew.assign_repair_shunter(selected_id)
		"select_power":
			_select_powered_control_with_driver(str(item.get("unit_id", "")))
		"uncouple":
			crew.assign_uncouple(selected_id, str(item.get("front_unit", "")), str(item.get("rear_unit", "")))
		"couple":
			crew.assign_couple_contact(selected_id)


func _get_context_menu_rect() -> Rect2:
	return Rect2(context_menu_position, _get_context_menu_size())


func _get_context_menu_option_rect(index: int) -> Rect2:
	return Rect2(
		context_menu_position + Vector2(
			CONTEXT_MENU_PADDING,
			CONTEXT_MENU_PADDING + CONTEXT_MENU_HEADER_HEIGHT + CONTEXT_MENU_ITEM_HEIGHT * float(index)
		),
		Vector2(CONTEXT_MENU_WIDTH - CONTEXT_MENU_PADDING * 2.0, CONTEXT_MENU_ITEM_HEIGHT)
	)


func _get_context_menu_size() -> Vector2:
	return Vector2(
		CONTEXT_MENU_WIDTH,
		CONTEXT_MENU_PADDING * 2.0 + CONTEXT_MENU_HEADER_HEIGHT + CONTEXT_MENU_ITEM_HEIGHT * float(context_menu_items.size())
	)


func _get_departure_modal_rect() -> Rect2:
	var playfield := get_playfield_rect()
	var modal_size := Vector2(minf(460.0, playfield.size.x - 48.0), 250.0)
	return Rect2(playfield.position + (playfield.size - modal_size) * 0.5, modal_size)


func _get_departure_confirm_rect() -> Rect2:
	var modal := _get_departure_modal_rect()
	var button_size := Vector2((modal.size.x - 54.0) * 0.5, 34.0)
	return Rect2(Vector2(modal.position.x + 18.0, modal.end.y - 52.0), button_size)


func _get_departure_cancel_rect() -> Rect2:
	var modal := _get_departure_modal_rect()
	var button_size := Vector2((modal.size.x - 54.0) * 0.5, 34.0)
	return Rect2(Vector2(modal.position.x + 36.0 + button_size.x, modal.end.y - 52.0), button_size)


func _confirm_departure_modal_at(screen_position: Vector2) -> bool:
	if _get_departure_confirm_rect().has_point(screen_position):
		return confirm_sector_departure()
	if _get_departure_cancel_rect().has_point(screen_position):
		return cancel_sector_departure()
	return _get_departure_modal_rect().has_point(screen_position)


func _clamp_context_menu_position(requested_position: Vector2) -> Vector2:
	var playfield := get_playfield_rect()
	var menu_size := _get_context_menu_size()
	return Vector2(
		clampf(requested_position.x, playfield.position.x, maxf(playfield.position.x, playfield.end.x - menu_size.x)),
		clampf(requested_position.y, playfield.position.y, maxf(playfield.position.y, playfield.end.y - menu_size.y))
	)


func _close_context_menu() -> void:
	context_menu_open = false
	context_menu_items.clear()
	context_menu_actor_id = ""
	context_menu_actor_name = ""
	context_menu_target_label = ""


func _describe_context_target(world_position: Vector2, clicked_survivor_id: String = "") -> String:
	if clicked_survivor_id != "":
		var survivor := crew.get_survivor_state(clicked_survivor_id)
		return str(survivor.get("name", clicked_survivor_id))

	for point_id in yard.get_point_ids():
		var anchor := yard.get_point_anchor(point_id)
		if world_position.distance_to(anchor) <= CONTEXT_TARGET_RADIUS:
			return point_id

	var yard_control := yard.get_yard_control_state()
	if world_position.distance_to(yard_control.get("repair_anchor", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS:
		return "Yard control"
	if world_position.distance_to(yard_control.get("power_anchor", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS:
		return "Yard power"

	var target_unit := _get_unit_id_near_world_position(world_position)
	if target_unit != "":
		return "%s (%s interior)" % [target_unit, interior.get_unit_interior_label(target_unit)]

	for joint in rail.get_coupled_joints():
		var anchor := joint.get("anchor", Vector2.ZERO) as Vector2
		if world_position.distance_to(anchor) <= CONTEXT_TARGET_RADIUS:
			return "Joint %s/%s" % [str(joint.get("front_unit", "?")), str(joint.get("rear_unit", "?"))]

	var contact := rail.get_last_contact_anchor()
	if not contact.is_empty():
		var contact_position := contact.get("anchor", contact.get("position", Vector2.ZERO)) as Vector2
		if world_position.distance_to(contact_position) <= CONTEXT_TARGET_RADIUS:
			return "Coupling contact"

	return "Ground"


func _get_selected_survivor_name() -> String:
	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	if selected.is_empty():
		return "survivor"
	return str(selected.get("name", "survivor"))


func _get_unit_draw_state(unit_id: String) -> Dictionary:
	for state in rail.get_unit_draw_states():
		if str(state.get("id", "")) == unit_id:
			return state
	return {}


func _get_unit_local_position_for_world(unit_id: String, world_position: Vector2) -> Vector2:
	var state := _get_unit_draw_state(unit_id)
	if state.is_empty():
		return Vector2.ZERO
	var transform := Transform2D(float(state.get("angle", 0.0)), state.get("position", Vector2.ZERO) as Vector2)
	var local_position := transform.affine_inverse() * world_position
	return interior.clamp_local_position(unit_id, local_position)


func _get_unit_id_near_world_position(world_position: Vector2) -> String:
	for state in rail.get_unit_draw_states():
		var unit_position := state.get("position", Vector2.ZERO) as Vector2
		var angle := float(state.get("angle", 0.0))
		var inverse := Transform2D(angle, unit_position).affine_inverse()
		var local := inverse * world_position
		var half_length := float(state.get("length", 48.0)) * 0.5 + 6.0
		if absf(local.x) <= half_length and absf(local.y) <= 18.0:
			return str(state.get("id", ""))
	return ""


func _is_point_on_modeled_rail(point: Vector2, tolerance: float) -> bool:
	var segments := rail.get_track_segments()
	for segment_id: String in segments:
		var points: Array = segments[segment_id]
		for index in range(points.size() - 1):
			var start := points[index] as Vector2
			var end := points[index + 1] as Vector2
			if _distance_to_line_segment(point, start, end) <= tolerance:
				return true
	return false


func _distance_to_line_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)

	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)


func _check_departure_boundary() -> void:
	if lifecycle == null or lifecycle.current_sector == null:
		return
	if not lifecycle.current_sector.is_exit_crossed():
		return

	if not lifecycle.can_depart():
		_hard_brake_before_exit(true)
		if yard != null:
			yard.last_status = lifecycle.transition_blocked_reason
		return

	_open_departure_confirmation()


func _open_departure_confirmation() -> void:
	departure_confirmation_open = true
	departure_confirmation_lines = _build_departure_confirmation_lines()
	_close_context_menu()
	_hard_brake_before_exit(true)
	if yard != null:
		yard.last_status = "Confirm departure or cancel before sector disposal"


func _build_departure_confirmation_lines() -> Array[String]:
	var lines: Array[String] = []
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.definition == null:
		return lines

	var def: SectorDefinition = lifecycle.current_sector.definition
	lines.append("Leave Sector %d?" % def.sector_index)
	lines.append("This disposes the current yard and cannot be reversed.")
	lines.append("Departing consist: %s" % rail.get_consist_summary())
	lines.append("Rolling stock left behind: %s" % rail.get_detached_summary())
	lines.append("Future supplies placeholder: food / parts / fuel left here.")
	lines.append("Confirm to enter the next sector, or cancel to stop.")
	return lines


func _hard_brake_before_exit(clamp_before_boundary: bool) -> void:
	if rail == null:
		return

	rail.set_throttle(0.0)
	rail.speed = 0.0
	rail.brake_active = true
	_throttle_up_held = false
	_throttle_down_held = false
	if not clamp_before_boundary:
		return
	if lifecycle == null or lifecycle.current_sector == null or lifecycle.current_sector.definition == null:
		return

	var def: SectorDefinition = lifecycle.current_sector.definition
	if rail.current_segment != def.exit_segment:
		return
	rail.distance = minf(rail.distance, maxf(def.exit_distance - 1.0, 0.0))


func _select_survivor_at(position: Vector2) -> bool:
	var survivor_id := _get_survivor_id_at_screen_position(position)
	if survivor_id == "":
		return false

	var selected := crew.select_survivor(survivor_id)
	if selected:
		survivor_selection_confirmed = true
	return selected


func _get_survivor_id_at_screen_position(position: Vector2, hit_radius: float = 18.0) -> String:
	var nearest_id := ""
	var nearest_distance := hit_radius
	var world_position := _screen_to_world(position)
	for state in crew.get_survivor_draw_states():
		var survivor_position := state.get("position", Vector2.ZERO) as Vector2
		var distance_to_survivor := world_position.distance_to(survivor_position)
		if distance_to_survivor >= nearest_distance:
			continue

		nearest_distance = distance_to_survivor
		nearest_id = str(state.get("id", ""))
	return nearest_id


func _toggle_controlled_power_unit() -> void:
	if rail.get_controlled_power_unit_id() == "S":
		_select_powered_control_with_driver("L")
	else:
		_select_powered_control_with_driver("S")


func _select_powered_control_with_driver(unit_id: String) -> bool:
	if not rail.is_powered_unit(unit_id) or rail.get_powered_unit_condition(unit_id) != RailMovement.CONDITION_OPERATIONAL:
		return rail.select_powered_control(unit_id)
	if not crew.has_survivor_aboard_unit(unit_id):
		rail.blocked_reason = "No crew aboard %s" % unit_id
		return false
	return rail.select_powered_control(unit_id)


func _controlled_power_has_crew() -> bool:
	return rail != null and crew != null and crew.has_survivor_aboard_unit(rail.get_controlled_power_unit_id())


func _layout_ui() -> void:
	var instruction_rect := get_instruction_panel_rect()
	var debug_rect := get_debug_panel_rect()
	_pin_to_top_left(instruction_label)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.clip_text = true
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.custom_minimum_size = Vector2.ZERO
	instruction_label.position = instruction_rect.position
	instruction_label.size = instruction_rect.size
	_pin_to_top_left(debug_label)
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.clip_text = true
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.custom_minimum_size = Vector2.ZERO
	debug_label.position = debug_rect.position
	debug_label.size = debug_rect.size


func _pin_to_top_left(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0


func _get_canvas_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	return get_viewport_rect().size


func _get_world_draw_scale() -> float:
	var playfield := get_playfield_rect()
	return minf(playfield.size.x / WORLD_BOUNDS.size.x, playfield.size.y / WORLD_BOUNDS.size.y)


func _get_world_draw_offset() -> Vector2:
	var playfield := get_playfield_rect()
	var draw_scale := _get_world_draw_scale()
	var scaled_world_size := WORLD_BOUNDS.size * draw_scale
	return playfield.position + (playfield.size - scaled_world_size) * 0.5 - WORLD_BOUNDS.position * draw_scale


func _screen_to_world(position: Vector2) -> Vector2:
	var draw_scale := maxf(_get_world_draw_scale(), 0.001)
	return (position - _get_world_draw_offset()) / draw_scale


func _latest_status_line() -> String:
	if rail.blocked_reason != "":
		return rail.blocked_reason
	if yard.last_status != "":
		return yard.last_status
	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	if not selected.is_empty():
		return str(selected.get("status_text", ""))
	return ""


func _yes_no(value: bool) -> String:
	if value:
		return "yes"
	return "no"


func _on_off(value: bool) -> String:
	if value:
		return "on"
	return "off"
