extends "res://tests/test_case.gd"


func test_every_controller_reason_has_its_own_text() -> void:
	var seen: Array[String] = []
	var script: GDScript = BattleController
	var constants: Dictionary = script.get_script_constant_map()
	var reasons := 0
	for key: String in constants:
		if not key.begins_with("REASON_"):
			continue
		reasons += 1
		var text := RejectionText.for_reason(constants[key])
		assert_ne(text, RejectionText.FALLBACK, "thiếu câu cho %s" % key)
		assert_false(seen.has(text), "câu bị trùng cho %s: %s" % [key, text])
		seen.append(text)
	assert_true(reasons >= 8, "phải tìm thấy các REASON_* của controller (thấy %d)" % reasons)


func test_unknown_reason_falls_back() -> void:
	assert_eq(RejectionText.for_reason(&"khong_biet"), RejectionText.FALLBACK)
	assert_eq(RejectionText.for_reason(&""), RejectionText.FALLBACK)
