extends RefCounted
class_name WorldgenCanonical


func canonical_stringify(value: Variant) -> String:
	var value_type := typeof(value)
	if value_type == TYPE_DICTIONARY:
		return _canonical_dictionary(value as Dictionary)
	if value_type == TYPE_ARRAY:
		return _canonical_array(value as Array)
	return JSON.stringify(value)


func hash_dictionary(data: Dictionary) -> String:
	var context := HashingContext.new()
	var err := context.start(HashingContext.HASH_SHA256)
	if err != OK:
		return ""
	context.update(canonical_stringify(data).to_utf8_buffer())
	return context.finish().hex_encode()


func _canonical_dictionary(data: Dictionary) -> String:
	var keys: Array[String] = []
	for key in data.keys():
		keys.append(str(key))
	keys.sort()

	var parts: Array[String] = []
	for key in keys:
		parts.append("%s:%s" % [JSON.stringify(key), canonical_stringify(data[key])])
	return "{%s}" % ",".join(parts)


func _canonical_array(data: Array) -> String:
	var parts: Array[String] = []
	for item in data:
		parts.append(canonical_stringify(item))
	return "[%s]" % ",".join(parts)
