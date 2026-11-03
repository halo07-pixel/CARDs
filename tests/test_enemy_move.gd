extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const T := EffectData.Type
const G := EffectData.Target


func test_valid_moves() -> void:
	assert_eq(Factory.attack_move(&"hit", 6).validate(), [] as Array[String])
	assert_eq(Factory.block_move(&"guard", 8).validate(), [] as Array[String])
	assert_eq(Factory.status_move(&"ritual", &"strength", 2, G.SELF).validate(), [] as Array[String])
	assert_eq(Factory.status_move(&"curse", &"weak", 1, G.TARGET_ENEMY).validate(), [] as Array[String])


func test_id_effects_weight_and_consecutive_rules() -> void:
	assert_false(Factory.attack_move(&"", 6).validate().is_empty())
	var no_effects: Array[EffectData] = []
	assert_false(Factory.move(&"empty", no_effects).validate().is_empty())
	assert_false(Factory.attack_move(&"x", 6, 0).validate().is_empty(), "weight 0")
	assert_false(Factory.attack_move(&"x", 6, 1, -1).validate().is_empty(), "max_consecutive âm")


func test_enemies_cannot_draw_or_gain_energy() -> void:
	var draw: Array[EffectData] = [EffectData.create(T.DRAW, 1, G.SELF)]
	var energy: Array[EffectData] = [EffectData.create(T.GAIN_ENERGY, 1, G.SELF)]
	assert_false(Factory.move(&"d", draw).validate().is_empty())
	assert_false(Factory.move(&"e", energy).validate().is_empty())


func test_invalid_or_null_effect_is_reported() -> void:
	var bad: Array[EffectData] = [EffectData.create(T.DAMAGE, 0, G.TARGET_ENEMY)]
	var errors := Factory.move(&"bad", bad).validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("effects[0]"))
	var with_null: Array[EffectData] = [null]
	assert_false(Factory.move(&"n", with_null).validate().is_empty())


func test_enemy_moves_cannot_scale_with_x() -> void:
	var effect := EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY)
	effect.scales_with_x = true
	var effects: Array[EffectData] = [effect]
	assert_false(Factory.move(&"x", effects).validate().is_empty())
