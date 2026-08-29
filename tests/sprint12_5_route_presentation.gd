extends SceneTree

# Sprint 12.5 — Route Presentation Tests.
# Verifies that OperationalUIPresenter formats route eligibility, reasons,
# and actionable physical hints from evaluator outputs for human players.

const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 12.5 Route Presentation Tests ---")
	test_sector_1_route_presentation()
	test_action_hints()
	test_switch_alignment_detection()
	_finish()


func test_sector_1_route_presentation() -> void:
	print("Testing Sector 1 route presentation...")
	var sector_1_def := SectorDefinition.create_for_index(12345, 1)

	# Consist [S, W, L, A, B]: 277t, 322px, workshop capability
	var mobility_heavy_with_workshop := {
		"total_mass": 277.0,
		"total_length": 322.0,
		"unit_count": 5,
		"has_traction": true,
		"powered_unit_id": "S",
		"capabilities": ["workshop", "storage", "traction"],
	}

	var active_switches := {"P1": "main", "P2": "main", "P3": "main"}
	var route_views := OperationalUIPresenter.present_all_routes(
		sector_1_def.route_exits,
		mobility_heavy_with_workshop,
		active_switches
	)

	_expect(route_views.size() == 3, "Sector 1 presents 3 routes")

	var direct_view: Dictionary = {}
	var industrial_view: Dictionary = {}
	var settlement_view: Dictionary = {}

	for rv in route_views:
		match str(rv.get("id", "")):
			"direct", "direct_exit":
				direct_view = rv
			"industrial", "industrial_exit":
				industrial_view = rv
			"settlement", "settlement_exit":
				settlement_view = rv

	# 1. Direct route: blocked by mass (277t > 250t)
	_expect(bool(direct_view.get("available", true)) == false, "Direct route is blocked for 277t train")
	_expect(str(direct_view.get("status_label", "")) == "BLOCKED", "Direct route status is BLOCKED")
	var direct_reasons: Array = direct_view.get("reasons", []) as Array
	var direct_has_mass_explanation := false
	for r in direct_reasons:
		if str(r).contains("250") and str(r).contains("277"):
			direct_has_mass_explanation = true
	_expect(direct_has_mass_explanation, "Direct route reasons clearly report 250t limit vs 277t train mass")
	_expect(str(direct_view.get("action_hint", "")).contains("reduce train mass"), "Direct route gives actionable mass reduction hint")

	# 2. Industrial route: available (277t <= 320t and has workshop)
	_expect(bool(industrial_view.get("available", false)) == true, "Industrial route is available for 277t train with workshop")
	_expect(str(industrial_view.get("status_label", "")) == "AVAILABLE", "Industrial route status is AVAILABLE")
	var industrial_reasons: Array = industrial_view.get("reasons", []) as Array
	var industrial_has_workshop_check := false
	for r in industrial_reasons:
		if str(r).contains("Workshop ✓"):
			industrial_has_workshop_check = true
	_expect(industrial_has_workshop_check, "Industrial route confirms workshop capability satisfied")

	# 3. Settlement route: blocked by length/accommodation
	_expect(bool(settlement_view.get("available", true)) == false, "Settlement route is blocked for 322px train without accommodation")
	var settlement_reasons: Array = settlement_view.get("reasons", []) as Array
	var settlement_has_accommodation_reason := false
	for r in settlement_reasons:
		if str(r).contains("Accommodation"):
			settlement_has_accommodation_reason = true
	_expect(settlement_has_accommodation_reason, "Settlement route explains missing crew accommodation")


func test_action_hints() -> void:
	print("Testing actionable physical hints...")
	var mobility_overloaded := {
		"total_mass": 350.0,
		"total_length": 250.0,
		"unit_count": 5,
		"has_traction": true,
		"capabilities": ["workshop"],
	}
	var exit_def := {
		"id": "heavy_exit",
		"route_id": "heavy",
		"label": "Heavy Branch",
		"requirements": {"max_mass": 320.0},
	}
	var view := OperationalUIPresenter.present_route_option(exit_def, mobility_overloaded)
	_expect(bool(view.get("available", true)) == false, "overloaded route is blocked")
	_expect(str(view.get("action_hint", "")).contains("320"), "action hint suggests reducing mass below 320t")


func test_switch_alignment_detection() -> void:
	print("Testing switch alignment hints...")
	var mobility_ok := {
		"total_mass": 200.0,
		"total_length": 200.0,
		"unit_count": 3,
		"has_traction": true,
		"capabilities": ["workshop"],
	}
	var exit_def := {
		"id": "industrial_exit",
		"route_id": "industrial",
		"label": "Industrial Line",
		"requirements": {"max_mass": 320.0, "required_capabilities": ["workshop"]},
	}

	# When P2 is main, industrial branch (siding) is NOT aligned
	var switches_main := {"P1": "main", "P2": "main", "P3": "main"}
	var view_not_aligned := OperationalUIPresenter.present_route_option(exit_def, mobility_ok, switches_main)
	_expect(bool(view_not_aligned.get("switch_aligned", true)) == false, "Industrial not aligned when P2 is main")
	_expect(str(view_not_aligned.get("action_hint", "")).contains("P2"), "Action hint instructs player to set P2 switch")

	# When P2 is siding, industrial branch is aligned
	var switches_siding := {"P1": "main", "P2": "siding", "P3": "main"}
	var view_aligned := OperationalUIPresenter.present_route_option(exit_def, mobility_ok, switches_siding)
	_expect(bool(view_aligned.get("switch_aligned", false)) == true, "Industrial is aligned when P2 is siding")
	_expect(str(view_aligned.get("action_hint", "")).contains("Drive forward"), "Aligned action hint instructs player to drive forward")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12.5 route presentation acceptance passed")
		quit(0)
	else:
		print("\nSprint 12.5 route presentation acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
