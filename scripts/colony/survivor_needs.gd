extends RefCounted
class_name SurvivorNeeds

# Sprint 5B — Minimal survivor needs.
#
# Each survivor owns three need values: health, hunger and rest. Values are
# normalised 0.0–100.0 where 100.0 is the best possible state. Needs change
# deterministically over simulation time.
#
# hunger and rest decay at a fixed rate. health only degrades when hunger or
# rest are critically low, and slowly recovers when both are adequate.
#
# Extremely poor needs produce a small, deterministic performance penalty
# (walk speed multiplier) so the player can observe the effect without the
# system silently doing nothing.

const NEED_HEALTH := "health"
const NEED_HUNGER := "hunger"
const NEED_REST := "rest"

const NEED_MIN := 0.0
const NEED_MAX := 100.0
const NEED_DEFAULT := 100.0

# Decay rates per second (higher = faster drain).
const HUNGER_DECAY_RATE := 0.35
const REST_DECAY_RATE := 0.25

# Health recovery/damage rates per second.
const HEALTH_RECOVERY_RATE := 0.10
const HEALTH_DAMAGE_RATE := 0.15

# Thresholds below which needs are considered critical/poor.
const CRITICAL_THRESHOLD := 15.0
const POOR_THRESHOLD := 35.0
const ADEQUATE_THRESHOLD := 50.0

# Performance multiplier at worst possible needs (0 hunger, 0 rest).
const WORST_PERFORMANCE := 0.35
const POOR_PERFORMANCE := 0.65


var _needs: Dictionary = {}


func init_survivor(survivor_id: String) -> void:
	_needs[survivor_id] = {
		NEED_HEALTH: NEED_DEFAULT,
		NEED_HUNGER: NEED_DEFAULT,
		NEED_REST: NEED_DEFAULT,
	}


func has_survivor(survivor_id: String) -> bool:
	return _needs.has(survivor_id)


func get_need(survivor_id: String, need_type: String) -> float:
	if not _needs.has(survivor_id):
		return NEED_DEFAULT
	return float((_needs[survivor_id] as Dictionary).get(need_type, NEED_DEFAULT))


func set_need(survivor_id: String, need_type: String, value: float) -> void:
	if not _needs.has(survivor_id):
		return
	(_needs[survivor_id] as Dictionary)[need_type] = clampf(value, NEED_MIN, NEED_MAX)


func get_all_needs(survivor_id: String) -> Dictionary:
	if not _needs.has(survivor_id):
		return {}
	return (_needs[survivor_id] as Dictionary).duplicate()


func step(delta: float) -> void:
	for survivor_id: String in _needs:
		_step_survivor(survivor_id, delta)


func _step_survivor(survivor_id: String, delta: float) -> void:
	var needs := _needs[survivor_id] as Dictionary
	var hunger := float(needs.get(NEED_HUNGER, NEED_DEFAULT))
	var rest := float(needs.get(NEED_REST, NEED_DEFAULT))
	var health := float(needs.get(NEED_HEALTH, NEED_DEFAULT))

	# Hunger and rest decay at fixed rates.
	hunger = clampf(hunger - HUNGER_DECAY_RATE * delta, NEED_MIN, NEED_MAX)
	rest = clampf(rest - REST_DECAY_RATE * delta, NEED_MIN, NEED_MAX)

	# Health is affected by the worst of hunger/rest:
	# - If either is critical, health degrades.
	# - If both are adequate, health slowly recovers.
	# - Otherwise health stays stable.
	var worst := minf(hunger, rest)
	if worst <= CRITICAL_THRESHOLD:
		health = clampf(health - HEALTH_DAMAGE_RATE * delta, NEED_MIN, NEED_MAX)
	elif worst >= ADEQUATE_THRESHOLD:
		health = clampf(health + HEALTH_RECOVERY_RATE * delta, NEED_MIN, NEED_MAX)

	needs[NEED_HUNGER] = hunger
	needs[NEED_REST] = rest
	needs[NEED_HEALTH] = health


func get_performance_multiplier(survivor_id: String) -> float:
	if not _needs.has(survivor_id):
		return 1.0

	var needs := _needs[survivor_id] as Dictionary
	var hunger := float(needs.get(NEED_HUNGER, NEED_DEFAULT))
	var rest := float(needs.get(NEED_REST, NEED_DEFAULT))
	var health := float(needs.get(NEED_HEALTH, NEED_DEFAULT))

	# Performance is the product of individual need factors.
	# Each factor goes from 1.0 (at 100) to a floor (at 0).
	var hunger_factor := _need_factor(hunger)
	var rest_factor := _need_factor(rest)
	var health_factor := _need_factor(health)

	return clampf(hunger_factor * rest_factor * health_factor, WORST_PERFORMANCE, 1.0)


func get_worst_need(survivor_id: String) -> String:
	if not _needs.has(survivor_id):
		return ""
	var needs := _needs[survivor_id] as Dictionary
	var worst_type := ""
	var worst_value := NEED_MAX + 1.0
	for need_type: String in [NEED_HEALTH, NEED_HUNGER, NEED_REST]:
		var value := float(needs.get(need_type, NEED_DEFAULT))
		if value < worst_value:
			worst_value = value
			worst_type = need_type
	return worst_type


func get_need_status(survivor_id: String, need_type: String) -> String:
	var value := get_need(survivor_id, need_type)
	if value <= CRITICAL_THRESHOLD:
		return "critical"
	if value <= POOR_THRESHOLD:
		return "poor"
	if value <= ADEQUATE_THRESHOLD:
		return "fair"
	return "good"


func get_debug_summary(survivor_id: String) -> String:
	if not _needs.has(survivor_id):
		return ""
	var needs := _needs[survivor_id] as Dictionary
	return "H:%.0f Hu:%.0f R:%.0f P:%.0f%%" % [
		float(needs.get(NEED_HEALTH, NEED_DEFAULT)),
		float(needs.get(NEED_HUNGER, NEED_DEFAULT)),
		float(needs.get(NEED_REST, NEED_DEFAULT)),
		get_performance_multiplier(survivor_id) * 100.0,
	]


func _need_factor(value: float) -> float:
	# Linear interpolation from 1.0 at NEED_MAX to 0.6 at NEED_MIN.
	return clampf(0.6 + 0.4 * (value / NEED_MAX), 0.6, 1.0)
