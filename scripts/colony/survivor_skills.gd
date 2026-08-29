extends RefCounted
class_name SurvivorSkills

# Sprint 5C — Minimal skills and jobs.
#
# Each survivor has a small set of skill values (0.0–100.0) and an assigned
# job/role. Skills affect task suitability and execution speed. Jobs determine
# which categories of automatic work a survivor is eligible for.

const SKILL_ENGINEERING := "engineering"
const SKILL_RAILWAY := "railway"
const SKILL_SCAVENGING := "scavenging"
const SKILL_MEDICAL := "medical"

const JOB_ENGINEER := "engineer"
const JOB_RAIL_WORKER := "rail_worker"
const JOB_SCAVENGER := "scavenger"
const JOB_MEDIC := "medic"
const JOB_GENERALIST := "generalist"

const SKILL_MIN := 0.0
const SKILL_MAX := 100.0

# Task -> relevant skill mapping.
const _TASK_SKILLS := {
	"repair_shunter": SKILL_ENGINEERING,
	"repair_yard_control": SKILL_ENGINEERING,
	"repair_point": SKILL_ENGINEERING,
	"repair_track": SKILL_ENGINEERING,
	"connect_power": SKILL_ENGINEERING,
	"repair_onboard_fault": SKILL_ENGINEERING,
	"clear_obstruction": SKILL_RAILWAY,
	"activate_workshop": SKILL_ENGINEERING,
	"operate_points": SKILL_RAILWAY,
	"operate_yard_point": SKILL_RAILWAY,
	"uncouple": SKILL_RAILWAY,
	"couple": SKILL_RAILWAY,
	"search_poi": SKILL_SCAVENGING,
}

# Job -> eligible task categories.
const _JOB_ELIGIBILITY := {
	JOB_ENGINEER: ["repair_shunter", "repair_yard_control", "repair_point", "repair_track", "connect_power",
					"repair_onboard_fault", "activate_workshop", "operate_points",
					"operate_yard_point", "uncouple", "couple"],
	JOB_RAIL_WORKER: ["operate_points", "operate_yard_point", "uncouple", "couple"],
	JOB_SCAVENGER: [],
	JOB_MEDIC: [],
	JOB_GENERALIST: ["repair_shunter", "repair_yard_control", "repair_point", "repair_track", "connect_power",
					  "repair_onboard_fault", "clear_obstruction", "activate_workshop",
					  "operate_points", "operate_yard_point", "uncouple", "couple"],
}

var _profiles: Dictionary = {}


func init_survivor(survivor_id: String, skills: Dictionary = {}, job: String = JOB_GENERALIST) -> void:
	_profiles[survivor_id] = {
		"skills": {
			SKILL_ENGINEERING: float(skills.get(SKILL_ENGINEERING, 25.0)),
			SKILL_RAILWAY: float(skills.get(SKILL_RAILWAY, 25.0)),
			SKILL_SCAVENGING: float(skills.get(SKILL_SCAVENGING, 25.0)),
			SKILL_MEDICAL: float(skills.get(SKILL_MEDICAL, 25.0)),
		},
		"job": job,
	}


func has_survivor(survivor_id: String) -> bool:
	return _profiles.has(survivor_id)


func get_skill(survivor_id: String, skill_type: String) -> float:
	if not _profiles.has(survivor_id):
		return 0.0
	var skills := (_profiles[survivor_id] as Dictionary).get("skills", {}) as Dictionary
	return clampf(float(skills.get(skill_type, 0.0)), SKILL_MIN, SKILL_MAX)


func set_skill(survivor_id: String, skill_type: String, value: float) -> void:
	if not _profiles.has(survivor_id):
		return
	var skills := (_profiles[survivor_id] as Dictionary).get("skills", {}) as Dictionary
	skills[skill_type] = clampf(value, SKILL_MIN, SKILL_MAX)


func get_all_skills(survivor_id: String) -> Dictionary:
	if not _profiles.has(survivor_id):
		return {}
	return ((_profiles[survivor_id] as Dictionary).get("skills", {}) as Dictionary).duplicate()


func get_job(survivor_id: String) -> String:
	if not _profiles.has(survivor_id):
		return JOB_GENERALIST
	return str((_profiles[survivor_id] as Dictionary).get("job", JOB_GENERALIST))


func set_job(survivor_id: String, job: String) -> void:
	if not _profiles.has(survivor_id):
		return
	(_profiles[survivor_id] as Dictionary)["job"] = job


func get_task_skill_type(task_type: String) -> String:
	return str(_TASK_SKILLS.get(task_type, ""))


func get_task_suitability(survivor_id: String, task_type: String) -> float:
	# Returns a 0.0–1.0 suitability score for a survivor performing the given task.
	# Based on the relevant skill divided by max.
	var skill_type := get_task_skill_type(task_type)
	if skill_type == "":
		return 0.5  # No specific skill required; baseline suitability.
	var skill_value := get_skill(survivor_id, skill_type)
	return clampf(skill_value / SKILL_MAX, 0.0, 1.0)


func get_task_speed_multiplier(survivor_id: String, task_type: String) -> float:
	# Skilled survivors complete interactions faster: 0.7 at skill 0, 1.3 at skill 100.
	var suitability := get_task_suitability(survivor_id, task_type)
	return 0.7 + 0.6 * suitability


func is_job_eligible(survivor_id: String, task_type: String) -> bool:
	var job := get_job(survivor_id)
	if not _JOB_ELIGIBILITY.has(job):
		return true  # Unknown job defaults to eligible.
	var eligible_tasks: Array = _JOB_ELIGIBILITY[job]
	if eligible_tasks.is_empty():
		return false  # Specialised non-eligible job.
	return eligible_tasks.has(task_type)


func get_job_label(job: String) -> String:
	match job:
		JOB_ENGINEER:
			return "Engineer"
		JOB_RAIL_WORKER:
			return "Rail Worker"
		JOB_SCAVENGER:
			return "Scavenger"
		JOB_MEDIC:
			return "Medic"
		JOB_GENERALIST:
			return "Generalist"
	return job.capitalize()


func get_debug_summary(survivor_id: String) -> String:
	if not _profiles.has(survivor_id):
		return ""
	var skills := get_all_skills(survivor_id)
	return "%s E:%.0f R:%.0f S:%.0f M:%.0f" % [
		get_job_label(get_job(survivor_id)),
		float(skills.get(SKILL_ENGINEERING, 0.0)),
		float(skills.get(SKILL_RAILWAY, 0.0)),
		float(skills.get(SKILL_SCAVENGING, 0.0)),
		float(skills.get(SKILL_MEDICAL, 0.0)),
	]
