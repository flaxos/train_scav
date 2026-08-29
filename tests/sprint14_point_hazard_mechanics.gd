extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 14 Point Hazard Mechanics Tests ---")
	_test_damaged_point_blocks_toggle()
	_test_crew_repairs_damaged_point()
	_test_point_repair_consumes_parts()

	if _failures == 0:
		print("\nSprint 14 point hazard mechanics acceptance passed\n")
		quit(0)
	else:
		printerr("\nSprint 14 point hazard mechanics acceptance FAILED with %d failures\n" % _failures)
		quit(1)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		printerr("  FAIL: %s" % msg)


func _test_damaged_point_blocks_toggle() -> void:
	print("Testing damaged point blocks toggle...")
	var rail := RailMovement.new()
	rail.set_point_condition("P1", RailMovement.CONDITION_DAMAGED)

	var initial_route := rail.get_point_route("P1")
	var success := rail.request_point_toggle("P1")
	_expect(not success, "request_point_toggle rejected for damaged point")
	_expect(rail.blocked_reason.contains("damaged / jammed"), "blocked_reason explains point is damaged / jammed")
	_expect(rail.get_point_route("P1") == initial_route, "route alignment untouched while damaged")


func _test_crew_repairs_damaged_point() -> void:
	print("Testing crew repairs damaged point...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)

	rail.set_point_condition("P1", RailMovement.CONDITION_DAMAGED)
	yard.sync_points_from_rail_layout()

	var survivor_id: String = crew.get_survivor_ids()[0]
	crew.force_survivor_yard_position(survivor_id, Vector2(512.0, 302.0))

	_expect(crew.assign_repair_point(survivor_id, "P1"), "assign_repair_point succeeds")
	
	# Step crew simulation through arrival and interaction
	for _i in range(150):
		crew.step(0.1)

	var p1_state := yard.get_point_state("P1")
	_expect(str(p1_state.get("mechanical_state", "")) == YardOperations.MECHANICAL_OPERATIONAL, "point mechanical state operational after repair")
	_expect(rail.get_point_condition("P1") == RailMovement.CONDITION_OPERATIONAL, "rail point condition restored")
	_expect(rail.request_point_toggle("P1"), "point can now be toggled after repair")


func _test_point_repair_consumes_parts() -> void:
	print("Testing point repair consumes parts...")
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var res := TrainResources.new()
	res.set_amount(TrainResources.RESOURCE_PARTS, 5.0)
	crew.train_resources = res

	rail.set_point_condition("P2", RailMovement.CONDITION_DAMAGED)
	yard.sync_points_from_rail_layout()

	var survivor_id: String = crew.get_survivor_ids()[0]
	crew.force_survivor_yard_position(survivor_id, yard.get_repair_anchor("point", "P2"))

	_expect(crew.assign_repair_point(survivor_id, "P2"), "assign_repair_point P2 succeeds")
	for _i in range(150):
		crew.step(0.1)

	_expect(res.get_amount(TrainResources.RESOURCE_PARTS) == 4.0, "consumed 1 part for point repair")
