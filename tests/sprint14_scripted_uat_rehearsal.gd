extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Scripted UAT Rehearsal ---")
	_rehearse_uat_scenario_a_bridge_restriction()
	_rehearse_uat_scenario_b_repairable_infrastructure()

	if _failures == 0:
		print("\nSprint 14 scripted UAT rehearsal passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 scripted UAT rehearsal FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _rehearse_uat_scenario_a_bridge_restriction() -> void:
	print("Rehearsing UAT A: Structural Bridge Restriction & Shunting Solution...")
	var rail := RailMovement.new()
	# Train consist: W(25), L(120), A(35), B(35), S(62) = 277t
	rail.active_units = ["W", "L", "A", "B", "S"]
	_expect(rail.get_total_mass() == 277.0, "consist starts at 277.0t")

	var bridge_exit := {
		"id": "creek_bridge_exit",
		"route_id": "bridge",
		"label": "Creek Bridge route",
		"requirements": {
			"require_traction": true,
			"max_mass": 240.0,
		},
	}

	# 1. Evaluate initial state -> BLOCKED
	var eval_init := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), bridge_exit.get("requirements", {}), "Creek Bridge route")
	_expect(not bool(eval_init.get("can_take_route", true)), "departure blocked initially due to 277t mass")
	var ui_init := OperationalUIPresenter.present_route_option(bridge_exit, rail.get_mobility_summary())
	_expect(str(ui_init.get("status_label", "")) == "BLOCKED", "UI displays BLOCKED")
	_expect(str(ui_init.get("action_hint", "")).contains("reduce train mass"), "UI suggests reducing train mass")

	# 2. Player uncouples heavy wagon S (62t) onto siding
	rail.active_units = ["W", "L", "A", "B"]
	_expect(rail.get_total_mass() == 215.0, "consist reduced to 215.0t")

	# 3. Re-evaluate -> AVAILABLE
	var eval_after := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), bridge_exit.get("requirements", {}), "Creek Bridge route")
	_expect(bool(eval_after.get("can_take_route", false)), "departure now available after shunting heavy wagon")
	var ui_after := OperationalUIPresenter.present_route_option(bridge_exit, rail.get_mobility_summary())
	_expect(str(ui_after.get("status_label", "")) == "AVAILABLE", "UI displays AVAILABLE")


func _rehearse_uat_scenario_b_repairable_infrastructure() -> void:
	print("Rehearsing UAT B: Repairable Turnout & Damaged Track Solution...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var res := TrainResources.new()
	res.set_amount(TrainResources.RESOURCE_PARTS, 8.0)
	res.set_amount(TrainResources.RESOURCE_DIESEL, 20.0)
	crew.train_resources = res

	# 1. Turnout is jammed
	rail.set_point_condition("P1", RailMovement.CONDITION_DAMAGED)
	yard.sync_points_from_rail_layout()
	_expect(not rail.request_point_toggle("P1"), "cannot toggle jammed turnout")

	# 2. Track section is damaged
	rail.set_track_condition("main_exit", RailMovement.CONDITION_DAMAGED)
	var exit_def := {
		"id": "forward_exit",
		"route_id": "forward",
		"label": "Forward Line",
		"requirements": {
			"require_traction": true,
			"required_segments_operational": ["main_exit"],
		},
	}
	var eval_init := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), exit_def.get("requirements", {}), "Forward Line")
	_expect(not bool(eval_init.get("can_take_route", true)), "route blocked by damaged track section")

	# 3. Crew repairs turnout P1
	var engineer_id := "marta"
	crew.force_survivor_yard_position(engineer_id, yard.get_repair_anchor("point", "P1"))
	_expect(crew.assign_repair_point(engineer_id, "P1"), "assigned repair_point to engineer")
	for _i in range(150):
		crew.step(0.1)
	_expect(rail.get_point_condition("P1") == RailMovement.CONDITION_OPERATIONAL, "turnout P1 repaired")
	_expect(rail.request_point_toggle("P1"), "turnout P1 can now be toggled")

	# 4. Crew repairs damaged track section
	crew.force_survivor_yard_position(engineer_id, yard.get_repair_anchor("track", "main_exit"))
	_expect(crew.assign_repair_track(engineer_id, "main_exit"), "assigned repair_track to engineer")
	for _i in range(150):
		crew.step(0.1)
	_expect(rail.get_track_condition("main_exit") == RailMovement.CONDITION_OPERATIONAL, "track section repaired")

	# 5. Route becomes available
	var eval_repaired := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), exit_def.get("requirements", {}), "Forward Line")
	_expect(bool(eval_repaired.get("can_take_route", false)), "route now clear and available")

	# 6. Crew boards train
	for survivor in crew.survivors:
		survivor["spatial_state"] = CrewSimulation.SPATIAL_ABOARD
		survivor["host_unit"] = "L"
		survivor["task_status"] = CrewSimulation.STATUS_IDLE
	_expect(crew.are_all_survivors_aboard(), "all crew safely aboard train before departure")
