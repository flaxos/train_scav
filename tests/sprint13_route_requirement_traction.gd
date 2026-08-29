extends SceneTree

# Sprint 13 — Route Requirement Traction Tests
# Verifies that routes requiring multiple traction units are blocked with single-loco trains
# and become eligible once a second operational powered unit is coupled into the consist.

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 13 Route Requirement Traction Tests ---")
	_test_single_loco_route_blocked()
	_test_multi_loco_route_available()
	_test_ui_route_option_presentation()
	_finish()


func _expect(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 13 route requirement traction acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 13 route requirement traction acceptance FAILED with %d failure(s)" % _failures)
		quit(1)


func _test_single_loco_route_blocked() -> void:
	print("Testing single loco train blocked on multi-traction route...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"

	var mobility := rail.get_mobility_summary()
	var requirements: Dictionary = {
		"min_traction": 2.0,
		"max_mass": 350.0,
	}

	var eval := RouteRequirementEvaluator.evaluate(mobility, requirements, "Heavy Mountain Line")
	_expect(not bool(eval.get("can_take_route", true)), "single loco train cannot take 2-traction route")
	_expect(eval.get("primary_reason", "").contains("requires 2 traction units"), "primary reason states 2 traction units required")
	_expect(eval.get("primary_reason", "").contains("train has 1"), "primary reason states train has 1")


func _test_multi_loco_route_available() -> void:
	print("Testing multi-loco train eligible on multi-traction route...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	var mobility := rail.get_mobility_summary()
	var requirements: Dictionary = {
		"min_traction": 2.0,
		"max_mass": 350.0,
	}

	var eval := RouteRequirementEvaluator.evaluate(mobility, requirements, "Heavy Mountain Line")
	_expect(bool(eval.get("can_take_route", false)) == true, "multi-loco train can take 2-traction route")
	_expect(str(eval.get("primary_reason", "")) == "", "no blocked reason for eligible multi-loco train")


func _test_ui_route_option_presentation() -> void:
	print("Testing UI route option presentation and action hints...")
	var rail := RailMovement.new()
	var units: Array[String] = ["L", "A", "B"]
	rail.active_units = units
	rail.controlled_power_unit_id = "L"

	var exit_def: Dictionary = {
		"id": "heavy_mountain_exit",
		"route_id": "heavy_mountain",
		"label": "Heavy Mountain Line",
		"requirements": {
			"min_traction": 2.0,
		},
	}

	# 1. Single loco presentation
	var opt_blocked := OperationalUIPresenter.present_route_option(exit_def, rail.get_mobility_summary())
	_expect(not bool(opt_blocked.get("available", true)), "UI marks route BLOCKED with 1 loco")
	_expect(str(opt_blocked.get("status_label", "")) == "BLOCKED", "status label is BLOCKED")
	var reasons_blocked: Array = opt_blocked.get("reasons", []) as Array
	var reasons_text_blocked := " ".join(reasons_blocked)
	_expect(reasons_text_blocked.contains("Traction required: 2 units (Train: 1)"), "reasons list explains 2 units needed vs 1")
	_expect(str(opt_blocked.get("action_hint", "")).contains("Recover and couple a second operational locomotive"), "action hint advises recovering second loco")

	# 2. Multi-loco presentation
	var four_units: Array[String] = ["L", "A", "B", "S"]
	rail.active_units = four_units
	rail.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)

	var opt_avail := OperationalUIPresenter.present_route_option(exit_def, rail.get_mobility_summary())
	_expect(bool(opt_avail.get("available", false)) == true, "UI marks route AVAILABLE with 2 locos")
	_expect(str(opt_avail.get("status_label", "")) == "AVAILABLE", "status label is AVAILABLE")
	var reasons_avail: Array = opt_avail.get("reasons", []) as Array
	var reasons_text_avail := " ".join(reasons_avail)
	_expect(reasons_text_avail.contains("Traction required: 2 units (Train: 2 ✓)"), "reasons list shows traction satisfied")
