extends RefCounted
class_name SectorLifecycle

# Sprint 6A — Disposable Sector Lifecycle Manager.
# Manages persistent RunState, active SectorInstance, departure safety validation,
# and deterministic transfer of train/crew state across disposable sectors.

const RunState := preload("res://scripts/run/run_state.gd")
const SectorDefinition := preload("res://scripts/sector/sector_definition.gd")
const SectorDefinitionProvider := preload("res://scripts/sector/sector_definition_provider.gd")
const SectorInstance := preload("res://scripts/sector/sector_instance.gd")
const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const YardOperations := preload("res://scripts/yard/yard_operations.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")

var run_state: RunState
var current_sector: SectorInstance
var previous_sector: SectorInstance
var crew: RefCounted
var task_broker: RefCounted
var train_resources: TrainResources
var scenario_coordinator: RefCounted
var sector_definition_provider: RefCounted

var is_transitioning: bool = false
var transition_blocked_reason: String = ""


func _init(initial_seed: int = 12345, crew_sim: RefCounted = null, broker: RefCounted = null, resource_store: TrainResources = null, provider: RefCounted = null) -> void:
	run_state = RunState.new(initial_seed)
	crew = crew_sim
	task_broker = broker
	sector_definition_provider = provider
	if sector_definition_provider == null:
		sector_definition_provider = SectorDefinitionProvider.new()
	if resource_store == null:
		train_resources = TrainResources.new()
	else:
		train_resources = resource_store

	var initial_def := _create_sector_definition(run_state.sector_index)
	var rail_inst: RefCounted = null
	var yard_inst: RefCounted = null
	if crew != null:
		rail_inst = crew.rail
		yard_inst = crew.yard

	current_sector = SectorInstance.new(initial_def, rail_inst, yard_inst)
	_link_scavenging_context()


func get_train_resources() -> TrainResources:
	return train_resources


func set_scenario_coordinator(coordinator: RefCounted) -> void:
	scenario_coordinator = coordinator
	if scenario_coordinator != null and scenario_coordinator.has_method("configure_sector") and current_sector != null:
		scenario_coordinator.configure_sector(current_sector)
	_link_scavenging_context()


func can_depart() -> bool:
	transition_blocked_reason = ""
	_prepare_scenario_departure_context()
	if crew != null and not crew.are_all_survivors_aboard():
		var unboarded: Array[String] = crew.get_unboarded_survivor_names()
		transition_blocked_reason = "Departure blocked: Survivor(s) in yard (%s)" % ", ".join(unboarded)
		return false
	if scenario_coordinator != null and scenario_coordinator.has_method("get_departure_blocked_reason"):
		var scenario_reason := str(scenario_coordinator.get_departure_blocked_reason())
		if scenario_reason != "":
			transition_blocked_reason = scenario_reason
			return false
	if train_resources != null and not train_resources.can_afford(TrainResources.RESOURCE_DIESEL, TrainResources.DEPARTURE_DIESEL_COST):
		transition_blocked_reason = "Departure blocked: need %.0f diesel (have %.0f)" % [
			TrainResources.DEPARTURE_DIESEL_COST,
			train_resources.get_amount(TrainResources.RESOURCE_DIESEL),
		]
		return false
	return true


func step() -> bool:
	if is_transitioning or current_sector == null or current_sector.disposed:
		return false
	if current_sector.is_exit_crossed():
		return request_transition()
	return false


func request_transition() -> bool:
	if is_transitioning:
		return false
	if current_sector == null or current_sector.disposed:
		return false

	if not can_depart():
		return false

	is_transitioning = true
	var next_index := run_state.sector_index + 1
	var next_def := _create_sector_definition(next_index)
	if next_def == null:
		transition_blocked_reason = "Departure blocked: procedural sector generation failed"
		is_transitioning = false
		return false
	if train_resources != null:
		if not train_resources.consume(TrainResources.RESOURCE_DIESEL, TrainResources.DEPARTURE_DIESEL_COST):
			transition_blocked_reason = "Departure blocked: need %.0f diesel (have %.0f)" % [
				TrainResources.DEPARTURE_DIESEL_COST,
				train_resources.get_amount(TrainResources.RESOURCE_DIESEL),
			]
			is_transitioning = false
			return false

	# 1. Snapshot persistent train & crew state from current sector
	var old_sector := current_sector
	var departed_id := old_sector.definition.sector_id
	var consist_order: Array[String] = old_sector.rail.active_units.duplicate()
	var controlled_power_id: String = str(old_sector.rail.controlled_power_unit_id)
	var powered_conditions: Dictionary = old_sector.rail.powered_unit_conditions.duplicate()

	# 2. Build next sector definition and new disposable environment
	var new_rail := RailMovement.new()
	var new_yard := YardOperations.new(new_rail)
	var new_sector := SectorInstance.new(next_def, new_rail, new_yard)

	# 3. Transfer persistent train onto new entry track
	new_rail.active_units = consist_order.duplicate()
	new_rail.controlled_power_unit_id = controlled_power_id
	new_rail.powered_unit_conditions = powered_conditions
	new_rail.current_segment = next_def.entry_segment
	new_rail.distance = next_def.entry_distance
	new_rail.speed = 0.0
	new_rail.throttle = 0.0
	new_rail.direction = 1
	if scenario_coordinator != null and scenario_coordinator.has_method("configure_sector"):
		scenario_coordinator.configure_sector(new_sector)

	# 4. Dispose old sector instance
	previous_sector = old_sector
	old_sector.dispose()

	# 5. Record transition in persistent run state
	run_state.record_transition(departed_id, next_def.sector_id, next_def.seed_value, consist_order)
	current_sector = new_sector

	# 6. Re-link crew simulation and task broker to new sector rail/yard
	if crew != null:
		crew.reset_for_new_sector(new_rail, new_yard)
	_link_scavenging_context()
	if task_broker != null:
		task_broker.rail = new_rail
		task_broker.yard = new_yard

	is_transitioning = false
	return true


func get_sector_state() -> Dictionary:
	var sec_id := ""
	var sec_template := ""
	var sec_seed := 0
	var sec_idx := run_state.sector_index
	if current_sector != null and current_sector.definition != null:
		sec_id = current_sector.definition.sector_id
		sec_template = current_sector.definition.template_name
		sec_seed = current_sector.definition.seed_value

	var prev_disposed := false
	if previous_sector != null:
		prev_disposed = previous_sector.disposed

	var consist: Array[String] = []
	if current_sector != null and current_sector.rail != null:
		consist = current_sector.rail.active_units.duplicate()

	return {
		"sector_id": sec_id,
		"template_name": sec_template,
		"seed": sec_seed,
		"sector_index": sec_idx,
		"transition_count": run_state.transition_count,
		"previous_sector_disposed": prev_disposed,
		"consist_order": consist,
		"blocked_reason": transition_blocked_reason,
		"resources": train_resources.get_all() if train_resources != null else {},
		"source_type": current_sector.definition.source_type if current_sector != null and current_sector.definition != null else "",
		"archetype_id": current_sector.definition.archetype_id if current_sector != null and current_sector.definition != null else "",
		"blueprint_hash": current_sector.definition.blueprint_hash if current_sector != null and current_sector.definition != null else "",
		"generator_version": current_sector.definition.generator_version if current_sector != null and current_sector.definition != null else "",
	}


func get_sector_debug_lines() -> Array[String]:
	var st := get_sector_state()
	return [
		"Sector: %s (%s)  Seed: %d  Idx: %d  %s" % [st["sector_id"], st["template_name"], st["seed"], st["sector_index"], str(st.get("source_type", ""))],
		"Transitions: %d  Prev Disposed: %s" % [st["transition_count"], str(st["previous_sector_disposed"])],
	]


func _link_scavenging_context() -> void:
	if crew == null or current_sector == null:
		return
	if crew.has_method("set_scavenging_context"):
		crew.set_scavenging_context(current_sector.pois, train_resources)


func _prepare_scenario_departure_context() -> void:
	if scenario_coordinator == null or not scenario_coordinator.has_method("prepare_departure_for_exit"):
		return
	var crossed_exit: Dictionary = {}
	if current_sector != null and current_sector.has_method("get_crossed_exit"):
		crossed_exit = current_sector.get_crossed_exit()
	scenario_coordinator.prepare_departure_for_exit(crossed_exit)


func _create_sector_definition(sector_index: int) -> SectorDefinition:
	var route_profile := run_state.next_sector_profile
	if route_profile.is_empty():
		route_profile = "forward"
	if sector_definition_provider != null and sector_definition_provider.has_method("create_definition"):
		return sector_definition_provider.create_definition(run_state.run_seed, sector_index, route_profile)
	return SectorDefinition.create_for_index(run_state.run_seed, sector_index)
