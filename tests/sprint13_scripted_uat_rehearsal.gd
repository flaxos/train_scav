extends SceneTree

# Sprint 13 — Scripted UAT Rehearsal
# Rehearses the complete normal-game human UAT:
# 1. Player begins in Sector 1 with single locomotive L (traction = 1.0).
# 2. Multi-traction route (requiring min_traction >= 2.0) is initially BLOCKED.
# 3. Second locomotive/shunter S is visible on reachable siding in damaged condition.
# 4. Survivor repairs S to operational condition.
# 5. Shunts and physically couples S into consist -> consist becomes [S][W][L][A][B].
# 6. Train status summary updates to Traction: 2.
# 7. Previously blocked multi-traction route becomes AVAILABLE.
# 8. Drives through the exit boundary and confirms departure.
# 9. Enters Sector 2 with both locomotives persistent in consist and traction = 2.0.
# 10. Uncoupling S drops traction back to 1.0 while primary locomotive identity remains stable.

const MainScene := preload("res://scripts/bootstrap/main.gd")
const FirstRunScenario := preload("res://scripts/run/first_run_scenario.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 13 Scripted UAT Rehearsal ---")
	_run_sprint13_uat_rehearsal()
	_finish()


func _expect(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 13 scripted UAT rehearsal passed\n")
		quit(0)
	else:
		printerr("\nSprint 13 scripted UAT rehearsal FAILED with %d failure(s)\n" % _failures)
		quit(1)


func _run_sprint13_uat_rehearsal() -> void:
	var packed_scene := load("res://scenes/bootstrap/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main.tscn loads for Sprint 13 UAT")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# --- STEP 1: Advance to Sector 1 with single locomotive L ---
	_advance_to_sector1_single_loco(scene)

	var initial_mobility: Dictionary = scene.rail.get_mobility_summary()
	_expect(is_equal_approx(float(initial_mobility.get("traction", 0.0)), 1.0), "initial train in Sector 1 has 1.0 traction")
	_expect(scene.rail.active_units == ["W", "L", "A", "B"], "initial consist has [W, L, A, B]")

	# --- STEP 2: Verify Multi-Traction Route is BLOCKED with single loco ---
	var heavy_route_exit: Dictionary = {
		"id": "heavy_route_exit",
		"route_id": "heavy_route",
		"label": "Heavy Industrial Line",
		"segment": RailMovement.SEGMENT_INDUSTRIAL_EXIT,
		"distance": 220.0,
		"requirements": {
			"min_traction": 2.0,
			"max_mass": 350.0,
			"required_capabilities": ["workshop"],
		},
	}

	var eval_single := RouteRequirementEvaluator.evaluate(initial_mobility, heavy_route_exit["requirements"], "Heavy Industrial Line")
	_expect(not bool(eval_single.get("can_take_route", true)), "heavy route is BLOCKED with single loco")
	_expect(str(eval_single.get("primary_reason", "")).contains("requires 2 traction units"), "evaluator explains 2 traction units required")

	var route_presentation := OperationalUIPresenter.present_route_option(heavy_route_exit, initial_mobility)
	_expect(str(route_presentation.get("status_label", "")) == "BLOCKED", "UI displays route as BLOCKED")
	_expect(str(route_presentation.get("action_hint", "")).contains("Recover and couple a second operational locomotive"), "UI gives physical action hint to recover second loco")

	# --- STEP 3 & 4: Discover & Repair Shunter S on Siding B ---
	_expect(scene.rail.get_unit_type("S") == RailMovement.UNIT_SHUNTER, "S is present as shunter")
	_expect(scene.rail.get_powered_unit_condition("S") == RailMovement.CONDITION_DAMAGED, "S starts in DAMAGED condition")

	# Repair S
	scene.rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	_expect(scene.rail.get_powered_unit_condition("S") == RailMovement.CONDITION_OPERATIONAL, "S repaired to OPERATIONAL")

	# --- STEP 5: Physically Couple Shunter S to the Train ---
	var full_units: Array[String] = ["S", "W", "L", "A", "B"]
	scene.rail.active_units = full_units
	scene.rail.controlled_power_unit_id = "L"

	# --- STEP 6: Train Summary now shows Traction: 2.0 ---
	var multi_mobility: Dictionary = scene.rail.get_mobility_summary()
	_expect(is_equal_approx(float(multi_mobility.get("traction", 0.0)), 2.0), "multi-loco train has 2.0 traction")
	_expect(int(multi_mobility.get("operational_loco_count", 0)) == 2, "train reports 2 operational locomotives")

	var status_lines: Array[String] = scene.get_player_status_panel_lines()
	var status_text := "\n".join(status_lines)
	_expect(status_text.contains("Traction: 2"), "player status panel displays Traction: 2")
	_expect(status_text.contains("[S][W][L][A][B]"), "player status panel displays consist [S][W][L][A][B]")

	# --- STEP 7: Multi-Traction Route becomes AVAILABLE ---
	var eval_multi := RouteRequirementEvaluator.evaluate(multi_mobility, heavy_route_exit["requirements"], "Heavy Industrial Line")
	_expect(bool(eval_multi.get("can_take_route", false)) == true, "heavy route is now AVAILABLE with 2 locos")

	var route_pres_multi := OperationalUIPresenter.present_route_option(heavy_route_exit, multi_mobility)
	_expect(str(route_pres_multi.get("status_label", "")) == "AVAILABLE", "UI displays route as AVAILABLE")

	# --- STEP 8 & 9: Drive through exit & confirm departure into Sector 2 ---
	scene.rail.current_segment = RailMovement.SEGMENT_INDUSTRIAL_EXIT
	scene.rail.distance = 225.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1

	scene._check_departure_boundary()
	_expect(bool(scene.departure_confirmation_open) == true, "departure confirmation opens at exit boundary")

	var departed: bool = scene.confirm_sector_departure()
	_expect(departed, "successfully departed into Sector 2 with multi-loco train")
	_expect(scene.lifecycle.run_state.sector_index == 2, "entered Sector 2")

	# Sector 2 state verification
	_expect(scene.rail.active_units == ["S", "W", "L", "A", "B"], "both locomotives S and L persisted in Sector 2 consist")
	_expect(scene.rail.is_powered_unit("S"), "S remains powered unit in Sector 2")
	_expect(scene.rail.is_powered_unit("L"), "L remains powered unit in Sector 2")
	_expect(is_equal_approx(scene.rail.get_available_traction(), 2.0), "Sector 2 train maintains 2.0 traction")

	# --- STEP 10: Uncoupling S drops traction back to 1.0 ---
	_expect(scene.rail.decouple_joint("S", "W"), "uncoupled S from front of train")
	_expect(scene.rail.active_units == ["W", "L", "A", "B"], "consist is now [W, L, A, B]")
	_expect(is_equal_approx(scene.rail.get_available_traction(), 1.0), "traction drops back to 1.0 after uncoupling S")
	_expect(scene.rail.get_controlled_power_unit_id() == "L", "primary locomotive L remains control authority")

	scene.release_runtime_references()
	scene.queue_free()


func _advance_to_sector1_single_loco(scene: Node) -> void:
	# Clear Sector 0
	if scene.scenario != null:
		scene.scenario.obstruction_state = FirstRunScenario.STATE_CLEARED
		scene.scenario.onboard_fault_state = FirstRunScenario.STATE_REPAIRED
	if scene.train_resources != null:
		scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)
		scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 10.0)

	scene.rail.current_segment = RailMovement.SEGMENT_MAIN_EXIT
	scene.rail.distance = 265.0
	scene.rail.speed = 10.0
	scene.rail.direction = 1

	scene._check_departure_boundary()
	scene.confirm_sector_departure()

	# In Sector 1: couple W, bring workshop online
	var w_units: Array[String] = ["W", "L", "A", "B"]
	scene.rail.active_units = w_units
	scene.rail.controlled_power_unit_id = "L"
	if scene.scenario != null:
		scene.scenario.workshop_state = FirstRunScenario.STATE_ONLINE
	if scene.train_resources != null:
		scene.train_resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)
		scene.train_resources.set_amount(TrainResources.RESOURCE_PARTS, 10.0)
