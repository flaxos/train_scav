extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const SurvivorNeeds := preload("res://scripts/colony/survivor_needs.gd")

var _failures: int = 0


func _init() -> void:
	_needs_initialise_at_maximum()
	_needs_decay_deterministically()
	_health_degrades_only_when_critical()
	_health_recovers_when_adequate()
	_values_clamp_correctly()
	_performance_multiplier_degrades()
	_needs_are_survivor_specific()
	_needs_stable_across_carriage_movement()
	_crew_simulation_steps_needs()
	_draw_states_expose_needs()
	_finish()


func _needs_initialise_at_maximum() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("test")
	_expect(absf(needs.get_need("test", SurvivorNeeds.NEED_HEALTH) - 100.0) < 0.01, "health initialises at 100")
	_expect(absf(needs.get_need("test", SurvivorNeeds.NEED_HUNGER) - 100.0) < 0.01, "hunger initialises at 100")
	_expect(absf(needs.get_need("test", SurvivorNeeds.NEED_REST) - 100.0) < 0.01, "rest initialises at 100")
	_expect(absf(needs.get_performance_multiplier("test") - 1.0) < 0.01, "performance starts at 1.0")


func _needs_decay_deterministically() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("test")
	var initial_hunger: float = needs.get_need("test", SurvivorNeeds.NEED_HUNGER)
	var initial_rest: float = needs.get_need("test", SurvivorNeeds.NEED_REST)

	needs.step(10.0)

	var hunger_after: float = needs.get_need("test", SurvivorNeeds.NEED_HUNGER)
	var rest_after: float = needs.get_need("test", SurvivorNeeds.NEED_REST)
	_expect(hunger_after < initial_hunger, "hunger decays over time")
	_expect(rest_after < initial_rest, "rest decays over time")

	# Verify determinism: running the same duration again from the same start
	var needs2 := SurvivorNeeds.new()
	needs2.init_survivor("test")
	needs2.step(10.0)
	_expect(absf(needs2.get_need("test", SurvivorNeeds.NEED_HUNGER) - hunger_after) < 0.001, "hunger decay is deterministic")
	_expect(absf(needs2.get_need("test", SurvivorNeeds.NEED_REST) - rest_after) < 0.001, "rest decay is deterministic")


func _health_degrades_only_when_critical() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("test")
	# At full hunger/rest, health should not degrade
	needs.step(10.0)
	var health: float = needs.get_need("test", SurvivorNeeds.NEED_HEALTH)
	_expect(health >= 100.0, "health does not degrade when needs are adequate (health=%.1f)" % health)

	# Force hunger to critical and step
	needs.set_need("test", SurvivorNeeds.NEED_HUNGER, 5.0)
	var health_before: float = needs.get_need("test", SurvivorNeeds.NEED_HEALTH)
	needs.step(10.0)
	var health_after: float = needs.get_need("test", SurvivorNeeds.NEED_HEALTH)
	_expect(health_after < health_before, "health degrades when hunger is critical")


func _health_recovers_when_adequate() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("test")
	needs.set_need("test", SurvivorNeeds.NEED_HEALTH, 50.0)
	# Keep hunger/rest above adequate
	needs.set_need("test", SurvivorNeeds.NEED_HUNGER, 80.0)
	needs.set_need("test", SurvivorNeeds.NEED_REST, 80.0)
	needs.step(10.0)
	var health: float = needs.get_need("test", SurvivorNeeds.NEED_HEALTH)
	_expect(health > 50.0, "health recovers when hunger and rest are adequate (health=%.1f)" % health)


func _values_clamp_correctly() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("test")
	needs.set_need("test", SurvivorNeeds.NEED_HUNGER, -10.0)
	_expect(needs.get_need("test", SurvivorNeeds.NEED_HUNGER) >= 0.0, "hunger clamps to minimum")
	needs.set_need("test", SurvivorNeeds.NEED_HUNGER, 200.0)
	_expect(needs.get_need("test", SurvivorNeeds.NEED_HUNGER) <= 100.0, "hunger clamps to maximum")

	# Extended decay should not go below zero
	needs.set_need("test", SurvivorNeeds.NEED_HUNGER, 1.0)
	needs.set_need("test", SurvivorNeeds.NEED_REST, 1.0)
	needs.set_need("test", SurvivorNeeds.NEED_HEALTH, 1.0)
	needs.step(1000.0)
	_expect(needs.get_need("test", SurvivorNeeds.NEED_HUNGER) >= 0.0, "hunger stays >= 0 after long decay")
	_expect(needs.get_need("test", SurvivorNeeds.NEED_REST) >= 0.0, "rest stays >= 0 after long decay")
	_expect(needs.get_need("test", SurvivorNeeds.NEED_HEALTH) >= 0.0, "health stays >= 0 after long decay")


func _performance_multiplier_degrades() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("test")
	var perf_full: float = needs.get_performance_multiplier("test")
	_expect(absf(perf_full - 1.0) < 0.01, "full needs give 1.0 performance")

	needs.set_need("test", SurvivorNeeds.NEED_HUNGER, 0.0)
	needs.set_need("test", SurvivorNeeds.NEED_REST, 0.0)
	needs.set_need("test", SurvivorNeeds.NEED_HEALTH, 0.0)
	var perf_worst: float = needs.get_performance_multiplier("test")
	_expect(perf_worst < 1.0, "depleted needs reduce performance")
	_expect(perf_worst >= SurvivorNeeds.WORST_PERFORMANCE, "performance has a floor (%.2f)" % perf_worst)


func _needs_are_survivor_specific() -> void:
	var needs := SurvivorNeeds.new()
	needs.init_survivor("alpha")
	needs.init_survivor("beta")
	needs.set_need("alpha", SurvivorNeeds.NEED_HUNGER, 30.0)
	needs.set_need("beta", SurvivorNeeds.NEED_HUNGER, 80.0)
	_expect(absf(needs.get_need("alpha", SurvivorNeeds.NEED_HUNGER) - 30.0) < 0.01, "alpha hunger is 30")
	_expect(absf(needs.get_need("beta", SurvivorNeeds.NEED_HUNGER) - 80.0) < 0.01, "beta hunger is 80")
	needs.step(5.0)
	_expect(needs.get_need("alpha", SurvivorNeeds.NEED_HUNGER) < 30.0, "alpha hunger decayed independently")
	_expect(needs.get_need("beta", SurvivorNeeds.NEED_HUNGER) < 80.0, "beta hunger decayed independently")
	_expect(needs.get_need("alpha", SurvivorNeeds.NEED_HUNGER) != needs.get_need("beta", SurvivorNeeds.NEED_HUNGER), "survivors have different hunger values")


func _needs_stable_across_carriage_movement() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	rail.speed = 24.0
	crew.force_survivor_aboard_unit("marta", "L", Vector2(-14.0, -4.0))
	var hunger_before: float = crew.needs.get_need("marta", SurvivorNeeds.NEED_HUNGER)

	crew.assign_move_aboard("marta", "B", Vector2(12.0, 4.0))
	_step_crew(crew, 4.0)

	var state := crew.get_survivor_state("marta")
	_expect(str(state.get("host_unit", "")) == "B", "Marta moved to B")
	var hunger_after: float = crew.needs.get_need("marta", SurvivorNeeds.NEED_HUNGER)
	_expect(hunger_after < hunger_before, "hunger decayed during carriage movement")
	_expect(hunger_after > 0.0, "hunger did not collapse during short movement")
	_expect(crew.needs.get_need("marta", SurvivorNeeds.NEED_HEALTH) >= 99.0, "health stable during short movement with good needs")


func _crew_simulation_steps_needs() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	var initial_hunger: float = crew.needs.get_need("marta", SurvivorNeeds.NEED_HUNGER)
	crew.step(10.0)
	var after_hunger: float = crew.needs.get_need("marta", SurvivorNeeds.NEED_HUNGER)
	_expect(after_hunger < initial_hunger, "crew.step() updates needs")
	# Verify all five survivors have needs
	for survivor_id in crew.get_survivor_ids():
		_expect(crew.needs.has_survivor(survivor_id), "%s has initialised needs" % survivor_id)


func _draw_states_expose_needs() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	crew.needs.set_need("marta", SurvivorNeeds.NEED_HUNGER, 42.0)
	var states := crew.get_survivor_draw_states()
	var found := false
	for state in states:
		if str(state.get("id", "")) != "marta":
			continue
		found = true
		_expect(absf(float(state.get("hunger", 0.0)) - 42.0) < 0.01, "draw state exposes hunger value")
		_expect(state.has("health"), "draw state includes health")
		_expect(state.has("rest"), "draw state includes rest")
		_expect(state.has("performance"), "draw state includes performance")
	_expect(found, "marta found in draw states")


func _step_crew(crew: RefCounted, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		crew.step(0.05)
		elapsed += 0.05


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 5B survivor needs acceptance passed")
		quit(0)
		return
	printerr("Sprint 5B survivor needs acceptance failed with %d failure(s)" % _failures)
	quit(1)
