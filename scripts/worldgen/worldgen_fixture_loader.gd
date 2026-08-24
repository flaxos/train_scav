extends RefCounted
class_name WorldgenFixtureLoader

const SectorBlueprint := preload("res://scripts/worldgen/sector_blueprint.gd")


func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func load_blueprint(path: String) -> RefCounted:
	var data := load_json(path)
	if data.is_empty():
		return null
	return SectorBlueprint.from_dictionary(data)


func load_registry(path: String) -> Array[Dictionary]:
	var data := load_json(path)
	var entries: Array[Dictionary] = []
	for entry in data.get("archetypes", []):
		entries.append((entry as Dictionary).duplicate(true))
	return entries
