extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TrainInterior := preload("res://scripts/colony/train_interior.gd")

var _failures: int = 0


func _init() -> void:
	_explicit_metadata_defaults_safe()
	_connected_consist_exposes_walk_path()
	_non_boardable_stock_rejects_boarding()
	_survivor_walks_between_connected_carriages_while_train_is_moving()
	_gangway_crossing_is_spatially_continuous()
	_uncoupled_joint_blocks_new_interior_route()
	_mid_walk_uncoupling_blocks_at_physical_side_of_split()
	_finish()


func _explicit_metadata_defaults_safe() -> void:
	var rail := RailMovement.new()
	var interior := TrainInterior.new(rail)
	_expect(interior.is_boardable_unit("L"), "locomotive L has a boardable cab")
	_expect(interior.has_rear_gangway("L"), "locomotive L exposes its rear gangway toward A")
	_expect(not interior.has_front_gangway("L"), "locomotive nose is not a fictional front gangway")
	_expect(interior.is_boardable_unit("S"), "shunter S remains boardable for powered control")
	_expect(not interior.has_front_gangway("S") and not interior.has_rear_gangway("S"), "shunter S is a cab, not a through corridor")
	_expect(not interior.is_boardable_unit("C"), "tanker C is not boardable")
	_expect(not interior.is_walkable_unit("D"), "unknown future stock defaults to no interior rather than magically walkable")


func _connected_consist_exposes_walk_path() -> void:
	var rail := RailMovement.new()
	var interior := TrainInterior.new(rail)
	var path := interior.get_walk_path("L", "B")
	_expect(_same_ids(path, ["L", "A", "B"]), "L -> B interior path follows physical consist order")
	_expect(interior.can_walk_joint("L", "A"), "L rear gangway connects to A front gangway")
	_expect(interior.can_walk_joint("A", "B"), "A rear gangway connects to B front gangway")
	_expect(interior.get_unit_interior_kind("A") == TrainInterior.KIND_BUNK, "A provides the prototype bunk interior")
	_expect(interior.get_unit_interior_kind("B") == TrainInterior.KIND_STORAGE, "B provides the prototype storage interior")
	_expect(interior.get_unit_interior_kind("W") == TrainInterior.KIND_WORKSHOP, "W provides the workshop interior")
	_expect(not interior.can_walk_between("B", "C"), "tanker C breaks the interior route")


func _non_boardable_stock_rejects_boarding() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	rail.speed = 0.0
	crew.force_survivor_yard_position("marta", Vector2.ZERO)
	_expect(not crew.assign_board("marta", "C"), "generic boarding rejects tanker C")
	var state := crew.get_survivor_state("marta")
	_expect(str(state.get("task_status", "")) == CrewSimulation.STATUS_BLOCKED, "rejected tanker boarding reports blocked")
	_expect(str(state.get("status_text", "")).contains("no boardable interior"), "rejected tanker boarding explains why")


func _survivor_walks_between_connected_carriages_while_train_is_moving() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	rail.speed = 24.0
	crew.force_survivor_aboard_unit("marta", "L", Vector2(-14.0, -4.0))

	_expect(crew.assign_move_aboard("marta", "B", Vector2(12.0, 4.0)), "aboard movement can be assigned while the train is moving")
	_step_crew(crew, 4.0)

	var state := crew.get_survivor_state("marta")
	_expect(str(state.get("host_unit", "")) == "B", "Marta physically crosses L -> A -> B")
	_expect(str(state.get("spatial_state", "")) == CrewSimulation.SPATIAL_ABOARD, "interior movement keeps Marta aboard")
	_expect(str(state.get("task_status", "")) == CrewSimulation.STATUS_COMPLETED, "connected-carriage interior movement completes")
	var local := state.get("local_offset", Vector2.ZERO) as Vector2
	_expect(local.distance_to(Vector2(12.0, 4.0)) <= 2.1, "aboard movement preserves requested local destination instead of carriage centre")


func _gangway_crossing_is_spatially_continuous() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	rail.speed = 0.0
	crew.force_survivor_aboard_unit("marta", "L", Vector2(-12.0, 0.0))
	_expect(crew.assign_move_aboard("marta", "B"), "continuity fixture assigns L -> B walk")

	var previous := _survivor_position(crew, "marta")
	var max_step := 0.0
	for _index in range(100):
		crew.step(0.05)
		var current := _survivor_position(crew, "marta")
		max_step = maxf(max_step, previous.distance_to(current))
		previous = current
		if str(crew.get_survivor_state("marta").get("task_status", "")) == CrewSimulation.STATUS_COMPLETED:
			break
	_expect(max_step <= crew.aboard_walk_speed * 0.05 + 1.0, "gangway crossing has no one-frame teleport between carriage doors")


func _uncoupled_joint_blocks_new_interior_route() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	crew.force_survivor_aboard_unit("marta", "L")
	rail.speed = 0.0
	_expect(rail.decouple_joint("A", "B"), "fixture can split A/B")
	_expect(not rail.are_units_in_same_consist("L", "B"), "rail topology reports B disconnected after A/B uncoupling")
	_expect(not crew.assign_move_aboard("marta", "B"), "crew cannot path through an uncoupled joint")
	var state := crew.get_survivor_state("marta")
	_expect(str(state.get("task_status", "")) == CrewSimulation.STATUS_BLOCKED, "disconnected interior route reports blocked")
	_expect(str(state.get("status_text", "")).contains("connected interior route"), "blocked route explains that train interiors are disconnected")


func _mid_walk_uncoupling_blocks_at_physical_side_of_split() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	crew.force_survivor_aboard_unit("marta", "L", Vector2(-14.0, 0.0))
	_expect(crew.assign_move_aboard("marta", "B"), "fixture starts L -> B interior movement")

	var reached_a := false
	for _index in range(80):
		crew.step(0.05)
		var state := crew.get_survivor_state("marta")
		if str(state.get("host_unit", "")) == "A":
			reached_a = true
			break
	_expect(reached_a, "Marta reaches A before the split")

	rail.speed = 0.0
	_expect(rail.decouple_joint("A", "B"), "fixture uncouples A/B while Marta is in A")
	crew.step(0.1)

	var after_split := crew.get_survivor_state("marta")
	_expect(str(after_split.get("host_unit", "")) == "A", "Marta remains in the carriage she physically reached after split")
	_expect(str(after_split.get("task_status", "")) == CrewSimulation.STATUS_BLOCKED, "mid-walk split blocks the impossible continuation")
	_expect(str(after_split.get("status_text", "")).contains("disconnected"), "mid-walk split reports disconnected route")


func _survivor_position(crew: RefCounted, survivor_id: String) -> Vector2:
	for state in crew.get_survivor_draw_states():
		if str(state.get("id", "")) == survivor_id:
			return state.get("position", Vector2.ZERO) as Vector2
	return Vector2.ZERO


func _step_crew(crew: RefCounted, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		crew.step(0.05)
		elapsed += 0.05


func _same_ids(actual: Array[String], expected: Array[String]) -> bool:
	if actual.size() != expected.size():
		return false
	for index in expected.size():
		if actual[index] != expected[index]:
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 5A interior movement acceptance passed")
		quit(0)
		return
	printerr("Sprint 5A interior movement acceptance failed with %d failure(s)" % _failures)
	quit(1)
