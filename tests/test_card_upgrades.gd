extends "res://tests/test_case.gd"
## Dữ liệu nâng cấp thẻ: bản "+" không bao giờ yếu hơn bản gốc và phải tốt hơn ở ít nhất một điểm.

const CardFactory := preload("res://tests/card_factory.gd")
const T := EffectData.Type
const G := EffectData.Target


func _dmg(amount: int, hits: int = 1) -> Array[EffectData]:
	return [EffectData.create(T.DAMAGE, amount, G.TARGET_ENEMY, hits)] as Array[EffectData]


## Registry gồm thẻ gốc "card" và bản nâng cấp "card+" với các ghi đè cho từng bên.
func _pair(base: Dictionary, up: Dictionary) -> CardRegistry:
	var registry := CardRegistry.new()
	var base_overrides := {"upgraded_id": &"card+"}
	base_overrides.merge(base, true)
	assert_true(registry.register(CardFactory.card(&"card", base_overrides)), "thẻ gốc phải hợp lệ")
	assert_true(registry.register(CardFactory.card(&"card+", up)), "bản + phải hợp lệ")
	return registry


func _has_problem(registry: CardRegistry, fragment: String) -> bool:
	for message in registry.upgrade_problems():
		if message.contains(fragment):
			return true
	return false


## --- Dữ liệu thật ---

func test_every_real_upgrade_is_valid_linked_and_strictly_better() -> void:
	var registry := CardRegistry.load_from_dir("res://data/cards")
	assert_eq(registry.upgrade_problems(), [] as Array[String])
	assert_eq(registry.link_errors(), [] as Array[String])
	var pairs := 0
	for id in registry.all_ids():
		var base := registry.get_card(id)
		if base.upgraded_id.is_empty():
			continue
		pairs += 1
		var improved := registry.upgraded(id)
		assert_true(improved != null and improved.is_upgrade(), "%s -> %s" % [id, base.upgraded_id])
		assert_true(improved.upgraded_id.is_empty(), "bản + không có bản + tiếp theo (%s)" % improved.id)
	assert_eq(pairs, 19, "mọi thẻ gốc đều có bản nâng cấp")


func test_upgraded_accessor() -> void:
	var registry := CardRegistry.load_from_dir("res://data/cards")
	assert_eq(registry.upgraded(&"bash").id, &"bash+")
	assert_true(registry.upgraded(&"bash+") == null, "bản + không nâng cấp thêm")
	assert_true(registry.upgraded(&"ghost") == null)


func test_real_upgrades_have_the_expected_improvements() -> void:
	var registry := CardRegistry.load_from_dir("res://data/cards")
	assert_eq(registry.get_card(&"bash+").effects[0].amount, 10)
	assert_eq(registry.get_card(&"bash+").effects[1].amount, 3)
	assert_eq(registry.get_card(&"barricade+").cost, 2, "Barricade+ rẻ hơn thay vì mạnh hơn")
	assert_eq(registry.get_card(&"whirlwind+").effects[0].amount, 8)
	assert_true(registry.get_card(&"whirlwind+").is_x_cost)
	assert_eq(registry.get_card(&"bandage_up+").effects[0].amount, 6)


## --- Trường hợp hợp lệ ---

func test_valid_improvements_are_accepted() -> void:
	assert_eq(_pair({"effects": _dmg(6)}, {"effects": _dmg(9)}).upgrade_problems(), [] as Array[String], "mạnh hơn")
	assert_eq(_pair({"effects": _dmg(6), "cost": 2}, {"effects": _dmg(6), "cost": 1}).upgrade_problems(),
			[] as Array[String], "chỉ rẻ hơn")
	assert_eq(_pair({"effects": _dmg(6), "exhaust": true}, {"effects": _dmg(6)}).upgrade_problems(),
			[] as Array[String], "chỉ bỏ exhaust")
	assert_eq(_pair({"effects": _dmg(5, 2)}, {"effects": _dmg(5, 3)}).upgrade_problems(),
			[] as Array[String], "thêm một hit")


func test_extra_effect_counts_as_an_improvement() -> void:
	var up: Array[EffectData] = [EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY), EffectData.create(T.BLOCK, 3, G.SELF)]
	assert_eq(_pair({"effects": _dmg(6)}, {"effects": up}).upgrade_problems(), [] as Array[String])


func test_losing_less_hp_counts_as_better_but_losing_more_is_worse() -> void:
	var base: Array[EffectData] = [EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY), EffectData.create(T.LOSE_HP, 3, G.SELF)]
	var less: Array[EffectData] = [EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY), EffectData.create(T.LOSE_HP, 2, G.SELF)]
	var more: Array[EffectData] = [EffectData.create(T.DAMAGE, 9, G.TARGET_ENEMY), EffectData.create(T.LOSE_HP, 5, G.SELF)]
	assert_eq(_pair({"effects": base}, {"effects": less}).upgrade_problems(), [] as Array[String])
	assert_true(_has_problem(_pair({"effects": base}, {"effects": more}), "yếu đi"))


func test_x_bonus_increase_is_an_improvement() -> void:
	var scaling := EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY)
	scaling.scales_with_x = true
	var effects: Array[EffectData] = [scaling]
	var x_overrides := {"effects": effects, "is_x_cost": true, "cost": 0}
	var better := x_overrides.duplicate()
	better["x_bonus"] = 1
	assert_eq(_pair(x_overrides, better).upgrade_problems(), [] as Array[String])


## --- Trường hợp phải bị bắt ---

func test_weaker_or_identical_upgrades_are_caught() -> void:
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(5)}), "yếu đi"))
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(6)}), "không tốt hơn"))
	var dropped: Array[EffectData] = [EffectData.create(T.DAMAGE, 9, G.TARGET_ENEMY)]
	var base: Array[EffectData] = [EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY), EffectData.create(T.BLOCK, 5, G.SELF)]
	assert_true(_has_problem(_pair({"effects": base}, {"effects": dropped}), "yếu đi"), "mất mất một effect")


func test_more_expensive_upgrade_is_caught() -> void:
	assert_true(_has_problem(_pair({"effects": _dmg(6), "cost": 1}, {"effects": _dmg(12), "cost": 2}), "cost tăng"))


func test_changing_identity_is_caught() -> void:
	var skill_effects: Array[EffectData] = [EffectData.create(T.BLOCK, 5, G.SELF)]
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(9), "card_type": CardData.CardType.SKILL}), "giữ nguyên"))
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(9), "rarity": CardData.Rarity.RARE}), "giữ nguyên"))
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(9), "character_id": &"rogue"}), "giữ nguyên"))
	assert_true(skill_effects.size() == 1)


func test_worse_keywords_are_caught() -> void:
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(9), "exhaust": true}), "từ khóa"))
	assert_true(_has_problem(_pair({"effects": _dmg(6)}, {"effects": _dmg(9), "ethereal": true}), "từ khóa"))
	assert_true(_has_problem(_pair({"effects": _dmg(6), "retain": true}, {"effects": _dmg(9)}), "từ khóa"))
	assert_true(_has_problem(_pair({"effects": _dmg(6), "innate": true}, {"effects": _dmg(9)}), "từ khóa"))


func test_losing_x_cost_status_is_caught() -> void:
	var scaling := EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY)
	scaling.scales_with_x = true
	var x_effects: Array[EffectData] = [scaling]
	assert_true(_has_problem(_pair({"effects": x_effects, "is_x_cost": true, "cost": 0}, {"effects": _dmg(9)}), "X-cost"))
