extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Bridge Restriction Routing Tests ---")
	_test_bridge_mass_limit_evaluator()
	_test_uncouple_reduces_mass_clearing_bridge()
	_test_operational_ui_bridge_presentation()

	if _failures == 0:
		print("\nSprint 14 bridge restriction routing acceptance passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 bridge restriction routing acceptance FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _test_bridge_mass_limit_evaluator() -> void:
	print("Testing bridge mass limit evaluator...")
	var mobility := {
		"total_mass": 277.0,
		"total_length": 322.0,
		"unit_count": 5,
		"has_traction": true,
		"traction": 1.0,
		"capabilities": ["workshop"],
	}
	var bridge_reqs := {
		"require_traction": true,
		"max_mass": 240.0,
	}

	var eval := RouteRequirementEvaluator.evaluate(mobility, bridge_reqs, "Creek Bridge")
	_expect(not bool(eval.get("can_take_route", true)), "277t train rejected on 240t bridge limit")
	_expect(str(eval.get("primary_reason", "")).contains("exceeds Creek Bridge limit (240.0t max)"), "primary_reason mentions Creek Bridge limit")


func _test_uncouple_reduces_mass_clearing_bridge() -> void:
	print("Testing uncouple reduces mass clearing bridge...")
	var rail := RailMovement.new()
	# Default consist: L(120), A(35), B(35), W(25), S(62) = 277t
	rail.active_units = ["W", "L", "A", "B", "S"]
	var initial_mass := rail.get_total_mass()
	_expect(initial_mass == 277.0, "initial mass is 277t")

	var bridge_reqs := {
		"require_traction": true,
		"max_mass": 240.0,
	}

	var eval_before := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), bridge_reqs, "Creek Bridge")
	_expect(not bool(eval_before.get("can_take_route", true)), "initially blocked by mass")

	# Uncouple S (62t)
	rail.active_units = ["W", "L", "A", "B"]
	var reduced_mass := rail.get_total_mass()
	_expect(reduced_mass == 215.0, "reduced mass is 215t")

	var eval_after := RouteRequirementEvaluator.evaluate(rail.get_mobility_summary(), bridge_reqs, "Creek Bridge")
	_expect(bool(eval_after.get("can_take_route", false)), "cleared bridge after leaving 62t wagon")


func _test_operational_ui_bridge_presentation() -> void:
	print("Testing operational UI bridge presentation...")
	var mobility := {
		"total_mass": 277.0,
		"total_length": 322.0,
		"unit_count": 5,
		"has_traction": true,
		"traction": 1.0,
		"capabilities": ["workshop"],
	}
	var exit_def := {
		"id": "creek_bridge_exit",
		"route_id": "bridge",
		"label": "Creek Bridge Route",
		"requirements": {
			"require_traction": true,
			"max_mass": 240.0,
		},
	}

	var option := OperationalUIPresenter.present_route_option(exit_def, mobility)
	_expect(str(option.get("status_label", "")) == "BLOCKED", "status label is BLOCKED")
	_expect(str(option.get("action_hint", "")).contains("reduce train mass"), "action hint recommends reducing mass")
