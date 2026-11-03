extends "res://tests/test_case.gd"

const Factory := preload("res://tests/card_factory.gd")
const CARD_DIR := "res://data/cards"


func test_default_factory_card_is_valid() -> void:
	assert_eq(Factory.card(&"strike").validate(), [] as Array[String])


func test_missing_id_and_name_are_invalid() -> void:
	var card := Factory.card(&"")
	card.display_name = "  "
	assert_true(card.validate().size() >= 2)


func test_cost_rules() -> void:
	assert_false(Factory.card(&"a", {"cost": -1}).validate().is_empty())
	assert_false(Factory.card(&"a", {"is_x_cost": true, "cost": 2}).validate().is_empty())
	assert_true(_x_card(&"a").validate().is_empty())


func test_playable_card_needs_effects() -> void:
	var empty: Array[EffectData] = []
	assert_false(Factory.card(&"a", {"effects": empty}).validate().is_empty())
	assert_true(Factory.card(&"curse", {"effects": empty, "unplayable": true, "card_type": CardData.CardType.SKILL,
			"target_mode": CardData.TargetMode.SELF}).validate().is_empty())


func test_attack_needs_damage_effect() -> void:
	var block: Array[EffectData] = [EffectData.create(EffectData.Type.BLOCK, 5, EffectData.Target.SELF)]
	var card := Factory.card(&"a", {"effects": block, "target_mode": CardData.TargetMode.SELF})
	assert_false(card.validate().is_empty())


func test_target_mode_must_match_effects() -> void:
	assert_false(Factory.card(&"a", {"target_mode": CardData.TargetMode.SELF}).validate().is_empty())
	var aoe: Array[EffectData] = [EffectData.create(EffectData.Type.DAMAGE, 4, EffectData.Target.ALL_ENEMIES)]
	assert_true(Factory.card(&"aoe", {"effects": aoe, "target_mode": CardData.TargetMode.ALL_ENEMIES}).validate().is_empty())
	assert_false(Factory.card(&"aoe", {"effects": aoe}).validate().is_empty())


func test_null_effect_is_reported_not_crashing() -> void:
	var card := Factory.card(&"a")
	card.effects.append(null)
	assert_false(card.validate().is_empty())


func test_upgrade_id_rules() -> void:
	assert_false(Factory.card(&"a", {"upgraded_id": &"a"}).validate().is_empty())
	assert_false(Factory.card(&"a+", {"upgraded_id": &"a++"}).validate().is_empty())
	assert_true(Factory.card(&"a+").is_upgrade())
	assert_false(Factory.card(&"a").is_upgrade())


func test_effect_errors_are_prefixed_with_index() -> void:
	var card := Factory.card(&"a")
	card.effects[0].amount = 0
	var errors := card.validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("effects[0]"))


func test_all_card_resources_are_valid_unique_and_linked() -> void:
	var cards: Dictionary = {}
	for file_name in DirAccess.get_files_at(CARD_DIR):
		if file_name.get_extension() != "tres":
			continue
		var card := load(CARD_DIR.path_join(file_name)) as CardData
		assert_true(card != null, "không nạp được " + file_name)
		if card == null:
			continue
		assert_eq(card.validate(), [] as Array[String], "thẻ %s lỗi" % card.id)
		assert_false(cards.has(card.id), "trùng id " + String(card.id))
		cards[card.id] = card
	assert_true(cards.size() > 0, "chưa có thẻ nào trong data/cards")
	for card: CardData in cards.values():
		if not card.upgraded_id.is_empty():
			assert_true(cards.has(card.upgraded_id), "%s trỏ tới upgraded_id không tồn tại" % card.id)


## --- X-cost ---

func _x_card(id: StringName, extra: Dictionary = {}) -> CardData:
	var scaling := EffectData.create(EffectData.Type.DAMAGE, 5, EffectData.Target.TARGET_ENEMY)
	scaling.scales_with_x = true
	var effects: Array[EffectData] = [scaling]
	var overrides := {"is_x_cost": true, "cost": 0, "effects": effects}
	overrides.merge(extra, true)
	return Factory.card(id, overrides)


func test_valid_x_cost_card() -> void:
	assert_eq(_x_card(&"whirl").validate(), [] as Array[String])
	assert_eq(_x_card(&"whirl", {"x_bonus": 1}).validate(), [] as Array[String])


func test_x_cost_card_needs_an_effect_that_scales() -> void:
	assert_false(Factory.card(&"x", {"is_x_cost": true, "cost": 0}).validate().is_empty(),
			"thẻ X-cost không có effect nào lặp theo X là vô nghĩa")


func test_scaling_effect_is_only_valid_on_x_cost_cards() -> void:
	var scaling := EffectData.create(EffectData.Type.DAMAGE, 5, EffectData.Target.TARGET_ENEMY)
	scaling.scales_with_x = true
	var effects: Array[EffectData] = [scaling]
	assert_false(Factory.card(&"normal", {"effects": effects}).validate().is_empty())


func test_x_bonus_rules() -> void:
	assert_false(_x_card(&"x", {"x_bonus": -1}).validate().is_empty(), "âm")
	assert_false(Factory.card(&"normal", {"x_bonus": 1}).validate().is_empty(), "chỉ dùng cho thẻ X-cost")


func test_target_mode_for_matches_the_expected_mode_of_cards() -> void:
	var single: Array[EffectData] = [EffectData.create(EffectData.Type.DAMAGE, 5, EffectData.Target.TARGET_ENEMY)]
	var everyone: Array[EffectData] = [EffectData.create(EffectData.Type.DAMAGE, 5, EffectData.Target.ALL_ENEMIES)]
	var random: Array[EffectData] = [EffectData.create(EffectData.Type.DAMAGE, 5, EffectData.Target.RANDOM_ENEMY)]
	var self_only: Array[EffectData] = [EffectData.create(EffectData.Type.BLOCK, 5, EffectData.Target.SELF)]
	var with_null: Array[EffectData] = [null, EffectData.create(EffectData.Type.BLOCK, 5, EffectData.Target.SELF)]
	assert_eq(CardData.target_mode_for(single), CardData.TargetMode.SINGLE_ENEMY)
	assert_eq(CardData.target_mode_for(everyone), CardData.TargetMode.ALL_ENEMIES)
	assert_eq(CardData.target_mode_for(random), CardData.TargetMode.NONE)
	assert_eq(CardData.target_mode_for(self_only), CardData.TargetMode.SELF)
	assert_eq(CardData.target_mode_for(with_null), CardData.TargetMode.SELF, "bỏ qua phần tử null")
	assert_eq(Factory.card(&"c").expected_target_mode(), CardData.target_mode_for(Factory.card(&"c").effects))
