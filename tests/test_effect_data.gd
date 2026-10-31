extends "res://tests/test_case.gd"

const T := EffectData.Type
const G := EffectData.Target


func test_valid_effects_have_no_errors() -> void:
	assert_true(EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY).validate().is_empty())
	assert_true(EffectData.create(T.DAMAGE, 3, G.ALL_ENEMIES, 2).validate().is_empty())
	assert_true(EffectData.create(T.BLOCK, 5, G.SELF).validate().is_empty())
	assert_true(EffectData.create(T.DRAW, 2, G.SELF).validate().is_empty())
	assert_true(EffectData.create(T.GAIN_ENERGY, 1, G.SELF).validate().is_empty())
	assert_true(EffectData.create(T.APPLY_STATUS, 2, G.TARGET_ENEMY, 1, &"vulnerable").validate().is_empty())


func test_non_positive_amount_is_invalid() -> void:
	assert_false(EffectData.create(T.DAMAGE, 0, G.TARGET_ENEMY).validate().is_empty())
	assert_false(EffectData.create(T.BLOCK, -3, G.SELF).validate().is_empty())


func test_hits_rules() -> void:
	assert_false(EffectData.create(T.DAMAGE, 3, G.TARGET_ENEMY, 0).validate().is_empty())
	assert_false(EffectData.create(T.BLOCK, 3, G.SELF, 2).validate().is_empty())


func test_status_id_rules() -> void:
	assert_false(EffectData.create(T.APPLY_STATUS, 1, G.TARGET_ENEMY).validate().is_empty(), "thiếu status_id")
	assert_false(EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY, 1, &"weak").validate().is_empty(), "status_id thừa")


func test_target_rules() -> void:
	assert_false(EffectData.create(T.DAMAGE, 5, G.SELF).validate().is_empty())
	assert_false(EffectData.create(T.BLOCK, 5, G.TARGET_ENEMY).validate().is_empty())
	assert_false(EffectData.create(T.DRAW, 1, G.ALL_ENEMIES).validate().is_empty())
	assert_false(EffectData.create(T.GAIN_ENERGY, 1, G.RANDOM_ENEMY).validate().is_empty())


func test_heal_must_target_self() -> void:
	assert_true(EffectData.create(T.HEAL, 4, G.SELF).validate().is_empty())
	assert_false(EffectData.create(T.HEAL, 4, G.TARGET_ENEMY).validate().is_empty())
	assert_false(EffectData.create(T.HEAL, 0, G.SELF).validate().is_empty())


func test_lose_hp_can_target_self_or_enemies() -> void:
	for target: int in [G.SELF, G.TARGET_ENEMY, G.ALL_ENEMIES, G.RANDOM_ENEMY]:
		assert_true(EffectData.create(T.LOSE_HP, 3, target).validate().is_empty(), "target %d" % target)
	assert_false(EffectData.create(T.LOSE_HP, 3, G.SELF, 2).validate().is_empty(), "hits chỉ dùng cho DAMAGE")


func test_event_source_is_only_valid_when_explicitly_allowed() -> void:
	var effect := EffectData.create(T.DAMAGE, 2, G.EVENT_SOURCE)
	assert_false(effect.validate().is_empty(), "thẻ và chiêu quái không được dùng EVENT_SOURCE")
	assert_true(effect.validate(true).is_empty(), "trigger được dùng")


func test_scaled_returns_a_copy_and_keeps_other_fields() -> void:
	var original := EffectData.create(T.APPLY_STATUS, 2, G.ALL_ENEMIES, 1, &"weak")
	var triple := original.scaled(3)
	assert_eq(triple.amount, 6)
	assert_eq(original.amount, 2, "effect gốc dùng chung không được bị sửa")
	assert_eq([triple.type, triple.target, triple.status_id], [T.APPLY_STATUS, G.ALL_ENEMIES, &"weak"])
	assert_true(triple != original)


func test_new_enum_values_were_appended_so_old_data_keeps_its_numbers() -> void:
	assert_eq([T.DAMAGE, T.BLOCK, T.DRAW, T.GAIN_ENERGY, T.APPLY_STATUS], [0, 1, 2, 3, 4])
	assert_eq([G.SELF, G.TARGET_ENEMY, G.ALL_ENEMIES, G.RANDOM_ENEMY], [0, 1, 2, 3])


func test_scales_with_x_defaults_to_false_and_survives_scaling() -> void:
	var effect := EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY)
	assert_false(effect.scales_with_x)
	effect.scales_with_x = true
	assert_true(effect.scaled(2).scales_with_x, "bản sao giữ nguyên cờ")
