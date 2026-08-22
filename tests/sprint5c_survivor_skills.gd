extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const SurvivorSkills := preload("res://scripts/colony/survivor_skills.gd")

var _failures: int = 0


func _init() -> void:
	_skills_initialise_with_distinct_profiles()
	_task_suitability_calculated_correctly()
	_task_speed_multiplier_affects_interaction_duration()
	_job_eligibility_filters_tasks()
	_skill_clamping_works()
	_crew_simulation_integrates_skills()
	_draw_states_expose_skills()
	_finish()


func _skills_initialise_with_distinct_profiles() -> void:
	var skills := SurvivorSkills.new()
	skills.init_survivor("marta", {
		SurvivorSkills.SKILL_ENGINEERING: 75.0,
		SurvivorSkills.SKILL_RAILWAY: 50.0,
	}, SurvivorSkills.JOB_ENGINEER)
	skills.init_survivor("olek", {
		SurvivorSkills.SKILL_RAILWAY: 80.0,
	}, SurvivorSkills.JOB_RAIL_WORKER)

	_expect(skills.get_job("marta") == SurvivorSkills.JOB_ENGINEER, "Marta is an engineer")
	_expect(skills.get_job("olek") == SurvivorSkills.JOB_RAIL_WORKER, "Olek is a rail worker")
	_expect(absf(skills.get_skill("marta", SurvivorSkills.SKILL_ENGINEERING) - 75.0) < 0.01, "Marta engineering is 75")
	_expect(absf(skills.get_skill("olek", SurvivorSkills.SKILL_RAILWAY) - 80.0) < 0.01, "Olek railway is 80")
	_expect(skills.get_skill("marta", SurvivorSkills.SKILL_ENGINEERING) > skills.get_skill("olek", SurvivorSkills.SKILL_ENGINEERING), "Marta is better at engineering than Olek")


func _task_suitability_calculated_correctly() -> void:
	var skills := SurvivorSkills.new()
	skills.init_survivor("marta", {SurvivorSkills.SKILL_ENGINEERING: 100.0}, SurvivorSkills.JOB_ENGINEER)
	skills.init_survivor("novice", {SurvivorSkills.SKILL_ENGINEERING: 0.0}, SurvivorSkills.JOB_GENERALIST)

	var marta_suitability: float = skills.get_task_suitability("marta", "repair_shunter")
	var novice_suitability: float = skills.get_task_suitability("novice", "repair_shunter")

	_expect(absf(marta_suitability - 1.0) < 0.01, "100 skill gives 1.0 suitability")
	_expect(absf(novice_suitability - 0.0) < 0.01, "0 skill gives 0.0 suitability")


func _task_speed_multiplier_affects_interaction_duration() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)

	# Marta (Engineering 75) vs Iris (Engineering 15) for repair_shunter
	var marta_mult: float = crew.skills.get_task_speed_multiplier("marta", "repair_shunter")
	var iris_mult: float = crew.skills.get_task_speed_multiplier("iris", "repair_shunter")

	_expect(marta_mult > iris_mult, "Marta has higher repair speed multiplier than Iris")
	_expect(marta_mult > 1.0, "High skill gives >1.0 speed multiplier")
	_expect(iris_mult < 1.0, "Low skill gives <1.0 speed multiplier")

	# Assign repair task to Marta, check duration, then cancel and assign to Iris to avoid target reservation conflict.
	crew.force_survivor_yard_position("marta", Vector2(1550.0, 252.0))
	crew.force_survivor_yard_position("iris", Vector2(1550.0, 252.0))

	_expect(crew.assign_repair_shunter("marta"), "Marta assigned to repair shunter")
	var marta_state := crew.get_survivor_state("marta")
	var marta_time := float(marta_state.get("interaction_remaining", 0.0))

	crew.cancel_task("marta")

	_expect(crew.assign_repair_shunter("iris"), "Iris assigned to repair shunter")
	var iris_state := crew.get_survivor_state("iris")
	var iris_time := float(iris_state.get("interaction_remaining", 0.0))

	_expect(marta_time < iris_time, "Marta (%.2fs) receives shorter interaction duration than Iris (%.2fs) due to engineering skill" % [marta_time, iris_time])


func _job_eligibility_filters_tasks() -> void:
	var skills := SurvivorSkills.new()
	skills.init_survivor("olek", {}, SurvivorSkills.JOB_RAIL_WORKER)
	skills.init_survivor("nia", {}, SurvivorSkills.JOB_SCAVENGER)

	_expect(skills.is_job_eligible("olek", "operate_points"), "Rail worker is eligible for operate_points")
	_expect(not skills.is_job_eligible("olek", "repair_shunter"), "Rail worker is not eligible for repair_shunter")
	_expect(not skills.is_job_eligible("nia", "operate_points"), "Scavenger is not eligible for rail tasks")


func _skill_clamping_works() -> void:
	var skills := SurvivorSkills.new()
	skills.init_survivor("test", {}, SurvivorSkills.JOB_GENERALIST)
	skills.set_skill("test", SurvivorSkills.SKILL_ENGINEERING, -50.0)
	_expect(skills.get_skill("test", SurvivorSkills.SKILL_ENGINEERING) >= 0.0, "skill clamps to 0")
	skills.set_skill("test", SurvivorSkills.SKILL_ENGINEERING, 200.0)
	_expect(skills.get_skill("test", SurvivorSkills.SKILL_ENGINEERING) <= 100.0, "skill clamps to 100")


func _crew_simulation_integrates_skills() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	_expect(crew.skills != null, "CrewSimulation instantiates SurvivorSkills")
	for survivor_id in crew.get_survivor_ids():
		_expect(crew.skills.has_survivor(survivor_id), "%s has registered skill profile" % survivor_id)


func _draw_states_expose_skills() -> void:
	var rail := RailMovement.new()
	var crew := CrewSimulation.new(rail)
	var states := crew.get_survivor_draw_states()
	var marta_state: Dictionary = {}
	for state in states:
		if str(state.get("id", "")) == "marta":
			marta_state = state
			break

	_expect(not marta_state.is_empty(), "Marta in draw states")
	_expect(str(marta_state.get("job", "")) == SurvivorSkills.JOB_ENGINEER, "Draw state exposes job")
	_expect(str(marta_state.get("job_label", "")) == "Engineer", "Draw state exposes job label")
	_expect(marta_state.has("skills"), "Draw state exposes skills dictionary")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 5C survivor skills acceptance passed")
		quit(0)
		return
	printerr("Sprint 5C survivor skills acceptance failed with %d failure(s)" % _failures)
	quit(1)
