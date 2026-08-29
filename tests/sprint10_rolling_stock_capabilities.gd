extends SceneTree

const RailMovement := preload("res://scripts/rail/rail_movement.gd")
const TrainResources := preload("res://scripts/train/train_resources.gd")
const TrainInterior := preload("res://scripts/colony/train_interior.gd")

var _failures: int = 0


func _init() -> void:
	print("\n--- Starting Sprint 10 Rolling-Stock Capability Tests ---")
	_initial_train_capacity_is_generous_and_non_destructive()
	_catalogue_capability_tags_are_queryable()
	_tanker_and_storage_wagons_change_resource_capacity()
	_catalog_drives_interior_metadata_without_losing_safe_unknown_defaults()
	_finish()


func _initial_train_capacity_is_generous_and_non_destructive() -> void:
	var rail := RailMovement.new()
	_expect(rail.has_method("get_train_resource_capacities"), "RailMovement exposes train resource capacities")
	if not rail.has_method("get_train_resource_capacities"):
		return
	var capacities: Dictionary = rail.get_train_resource_capacities()
	_expect(float(capacities.get(TrainResources.RESOURCE_DIESEL, 0.0)) >= 80.0, "authored starting train has comfortable diesel capacity")
	_expect(float(capacities.get(TrainResources.RESOURCE_FOOD, 0.0)) >= 40.0, "authored starting train has comfortable food capacity")
	_expect(float(capacities.get(TrainResources.RESOURCE_PARTS, 0.0)) >= 40.0, "authored starting train has comfortable parts capacity")

	var resources := TrainResources.new({
		TrainResources.RESOURCE_DIESEL: float(capacities.get(TrainResources.RESOURCE_DIESEL, 0.0)) + 5.0,
		TrainResources.RESOURCE_FOOD: 12.0,
		TrainResources.RESOURCE_PARTS: 0.0,
	})
	_expect(resources.has_method("bind_capacity_provider"), "TrainResources can bind a capacity provider")
	if not resources.has_method("bind_capacity_provider"):
		return
	resources.bind_capacity_provider(rail)
	var before := resources.get_amount(TrainResources.RESOURCE_DIESEL)
	_expect(not resources.add(TrainResources.RESOURCE_DIESEL, 1.0), "capacity rejection does not accept overfilled diesel")
	_expect(is_equal_approx(resources.get_amount(TrainResources.RESOURCE_DIESEL), before), "capacity rejection does not silently destroy existing diesel")


func _catalogue_capability_tags_are_queryable() -> void:
	var rail := RailMovement.new()
	_expect(rail.has_method("get_unit_capabilities"), "RailMovement exposes unit capability tags")
	_expect(rail.has_method("has_train_capability"), "RailMovement exposes active-train capability queries")
	if not rail.has_method("get_unit_capabilities") or not rail.has_method("has_train_capability"):
		return

	var bunk_capabilities: Array[String] = rail.get_unit_capabilities("A")
	_expect(bunk_capabilities.has("crew_accommodation"), "bunk car exposes crew accommodation capability")
	_expect(rail.has_train_capability("crew_accommodation"), "active starting train reports crew accommodation capability")
	_expect(not rail.has_train_capability("workshop"), "detached workshop is not an active-train capability")

	rail.active_units.append("W")
	_expect(rail.has_train_capability("workshop"), "recovered workshop car exposes workshop capability tag")

	var flatbed_id := "sector_024_salvage_01"
	_expect(rail.set_unit_type(flatbed_id, "parts_flatbed"), "fixture assigns generated parts flatbed type for capability tag")
	rail.active_units.append(flatbed_id)
	var flatbed_capabilities: Array[String] = rail.get_unit_capabilities(flatbed_id)
	_expect(flatbed_capabilities.has("storage_parts"), "parts flatbed exposes parts storage capability tag")


func _tanker_and_storage_wagons_change_resource_capacity() -> void:
	var baseline := RailMovement.new()
	var baseline_capacity: Dictionary = baseline.get_train_resource_capacities()

	var with_tanker := RailMovement.new()
	with_tanker.active_units.append("sector_020_salvage_01")
	_expect(with_tanker.set_unit_type("sector_020_salvage_01", "fuel_tanker"), "fixture assigns generated tanker type")
	var tanker_capacity: Dictionary = with_tanker.get_train_resource_capacities()
	_expect(
		float(tanker_capacity.get(TrainResources.RESOURCE_DIESEL, 0.0)) > float(baseline_capacity.get(TrainResources.RESOURCE_DIESEL, 0.0)),
		"recovered tanker materially increases diesel capacity"
	)

	var with_storage := RailMovement.new()
	with_storage.active_units.append("sector_021_salvage_01")
	_expect(with_storage.set_unit_type("sector_021_salvage_01", "boxcar_storage"), "fixture assigns generated storage type")
	var storage_capacity: Dictionary = with_storage.get_train_resource_capacities()
	_expect(
		float(storage_capacity.get(TrainResources.RESOURCE_PARTS, 0.0)) > float(baseline_capacity.get(TrainResources.RESOURCE_PARTS, 0.0)),
		"recovered storage boxcar materially increases parts capacity"
	)
	_expect(
		float(storage_capacity.get(TrainResources.RESOURCE_FOOD, 0.0)) > float(baseline_capacity.get(TrainResources.RESOURCE_FOOD, 0.0)),
		"recovered storage boxcar materially increases food capacity"
	)

	var with_flatbed := RailMovement.new()
	with_flatbed.active_units.append("sector_023_salvage_01")
	_expect(with_flatbed.set_unit_type("sector_023_salvage_01", "parts_flatbed"), "fixture assigns generated parts flatbed type")
	var flatbed_capacity: Dictionary = with_flatbed.get_train_resource_capacities()
	_expect(
		float(flatbed_capacity.get(TrainResources.RESOURCE_PARTS, 0.0)) > float(baseline_capacity.get(TrainResources.RESOURCE_PARTS, 0.0)),
		"recovered parts flatbed materially increases parts capacity"
	)
	_expect(
		is_equal_approx(
			float(flatbed_capacity.get(TrainResources.RESOURCE_FOOD, 0.0)),
			float(baseline_capacity.get(TrainResources.RESOURCE_FOOD, 0.0))
		),
		"parts flatbed does not fake unrelated food capacity"
	)


func _catalog_drives_interior_metadata_without_losing_safe_unknown_defaults() -> void:
	var rail := RailMovement.new()
	var interior := TrainInterior.new(rail)

	_expect(interior.get_unit_interior_kind("A") == TrainInterior.KIND_BUNK, "legacy A remains bunk from catalogue")
	_expect(interior.get_unit_interior_kind("B") == TrainInterior.KIND_STORAGE, "legacy B remains storage from catalogue")
	_expect(interior.get_unit_interior_kind("W") == TrainInterior.KIND_WORKSHOP, "legacy W remains workshop from catalogue")
	_expect(not interior.is_boardable_unit("C"), "legacy tanker remains non-boardable")

	_expect(rail.set_unit_type("sector_022_salvage_01", "boxcar_storage"), "generated storage receives explicit metadata")
	rail.active_units.append("sector_022_salvage_01")
	_expect(interior.is_boardable_unit("sector_022_salvage_01"), "explicit generated storage is boardable through catalogue")
	_expect(interior.get_unit_interior_kind("sector_022_salvage_01") == TrainInterior.KIND_STORAGE, "explicit generated storage exposes storage interior")
	_expect(not interior.is_walkable_unit("unknown_future_stock"), "unknown future stock remains safely non-walkable")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("\nSprint 10 rolling-stock capability acceptance passed")
		quit(0)
	else:
		printerr("\nSprint 10 rolling-stock capability FAILED with %d failure(s)" % _failures)
		quit(1)
