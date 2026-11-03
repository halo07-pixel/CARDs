extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const CardFactory := preload("res://tests/card_factory.gd")
const T := EffectData.Type
const G := EffectData.Target


func _real() -> CardRegistry:
	return CardRegistry.load_from_dir("res://data/cards")


func test_loads_all_starter_cards_valid_and_linked() -> void:
	var registry := _real()
	assert_eq(registry.size(), 38, "19 thẻ gốc + 19 bản nâng cấp (file lỗi/trùng id sẽ bị loại)")
	assert_eq(registry.link_errors(), [] as Array[String])
	for id in [&"strike", &"strike+", &"defend", &"defend+", &"bash", &"cleave", &"iron_wave",
			&"pommel_strike", &"shrug_it_off", &"twin_strike", &"adrenaline", &"thunderclap"]:
		assert_true(registry.has_card(id), String(id))
		assert_eq(registry.get_card(id).validate(), [] as Array[String], String(id))


func test_new_cards_have_designed_values() -> void:
	var registry := _real()
	var bash := registry.get_card(&"bash")
	assert_eq(bash.cost, 2)
	assert_eq(bash.effects[0].amount, 8)
	assert_eq(bash.effects[1].status_id, &"vulnerable")
	assert_eq(bash.effects[1].amount, 2)
	var cleave := registry.get_card(&"cleave")
	assert_eq(cleave.target_mode, CardData.TargetMode.ALL_ENEMIES)
	var twin := registry.get_card(&"twin_strike")
	assert_eq(twin.effects[0].hits, 2)
	var adrenaline := registry.get_card(&"adrenaline")
	assert_eq(adrenaline.cost, 0)
	assert_true(adrenaline.exhaust)
	var types: Array = []
	for effect in adrenaline.effects:
		types.append(effect.type)
	assert_true(types.has(T.GAIN_ENERGY) and types.has(T.DRAW))
	var thunder := registry.get_card(&"thunderclap")
	assert_eq(thunder.effects[1].target, G.ALL_ENEMIES)
	assert_eq(registry.get_card(&"strike").upgraded_id, &"strike+")


func test_every_effect_type_is_covered_by_the_card_set() -> void:
	var seen: Dictionary = {}
	var registry := _real()
	for id in registry.all_ids():
		for effect in registry.get_card(id).effects:
			seen[effect.type] = true
	assert_eq(seen.size(), EffectData.Type.size(), "bộ thẻ mẫu phải dùng đủ mọi loại hiệu ứng")


func test_phase_2_cards_have_designed_values() -> void:
	var registry := _real()
	var inflame := registry.get_card(&"inflame")
	assert_eq(inflame.card_type, CardData.CardType.POWER)
	assert_eq(inflame.effects[0].status_id, &"strength")
	assert_eq(inflame.effects[0].amount, 2)
	assert_eq(registry.get_card(&"demon_form").cost, 3)
	assert_eq(registry.get_card(&"barricade").cost, 3)
	assert_eq(registry.get_card(&"deadly_poison").effects[0].status_id, &"poison")
	var bloodletting := registry.get_card(&"bloodletting")
	assert_eq(bloodletting.cost, 0)
	assert_eq(bloodletting.effects[0].type, T.LOSE_HP)
	var bandage := registry.get_card(&"bandage_up")
	assert_true(bandage.exhaust)
	assert_eq(bandage.effects[0].type, T.HEAL)
	for id in [&"inflame", &"metallicize", &"demon_form", &"barricade"]:
		assert_eq(registry.get_card(id).card_type, CardData.CardType.POWER, String(id))


func test_register_rejects_wrong_type_duplicate_invalid_and_null() -> void:
	var registry := CardRegistry.new()
	assert_true(registry.register(CardFactory.card(&"a")))
	assert_false(registry.register(CardFactory.card(&"a")), "trùng id")
	assert_false(registry.register(CardData.new()), "không hợp lệ")
	assert_false(registry.register(Factory.weak()), "sai kiểu (StatusData)")
	assert_false(registry.register(null))
	assert_eq(registry.size(), 1)
	assert_true(registry.get_card(&"nope") == null)


func test_missing_ids_are_deduplicated() -> void:
	var registry := _real()
	var ids: Array[StringName] = [&"strike", &"ghost", &"ghost", &"phantom"]
	assert_eq(registry.missing_ids(ids), [&"ghost", &"phantom"] as Array[StringName])


func test_create_instances_gives_independent_cards_in_order() -> void:
	var registry := _real()
	var ids: Array[StringName] = [&"strike", &"strike", &"defend"]
	var cards := registry.create_instances(ids)
	assert_eq(cards.size(), 3)
	assert_ne(cards[0].uid, cards[1].uid, "hai Strike là hai instance khác nhau")
	assert_true(cards[0].data == cards[1].data, "nhưng dùng chung CardData")
	assert_eq(cards[2].data.id, &"defend")


func test_create_instances_with_unknown_id_returns_nothing() -> void:
	var registry := _real()
	var ids: Array[StringName] = [&"strike", &"ghost"]
	assert_eq(registry.create_instances(ids).size(), 0, "không tạo nửa chừng")


func test_link_errors_detects_dangling_upgrade() -> void:
	var registry := CardRegistry.new()
	registry.register(CardFactory.card(&"a", {"upgraded_id": &"a+"}))
	assert_eq(registry.link_errors().size(), 1)
	registry.register(CardFactory.card(&"a+"))
	assert_eq(registry.link_errors().size(), 0)
