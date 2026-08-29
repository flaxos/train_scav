extends RefCounted
class_name RouteRequirementEvaluator

const KEY_MAX_MASS := "max_mass"
const KEY_MIN_MASS := "min_mass"
const KEY_MAX_LENGTH := "max_length"
const KEY_MAX_UNITS := "max_units"
const KEY_REQUIRE_TRACTION := "require_traction"
const KEY_MIN_TRACTION := "min_traction"
const KEY_REQUIRED_CAPABILITIES := "required_capabilities"


static func evaluate(mobility_summary: Dictionary, requirements: Dictionary, route_label: String = "Route") -> Dictionary:
	var blocked_reasons: Array[String] = []
	var details: Dictionary = {}

	if requirements.is_empty():
		return {
			"can_take_route": true,
			"blocked_reasons": blocked_reasons,
			"primary_reason": "",
			"details": details,
		}

	# 1. Traction authority & quantity check
	var require_traction := bool(requirements.get(KEY_REQUIRE_TRACTION, true))
	var has_traction := bool(mobility_summary.get("has_traction", false))
	var available_traction := float(mobility_summary.get("traction", 1.0 if has_traction else 0.0))
	var min_traction := float(requirements.get(KEY_MIN_TRACTION, 0.0))
	if min_traction <= 0.0 and typeof(requirements.get(KEY_REQUIRE_TRACTION)) in [TYPE_INT, TYPE_FLOAT]:
		min_traction = float(requirements.get(KEY_REQUIRE_TRACTION))

	details["require_traction"] = require_traction
	details["has_traction"] = has_traction
	details["min_traction"] = min_traction
	details["available_traction"] = available_traction

	if require_traction and not has_traction:
		blocked_reasons.append("Departure blocked: Train has no operational traction authority")
	elif min_traction > 0.0 and available_traction < min_traction:
		blocked_reasons.append("Departure blocked: %s requires %.0f traction units (train has %.0f)" % [
			route_label,
			min_traction,
			available_traction,
		])

	# 2. Maximum mass check
	var max_mass := float(requirements.get(KEY_MAX_MASS, 0.0))
	var total_mass := float(mobility_summary.get("total_mass", 0.0))
	details["max_mass"] = max_mass
	details["total_mass"] = total_mass
	if max_mass > 0.0 and total_mass > max_mass:
		blocked_reasons.append("Departure blocked: Train mass %.1ft exceeds %s limit (%.1ft max)" % [
			total_mass,
			route_label,
			max_mass,
		])

	# 3. Minimum mass check
	var min_mass := float(requirements.get(KEY_MIN_MASS, 0.0))
	details["min_mass"] = min_mass
	if min_mass > 0.0 and total_mass < min_mass:
		blocked_reasons.append("Departure blocked: Train mass %.1ft below %s minimum (%.1ft min)" % [
			total_mass,
			route_label,
			min_mass,
		])

	# 4. Maximum length check
	var max_length := float(requirements.get(KEY_MAX_LENGTH, 0.0))
	var total_length := float(mobility_summary.get("total_length", 0.0))
	details["max_length"] = max_length
	details["total_length"] = total_length
	if max_length > 0.0 and total_length > max_length:
		blocked_reasons.append("Departure blocked: Train length %.0fpx exceeds %s limit (%.0fpx max)" % [
			total_length,
			route_label,
			max_length,
		])

	# 5. Maximum units check
	var max_units := int(requirements.get(KEY_MAX_UNITS, 0))
	var unit_count := int(mobility_summary.get("unit_count", 0))
	details["max_units"] = max_units
	details["unit_count"] = unit_count
	if max_units > 0 and unit_count > max_units:
		blocked_reasons.append("Departure blocked: Consist size %d units exceeds %s limit (%d max)" % [
			unit_count,
			route_label,
			max_units,
		])

	# 6. Required capabilities check
	var required_caps: Array = requirements.get(KEY_REQUIRED_CAPABILITIES, []) as Array
	var train_caps: Array = mobility_summary.get("capabilities", []) as Array
	var missing_caps: Array[String] = []
	for raw_cap in required_caps:
		var cap := str(raw_cap)
		if cap != "" and not train_caps.has(cap):
			missing_caps.append(cap)
	details["required_capabilities"] = required_caps
	details["missing_capabilities"] = missing_caps
	for missing in missing_caps:
		blocked_reasons.append("Departure blocked: %s requires capability '%s' (not present on train)" % [
			route_label,
			missing,
		])

	var can_take := blocked_reasons.is_empty()
	var primary := ""
	if not can_take:
		primary = blocked_reasons[0]

	return {
		"can_take_route": can_take,
		"blocked_reasons": blocked_reasons,
		"primary_reason": primary,
		"details": details,
	}


static func format_requirements_summary(requirements: Dictionary) -> String:
	if requirements.is_empty():
		return "Unrestricted"

	var parts: Array[String] = []
	var max_mass := float(requirements.get(KEY_MAX_MASS, 0.0))
	if max_mass > 0.0:
		parts.append("Max %.0ft" % max_mass)
	var max_len := float(requirements.get(KEY_MAX_LENGTH, 0.0))
	if max_len > 0.0:
		parts.append("Max %.0fpx" % max_len)
	var max_u := int(requirements.get(KEY_MAX_UNITS, 0))
	if max_u > 0:
		parts.append("Max %d units" % max_u)
	var req_caps: Array = requirements.get(KEY_REQUIRED_CAPABILITIES, []) as Array
	for cap in req_caps:
		parts.append("Req %s" % str(cap))
	var min_tr := float(requirements.get(KEY_MIN_TRACTION, 0.0))
	if min_tr > 1.0:
		parts.append("Min %.0f traction" % min_tr)
	if not bool(requirements.get(KEY_REQUIRE_TRACTION, true)):
		parts.append("No traction req")

	if parts.is_empty():
		return "Standard"
	return " | ".join(parts)
