extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Rolling-Stock Identity Tests ---")
	_explicit_type_metadata_overrides_prefix_inference()
	_same_type_wagons_keep_distinct_identity_through_coupling_and_uncoupling()
	_finish()


func _explicit_type_metadata_overrides_prefix_inference() -> void:
	var rail := RailMovement.new()
	_expect(rail.has_method("set_unit_type"), "RailMovement exposes set_unit_type")
	_expect(rail.has_method("get_unit_type_id"), "RailMovement exposes get_unit_type_id")
	_expect(rail.has_method("get_unit_definition"), "RailMovement exposes get_unit_definition")
	_expect(rail.has_method("get_unit_capability_summary"), "RailMovement exposes get_unit_capability_summary")
	if not rail.has_method("set_unit_type"):
		return

	_expect(rail.set_unit_type("A900", "fuel_tanker"), "explicit metadata accepts known type")
	_expect(str(rail.get_unit_type_id("A900")) == "fuel_tanker", "explicit type metadata wins over A-prefix fallback")
	_expect(str(rail.get_unit_type("A900")) == RailMovement.UNIT_TANKER, "physical rendering type follows explicit fuel tanker metadata")
	_expect(str(rail.get_unit_definition("A900").get("display_name", "")) != "", "unit definition is inspectable")
	_expect(str(rail.get_unit_capability_summary("A900")).contains("diesel"), "capability summary explains tanker function")


func _same_type_wagons_keep_distinct_identity_through_coupling_and_uncoupling() -> void:
	var wagon_a := "sector_012_salvage_01"
	var wagon_b := "sector_014_salvage_01"
	var rail := RailMovement.new()
	var active: Array[String] = ["L"]
	rail.active_units = active
	rail.detached_consists = [
		{
			"units": [wagon_a],
			"segment": RailMovement.SEGMENT_MAIN_WEST,
			"distance": 260.0,
		},
	]
	rail.current_segment = RailMovement.SEGMENT_MAIN_WEST
	rail.distance = 200.0
	rail.direction = 1
	rail.speed = 8.0
	rail.throttle = 1.0
	rail.max_speed = 8.0
	rail.acceleration = 0.0
	rail.coast_deceleration = 0.0

	_expect(rail.set_unit_type(wagon_a, "fuel_tanker"), "first generated tanker receives explicit type")
	_expect(rail.set_unit_type(wagon_b, "fuel_tanker"), "second generated tanker receives explicit type")
	_expect(wagon_a != wagon_b, "same-type generated wagons have distinct unit IDs")
	_expect(str(rail.get_unit_type_id(wagon_a)) == str(rail.get_unit_type_id(wagon_b)), "same-type generated wagons share type")

	_step_until_can_couple(rail, wagon_a, 12.0)
	rail.speed = 0.0
	rail.throttle = 0.0
	_expect(rail.can_couple_unit(wagon_a), "generated wagon is physically reachable for coupling")
	_expect(rail.couple_nearest(), "existing RailMovement coupling recovers generated wagon")
	_expect(rail.get_active_consist_ids().has(wagon_a), "recovered wagon joins active consist by coupling")
	_expect(str(rail.get_unit_type_id(wagon_a)) == "fuel_tanker", "explicit type persists after coupling")

	_expect(rail.decouple_front(), "front decoupling can detach the recovered front tanker")
	_expect(not rail.get_active_consist_ids().has(wagon_a), "decoupled wagon leaves active consist")
	_expect(str(rail.get_unit_type_id(wagon_a)) == "fuel_tanker", "explicit type persists after uncoupling")


func _step_until_can_couple(rail: RefCounted, unit_id: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and not rail.can_couple_unit(unit_id):
		rail.step(0.1, false)
		elapsed += 0.1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 rolling-stock identity acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 rolling-stock identity FAILED with %d failure(s)" % _failures)
		quit(1)
