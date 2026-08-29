extends SceneTree

# Sprint 13 — Lifecycle Persistence Tests
# Verifies that multiple coupled powered units, their conditions, types, and aggregate traction
# persist across disposable sector transitions.

const SectorLifecycle := preload("res://scripts/sector/sector_lifecycle.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 13 Lifecycle Persistence Tests ---")
	_test_multi_loco_sector_transition_persistence()
	_finish()


func _expect(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 13 lifecycle persistence acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 13 lifecycle persistence acceptance FAILED with %d failure(s)" % _failures)
		quit(1)


func _test_multi_loco_sector_transition_persistence() -> void:
	print("Testing multi-loco sector transition persistence...")
	var lifecycle := SectorLifecycle.new(9001)
	var resources := TrainResources.new()
	resources.set_amount(TrainResources.RESOURCE_DIESEL, 40.0)
	lifecycle.train_resources = resources

	# 1. Setup Sector 0 with a multi-loco consist [L, A, B, S]
	var sec0_def := SectorDefinition.create_for_index(9001, 0)
	var rail0 := RailMovement.new()
	var units: Array[String] = ["L", "A", "B", "S"]
	rail0.active_units = units
	rail0.controlled_power_unit_id = "L"
	rail0.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL)
	rail0.current_segment = RailMovement.SEGMENT_MAIN_EXIT
	rail0.distance = 265.0
	rail0.speed = 10.0
	rail0.direction = 1

	var sec0_instance := SectorLifecycle.SectorInstance.new(sec0_def, rail0, null)
	lifecycle.current_sector = sec0_instance
	lifecycle.run_state.sector_index = 0

	_expect(is_equal_approx(rail0.get_available_traction(), 2.0), "Sector 0 train has 2.0 traction")

	# 2. Perform sector transition
	_expect(lifecycle.can_depart(), "can depart Sector 0")
	var transitioned := lifecycle.request_transition()
	_expect(transitioned, "successfully transitioned to Sector 1")

	# 3. Verify next sector
	var sec1_instance: RefCounted = lifecycle.current_sector
	_expect(sec1_instance != null, "Sector 1 instance exists")
	var rail1: RefCounted = sec1_instance.rail
	_expect(rail1 != null, "Sector 1 rail exists")

	_expect(rail1.active_units == ["L", "A", "B", "S"], "consist order [L, A, B, S] persisted in Sector 1")
	_expect(rail1.get_controlled_power_unit_id() == "L", "controlled power unit L persisted")
	_expect(rail1.get_powered_unit_condition("S") == RailMovement.CONDITION_OPERATIONAL, "S operational condition persisted")
	_expect(rail1.get_unit_type("S") == RailMovement.UNIT_SHUNTER, "S unit type persisted as shunter")
	_expect(rail1.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "L unit type persisted as locomotive")

	var mobility1: Dictionary = rail1.get_mobility_summary()
	_expect(is_equal_approx(float(mobility1.get("traction", 0.0)), 2.0), "Sector 1 mobility summary reports 2.0 traction")
	_expect(int(mobility1.get("operational_loco_count", 0)) == 2, "Sector 1 reports 2 operational locos")
	var powered_units1: Array = mobility1.get("powered_units", []) as Array
	_expect(powered_units1.has("L") and powered_units1.has("S"), "Sector 1 powered_units contains both L and S")
