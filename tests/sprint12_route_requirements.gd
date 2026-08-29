extends SceneTree

# Sprint 12 — Route Requirements Evaluation Tests.
# Verifies that RouteRequirementEvaluator deterministically validates
# train mobility summaries against requirement dictionaries and formats readable summaries.

const RouteRequirementEvaluator := preload("res://scripts/sector/route_requirement_evaluator.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 12 Route Requirements Tests ---")
	test_empty_requirements_unrestricted()
	test_traction_requirement()
	test_mass_thresholds()
	test_length_thresholds()
	test_unit_count_thresholds()
	test_required_capabilities()
	test_combined_requirements()
	test_requirements_formatting()
	_finish()


func test_empty_requirements_unrestricted() -> void:
	print("Testing empty/unrestricted requirements...")
	var mobility := {
		"total_mass": 200.0,
		"total_length": 250.0,
		"unit_count": 4,
		"has_traction": true,
		"capabilities": ["traction", "crew_accommodation"],
	}
	var res: Dictionary = RouteRequirementEvaluator.evaluate(mobility, {}, "Main Route")
	_expect(bool(res.get("can_take_route", false)) == true, "empty requirements always permit route")
	_expect(str(res.get("primary_reason", "")) == "", "no blocker reason for unrestricted route")


func test_traction_requirement() -> void:
	print("Testing traction requirement...")
	var mobility_unpowered := {
		"total_mass": 100.0,
		"total_length": 120.0,
		"unit_count": 2,
		"has_traction": false,
		"capabilities": ["resource_storage"],
	}
	var reqs := {
		"require_traction": true,
	}
	var res: Dictionary = RouteRequirementEvaluator.evaluate(mobility_unpowered, reqs, "Exit")
	_expect(bool(res.get("can_take_route", true)) == false, "unpowered train fails traction requirement")
	_expect(str(res.get("primary_reason", "")).contains("no operational traction authority"), "blocked reason mentions traction authority")

	var mobility_powered := mobility_unpowered.duplicate()
	mobility_powered["has_traction"] = true
	var res_ok: Dictionary = RouteRequirementEvaluator.evaluate(mobility_powered, reqs, "Exit")
	_expect(bool(res_ok.get("can_take_route", false)) == true, "powered train passes traction requirement")


func test_mass_thresholds() -> void:
	print("Testing mass thresholds...")
	var mobility := {
		"total_mass": 167.0,
		"total_length": 192.0,
		"unit_count": 3,
		"has_traction": true,
		"capabilities": ["traction"],
	}
	var reqs_max_ok := {"max_mass": 250.0}
	var res_max_ok: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_max_ok, "Direct Route")
	_expect(bool(res_max_ok.get("can_take_route", false)) == true, "mass 167t < 250t max passes")

	var reqs_max_fail := {"max_mass": 150.0}
	var res_max_fail: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_max_fail, "Light Branch")
	_expect(bool(res_max_fail.get("can_take_route", true)) == false, "mass 167t > 150t max fails")
	_expect(str(res_max_fail.get("primary_reason", "")).contains("exceeds Light Branch limit (150.0t max)"), "mass limit failure explains limit")

	var reqs_min_fail := {"min_mass": 200.0}
	var res_min_fail: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_min_fail, "Heavy Line")
	_expect(bool(res_min_fail.get("can_take_route", true)) == false, "mass 167t < 200t min fails")


func test_length_thresholds() -> void:
	print("Testing length thresholds...")
	var mobility := {
		"total_mass": 215.0,
		"total_length": 260.0,
		"unit_count": 4,
		"has_traction": true,
		"capabilities": ["traction"],
	}
	var reqs_ok := {"max_length": 300.0}
	var res_ok: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_ok, "Siding Exit")
	_expect(bool(res_ok.get("can_take_route", false)) == true, "length 260px < 300px max passes")

	var reqs_fail := {"max_length": 240.0}
	var res_fail: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_fail, "Short Loop")
	_expect(bool(res_fail.get("can_take_route", true)) == false, "length 260px > 240px max fails")
	_expect(str(res_fail.get("primary_reason", "")).contains("exceeds Short Loop limit (240px max)"), "length failure explains limit")


func test_unit_count_thresholds() -> void:
	print("Testing unit count thresholds...")
	var mobility := {
		"total_mass": 215.0,
		"total_length": 260.0,
		"unit_count": 5,
		"has_traction": true,
		"capabilities": ["traction"],
	}
	var reqs_fail := {"max_units": 4}
	var res_fail: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_fail, "Short Platform")
	_expect(bool(res_fail.get("can_take_route", true)) == false, "5 units > 4 max fails")
	_expect(str(res_fail.get("primary_reason", "")).contains("exceeds Short Platform limit (4 max)"), "unit count failure explains limit")


func test_required_capabilities() -> void:
	print("Testing required capabilities...")
	var mobility := {
		"total_mass": 167.0,
		"total_length": 192.0,
		"unit_count": 3,
		"has_traction": true,
		"capabilities": ["traction", "crew_accommodation", "resource_storage"],
	}
	var reqs_workshop := {
		"required_capabilities": ["workshop"],
	}
	var res_fail: Dictionary = RouteRequirementEvaluator.evaluate(mobility, reqs_workshop, "Industrial Route")
	_expect(bool(res_fail.get("can_take_route", true)) == false, "missing workshop capability fails")
	_expect(str(res_fail.get("primary_reason", "")).contains("requires capability 'workshop'"), "reason names missing workshop capability")

	var mobility_with_workshop := mobility.duplicate(true)
	(mobility_with_workshop["capabilities"] as Array).append("workshop")
	var res_ok: Dictionary = RouteRequirementEvaluator.evaluate(mobility_with_workshop, reqs_workshop, "Industrial Route")
	_expect(bool(res_ok.get("can_take_route", false)) == true, "consist with workshop capability passes")


func test_combined_requirements() -> void:
	print("Testing combined requirements...")
	var mobility := {
		"total_mass": 215.0,
		"total_length": 260.0,
		"unit_count": 4,
		"has_traction": true,
		"capabilities": ["traction", "crew_accommodation", "resource_storage", "workshop"],
	}
	var industrial_reqs := {
		"max_mass": 320.0,
		"require_traction": true,
		"required_capabilities": ["workshop"],
	}
	var res: Dictionary = RouteRequirementEvaluator.evaluate(mobility, industrial_reqs, "Industrial Exit")
	_expect(bool(res.get("can_take_route", false)) == true, "compliant train passes combined industrial requirements")

	var overloaded_reqs := {
		"max_mass": 200.0,
		"require_traction": true,
		"required_capabilities": ["workshop"],
	}
	var res_overloaded: Dictionary = RouteRequirementEvaluator.evaluate(mobility, overloaded_reqs, "Industrial Exit")
	_expect(bool(res_overloaded.get("can_take_route", true)) == false, "overloaded train fails mass requirement even with workshop")


func test_requirements_formatting() -> void:
	print("Testing requirements summary formatting...")
	_expect(RouteRequirementEvaluator.format_requirements_summary({}) == "Unrestricted", "empty dict is Unrestricted")

	var formatted := RouteRequirementEvaluator.format_requirements_summary({
		"max_mass": 320.0,
		"required_capabilities": ["workshop"],
	})
	_expect(formatted.contains("Max 320t"), "formatted includes mass")
	_expect(formatted.contains("Req workshop"), "formatted includes required capability")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 12 route requirements acceptance passed")
		quit(0)
	else:
		print("\nSprint 12 route requirements acceptance FAILED with %d failure(s)" % _failures)
		quit(1)
