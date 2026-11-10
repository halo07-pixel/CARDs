extends "res://tests/test_case.gd"
## SfxMap: bảng cái-gì-xảy-ra -> tên âm thanh (hàm thuần).


func _cue(kind: EffectCue.Kind) -> EffectCue:
	return EffectCue.create(kind, null, "x")


func test_names_are_unique_and_valid_file_names() -> void:
	var seen := {}
	for sfx in SfxMap.ALL:
		assert_false(seen.has(sfx), "trùng tên: %s" % sfx)
		seen[sfx] = true
		assert_true(String(sfx).is_valid_filename() and String(sfx) == String(sfx).to_lower() and not String(sfx).contains(" "), "tên tệp hợp lệ: %s" % sfx)


func test_every_cue_kind_is_decided_explicitly_sound_or_silent() -> void:
	var silent: Array = [EffectCue.Kind.DRAW, EffectCue.Kind.ENERGY]
	for kind in EffectCue.Kind.values():
		var sfx := SfxMap.for_cue_kind(kind)
		if silent.has(kind):
			assert_eq(sfx, &"", "kind %d im lặng có chủ ý" % kind)
		else:
			assert_true(SfxMap.ALL.has(sfx), "kind %d phải có âm thanh nằm trong ALL" % kind)


func test_cue_kind_mapping() -> void:
	assert_eq(SfxMap.for_cue_kind(EffectCue.Kind.DAMAGE), SfxMap.HIT)
	assert_eq(SfxMap.for_cue_kind(EffectCue.Kind.LOSE_HP), SfxMap.HIT)
	assert_eq(SfxMap.for_cue_kind(EffectCue.Kind.BLOCKED), SfxMap.BLOCKED)
	assert_eq(SfxMap.for_cue_kind(EffectCue.Kind.BLOCK_GAIN), SfxMap.BLOCK_GAIN)
	assert_eq(SfxMap.for_cue_kind(EffectCue.Kind.HEAL), SfxMap.HEAL)
	assert_eq(SfxMap.for_cue_kind(EffectCue.Kind.STATUS), SfxMap.STATUS)


func test_a_batch_plays_each_sound_once_in_first_seen_order() -> void:
	var cues: Array[EffectCue] = [_cue(EffectCue.Kind.DAMAGE), _cue(EffectCue.Kind.DAMAGE), _cue(EffectCue.Kind.STATUS),
			_cue(EffectCue.Kind.LOSE_HP), _cue(EffectCue.Kind.BLOCK_GAIN)]
	assert_eq(SfxMap.for_cues(cues), [SfxMap.HIT, SfxMap.STATUS, SfxMap.BLOCK_GAIN] as Array[StringName], "đòn nhiều hit không phát chồng")


func test_silent_cues_are_skipped_and_empty_input_is_empty() -> void:
	var cues: Array[EffectCue] = [_cue(EffectCue.Kind.DRAW), _cue(EffectCue.Kind.ENERGY)]
	assert_eq(SfxMap.for_cues(cues).size(), 0)
	assert_eq(SfxMap.for_cues([] as Array[EffectCue]).size(), 0)


func test_battle_end_sound() -> void:
	assert_eq(SfxMap.for_battle_end(true), SfxMap.VICTORY)
	assert_eq(SfxMap.for_battle_end(false), SfxMap.DEFEAT)


func test_input_array_is_not_changed() -> void:
	var cues: Array[EffectCue] = [_cue(EffectCue.Kind.DAMAGE), _cue(EffectCue.Kind.DAMAGE)]
	SfxMap.for_cues(cues)
	assert_eq(cues.size(), 2)
