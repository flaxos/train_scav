extends RefCounted
class_name WorldgenSeedDerivation

const WorldgenCanonical := preload("res://scripts/worldgen/worldgen_canonical.gd")

const SEED_NAMESPACE := "train_scav_worldgen_stream_seed_v1"
const RNG_MODULUS := 2147483647
const SUBSEED_RANGE := RNG_MODULUS - 1
const DIGEST_BYTES_USED := 8


func derive_subseed(identity: Dictionary, stream_name: String) -> int:
	var material := get_seed_material(identity, stream_name)
	var canonical := WorldgenCanonical.new().canonical_stringify(material)
	var digest := _sha256_bytes(canonical)
	var accumulator := 0
	# Contract: bytes 0..7 of the SHA-256 digest, digest order, interpreted as
	# unsigned big-endian, then modulo 2147483646 plus one.
	for i in range(DIGEST_BYTES_USED):
		accumulator = int((accumulator * 256 + int(digest[i])) % SUBSEED_RANGE)
	return accumulator + 1


func get_seed_material(identity: Dictionary, stream_name: String) -> Dictionary:
	return {
		"namespace": SEED_NAMESPACE,
		"run_seed": int(identity.get("run_seed", 0)),
		"sector_index": int(identity.get("sector_index", 0)),
		"route_profile": str(identity.get("route_profile", "")),
		"region_pack": str(identity.get("region_pack", "")),
		"grammar_version": str(identity.get("grammar_version", "")),
		"generator_version": str(identity.get("generator_version", "")),
		"stream_name": stream_name,
	}


func get_contract_dictionary() -> Dictionary:
	return {
		"algorithm": "sha256_first_8_bytes_big_endian_mod_2147483646_plus_1",
		"digest": "SHA-256 over WorldgenCanonical.canonical_stringify(seed_material)",
		"digest_bytes_used": "bytes[0..7]",
		"byte_order": "big_endian",
		"modulus": SUBSEED_RANGE,
		"offset": 1,
		"seed_range": "[1, 2147483646]",
	}


func _sha256_bytes(value: String) -> PackedByteArray:
	var context := HashingContext.new()
	var err := context.start(HashingContext.HASH_SHA256)
	if err != OK:
		return PackedByteArray()
	context.update(value.to_utf8_buffer())
	return context.finish()
