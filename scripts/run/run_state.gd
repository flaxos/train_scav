extends RefCounted
class_name RunState

# Sprint 6A — Persistent run-level state model.
# Persists independent of disposable sector instances.

var run_seed: int = 12345
var sector_index: int = 0
var transition_count: int = 0
var previous_sector_disposed: bool = false
var last_departed_sector_id: String = ""
var run_journal: Array[Dictionary] = []


func _init(initial_seed: int = 12345) -> void:
	run_seed = initial_seed
	sector_index = 0
	transition_count = 0
	previous_sector_disposed = false
	last_departed_sector_id = ""
	run_journal = []


func record_transition(departed_id: String, entered_id: String, dest_seed: int, consist_order: Array[String]) -> void:
	sector_index += 1
	transition_count += 1
	previous_sector_disposed = true
	last_departed_sector_id = departed_id
	run_journal.append({
		"departed_sector_id": departed_id,
		"entered_sector_id": entered_id,
		"destination_seed": dest_seed,
		"consist_order": consist_order.duplicate(),
	})
