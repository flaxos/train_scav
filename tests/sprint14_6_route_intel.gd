extends SceneTree

const WorldgenProductionSectorGenerator := preload("res://scripts/worldgen/worldgen_production_sector_generator.gd")
const SectorDefinitionProvider := preload("res://scripts/sector/sector_definition_provider.gd")
const OperationalUIPresenter := preload("res://scripts/ui/operational_ui_presenter.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")

var _failures: Array[String] = []

func _init() -> void:
	print("\n--- SPRINT 14.6: ROUTE INTEL & PRESENTATION TESTS ---")
	test_route_exit_intel_schema()
	test_ui_presenter_route_intel()

	if _failures.is_empty():
		print("\n>>> ALL SPRINT 14.6 ROUTE INTEL TESTS PASSED <<<\n")
		quit(0)
	else:
		printerr("\n>>> FAILED with %d error(s): <<<" % _failures.size())
		for f in _failures:
			printerr("  - %s" % f)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		printerr("FAIL: %s" % msg)
	else:
		print("  PASS: %s" % msg)


func test_route_exit_intel_schema() -> void:
	print("\n[TEST] Route Exit Intel Schema Completeness across 100 Sectors")
	var provider := SectorDefinitionProvider.new()

	var valid_confidence := {"HIGH": true, "MODERATE": true, "LOW": true}
	var total_routes_tested := 0

	for s in range(100):
		var seed_val := 4000 + s * 13
		var def := provider.create_definition(seed_val, 2, "forward")
		_expect(def != null, "Sector generated for seed %d" % seed_val)
		if def == null:
			continue

		for route in def.route_exits:
			total_routes_tested += 1
			var rid := str(route.get("id", ""))
			_expect(not rid.is_empty(), "Route has non-empty id in seed %d" % seed_val)
			_expect(not str(route.get("route_id", "")).is_empty(), "Route has non-empty route_id")
			_expect(not str(route.get("label", "")).is_empty(), "Route has non-empty label")
			_expect(not str(route.get("summary", "")).is_empty(), "Route has non-empty summary")
			_expect(not str(route.get("profile", "")).is_empty(), "Route has non-empty profile")
			_expect(not str(route.get("segment", "")).is_empty(), "Route has non-empty segment")
			_expect(float(route.get("distance", 0.0)) > 0.0, "Route has positive exit distance")

			var intel := route.get("intel", {}) as Dictionary
			_expect(not intel.is_empty(), "Route %s has intel dictionary" % rid)
			_expect(valid_confidence.has(str(intel.get("confidence", ""))), "Valid confidence level '%s'" % str(intel.get("confidence", "")))
			_expect(not str(intel.get("destination_type", "")).is_empty(), "Intel has destination_type")
			_expect(not str(intel.get("food_prospects", "")).is_empty(), "Intel has food_prospects")
			_expect(not str(intel.get("parts_prospects", "")).is_empty(), "Intel has parts_prospects")
			_expect(not str(intel.get("fuel_prospects", "")).is_empty(), "Intel has fuel_prospects")
			_expect(not str(intel.get("rolling_stock", "")).is_empty(), "Intel has rolling_stock")
			_expect(not str(intel.get("rail_condition", "")).is_empty(), "Intel has rail_condition")
			_expect(typeof(intel.get("known_hazards", [])) == TYPE_ARRAY, "Intel has known_hazards array")

	print("  Tested %d outbound routes across 100 seeds without schema defects." % total_routes_tested)


func test_ui_presenter_route_intel() -> void:
	print("\n[TEST] UI Presenter Route Formatting with Route Intel")
	var provider := SectorDefinitionProvider.new()

	var def := provider.create_definition(4004, 2, "forward")
	_expect(def != null, "Sector 4004 generated successfully")
	if def == null:
		return

	var mobility := {
		"has_traction": true,
		"traction": 2.0,
		"total_mass": 180.0,
		"unit_count": 3,
		"operational_units": ["loco_01", "wagon_01"],
		"damaged_units": [],
		"intact": true,
	}

	var routes_panel := OperationalUIPresenter.format_player_routes_panel(def, mobility, {}, {})
	_expect(not routes_panel.is_empty(), "Routes panel is formatted")

	var found_intel_line := false
	for line in routes_panel:
		if line.contains("[Intel:") and line.contains("Food:") and line.contains("Parts:") and line.contains("Fuel:"):
			found_intel_line = true
			print("  Sample formatted intel line: %s" % line.strip_edges())
			break

	_expect(found_intel_line, "Routes panel renders rich intel block for multi-corridor exits")
