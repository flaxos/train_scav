extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")

var _failures: int = 0


func _init() -> void:
	var probe = RailMovement.new()
	if _require_methods(probe):
		_shunter_identity_and_explicit_control()
		_only_selected_powered_consist_moves()
		_wagon_only_consist_cannot_be_selected_or_powered()

	_finish()


func _require_methods(sim: RefCounted) -> bool:
	var methods: Array[String] = [
		"get_controlled_power_unit_id",
		"select_powered_control",
		"set_powered_unit_condition",
		"get_powered_unit_condition",
		"is_powered_unit",
		"get_consist_containing_unit",
	]
	var all_present := true
	for method_name in methods:
		if sim.has_method(method_name):
			continue

		_failures += 1
		all_present = false
		printerr("FAIL: missing powered-control method %s" % method_name)
	return all_present


func _shunter_identity_and_explicit_control() -> void:
	var sim = RailMovement.new()
	_expect(sim.get_unit_type("L") == RailMovement.UNIT_LOCOMOTIVE, "main locomotive L keeps locomotive identity")
	_expect(sim.get_unit_type("S") == RailMovement.UNIT_SHUNTER, "local shunter S has persistent shunter identity")
	_expect(sim.get_unit_type("W") == RailMovement.UNIT_WORKSHOP, "salvage W has persistent workshop wagon identity")
	_expect(sim.is_powered_unit("L"), "L is a powered unit")
	_expect(sim.is_powered_unit("S"), "S is a powered unit")
	_expect(not sim.is_powered_unit("A"), "normal wagon A is not a powered unit")
	_expect(sim.get_controlled_power_unit_id() == "L", "player initially controls main locomotive L")

	var l_consist_before := _format_ids(sim.get_consist_containing_unit("L").get("units", []))
	var s_consist_before := _format_ids(sim.get_consist_containing_unit("S").get("units", []))
	_expect(not sim.select_powered_control("A"), "wagon cannot be selected as powered control")
	_expect(not sim.select_powered_control("S"), "damaged shunter cannot be selected for powered control")
	_expect(sim.get_controlled_power_unit_id() == "L", "failed control selection leaves L controlled")
	_expect(sim.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL), "repair can make shunter operational")
	_expect(sim.select_powered_control("S"), "explicit control can transfer from L to repaired S")
	_expect(sim.get_controlled_power_unit_id() == "S", "controlled powered unit records S")
	_expect(_format_ids(sim.get_active_consist_ids()) == s_consist_before, "selecting S activates the shunter consist without reordering it")
	_expect(_format_ids(sim.get_consist_containing_unit("L").get("units", [])) == l_consist_before, "selecting S parks the main train without changing consist order")
	_expect(sim.select_powered_control("L"), "explicit control can transfer from S back to L")
	_expect(sim.get_controlled_power_unit_id() == "L", "controlled powered unit records L after transfer back")
	_expect(_format_ids(sim.get_active_consist_ids()) == l_consist_before, "selecting L restores the main train consist without reordering")


func _only_selected_powered_consist_moves() -> void:
	var sim = RailMovement.new()
	_expect(sim.set_powered_unit_condition("S", RailMovement.CONDITION_OPERATIONAL), "fixture repairs S")
	var l_before := _find_state(sim.get_unit_draw_states(), "L")
	var s_before := _find_state(sim.get_unit_draw_states(), "S")

	_expect(sim.select_powered_control("S"), "fixture selects S")
	sim.set_direction(-1)
	sim.set_throttle(1.0)
	sim.step(0.7, false)
	var l_while_s := _find_state(sim.get_unit_draw_states(), "L")
	var s_after := _find_state(sim.get_unit_draw_states(), "S")
	_expect(_same_position(l_before, l_while_s), "parked main train remains stationary while S is controlled")
	_expect(not _same_position(s_before, s_after), "selected shunter consist moves under throttle")

	_expect(sim.select_powered_control("L"), "fixture returns control to L")
	var s_parked := _find_state(sim.get_unit_draw_states(), "S")
	var l_before_move := _find_state(sim.get_unit_draw_states(), "L")
	sim.set_direction(1)
	sim.set_throttle(1.0)
	sim.step(0.7, false)
	var s_after_l := _find_state(sim.get_unit_draw_states(), "S")
	var l_after_move := _find_state(sim.get_unit_draw_states(), "L")
	_expect(_same_position(s_parked, s_after_l), "parked shunter remains stationary while L is controlled")
	_expect(not _same_position(l_before_move, l_after_move), "selected main locomotive consist moves under throttle")


func _wagon_only_consist_cannot_be_selected_or_powered() -> void:
	var sim = RailMovement.new()
	_expect(not sim.select_powered_control("W"), "workshop wagon cannot become controlled powered unit")
	_expect(sim.get_unit_type("W") != RailMovement.UNIT_LOCOMOTIVE, "workshop wagon is not promoted to locomotive")

	sim.active_units = _typed_units(["W"])
	var detached_consists: Array[Dictionary] = []
	sim.detached_consists = detached_consists
	sim.current_segment = RailMovement.SEGMENT_MAIN_WEST
	sim.distance = 260.0
	sim.speed = 0.0
	sim.throttle = 0.0
	var before: float = sim.distance
	sim.set_throttle(1.0)
	sim.step(1.0, false)
	_expect(not sim.has_traction_authority(), "wagon-only active consist exposes no traction authority")
	_expect(is_equal_approx(sim.distance, before), "wagon-only active consist cannot move from throttle input")


func _typed_units(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	result.assign(values)
	return result


func _find_state(states: Array[Dictionary], unit_id: String) -> Dictionary:
	for state in states:
		if str(state.get("id", "")) == unit_id:
			return state
	return {}


func _same_position(left: Dictionary, right: Dictionary) -> bool:
	if left.is_empty() or right.is_empty():
		return false
	return str(left.get("segment", "")) == str(right.get("segment", "")) \
		and absf(float(left.get("distance", -9999.0)) - float(right.get("distance", 9999.0))) < 0.01


func _format_ids(ids: Array) -> String:
	var text := ""
	for id in ids:
		text += "[%s]" % id
	return text


func _expect(condition: bool, message: String) -> void:
	if condition:
		return

	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 4 powered-control acceptance passed")
		quit(0)
		return

	printerr("Sprint 4 powered-control acceptance failed with %d failure(s)" % _failures)
	quit(1)
