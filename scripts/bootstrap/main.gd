extends Control

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const TrainInterior := preload("res://scripts/colony/train_interior.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const RollingStockCatalog := preload("res://scripts/train/rolling_stock_catalog.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")
const WorldgenSemanticGenerator := preload("res://scripts/worldgen/worldgen_semantic_generator.gd")

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
const POI_FUEL_COLOR := Color(0.92, 0.54, 0.22, 1.0)
const POI_PARTS_COLOR := Color(0.58, 0.70, 0.86, 1.0)
const POI_FOOD_COLOR := Color(0.44, 0.78, 0.42, 1.0)
const CARGO_COLOR := Color(0.98, 0.82, 0.24, 1.0)
const OBSTRUCTION_COLOR := Color(0.78, 0.36, 0.22, 1.0)
const FAULT_COLOR := Color(0.95, 0.42, 0.28, 1.0)
const WORKSHOP_ONLINE_COLOR := Color(0.42, 0.95, 0.72, 1.0)
const ROUTE_DECISION_COLOR := Color(0.72, 0.68, 0.98, 1.0)
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
const UI_REFRESH_INTERVAL := 0.12
const DEFAULT_RUN_SEED := 12345
const ENV_RUN_SEED := "TRAIN_SCAV_RUN_SEED"
const ENV_START_SECTOR := "TRAIN_SCAV_START_SECTOR"
const ENV_START_ROUTE := "TRAIN_SCAV_START_ROUTE"
const SPRINT10_SECTOR_INDEX := 2
const SPRINT10_UAT_ROUTE_PROFILE := "industrial"
const SPRINT10_UAT_SEED_SAMPLES := [
	{"seed": 6001, "expected_type_id": "fuel_tanker"},
	{"seed": 6006, "expected_type_id": "parts_flatbed"},
	{"seed": 6061, "expected_type_id": "boxcar_storage"},
]
const SPRINT11_SECTOR_INDEX := 2
const SPRINT11_UAT_ROUTE_PROFILE := "industrial"
const SPRINT11_UAT_SEED_SAMPLES := [
	{"seed": 6003, "expected_archetype_id": "rural_through"},
	{"seed": 6012, "expected_archetype_id": "village_passing_station"},
	{"seed": 6001, "expected_archetype_id": "small_town_goods"},
	{"seed": 6005, "expected_archetype_id": "agricultural_loading_point"},
	{"seed": 6004, "expected_archetype_id": "river_valley_constrained"},
	{"seed": 6008, "expected_archetype_id": "declining_abandoned_branch"},
]

@onready var instruction_label: Label = %InstructionLabel
@onready var debug_label: Label = %DebugLabel

var rail: RailMovement
var crew: CrewSimulation
var yard: YardOperations
var interior: TrainInterior
var task_broker: RefCounted
var lifecycle: RefCounted
var train_resources: TrainResources
var scenario: FirstRunScenario
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
var _ui_refresh_elapsed: float = 0.0
var _ui_panel_refresh_count: int = 0
var _sprint10_preflight_state: Dictionary = {}
var _sprint11_preflight_state: Dictionary = {}


func _ready() -> void:
	rail = RailMovement.new()
	yard = YardOperations.new(rail)
	interior = TrainInterior.new(rail)
	crew = CrewSimulation.new(rail, yard)
	task_broker = TaskBroker.new(crew, yard, rail)
	lifecycle = SectorLifecycle.new(_get_initial_run_seed(), crew, task_broker)
	train_resources = lifecycle.get_train_resources()
	train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 12.0)
	train_resources.set_amount(TrainResources.RESOURCE_FOOD, 12.0)
	train_resources.set_amount(TrainResources.RESOURCE_PARTS, 0.0)
	scenario = FirstRunScenario.new()
	scenario.attach(lifecycle, crew, task_broker)
	lifecycle.set_scenario_coordinator(scenario)
	_apply_debug_start_sector_from_environment()
	_sprint10_preflight_state = _build_sprint10_preflight_state()
	_sprint11_preflight_state = _build_sprint11_preflight_state()
	_refresh_side_panel_text(true)
	_layout_ui()
	queue_redraw()


func _exit_tree() -> void:
	release_runtime_references()


func release_runtime_references() -> void:
	# Break shutdown-only RefCounted cycles between runtime services.
	_throttle_up_held = false
	_throttle_down_held = false
	_brake_held = false
	context_menu_open = false
	departure_confirmation_open = false
	context_menu_items.clear()
	departure_confirmation_lines.clear()
	_sprint10_preflight_state.clear()
	_sprint11_preflight_state.clear()

	if scenario != null and scenario.has_method("detach"):
		scenario.detach()
	if lifecycle != null and lifecycle.has_method("dispose"):
		lifecycle.dispose()
	if task_broker != null and task_broker.has_method("dispose"):
		task_broker.dispose()
	if crew != null and crew.has_method("dispose"):
		crew.dispose()
	if interior != null and interior.has_method("dispose"):
		interior.dispose()
	if yard != null and yard.has_method("dispose"):
		yard.dispose()
	if train_resources != null and train_resources.has_method("clear_capacity_provider"):
		train_resources.clear_capacity_provider()

	rail = null
	yard = null
	interior = null
	crew = null
	task_broker = null
	lifecycle = null
	train_resources = null
	scenario = null


func _get_initial_run_seed() -> int:
	var env_seed := OS.get_environment(ENV_RUN_SEED).strip_edges()
	if env_seed.is_valid_int():
		return int(env_seed)
	return DEFAULT_RUN_SEED


func _apply_debug_start_sector_from_environment() -> bool:
	var env_sector := OS.get_environment(ENV_START_SECTOR).strip_edges()
	if env_sector.is_empty():
		return false
	if not env_sector.is_valid_int():
		push_warning("%s must be an integer sector index" % ENV_START_SECTOR)
		return false
	var route_profile := OS.get_environment(ENV_START_ROUTE).strip_edges()
	if route_profile.is_empty():
		route_profile = SPRINT10_UAT_ROUTE_PROFILE
	var sector_index := int(env_sector)
	if lifecycle == null or not lifecycle.has_method("debug_start_at_sector"):
		return false
	if not lifecycle.debug_start_at_sector(sector_index, route_profile):
		push_warning("Debug sector start failed: %s" % str(lifecycle.transition_blocked_reason))
		return false

	rail = lifecycle.current_sector.rail
	yard = lifecycle.current_sector.yard
	train_resources = lifecycle.get_train_resources()
	interior = crew.interior
	if yard != null:
		yard.last_status = "Debug start: Sector %d via %s" % [sector_index, route_profile]
	return true


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
	var source_type: String = str(sector_visual.get("source_type", "AUTHORED"))
	var archetype_id: String = str(sector_visual.get("archetype_id", ""))
	var sector_index := int(sector_visual.get("sector_index", 0))
	var run_seed := int(sector_visual.get("run_seed", 0))
	var blueprint_hash := str(sector_visual.get("blueprint_hash", ""))
	var generator_version := str(sector_visual.get("generator_version", ""))
	var elapsed_time := 0.0
	if lifecycle != null and lifecycle.current_sector != null:
		elapsed_time = lifecycle.current_sector.get_elapsed_time()
	var stock := "D0 F0 P0"
	if train_resources != null:
		stock = _format_resource_stock()
	var sector_line := "Sector: %s  Time: %.0fs  Stock: %s  Auto: %s" % [sec_name, elapsed_time, stock, auto_label]
	lines.append(sector_line)
	if source_type == SectorDefinition.SOURCE_PROCEDURAL:
		lines.append("Worldgen: PROCEDURAL  Run:%d  Idx:%d  Archetype:%s  Hash:%s  Gen:%s" % [
			run_seed,
			sector_index,
			archetype_id,
			blueprint_hash.substr(0, 12),
			generator_version,
		])
		var feature_summary := _get_archetype_feature_summary(archetype_id)
		if feature_summary != "":
			lines.append("Features: %s" % feature_summary)
	for stock_line in get_current_generated_stock_debug_lines():
		lines.append(stock_line)
	if scenario != null:
		var objective := _get_current_objective_text()
		var departure_blocker := _get_departure_blocker_text()
		if departure_blocker != "":
			objective = "%s  Exit blocked: %s" % [objective, _short_departure_blocker(departure_blocker)]
		lines.append("Objective: %s" % objective)
		var workshop_visual := get_workshop_visual_state()
		if not workshop_visual.is_empty():
			lines.append("Workshop W: %s" % str(workshop_visual.get("status", "")))
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
	var shunter_status := "not in sector"
	var shunter_controllable := "no"
	if _sector_has_unit("S"):
		shunter_status = str(shunter.get("condition", ""))
		shunter_controllable = _yes_no(bool(shunter.get("controllable", false)))
	lines.append("Yard: control %s power %s remote %s  S:%s/%s" % [
		str(yard_control.get("condition", "")),
		_on_off(bool(yard_control.get("powered", false))),
		_yes_no(bool(yard_control.get("remote_control", false))),
		shunter_status,
		shunter_controllable,
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
		var cargo_label := "none"
		if float(selected.get("cargo_amount", 0.0)) > 0.0:
			cargo_label = "%.0f %s" % [
				float(selected.get("cargo_amount", 0.0)),
				str(selected.get("cargo_type", "")),
			]
		lines.append("Task: %s  target %s  Cargo: %s" % [
			str(selected.get("task_type", "")),
			str(selected.get("task_target", "")),
			cargo_label,
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
			"run_seed": 0,
			"sector_seed": 0,
			"display_name": "",
			"entry_label": "",
			"accent_color": Color(0.35, 0.95, 0.85, 0.9),
			"source_type": "",
			"archetype_id": "",
			"blueprint_hash": "",
			"generator_version": "",
		}

	var def: SectorDefinition = lifecycle.current_sector.definition
	return {
		"sector_id": def.sector_id,
		"template_name": def.template_name,
		"sector_index": def.sector_index,
		"run_seed": lifecycle.run_state.run_seed,
		"sector_seed": def.seed_value,
		"display_name": def.display_name,
		"entry_label": def.entry_label,
		"accent_color": def.accent_color,
		"entry_segment": def.entry_segment,
		"entry_distance": def.entry_distance,
		"exit_segment": def.exit_segment,
		"exit_distance": def.exit_distance,
		"route_exits": def.route_exits.duplicate(true),
		"source_type": def.source_type,
		"archetype_id": def.archetype_id,
		"blueprint_hash": def.blueprint_hash,
		"generator_version": def.generator_version,
	}


func get_sector_exit_draw_states() -> Array[Dictionary]:
	if lifecycle == null or lifecycle.current_sector == null:
		return []
	if lifecycle.current_sector.has_method("get_route_exit_states"):
		return lifecycle.current_sector.get_route_exit_states()
	return []


func get_workshop_visual_state() -> Dictionary:
	if scenario == null:
		return {}
	var state: Dictionary = scenario.get_state()
	if str(state.get("phase", "")) != FirstRunScenario.PHASE_INDUSTRIAL:
		return {}
	var recovered := bool(state.get("workshop_recovered", false))
	var online := bool(state.get("workshop_online", false))
	var status := "not recovered"
	if recovered:
		status = "online" if online else "offline"
		if not online:
			var cost := FirstRunScenario.WORKSHOP_ACTIVATION_PARTS_COST
			var available := 0.0
			if train_resources != null:
				available = train_resources.get_amount(TrainResources.RESOURCE_PARTS)
			status = "offline - needs %.0f parts (have %.0f)" % [cost, available]
	var label := "W WORKSHOP"
	if online:
		label = "W WORKSHOP ONLINE"
	elif recovered:
		label = "W WORKSHOP OFFLINE"
	var unit_state := _get_unit_draw_state(FirstRunScenario.WORKSHOP_ID)
	var position := Vector2.ZERO
	if not unit_state.is_empty():
		position = unit_state.get("position", Vector2.ZERO) as Vector2
	return {
		"id": FirstRunScenario.WORKSHOP_ID,
		"recovered": recovered,
		"online": online,
		"status": status,
		"label": label,
		"position": position,
	}


func get_train_resource_state() -> Dictionary:
	if train_resources == null:
		return {}
	var state: Dictionary = train_resources.get_all()
	state["departure_cost"] = TrainResources.DEPARTURE_DIESEL_COST
	state["capacity_diesel"] = train_resources.get_capacity(TrainResources.RESOURCE_DIESEL)
	state["capacity_food"] = train_resources.get_capacity(TrainResources.RESOURCE_FOOD)
	state["capacity_parts"] = train_resources.get_capacity(TrainResources.RESOURCE_PARTS)
	return state


func get_sprint10_preflight_state() -> Dictionary:
	if _sprint10_preflight_state.is_empty():
		_sprint10_preflight_state = _build_sprint10_preflight_state()
	return _sprint10_preflight_state.duplicate(true)


func get_sprint10_preflight_lines() -> Array[String]:
	var state := get_sprint10_preflight_state()
	var lines: Array[String] = ["Sprint 10 Load Check"]
	var catalog_types := state.get("catalog_type_ids", []) as Array
	var salvage_types := state.get("salvage_type_ids", []) as Array
	lines.append("Catalog: %d types  Salvage: %s" % [
		catalog_types.size(),
		", ".join(_string_array(salvage_types)),
	])
	for raw_sample in state.get("seed_samples", []) as Array:
		var sample := raw_sample as Dictionary
		var status := "SEEDED" if bool(sample.get("seeded", false)) else "MISSING"
		lines.append("%d -> %s %s [%s]" % [
			int(sample.get("seed", 0)),
			str(sample.get("unit_id", "")),
			str(sample.get("actual_type_id", "")),
			status,
		])
	var current_preview := state.get("current_seed_preview", {}) as Dictionary
	if not current_preview.is_empty():
		var current_type := str(current_preview.get("actual_type_id", ""))
		var current_archetype := str(current_preview.get("archetype_id", ""))
		if current_type != "":
			lines.append("Current seed %d sector 2: %s %s" % [
				int(current_preview.get("seed", 0)),
				current_archetype,
				current_type,
			])
		else:
			lines.append("Current seed %d sector 2: %s" % [
				int(current_preview.get("seed", 0)),
				current_archetype,
			])
	return lines


func get_sprint11_preflight_state() -> Dictionary:
	if _sprint11_preflight_state.is_empty():
		_sprint11_preflight_state = _build_sprint11_preflight_state()
	return _sprint11_preflight_state.duplicate(true)


func get_sprint11_preflight_lines() -> Array[String]:
	var state := get_sprint11_preflight_state()
	var lines: Array[String] = ["Sprint 11 Procgen Check"]
	var supported := state.get("supported_archetypes", []) as Array
	lines.append("Archetypes: %d  Promoted: agricultural, river, declining" % supported.size())
	for raw_sample in state.get("seed_samples", []) as Array:
		var sample := raw_sample as Dictionary
		var status := "SEEDED" if bool(sample.get("seeded", false)) else "MISSING"
		lines.append("%d -> sector 2 %s [%s]" % [
			int(sample.get("seed", 0)),
			str(sample.get("actual_archetype_id", "")),
			status,
		])
	var current_preview := state.get("current_seed_preview", {}) as Dictionary
	if not current_preview.is_empty():
		lines.append("Current seed %d sector 2: %s" % [
			int(current_preview.get("seed", 0)),
			str(current_preview.get("actual_archetype_id", "")),
		])
	return lines


func get_current_generated_stock_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	if rail == null:
		return lines
	for state in rail.get_unit_draw_states():
		var unit_id := str(state.get("id", ""))
		if not unit_id.begins_with("sector_"):
			continue
		var type_id := str(state.get("type_id", ""))
		var ownership := "owned" if bool(state.get("active", false)) else "salvage"
		var summary := str(state.get("capability_summary", ""))
		if summary != "":
			lines.append("Generated stock: %s %s %s - %s" % [
				unit_id,
				type_id,
				ownership,
				summary,
			])
		else:
			lines.append("Generated stock: %s %s %s" % [
				unit_id,
				type_id,
				ownership,
			])
	return lines


func get_vertical_slice_state() -> Dictionary:
	if scenario == null:
		return {}
	return scenario.get_state()


func get_scenario_draw_states() -> Array[Dictionary]:
	if scenario == null:
		return []
	return scenario.get_world_interaction_states()


func get_ui_panel_refresh_count() -> int:
	return _ui_panel_refresh_count


func get_ui_refresh_interval() -> float:
	return UI_REFRESH_INTERVAL


func get_sector_poi_states() -> Array[Dictionary]:
	if lifecycle == null or lifecycle.current_sector == null:
		return []
	return lifecycle.current_sector.get_poi_states()


func get_sector_poi_state(poi_id: String) -> Dictionary:
	if lifecycle == null or lifecycle.current_sector == null:
		return {}
	return lifecycle.current_sector.get_poi_state(poi_id)


func get_poi_draw_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for poi in get_sector_poi_states():
		var resource_type := str(poi.get("yield_type", ""))
		if bool(poi.get("searched", false)) and str(poi.get("available_type", "")) != "":
			resource_type = str(poi.get("available_type", ""))
		var draw_state: Dictionary = poi.duplicate(true)
		draw_state["icon"] = _get_poi_icon_kind(resource_type)
		draw_state["color"] = _get_poi_color(resource_type)
		states.append(draw_state)
	return states


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
	train_resources = lifecycle.get_train_resources()
	interior = crew.interior
	yard.last_status = "Entered %s" % lifecycle.current_sector.definition.display_name
	_refresh_side_panel_text(true)
	queue_redraw()
	return true


func cancel_sector_departure() -> bool:
	if not departure_confirmation_open:
		return false
	departure_confirmation_open = false
	departure_confirmation_lines.clear()
	if scenario != null and scenario.has_method("clear_pending_route_selection"):
		scenario.clear_pending_route_selection()
	_hard_brake_before_exit(true)
	if yard != null:
		yard.last_status = "Departure cancelled - train stopped before sector exit"
	_refresh_side_panel_text(true)
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
		if anchor_id == "shunter" and not _sector_has_unit("S"):
			continue
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
	if not _is_default_authored_runtime_layout():
		return _get_generic_switch_route_visual_states()
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


func _get_generic_switch_route_visual_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for point_id in yard.get_point_ids():
		var point_state := yard.get_point_state(point_id)
		var position := point_state.get("track_position", point_state.get("anchor", Vector2.ZERO)) as Vector2
		var route := str(point_state.get("route", ""))
		states.append({
			"point_id": point_id,
			"position": position,
			"control_label": "%s route %s" % [point_id, route],
			"label_position": position + Vector2(-62.0, -42.0),
			"active_kind": _route_kind_from_route(route),
			"options": [],
		})
	return states


func get_current_uat_step_index() -> int:
	var steps := _get_uat_step_states()
	for index in steps.size():
		if not bool(steps[index].get("done", false)):
			return index
	return max(steps.size() - 1, 0)


func get_uat_tutorial_lines() -> Array[String]:
	var lines: Array[String] = [
		"Train Scav - Sprint 11 UAT",
		"Goal: prove bounded procedural railway variety.",
	]
	for line in get_sprint11_preflight_lines():
		lines.append(line)
	lines.append_array([
		"Opening still uses Sprint 8 vertical slice.",
		"Sprint 10 salvage seeds remain active.",
		"Mouse-first operations",
		"Left click survivor: select",
		"Right click object/train/POI: options",
		"Left click menu item: confirm",
		"Drive remains keyboard: W/S Space R",
		"Discover != owned; haul supplies to B.",
		"Coupled W != online; activate it.",
		"Final route: drive onto a marked exit branch.",
		"Shunter S appears in Sector 1 after first departure.",
		"Departure requires all crew aboard and diesel.",
		"Departure blockers show in Objective/Status.",
	])
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
		if scenario != null and scenario.apply_movement_constraints(rail):
			_throttle_up_held = false
			_throttle_down_held = false
			if yard != null:
				yard.last_status = str(scenario.last_status)
	if lifecycle != null and lifecycle.current_sector != null and not lifecycle.current_sector.disposed:
		lifecycle.current_sector.step(delta)
	if report_missing_driver:
		rail.blocked_reason = missing_driver
		yard.last_status = missing_driver
	crew.step(delta)
	task_broker.step(delta)
	if lifecycle != null and not departure_confirmation_open:
		_check_departure_boundary()
	_step_side_panel_refresh(delta)
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
	_draw_sector_pois()
	_draw_scenario_objects()
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
	var exits := get_sector_exit_draw_states()
	if exits.is_empty():
		var def: SectorDefinition = lifecycle.current_sector.definition
		exits.append({
			"label": "Exit boundary",
			"position": rail.get_point_on_segment(def.exit_segment, def.exit_distance),
		})
	var exit_color := Color(0.95, 0.35, 0.35, 0.9) if lifecycle.transition_blocked_reason != "" else Color(0.35, 0.95, 0.85, 0.9)
	for exit_state in exits:
		var exit_pos := exit_state.get("position", Vector2.ZERO) as Vector2
		var route_id := str(exit_state.get("route_id", exit_state.get("id", "")))
		var label := str(exit_state.get("label", "Exit boundary"))
		if route_id == "forward":
			label = "EXIT BOUNDARY"
		var color := exit_color
		if route_id == "industrial":
			color = Color(0.96, 0.67, 0.24, 0.95)
		elif route_id == "settlement":
			color = Color(0.42, 0.78, 0.48, 0.95)
		elif route_id == "direct":
			color = Color(0.65, 0.72, 0.82, 0.95)
		draw_line(exit_pos + Vector2(0.0, -32.0), exit_pos + Vector2(0.0, 32.0), color, 4.0)
		draw_string(get_theme_default_font(), exit_pos + Vector2(-44.0, -38.0), label.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 11, color)


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
	for point_id in yard.get_point_ids():
		var point_state := yard.get_point_state(point_id)
		var color := ROUTE_MAIN_COLOR
		if str(point_state.get("route", "")) != YardOperations.ROUTE_MAIN and str(point_state.get("route", "")) != RailMovement.POINTS_MAIN:
			color = ROUTE_SIDING_COLOR
		if str(point_state.get("mechanical_state", "")) == YardOperations.MECHANICAL_DAMAGED:
			color = Color(0.72, 0.20, 0.18, 1.0)
		var position := point_state.get("track_position", point_state.get("anchor", Vector2.ZERO)) as Vector2
		if point_id == YardOperations.POINT_P1 and not point_state.has("track_position"):
			position = RailMovement.SWITCH_POSITION
		_draw_track_switch_icon(position, color, point_id)
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
	if str(state["type"]) == RailMovement.UNIT_WORKSHOP and _is_workshop_online():
		_draw_workshop_online_indicator(state)
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


func _draw_workshop_online_indicator(state: Dictionary) -> void:
	var pos := state["position"] as Vector2
	var angle := float(state["angle"])
	var tangent := Vector2.RIGHT.rotated(angle)
	var normal := Vector2.UP.rotated(angle)
	var length := float(state["length"])
	var half_length := maxf(length * 0.5 - 5.0, 8.0)
	var half_width := 17.0
	var panel := PackedVector2Array([
		pos - tangent * half_length - normal * half_width,
		pos + tangent * half_length - normal * half_width,
		pos + tangent * half_length + normal * half_width,
		pos - tangent * half_length + normal * half_width,
		pos - tangent * half_length - normal * half_width,
	])
	draw_polyline(panel, WORKSHOP_ONLINE_COLOR, 3.0, true)
	draw_circle(pos + normal * 1.0, 7.0, WORKSHOP_ONLINE_COLOR)
	draw_circle(pos + normal * 1.0, 3.2, ICON_BACKGROUND_COLOR)

	var font := get_theme_default_font()
	if font != null:
		var label_pos := pos + normal * 36.0 - tangent * 28.0
		draw_string(font, label_pos, "ONLINE", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 11, WORKSHOP_ONLINE_COLOR)


func _draw_unit_label(state: Dictionary) -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	var pos := state["position"] as Vector2
	var unit_id := str(state["id"])
	draw_string(font, pos + Vector2(-7.0, 6.0), unit_id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, UNIT_LABEL_COLOR)


func _draw_sector_pois() -> void:
	var font := get_theme_default_font()
	for state in get_poi_draw_states():
		var position := state.get("position", Vector2.ZERO) as Vector2
		var color := state.get("color", POI_PARTS_COLOR) as Color
		var icon := str(state.get("icon", "crate"))
		_draw_poi_icon(position, icon, color, bool(state.get("searched", false)))
		if font == null:
			continue
		var name := str(state.get("name", "POI"))
		var status := str(state.get("status", ""))
		var amount := float(state.get("available_amount", 0.0))
		var available_type := str(state.get("available_type", ""))
		var line := "%s - %s" % [name, status]
		if amount > 0.0:
			line = "%s: %.0f %s" % [name, amount, available_type]
		draw_string(font, position + Vector2(20.0, -12.0), line, HORIZONTAL_ALIGNMENT_LEFT, 190.0, 12, ICON_LABEL_COLOR)


func _draw_poi_icon(position: Vector2, icon: String, color: Color, searched: bool) -> void:
	var bg := Color(0.12, 0.13, 0.14, 1.0)
	if searched:
		bg = bg.lightened(0.08)
	draw_rect(Rect2(position - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), bg, true)
	draw_rect(Rect2(position - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), color, false, 2.0)
	match icon:
		"fuel":
			draw_circle(position + Vector2(-4.0, 2.0), 7.0, color)
			draw_rect(Rect2(position + Vector2(-6.0, -9.0), Vector2(8.0, 5.0)), color, true)
			draw_line(position + Vector2(5.0, -6.0), position + Vector2(10.0, -1.0), color, 2.0, true)
			draw_line(position + Vector2(10.0, -1.0), position + Vector2(10.0, 8.0), color, 2.0, true)
		"food":
			draw_circle(position + Vector2(-4.0, 0.0), 6.0, color)
			draw_line(position + Vector2(4.0, -8.0), position + Vector2(4.0, 9.0), color, 2.0, true)
			draw_line(position + Vector2(8.0, -8.0), position + Vector2(8.0, 9.0), color, 2.0, true)
		_:
			draw_rect(Rect2(position - Vector2(8.0, 6.0), Vector2(16.0, 8.0)), color, true)
			draw_line(position + Vector2(-8.0, 6.0), position + Vector2(0.0, -8.0), color, 2.0, true)
			draw_line(position + Vector2(8.0, 6.0), position + Vector2(0.0, -8.0), color, 2.0, true)
	if searched:
		draw_line(position + Vector2(-11.0, 11.0), position + Vector2(11.0, -11.0), Color(1.0, 1.0, 1.0, 0.55), 2.0, true)


func _draw_scenario_objects() -> void:
	var font := get_theme_default_font()
	for state in get_scenario_draw_states():
		var target_id := str(state.get("id", ""))
		var position := state.get("position", Vector2.ZERO) as Vector2
		var label := str(state.get("label", target_id))
		match target_id:
			FirstRunScenario.OBSTRUCTION_ID:
				_draw_obstruction_marker(position)
			FirstRunScenario.ONBOARD_FAULT_ID:
				_draw_fault_marker(position)
			FirstRunScenario.WORKSHOP_ACTIVATION_ID:
				_draw_workshop_marker(position)
			FirstRunScenario.ROUTE_DECISION_ID:
				_draw_route_decision_marker(position)
			_:
				draw_circle(position, 10.0, ROUTE_DECISION_COLOR)
		if font != null:
			draw_string(font, position + Vector2(18.0, -12.0), label, HORIZONTAL_ALIGNMENT_LEFT, 190.0, 12, ICON_LABEL_COLOR)


func _draw_obstruction_marker(position: Vector2) -> void:
	draw_rect(Rect2(position - Vector2(17.0, 10.0), Vector2(34.0, 13.0)), OBSTRUCTION_COLOR, true)
	draw_line(position + Vector2(-19.0, 11.0), position + Vector2(-6.0, -10.0), OBSTRUCTION_COLOR.lightened(0.2), 4.0, true)
	draw_line(position + Vector2(3.0, 10.0), position + Vector2(17.0, -9.0), OBSTRUCTION_COLOR.lightened(0.15), 4.0, true)
	draw_arc(position, 22.0, 0.0, TAU, 28, ICON_STROKE_COLOR, 2.0)


func _draw_fault_marker(position: Vector2) -> void:
	draw_circle(position, 11.0, FAULT_COLOR)
	draw_line(position + Vector2(-5.0, -7.0), position + Vector2(6.0, 4.0), ICON_BACKGROUND_COLOR, 3.0, true)
	draw_line(position + Vector2(5.0, -7.0), position + Vector2(-6.0, 5.0), ICON_BACKGROUND_COLOR, 3.0, true)


func _draw_workshop_marker(position: Vector2) -> void:
	draw_circle(position, 13.0, ICON_BACKGROUND_COLOR)
	draw_arc(position, 14.0, 0.0, TAU, 28, WORKSHOP_ONLINE_COLOR, 2.0)
	_draw_repair_anchor_icon(position, WORKSHOP_ONLINE_COLOR)


func _draw_route_decision_marker(position: Vector2) -> void:
	draw_rect(Rect2(position - Vector2(18.0, 14.0), Vector2(36.0, 28.0)), ROUTE_LABEL_BACKGROUND_COLOR, true)
	draw_rect(Rect2(position - Vector2(18.0, 14.0), Vector2(36.0, 28.0)), ROUTE_DECISION_COLOR, false, 2.0)
	draw_line(position + Vector2(-9.0, -4.0), position + Vector2(9.0, -4.0), ROUTE_DECISION_COLOR, 2.0, true)
	draw_line(position + Vector2(-9.0, 4.0), position + Vector2(5.0, 4.0), ROUTE_DECISION_COLOR, 2.0, true)


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
	if float(state.get("cargo_amount", 0.0)) > 0.0:
		draw_rect(Rect2(position + Vector2(7.0, 3.0), Vector2(9.0, 9.0)), CARGO_COLOR, true)
		draw_rect(Rect2(position + Vector2(7.0, 3.0), Vector2(9.0, 9.0)), ICON_STROKE_COLOR, false, 1.0)

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
	if segment_id == RailMovement.SEGMENT_INDUSTRIAL_EXIT:
		return Color(0.96, 0.67, 0.24, 0.92)
	if segment_id == RailMovement.SEGMENT_SETTLEMENT_EXIT:
		return Color(0.42, 0.78, 0.48, 0.92)
	return ROUTE_INACTIVE_COLOR


func _is_workshop_online() -> bool:
	if scenario == null:
		return false
	return bool(scenario.get_state().get("workshop_online", false))


func _route_kind_from_route(route: String) -> String:
	if route == RailMovement.POINTS_MAIN or route == YardOperations.ROUTE_MAIN:
		return "straight"
	return "branch"


func _is_default_authored_runtime_layout() -> bool:
	if rail == null or not rail.has_method("get_runtime_topology_snapshot"):
		return true
	var snapshot: Dictionary = rail.get_runtime_topology_snapshot()
	return str(snapshot.get("layout_id", "")) == "default_authored_yard"


func _format_route_option_label(kind: String, destination: String, active: bool) -> String:
	var prefix := kind.to_upper()
	if active:
		prefix = "ACTIVE %s" % prefix
	return "%s: %s" % [prefix, destination]


func _step_side_panel_refresh(delta: float) -> void:
	_ui_refresh_elapsed += delta
	if _ui_refresh_elapsed < UI_REFRESH_INTERVAL:
		return
	_refresh_side_panel_text(false)


func _refresh_side_panel_text(force: bool = false) -> void:
	if not force and _ui_refresh_elapsed < UI_REFRESH_INTERVAL:
		return
	_ui_refresh_elapsed = 0.0
	_ui_panel_refresh_count += 1

	if instruction_label != null:
		var instruction_text := "\n".join(get_uat_tutorial_lines())
		if force or instruction_label.text != instruction_text:
			instruction_label.text = instruction_text

	if debug_label != null:
		var debug_text := "\n".join(get_compact_debug_lines())
		if force or debug_label.text != debug_text:
			debug_label.text = debug_text


func _refresh_instruction_text() -> void:
	_refresh_side_panel_text(true)


func _build_sprint10_preflight_state() -> Dictionary:
	var seed_samples: Array[Dictionary] = []
	for sample in SPRINT10_UAT_SEED_SAMPLES:
		seed_samples.append(_make_sprint10_seed_preview(sample as Dictionary))
	var current_seed := DEFAULT_RUN_SEED
	if lifecycle != null and lifecycle.run_state != null:
		current_seed = int(lifecycle.run_state.run_seed)
	var current_preview := _make_sprint10_seed_preview({
		"seed": current_seed,
		"expected_type_id": "",
	})
	return {
		"catalog_loaded": true,
		"catalog_type_ids": RollingStockCatalog.get_type_ids(),
		"salvage_type_ids": RollingStockCatalog.get_salvage_type_ids(),
		"seed_samples": seed_samples,
		"current_seed_preview": current_preview,
	}


func _build_sprint11_preflight_state() -> Dictionary:
	var seed_samples: Array[Dictionary] = []
	for sample in SPRINT11_UAT_SEED_SAMPLES:
		seed_samples.append(_make_sprint11_seed_preview(sample as Dictionary))
	var current_seed := DEFAULT_RUN_SEED
	if lifecycle != null and lifecycle.run_state != null:
		current_seed = int(lifecycle.run_state.run_seed)
	var current_preview := _make_sprint11_seed_preview({
		"seed": current_seed,
		"expected_archetype_id": "",
	})
	return {
		"supported_archetypes": WorldgenProductionSectorGenerator.SUPPORTED_ARCHETYPES,
		"seed_samples": seed_samples,
		"current_seed_preview": current_preview,
	}


func _make_sprint10_seed_preview(sample: Dictionary) -> Dictionary:
	var seed := int(sample.get("seed", 0))
	var expected_type_id := str(sample.get("expected_type_id", ""))
	var result := WorldgenProductionSectorGenerator.new().generate_sector(
		seed,
		SPRINT10_SECTOR_INDEX,
		SPRINT10_UAT_ROUTE_PROFILE
	)
	var unit_id := "sector_%03d_salvage_01" % SPRINT10_SECTOR_INDEX
	var unit_types := result.get("rolling_stock_units", {}) as Dictionary
	var detached := result.get("detached_consists", []) as Array
	var segment_id := ""
	var distance := 0.0
	if not detached.is_empty():
		var placement := detached[0] as Dictionary
		segment_id = str(placement.get("segment", ""))
		distance = float(placement.get("distance", 0.0))
	var actual_type_id := str(unit_types.get(unit_id, ""))
	var archetype_id := str(result.get("archetype_id", ""))
	var success := bool(result.get("success", false))
	var expected_matches := true
	if expected_type_id != "":
		expected_matches = actual_type_id == expected_type_id
	return {
		"seed": seed,
		"sector_index": SPRINT10_SECTOR_INDEX,
		"route_profile": SPRINT10_UAT_ROUTE_PROFILE,
		"success": success,
		"archetype_id": archetype_id,
		"unit_id": unit_id,
		"expected_type_id": expected_type_id,
		"actual_type_id": actual_type_id,
		"capability_summary": RollingStockCatalog.get_capability_summary(actual_type_id),
		"placement_segment": segment_id,
		"placement_distance": distance,
		"rolling_stock_signature": str(result.get("rolling_stock_signature", "")),
		"seeded": success \
				and archetype_id == WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS \
				and actual_type_id != "" \
				and expected_matches,
	}


func _make_sprint11_seed_preview(sample: Dictionary) -> Dictionary:
	var seed := int(sample.get("seed", 0))
	var expected_archetype_id := str(sample.get("expected_archetype_id", ""))
	var result := WorldgenProductionSectorGenerator.new().generate_sector(
		seed,
		SPRINT11_SECTOR_INDEX,
		SPRINT11_UAT_ROUTE_PROFILE
	)
	var actual_archetype_id := str(result.get("archetype_id", ""))
	var success := bool(result.get("success", false))
	var expected_matches := true
	if expected_archetype_id != "":
		expected_matches = actual_archetype_id == expected_archetype_id
	return {
		"seed": seed,
		"sector_index": SPRINT11_SECTOR_INDEX,
		"route_profile": SPRINT11_UAT_ROUTE_PROFILE,
		"success": success,
		"expected_archetype_id": expected_archetype_id,
		"actual_archetype_id": actual_archetype_id,
		"blueprint_hash": str(result.get("blueprint_hash", "")),
		"spatial_embedding_hash": str(result.get("spatial_embedding_hash", "")),
		"runtime_topology_hash": str(result.get("runtime_topology_hash", "")),
		"poi_signature": str(result.get("poi_signature", "")),
		"seeded": success and expected_matches,
	}


func _get_uat_step_states() -> Array[Dictionary]:
	var fuel: Dictionary = get_sector_poi_state("fuel_depot")
	var parts: Dictionary = get_sector_poi_state("maintenance_shed")
	var fuel_searched := bool(fuel.get("searched", false))
	var fuel_available := float(fuel.get("available_amount", 0.0))
	var parts_available := float(parts.get("available_amount", 0.0))
	var diesel_amount := 0.0
	var parts_amount := 0.0
	if train_resources != null:
		diesel_amount = train_resources.get_amount(TrainResources.RESOURCE_DIESEL)
		parts_amount = train_resources.get_amount(TrainResources.RESOURCE_PARTS)
	var scenario_state: Dictionary = get_vertical_slice_state()
	return [
		{
			"label": "Drive to obstruction and stop",
			"done": (lifecycle != null and str(lifecycle.transition_blocked_reason).contains("obstruction")) \
					or (rail != null and str(rail.blocked_reason).contains("obstruction")),
		},
		{
			"label": "Select crew and clear obstruction",
			"done": not bool(scenario_state.get("obstruction_active", true)),
		},
		{
			"label": "Search fuel + parts POIs",
			"done": fuel_searched and bool(parts.get("searched", false)),
		},
		{
			"label": "Haul diesel and parts to B storage",
			"done": diesel_amount > 12.0 \
					and parts_amount >= FirstRunScenario.WORKSHOP_ACTIVATION_PARTS_COST \
					and fuel_available <= 0.0 \
					and parts_available <= 0.0,
		},
		{
			"label": "Repair onboard locomotive fault",
			"done": not bool(scenario_state.get("onboard_fault_active", true)),
		},
		{
			"label": "Board all crew and depart Sector 0",
			"done": lifecycle != null and lifecycle.run_state.sector_index > 0,
		},
		{
			"label": "In industrial yard, recover W by coupling",
			"done": bool(scenario_state.get("workshop_recovered", false)),
		},
		{
			"label": "Activate workshop W with crew + parts",
			"done": bool(scenario_state.get("workshop_online", false)),
		},
		{
			"label": "Drive onto a marked route exit branch",
			"done": str(scenario_state.get("selected_route", "")) != "",
		},
		{
			"label": "Depart with upgraded train",
			"done": lifecycle != null and lifecycle.run_state.sector_index > 1,
		},
		{
			"label": "Selected survivor visible",
			"done": survivor_selection_confirmed,
		},
	]


func _get_current_objective_text() -> String:
	var state: Dictionary = get_vertical_slice_state()
	if state.is_empty():
		return "Drive and inspect the sector"
	var phase := str(state.get("phase", ""))
	if phase == FirstRunScenario.PHASE_OPENING:
		if bool(state.get("obstruction_active", false)):
			return "Stop and clear the track obstruction"
		var fuel: Dictionary = get_sector_poi_state("fuel_depot")
		var parts: Dictionary = get_sector_poi_state("maintenance_shed")
		var diesel_amount := train_resources.get_amount(TrainResources.RESOURCE_DIESEL) if train_resources != null else 0.0
		var parts_amount := train_resources.get_amount(TrainResources.RESOURCE_PARTS) if train_resources != null else 0.0
		if not bool(fuel.get("searched", false)) or not bool(parts.get("searched", false)):
			return "Search fuel and parts POIs"
		if diesel_amount <= 12.0:
			return "Haul discovered supplies back to B"
		if parts_amount < FirstRunScenario.WORKSHOP_ACTIVATION_PARTS_COST:
			return "Haul parts for workshop W (need %.0f, have %.0f)" % [
				FirstRunScenario.WORKSHOP_ACTIVATION_PARTS_COST,
				parts_amount,
			]
		if bool(state.get("onboard_fault_active", false)):
			return "Repair the onboard locomotive fault"
		if not crew.are_all_survivors_aboard():
			return "Board every expedition survivor"
		return "Depart irreversibly to the industrial sector"
	if phase == FirstRunScenario.PHASE_INDUSTRIAL:
		if not bool(state.get("workshop_recovered", false)):
			return "Recover workshop wagon W by physical coupling"
		if not bool(state.get("workshop_online", false)):
			return "Activate workshop W with crew and parts"
		if str(state.get("selected_route", "")) == "":
			return "Drive onto a marked route exit branch"
		return "Depart with W attached and online"
	return "Continue on the chosen route"


func _get_departure_blocker_text() -> String:
	if lifecycle == null:
		return ""
	if crew != null and not crew.are_all_survivors_aboard():
		var unboarded: Array[String] = crew.get_unboarded_survivor_names()
		return "Departure blocked: Survivor(s) in yard (%s)" % ", ".join(unboarded)
	if scenario != null and scenario.has_method("get_departure_blocked_reason"):
		var scenario_reason := str(scenario.get_departure_blocked_reason())
		if scenario_reason != "":
			return scenario_reason
	if train_resources != null and not train_resources.can_afford(TrainResources.RESOURCE_DIESEL, TrainResources.DEPARTURE_DIESEL_COST):
		return "Departure blocked: need %.0f diesel (have %.0f)" % [
			TrainResources.DEPARTURE_DIESEL_COST,
			train_resources.get_amount(TrainResources.RESOURCE_DIESEL),
		]
	return ""


func _short_departure_blocker(reason: String) -> String:
	var prefix := "Departure blocked: "
	if reason.begins_with(prefix):
		return reason.substr(prefix.length())
	return reason


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


func _get_poi_icon_kind(resource_type: String) -> String:
	match resource_type:
		TrainResources.RESOURCE_DIESEL:
			return "fuel"
		TrainResources.RESOURCE_FOOD:
			return "food"
	return "crate"


func _get_poi_color(resource_type: String) -> Color:
	match resource_type:
		TrainResources.RESOURCE_DIESEL:
			return POI_FUEL_COLOR
		TrainResources.RESOURCE_FOOD:
			return POI_FOOD_COLOR
		TrainResources.RESOURCE_PARTS:
			return POI_PARTS_COLOR
	return POI_PARTS_COLOR


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
	_add_scenario_context_items(items, world_position)
	_add_poi_context_items(items, world_position)
	if _get_unit_id_near_world_position(world_position) == "" and _get_poi_id_near_world_position(world_position) == "":
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
	var shunter_state := _get_unit_draw_state("S")
	if shunter_state.is_empty():
		return
	var shunter_anchor := yard.get_repair_anchor("shunter")
	var near_shunter_anchor := world_position.distance_to(shunter_anchor) <= CONTEXT_TARGET_RADIUS
	var near_shunter_unit := false
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


func _add_poi_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	var poi_id := _get_poi_id_near_world_position(world_position)
	if poi_id == "":
		return
	var poi: Dictionary = get_sector_poi_state(poi_id)
	if poi.is_empty():
		return

	var name := str(poi.get("name", poi_id))
	if not bool(poi.get("searched", false)):
		_add_context_item(items, "Search %s" % name, "search_poi", {
			"poi_id": poi_id,
		})
		return

	var amount := float(poi.get("available_amount", 0.0))
	var resource_type := str(poi.get("available_type", ""))
	if amount > 0.0 and resource_type != "":
		_add_context_item(items, "Haul %.0f %s to train" % [amount, resource_type], "haul_poi", {
			"poi_id": poi_id,
		})


func _add_scenario_context_items(items: Array[Dictionary], world_position: Vector2) -> void:
	if scenario == null:
		return
	for state in scenario.get_world_interaction_states():
		var position := state.get("position", Vector2.ZERO) as Vector2
		if world_position.distance_to(position) > CONTEXT_TARGET_RADIUS:
			continue
		var target_id := str(state.get("id", ""))
		if target_id == FirstRunScenario.ROUTE_DECISION_ID:
			continue

		var action_id := str(state.get("action_id", ""))
		_add_context_item(items, _get_scenario_context_label(state), "scenario_interaction", {
			"action_id": action_id,
			"target_id": target_id,
			"target_position": position,
			"target_label": str(state.get("label", target_id)),
			"duration": float(state.get("duration", 0.0)),
			"host_unit": str(state.get("host_unit", "")),
			"local_offset": state.get("local_offset", Vector2.ZERO),
		})


func _get_scenario_context_label(state: Dictionary) -> String:
	var label := str(state.get("label", state.get("id", "")))
	var action_id := str(state.get("action_id", ""))
	if action_id != FirstRunScenario.ACTION_ACTIVATE_WORKSHOP:
		return label

	var cost := float(state.get("parts_cost", FirstRunScenario.WORKSHOP_ACTIVATION_PARTS_COST))
	var available := 0.0
	if train_resources != null:
		available = train_resources.get_amount(TrainResources.RESOURCE_PARTS)
	if available < cost:
		return "%s (need %.0f parts; have %.0f)" % [label, cost, available]
	return "%s (uses %.0f parts; have %.0f)" % [label, cost, available]


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
		"search_poi":
			crew.assign_search_poi(selected_id, str(item.get("poi_id", "")))
		"haul_poi":
			crew.assign_haul_poi_resource(selected_id, str(item.get("poi_id", "")))
		"scenario_interaction":
			var assigned := crew.assign_scenario_interaction(
				selected_id,
				str(item.get("action_id", "")),
				str(item.get("target_id", "")),
				item.get("target_position", Vector2.ZERO) as Vector2,
				str(item.get("target_label", "")),
				float(item.get("duration", 0.0)),
				{},
				str(item.get("host_unit", "")),
				item.get("local_offset", Vector2.ZERO) as Vector2
			)
			if assigned:
				yard.last_status = "Assigned %s: %s" % [
					_get_context_actor_name(selected_id),
					str(item.get("target_label", "scenario task")),
				]
			else:
				yard.last_status = _get_context_assignment_failure_status(selected_id, item)


func _get_context_actor_name(survivor_id: String) -> String:
	var actor_state := crew.get_survivor_state(survivor_id)
	if actor_state.is_empty():
		return "crew"
	return str(actor_state.get("name", "crew"))


func _get_context_assignment_failure_status(survivor_id: String, item: Dictionary) -> String:
	var label := str(item.get("target_label", item.get("label", "task")))
	if survivor_id == "":
		return "Select a survivor before assigning %s" % label

	var selected := crew.get_survivor_state(survivor_id)
	var selected_status := str(selected.get("status_text", ""))
	if selected_status != "" and selected_status != "Idle":
		return selected_status
	if scenario != null and scenario.last_status != "":
		return str(scenario.last_status)
	return "Could not assign %s" % label


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
	var modal_size := Vector2(minf(480.0, playfield.size.x - 48.0), 290.0)
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

	var poi_id := _get_poi_id_near_world_position(world_position)
	if poi_id != "":
		var poi: Dictionary = get_sector_poi_state(poi_id)
		return str(poi.get("name", poi_id))

	var scenario_target := _get_scenario_target_near_world_position(world_position)
	if scenario_target != "":
		for state in get_scenario_draw_states():
			if str(state.get("id", "")) == scenario_target:
				return str(state.get("label", scenario_target))
		return scenario_target

	var yard_control := yard.get_yard_control_state()
	if world_position.distance_to(yard_control.get("repair_anchor", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS:
		return "Yard control"
	if world_position.distance_to(yard_control.get("power_anchor", Vector2.ZERO) as Vector2) <= CONTEXT_TARGET_RADIUS:
		return "Yard power"

	var target_unit := _get_unit_id_near_world_position(world_position)
	if target_unit != "":
		var state := _get_unit_draw_state(target_unit)
		var display_name := str(state.get("label", target_unit))
		var summary := str(state.get("capability_summary", ""))
		var ownership := "owned" if bool(state.get("active", false)) else "salvage"
		if summary != "":
			return "%s [%s] - %s" % [display_name, ownership, summary]
		return "%s [%s] (%s interior)" % [display_name, ownership, interior.get_unit_interior_label(target_unit)]

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


func _format_resource_stock() -> String:
	if train_resources == null:
		return "D0 F0 P0"
	return "D%.0f/%.0f F%.0f/%.0f P%.0f/%.0f" % [
		train_resources.get_amount(TrainResources.RESOURCE_DIESEL),
		train_resources.get_capacity(TrainResources.RESOURCE_DIESEL),
		train_resources.get_amount(TrainResources.RESOURCE_FOOD),
		train_resources.get_capacity(TrainResources.RESOURCE_FOOD),
		train_resources.get_amount(TrainResources.RESOURCE_PARTS),
		train_resources.get_capacity(TrainResources.RESOURCE_PARTS),
	]


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


func _sector_has_unit(unit_id: String) -> bool:
	if rail == null:
		return false
	return not _get_unit_draw_state(unit_id).is_empty()


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


func _get_poi_id_near_world_position(world_position: Vector2) -> String:
	var nearest_id := ""
	var nearest_distance := CONTEXT_TARGET_RADIUS
	for state in get_sector_poi_states():
		var position := state.get("position", Vector2.ZERO) as Vector2
		var distance := world_position.distance_to(position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_id = str(state.get("id", ""))
	return nearest_id


func _get_scenario_target_near_world_position(world_position: Vector2) -> String:
	var nearest_id := ""
	var nearest_distance := CONTEXT_TARGET_RADIUS
	for state in get_scenario_draw_states():
		var position := state.get("position", Vector2.ZERO) as Vector2
		var distance := world_position.distance_to(position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_id = str(state.get("id", ""))
	return nearest_id


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
	if train_resources != null:
		lines.append("Diesel cost: %.0f   Train diesel: %.0f" % [
			TrainResources.DEPARTURE_DIESEL_COST,
			train_resources.get_amount(TrainResources.RESOURCE_DIESEL),
		])
	var selected_route_label := _get_selected_route_label()
	if selected_route_label != "":
		lines.append("Route branch: %s" % selected_route_label)
	lines.append("Departing consist: %s" % rail.get_consist_summary())
	lines.append("Rolling stock left behind: %s" % rail.get_detached_summary())
	lines.append("Uncollected POI supplies are abandoned with this sector.")
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

	for exit_state in get_sector_exit_draw_states():
		var segment_id := str(exit_state.get("segment", ""))
		if rail.current_segment != segment_id:
			continue
		var exit_distance := float(exit_state.get("distance", 0.0))
		rail.distance = minf(rail.distance, maxf(exit_distance - 1.0, 0.0))
		return


func _get_selected_route_label() -> String:
	if scenario == null:
		return ""
	var scenario_state: Dictionary = scenario.get_state()
	var selected_route := str(scenario_state.get("selected_route", ""))
	if selected_route == "":
		return ""
	for option in scenario.get_route_options():
		if str(option.get("id", "")) == selected_route:
			return str(option.get("label", selected_route))
	return selected_route


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
	if departure_confirmation_open:
		return "Confirm departure: click Yes - leave sector or press Enter/Y; No/Esc cancels"

	var selected := crew.get_survivor_state(crew.get_selected_survivor_id())
	if not selected.is_empty():
		var selected_status := str(selected.get("status_text", ""))
		var task_status := str(selected.get("task_status", ""))
		if selected_status != "" and selected_status != "Idle" and _task_status_has_current_feedback(task_status):
			return selected_status
	if rail.blocked_reason != "":
		return rail.blocked_reason

	var departure_blocker := _get_departure_blocker_text()
	if _is_current_departure_attempt_blocker(departure_blocker):
		return departure_blocker
	if scenario != null and scenario.last_status != "" and scenario.last_status != "First run started":
		return scenario.last_status
	if yard.last_status != "":
		return yard.last_status
	if departure_blocker != "":
		return departure_blocker
	if not selected.is_empty():
		return str(selected.get("status_text", ""))
	return ""


func _task_status_has_current_feedback(task_status: String) -> bool:
	return task_status == CrewSimulation.STATUS_ASSIGNED \
			or task_status == CrewSimulation.STATUS_MOVING \
			or task_status == CrewSimulation.STATUS_INTERACTING \
			or task_status == CrewSimulation.STATUS_BLOCKED \
			or task_status == CrewSimulation.STATUS_CANCELLED


func _is_current_departure_attempt_blocker(departure_blocker: String) -> bool:
	if departure_blocker == "" or lifecycle == null or yard == null:
		return false
	if str(lifecycle.transition_blocked_reason) == "":
		return false
	if str(yard.last_status) != str(lifecycle.transition_blocked_reason):
		return false
	return departure_blocker == str(lifecycle.transition_blocked_reason)


func _yes_no(value: bool) -> String:
	if value:
		return "yes"
	return "no"


func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result


func _get_archetype_feature_summary(archetype_id: String) -> String:
	match archetype_id:
		WorldgenSemanticGenerator.ARCHETYPE_RURAL_THROUGH:
			return "sparse through main, wayside diesel"
		WorldgenSemanticGenerator.ARCHETYPE_VILLAGE_PASSING_STATION:
			return "station loop, platform route"
		WorldgenSemanticGenerator.ARCHETYPE_SMALL_TOWN_GOODS:
			return "goods loading, recoverable Sprint 10 salvage"
		WorldgenSemanticGenerator.ARCHETYPE_AGRICULTURAL_LOADING_POINT:
			return "agricultural loading, grain track, headshunt"
		WorldgenSemanticGenerator.ARCHETYPE_RIVER_VALLEY_CONSTRAINED:
			return "bridge/water crossing, constrained loop"
		WorldgenSemanticGenerator.ARCHETYPE_DECLINING_ABANDONED_BRANCH:
			return "overgrown storage, display-only abandoned track"
	return ""


func _on_off(value: bool) -> String:
	if value:
		return "on"
	return "off"
