extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Damaged Track Repair Tests ---")
	_test_damaged_track_blocks_route()
	_test_operational_ui_track_hazard()
	_test_crew_repairs_damaged_track()

	if _failures == 0:
		print("\nSprint 14 damaged track repair acceptance passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 damaged track repair acceptance FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _test_damaged_track_blocks_route() -> void:
	print("Testing damaged track blocks route...")
	var rail := RailMovement.new()
	rail.set_track_condition("main_west", RailMovement.CONDITION_DAMAGED)

	var reqs := {
		"require_traction": true,
		"required_segments_operational": ["main_west"],
	}

	var eval := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), reqs, "West Route")
	_expect(not bool(eval.get("can_take_route", true)), "route blocked by damaged track")
	_expect(str(eval.get("primary_reason", "")).contains("requires operational track 'main_west'"), "primary reason mentions damaged track")


func _test_operational_ui_track_hazard() -> void:
	print("Testing operational UI track hazard presentation...")
	var rail := RailMovement.new()
	rail.set_track_condition("main_west", RailMovement.CONDITION_DAMAGED)

	var exit_def := {
		"id": "west_exit",
		"route_id": "west",
		"label": "West Exit Route",
		"requirements": {
			"require_traction": true,
			"required_segments_operational": ["main_west"],
		},
	}

	var option := OperationalUIPresenter.present_route_option(exit_def, rail.get_mobility_summary())
	_expect(str(option.get("status_label", "")) == "BLOCKED", "option is BLOCKED")
	_expect(str(option.get("action_hint", "")).contains("Assign crew to repair damaged track section"), "action hint recommends repairing track")


func _test_crew_repairs_damaged_track() -> void:
	print("Testing crew repairs damaged track...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var res := TrainResources.new()
	res.set_amount(TrainResources.RESOURCE_PARTS, 6.0)
	crew.train_resources = res

	rail.set_track_condition("main_west", RailMovement.CONDITION_DAMAGED)

	var survivor_id: String = crew.get_survivor_ids()[0]
	crew.force_survivor_yard_position(survivor_id, yard.get_repair_anchor("track", "main_west"))

	_expect(crew.assign_repair_track(survivor_id, "main_west"), "assign_repair_track succeeds")

	for _i in range(150):
		crew.step(0.1)

	_expect(rail.get_track_condition("main_west") == RailMovement.CONDITION_OPERATIONAL, "track condition restored to operational")
	_expect(res.get_amount(TrainResources.RESOURCE_PARTS) == 4.0, "consumed 2 parts for track repair")

	var reqs := {
		"require_traction": true,
		"required_segments_operational": ["main_west"],
	}
	var eval := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), reqs, "West Route")
	_expect(bool(eval.get("can_take_route", false)), "route is now eligible after track repair")
