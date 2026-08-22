extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")

var _failures: int = 0


func _init() -> void:
	_geometry_is_a_real_yard_ladder()
	_p3_has_authoritative_route_control()
	_p3_routes_forward_into_both_sidings()
	_p3_blocks_wrong_trailing_route()
	_p3_occupancy_interlock_is_real()
	_finish()


func _geometry_is_a_real_yard_ladder() -> void:
	var rail := RailMovement.new()
	var tracks: Dictionary = rail.get_track_segments()
	_expect(tracks.has(RailMovement.SEGMENT_YARD_STORAGE), "P3 storage siding is modeled rail, not decorative scenery")
	_expect(tracks.has(RailMovement.SEGMENT_YARD_REPAIR), "P3 repair siding is modeled rail, not decorative scenery")
	if not tracks.has(RailMovement.SEGMENT_YARD_STORAGE) or not tracks.has(RailMovement.SEGMENT_YARD_REPAIR):
		return

	var approach: Array = tracks[RailMovement.SEGMENT_SIDING]
	var storage: Array = tracks[RailMovement.SEGMENT_YARD_STORAGE]
	var repair: Array = tracks[RailMovement.SEGMENT_YARD_REPAIR]
	var p3_position := approach[approach.size() - 1] as Vector2
	_expect((storage[0] as Vector2).distance_to(p3_position) <= 0.1, "storage siding begins exactly at P3")
	_expect((repair[0] as Vector2).distance_to(p3_position) <= 0.1, "repair siding begins exactly at P3")

	var approach_tangent := ((approach[approach.size() - 1] as Vector2) - (approach[approach.size() - 2] as Vector2)).normalized()
	var storage_tangent := ((storage[1] as Vector2) - (storage[0] as Vector2)).normalized()
	var repair_tangent := ((repair[1] as Vector2) - (repair[0] as Vector2)).normalized()
	_expect(absf(angle_difference(approach_tangent.angle(), storage_tangent.angle())) <= 0.35, "P3 straight route leaves yard lead at plausible turnout angle")
	_expect(absf(angle_difference(approach_tangent.angle(), repair_tangent.angle())) <= 0.45, "P3 diverging route avoids an impossible reverse bend")

	var storage_end_tangent := ((storage[storage.size() - 1] as Vector2) - (storage[storage.size() - 2] as Vector2)).normalized()
	var repair_end_tangent := ((repair[repair.size() - 1] as Vector2) - (repair[repair.size() - 2] as Vector2)).normalized()
	_expect(absf(angle_difference(storage_end_tangent.angle(), repair_end_tangent.angle())) <= 0.12, "P3 sidings settle roughly parallel like a yard ladder")


func _p3_has_authoritative_route_control() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var state := yard.get_point_state(YardOperations.POINT_P3)
	_expect(bool(state.get("rail_authority", false)), "P3 has rail authority in Sprint 4.5")
	_expect((state.get("track_position", Vector2.ZERO) as Vector2).distance_to(YardOperations.POINT_P3_TRACK_POSITION) <= 0.1, "P3 visual/control position is on the modeled turnout")
	var before: String = rail.get_yard_point_route(YardOperations.POINT_P3)
	_expect(not yard.manual_operate_point(YardOperations.POINT_P3), "damaged P3 cannot move")
	_expect(yard.repair_point(YardOperations.POINT_P3), "P3 can be repaired")
	_expect(yard.manual_operate_point(YardOperations.POINT_P3), "repaired P3 operates authoritative rail route")
	_expect(rail.get_yard_point_route(YardOperations.POINT_P3) != before, "operating P3 changes RailMovement route state")


func _p3_routes_forward_into_both_sidings() -> void:
	var straight := _make_single_loco_fixture(RailMovement.SEGMENT_SIDING)
	straight.set_yard_point_route(YardOperations.POINT_P3, RailMovement.POINTS_MAIN)
	straight.distance = straight.get_segment_length(RailMovement.SEGMENT_SIDING) - 2.0
	straight.step(0.5, false)
	_expect(straight.current_segment == RailMovement.SEGMENT_YARD_STORAGE, "P3 straight sends facing movement into storage siding")

	var branch := _make_single_loco_fixture(RailMovement.SEGMENT_SIDING)
	branch.set_yard_point_route(YardOperations.POINT_P3, RailMovement.POINTS_SIDING)
	branch.distance = branch.get_segment_length(RailMovement.SEGMENT_SIDING) - 2.0
	branch.step(0.5, false)
	_expect(branch.current_segment == RailMovement.SEGMENT_YARD_REPAIR, "P3 branch sends facing movement into repair siding")


func _p3_blocks_wrong_trailing_route() -> void:
	var rail := _make_single_loco_fixture(RailMovement.SEGMENT_YARD_STORAGE)
	rail.direction = -1
	rail.distance = 150.0
	rail.set_yard_point_route(YardOperations.POINT_P3, RailMovement.POINTS_SIDING)
	for _index in range(30):
		rail.step(0.25, false)
		if rail.blocked_reason.contains("P3 route blocks"):
			break
	_expect(rail.current_segment == RailMovement.SEGMENT_YARD_STORAGE, "wrong P3 route keeps train on storage siding")
	_expect(rail.blocked_reason.contains("P3 route blocks storage siding"), "wrong trailing P3 route reports explicit block reason")


func _p3_occupancy_interlock_is_real() -> void:
	var rail := _make_single_loco_fixture(RailMovement.SEGMENT_SIDING)
	var yard := YardOperations.new(rail)
	rail.speed = 0.0
	rail.distance = rail.get_segment_length(RailMovement.SEGMENT_SIDING) - 8.0
	_expect(yard.is_point_occupied(YardOperations.POINT_P3), "rolling stock near P3 occupies the turnout")
	_expect(yard.repair_point(YardOperations.POINT_P3), "fixture repairs P3")
	var before: String = rail.get_yard_point_route(YardOperations.POINT_P3)
	_expect(not yard.manual_operate_point(YardOperations.POINT_P3), "occupied P3 rejects manual operation")
	_expect(rail.get_yard_point_route(YardOperations.POINT_P3) == before, "occupied P3 leaves route unchanged")


func _make_single_loco_fixture(segment_id: String) -> RefCounted:
	var rail := RailMovement.new()
	var active: Array[String] = ["L"]
	var detached: Array[Dictionary] = []
	rail.active_units = active
	rail.detached_consists = detached
	rail.current_segment = segment_id
	rail.distance = 80.0
	rail.direction = 1
	rail.speed = 20.0
	rail.throttle = 1.0
	rail.max_speed = 20.0
	rail.acceleration = 0.0
	rail.coast_deceleration = 0.0
	return rail


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4.5 yard grammar acceptance passed")
		quit(0)
		return
	printerr("Sprint 4.5 yard grammar acceptance failed with %d failure(s)" % _failures)
	quit(1)
