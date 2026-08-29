extends SceneTree

# Sprint 8 scene-level smoke test for the playable vertical-slice UX hooks.

const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 8 Scene Vertical Slice Tests ---")
	await test_sector0_exit_feedback_is_explicit()
	await test_scene_exposes_vertical_slice_guidance_and_actions()
	_finish()


func test_sector0_exit_feedback_is_explicit() -> void:
	print("Testing Sector 0 exit feedback...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var opening_def = scene.lifecycle.current_sector.definition
	scene.rail.current_segment = opening_def.exit_segment
	scene.rail.distance = opening_def.exit_distance + 8.0
	scene.rail.direction = 1
	scene.rail.speed = 25.0
	scene.rail.throttle = 0.4
	scene._process(1.0 / 60.0)
	_expect(not scene.is_departure_confirmation_open(), "blocked Sector 0 exit does not open departure confirmation")
	_expect(scene.rail.speed <= 0.05, "blocked Sector 0 exit hard-brakes the train")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Status: Departure blocked: opening obstruction still blocks the route"), "blocked Sector 0 exit status explains the obstruction")

	scene.scenario.execute_scenario_interaction(FirstRunScenario.ACTION_CLEAR_OBSTRUCTION, FirstRunScenario.OBSTRUCTION_ID, "olek")
	scene.rail.blocked_reason = ""
	scene.rail.current_segment = opening_def.exit_segment
	scene.rail.distance = opening_def.exit_distance + 8.0
	scene.rail.direction = 1
	scene.rail.speed = 25.0
	scene.rail.throttle = 0.4
	scene._process(1.0 / 60.0)
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Status: Departure blocked: onboard fault needs engineer response"), "blocked Sector 0 exit status replaces stale scenario text with the fault blocker")

	scene.scenario.execute_scenario_interaction(FirstRunScenario.ACTION_REPAIR_ONBOARD_FAULT, FirstRunScenario.ONBOARD_FAULT_ID, "marta")
	scene.rail.blocked_reason = ""
	scene.rail.current_segment = opening_def.exit_segment
	scene.rail.distance = opening_def.exit_distance + 8.0
	scene.rail.direction = 1
	scene.rail.speed = 25.0
	scene.rail.throttle = 0.4
	scene._process(1.0 / 60.0)
	_expect(scene.is_departure_confirmation_open(), "resolved Sector 0 exit opens departure confirmation")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Status: Confirm departure"), "departure confirmation is visible in the side-panel status")

	scene.queue_free()


func test_scene_exposes_vertical_slice_guidance_and_actions() -> void:
	print("Testing playable scene vertical slice hooks...")
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("get_vertical_slice_state"), "scene exposes vertical-slice state")
	_expect(scene.has_method("get_scenario_draw_states"), "scene exposes scenario draw states")
	_expect(scene.has_method("get_sector_exit_draw_states"), "scene exposes sector route exit draw states")
	if not scene.has_method("get_vertical_slice_state") or not scene.has_method("get_scenario_draw_states"):
		scene.queue_free()
		return

	var guide := "\n".join(scene.get_uat_tutorial_lines())
	_expect(guide.contains("Train Scav - Sprint 12 UAT"), "guide names the current sprint")
	_expect(guide.contains("Sprint 11 Procgen Check"), "guide includes the current sprint load check")
	_expect(guide.contains("vertical slice"), "guide explains this is the vertical slice")
	_expect(guide.contains("Shunter S appears in Sector 1"), "guide explains shunter is not in the opening sector")
	_expect(guide.contains("drive onto"), "guide explains final route choice is made by track branch")
	var initial_state: Dictionary = scene.get_vertical_slice_state()
	_expect(str(initial_state.get("phase", "")) == FirstRunScenario.PHASE_OPENING, "scene starts in opening phase")
	_expect(bool(initial_state.get("obstruction_active", false)), "opening obstruction is active")
	_expect(bool(initial_state.get("onboard_fault_active", false)), "onboard fault is active")
	_expect(not _detached_has_unit(scene.rail, "W"), "opening scene does not show W before the industrial sector")
	_expect(not _unit_visible(scene.rail, "S"), "opening scene does not expose a phantom shunter")
	_expect(not _anchor_has_id(scene.get_anchor_icon_states(), "shunter"), "opening scene hides shunter repair anchor until S exists")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Exit blocked:"), "side panel reports why first-sector departure is blocked")
	_expect(_scenario_draw_has(scene.get_scenario_draw_states(), FirstRunScenario.OBSTRUCTION_ID), "scene exposes obstruction draw state")
	_expect(_scenario_draw_has(scene.get_scenario_draw_states(), FirstRunScenario.ONBOARD_FAULT_ID), "scene exposes onboard fault draw state")

	scene.rail.current_segment = FirstRunScenario.OBSTRUCTION_SEGMENT
	scene.rail.distance = FirstRunScenario.OBSTRUCTION_DISTANCE + 30.0
	scene.rail.speed = 20.0
	scene.rail.direction = 1
	scene.rail.set_throttle(1.0)
	scene._process(0.1)
	_expect(is_equal_approx(scene.rail.speed, 0.0), "playable scene physically stops at the active opening obstruction")

	scene.crew.select_survivor("olek")
	var obstruction: Dictionary = scene.scenario.get_interaction_state(FirstRunScenario.OBSTRUCTION_ID)
	scene._open_context_menu(scene.world_to_screen_position(obstruction.get("position", Vector2.ZERO) as Vector2))
	_expect(_labels_contain(scene.get_context_menu_labels(), "Clear track obstruction"), "right-click obstruction offers clear action")
	scene._close_context_menu()
	scene._open_context_menu(scene.world_to_screen_position(scene.yard.get_repair_anchor("shunter")))
	_expect(not _labels_contain(scene.get_context_menu_labels(), "Repair shunter S"), "opening sector does not offer repair for missing shunter")
	scene._close_context_menu()

	scene.scenario.execute_scenario_interaction(FirstRunScenario.ACTION_CLEAR_OBSTRUCTION, FirstRunScenario.OBSTRUCTION_ID, "olek")
	scene.scenario.execute_scenario_interaction(FirstRunScenario.ACTION_REPAIR_ONBOARD_FAULT, FirstRunScenario.ONBOARD_FAULT_ID, "marta")
	scene.train_resources.set_amount("diesel", 24.0)
	_expect(scene.lifecycle.request_transition(), "scene fixture can enter industrial sector")
	scene.rail = scene.lifecycle.current_sector.rail
	scene.yard = scene.lifecycle.current_sector.yard
	scene.interior = scene.crew.interior
	var industrial_state: Dictionary = scene.get_vertical_slice_state()
	_expect(str(industrial_state.get("phase", "")) == FirstRunScenario.PHASE_INDUSTRIAL, "scene enters industrial phase")
	_expect(_detached_has_unit(scene.rail, "W"), "industrial scene exposes W as detached physical rolling stock")
	_expect(_detached_has_unit(scene.rail, "S"), "industrial scene exposes S as detached physical shunter")
	_expect(_anchor_has_id(scene.get_anchor_icon_states(), "shunter"), "industrial scene exposes shunter repair anchor when S exists")
	_expect(_physically_couple_workshop(scene), "scene fixture physically couples W before route-choice UX check")

	var activation: Dictionary = scene.scenario.get_interaction_state(FirstRunScenario.WORKSHOP_ACTIVATION_ID)
	_expect(not activation.is_empty(), "online-effect fixture exposes workshop activation task")
	scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 0.0)
	scene.crew.select_survivor("marta")
	scene._open_context_menu(scene.world_to_screen_position(activation.get("position", Vector2.ZERO) as Vector2))
	_expect(_labels_contain(scene.get_context_menu_labels(), "need 2 parts; have 0"), "workshop activation menu states missing parts")
	_expect(scene._confirm_context_menu_at(scene.get_context_menu_option_position("Activate workshop W")), "workshop activation can be confirmed through the context menu")
	_step_scene_task_until_done(scene, "marta", 12.0)
	_expect(not bool(scene.get_vertical_slice_state().get("workshop_online", false)), "workshop stays offline when activation lacks parts")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Need 2 parts to activate workshop"), "failed activation status explains missing parts instead of only W offline")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Workshop W: offline"), "side panel keeps explicit offline workshop state after failed activation")

	scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 5.0)
	_expect(scene.crew.assign_scenario_interaction(
		"marta",
		str(activation.get("action_id", "")),
		str(activation.get("id", "")),
		activation.get("position", Vector2.ZERO) as Vector2,
		str(activation.get("label", "")),
		float(activation.get("duration", 0.0))
	), "Marta can be assigned to activate W through scene crew task")
	_step_scene_task_until_done(scene, "marta", 12.0)
	_expect(bool(scene.get_vertical_slice_state().get("workshop_online", false)), "scene crew task brings W online")
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Workshop W: online"), "side panel makes online workshop effect explicit")
	_expect(scene.has_method("get_workshop_visual_state"), "scene exposes workshop visual state")
	if scene.has_method("get_workshop_visual_state"):
		var workshop_visual: Dictionary = scene.get_workshop_visual_state()
		_expect(bool(workshop_visual.get("online", false)), "workshop visual state records W as online")
		_expect(str(workshop_visual.get("label", "")).contains("ONLINE"), "workshop visual label says ONLINE")

	scene.scenario.selected_route = ""
	_expect(_lines_contain(scene.get_compact_debug_lines(), "Drive onto a marked route exit branch"), "objective tells the player to choose by physical route branch")
	if scene.has_method("get_sector_exit_draw_states"):
		var route_exits: Array[Dictionary] = scene.get_sector_exit_draw_states()
		_expect(route_exits.size() >= 3, "industrial yard exposes three route exit branches")
		_expect(_exit_draw_has_route(route_exits, "direct"), "direct route branch is drawn")
		_expect(_exit_draw_has_route(route_exits, "industrial"), "industrial route branch is drawn")
		_expect(_exit_draw_has_route(route_exits, "settlement"), "settlement route branch is drawn")
	var workshop_position := _unit_position(scene.rail, "W")
	scene._open_context_menu(scene.world_to_screen_position(workshop_position))
	_expect(not _labels_contain(scene.get_context_menu_labels(), "Choose Industrial route"), "right-clicking online workshop W does not offer menu route choice")
	scene._close_context_menu()
	scene._open_context_menu(scene.world_to_screen_position(FirstRunScenario.ROUTE_DECISION_ANCHOR))
	_expect(not _labels_contain(scene.get_context_menu_labels(), "Choose Industrial route"), "route intel marker does not offer menu route choice")
	scene._close_context_menu()

	scene.queue_free()


func _scenario_draw_has(states: Array[Dictionary], target_id: String) -> bool:
	for state in states:
		if str(state.get("id", "")) == target_id:
			return true
	return false


func _detached_has_unit(rail: RefCounted, unit_id: String) -> bool:
	for consist in rail.detached_consists:
		var units: Array = consist.get("units", [])
		if units.has(unit_id):
			return true
	return false


func _unit_visible(rail: RefCounted, unit_id: String) -> bool:
	for state in rail.get_unit_draw_states():
		if str(state.get("id", "")) == unit_id:
			return true
	return false


func _unit_position(rail: RefCounted, unit_id: String) -> Vector2:
	for state in rail.get_unit_draw_states():
		if str(state.get("id", "")) == unit_id:
			return state.get("position", Vector2.ZERO) as Vector2
	return Vector2.ZERO


func _physically_couple_workshop(scene: Node) -> bool:
	scene.rail.set_yard_point_route("P2", "siding")
	scene.rail.max_speed = 10.0
	scene.rail.acceleration = 24.0
	scene.rail.coast_deceleration = 6.0
	scene.rail.set_throttle(1.0)
	var elapsed := 0.0
	while elapsed < 140.0 and not scene.rail.can_couple_unit("W"):
		scene.rail.step(0.1, false)
		elapsed += 0.1
	scene.rail.set_throttle(0.0)
	if not scene.rail.can_couple_unit("W"):
		return false
	return scene.rail.couple_nearest()


func _anchor_has_id(states: Array[Dictionary], anchor_id: String) -> bool:
	for state in states:
		if str(state.get("id", "")) == anchor_id:
			return true
	return false


func _lines_contain(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if line.contains(needle):
			return true
	return false


func _labels_contain(labels: Array[String], needle: String) -> bool:
	for label in labels:
		if label.contains(needle):
			return true
	return false


func _step_scene_task_until_done(scene: Node, survivor_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds:
		var state: Dictionary = scene.crew.get_survivor_state(survivor_id)
		var status := str(state.get("task_status", ""))
		if status != "assigned" and status != "moving" and status != "interacting":
			return
		scene._process(0.1)
		elapsed += 0.1


func _exit_draw_has_route(exits: Array[Dictionary], route_id: String) -> bool:
	for exit_state in exits:
		if str(exit_state.get("route_id", exit_state.get("id", ""))) == route_id:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 8 scene vertical slice acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 8 scene vertical slice FAILED with %d failure(s)" % _failures)
		quit(1)
