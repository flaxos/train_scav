extends RefCounted
class_name WorldgenGenerationTrace

const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")

const TRACE_VERSION := "worldgen_generation_trace_v1"

var _data: Dictionary = {}
var _canonical_hash: String = ""


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)
	_canonical_hash = WorldgenCanonical.new().hash_dictionary(_data)


func to_dictionary() -> Dictionary:
	return _data.duplicate(true)


func to_canonical_string() -> String:
	return WorldgenCanonical.new().canonical_stringify(_data)


func get_canonical_hash() -> String:
	return _canonical_hash


func get_stream_subseed(stream_name: String) -> int:
	return int((_data.get("stream_subseeds", {}) as Dictionary).get(stream_name, 0))
