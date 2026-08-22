extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const CrewSimulation := preload("res://scripts/crew/crew_simulation.gd")
const TaskBroker := preload("res://scripts/colony/task_broker.gd")
const SurvivorSkills := preload("res://scripts/colony/survivor_skills.gd")

var _failures: int = 0


func _init() -> void:
	_auto_assignment_dispatches_repair_task_to_eligible_engineer()
	_auto_assigned_worker_physically_travels_and_completes()
	_ineligible_jobs_skipped()
	_skill_and_distance_tiebreakers_work()
	_disabling_broker_stops_auto_assignment()
	_finish()


func _auto_assignment_dispatches_repair_task_to_eligible_engineer() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	broker.enabled = true

	# Ensure Marta (Engineer) is in yard and idle
	crew.force_survivor_yard_position("marta", Vector2(1000.0, 252.0))
	_expect(rail.get_powered_unit_condition("S") == RailMovement.CONDITION_DAMAGED, "Shunter initially needs repair")

	var assigned_count := broker.evaluate_and_assign()
	_expect(assigned_count > 0, "Broker assigned an auto task")

	var marta_state := crew.get_survivor_state("marta")
	_expect(str(marta_state.get("task_type", "")) == "repair_shunter", "Marta auto-assigned to repair_shunter")
	_expect(str(marta_state.get("task_status", "")) != CrewSimulation.STATUS_IDLE, "Marta is no longer idle")


func _auto_assigned_worker_physically_travels_and_completes() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	broker.enabled = true

	# Marta starts in yard near shunter
	var anchor := yard.get_repair_anchor("shunter")
	crew.force_survivor_yard_position("marta", anchor + Vector2(20.0, 0.0))

	# Run broker evaluation
	broker.step(0.1)
	var marta_state := crew.get_survivor_state("marta")
	_expect(str(marta_state.get("task_type", "")) == "repair_shunter", "Marta auto-assigned to shunter repair")

	# Step physical simulation until completion
	var elapsed := 0.0
	while elapsed < 5.0 and rail.get_powered_unit_condition("S") != RailMovement.CONDITION_OPERATIONAL:
		crew.step(0.1)
		broker.step(0.1)
		elapsed += 0.1

	_expect(rail.get_powered_unit_condition("S") == RailMovement.CONDITION_OPERATIONAL, "Shunter successfully repaired by auto-assigned worker")
	var final_state := crew.get_survivor_state("marta")
	_expect(str(final_state.get("task_status", "")) == CrewSimulation.STATUS_IDLE or str(final_state.get("task_status", "")) == CrewSimulation.STATUS_COMPLETED, "Marta completed task and returned to idle")


func _ineligible_jobs_skipped() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	broker.enabled = true

	# Make Marta (Engineer) busy so she is unavailable
	crew.assign_move_aboard("marta", "B")

	# Place Nia (Scavenger) in yard idle
	crew.force_survivor_yard_position("nia", Vector2(1000.0, 252.0))

	broker.evaluate_and_assign()

	var nia_state := crew.get_survivor_state("nia")
	_expect(str(nia_state.get("task_status", "")) == CrewSimulation.STATUS_IDLE, "Ineligible Scavenger Nia not assigned repair task")


func _skill_and_distance_tiebreakers_work() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)
	broker.enabled = true

	# Make Marta busy
	crew.assign_move_aboard("marta", "B")

	# Both Pavel (Generalist, Engineering 45) and Iris (Medic, Engineering 15) are idle in yard
	crew.force_survivor_yard_position("pavel", Vector2(1500.0, 252.0))
	crew.force_survivor_yard_position("iris", Vector2(1500.0, 252.0))

	broker.evaluate_and_assign()

	var pavel_state := crew.get_survivor_state("pavel")
	_expect(str(pavel_state.get("task_type", "")) == "repair_shunter", "Pavel (higher engineering skill) selected over Iris")


func _disabling_broker_stops_auto_assignment() -> void:
	var rail := RailMovement.new()
	var yard := YardOperations.new(rail)
	var crew := CrewSimulation.new(rail, yard)
	var broker := TaskBroker.new(crew, yard, rail)

	broker.enabled = false
	crew.force_survivor_yard_position("marta", Vector2(1000.0, 252.0))

	var count := broker.evaluate_and_assign()
	_expect(count == 0, "Disabled broker assigns zero tasks")

	var marta_state := crew.get_survivor_state("marta")
	_expect(str(marta_state.get("task_status", "")) == CrewSimulation.STATUS_IDLE, "Marta remains idle when broker disabled")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("Sprint 5D automatic task assignment acceptance passed")
		quit(0)
		return
	printerr("Sprint 5D automatic task assignment acceptance failed with %d failure(s)" % _failures)
	quit(1)
