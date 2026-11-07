extends "res://tests/test_case.gd"
## TooltipBuilder: dựng nội dung tooltip từ view-model/dữ liệu.

const Factory := preload("res://tests/combat_factory.gd")
const CardFactory := preload("res://tests/card_factory.gd")

var _cards: CardRegistry
var _statuses: StatusRegistry
var _relics: RelicRegistry
var _potions: PotionRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")
	_relics = RelicRegistry.load_from_dir("res://data/relics")
	_potions = PotionRegistry.load_from_dir("res://data/potions")


func _intent(move: EnemyMove, strength: int = 0) -> IntentInfo:
	var source := Factory.combatant(&"enemy", 30)
	if strength > 0:
		source.add_status(_statuses.get_status(&"strength"), strength)
	return IntentInfo.build(move, source, Factory.combatant(&"player", 80))


func test_status_tooltip_uses_title_and_description() -> void:
	var owner := Factory.combatant(&"p", 50)
	owner.add_status(_statuses.get_status(&"weak"), 2)
	var tooltip := TooltipBuilder.for_status(StatusView.build(owner, &"weak"))
	assert_eq(tooltip.title, _statuses.get_status(&"weak").display_name)
	assert_eq(tooltip.body, _statuses.get_status(&"weak").description)
	assert_eq(tooltip.entries.size(), 0)
	assert_true(tooltip.has_content())


func test_relic_tooltip_uses_title_and_description() -> void:
	var data := _relics.get_relic(&"anchor")
	var tooltip := TooltipBuilder.for_relic(RelicView.build(data))
	assert_eq(tooltip.title, data.display_name)
	assert_eq(tooltip.body, data.description)


func test_potion_tooltip_and_empty_slot() -> void:
	var belt := PotionBelt.from_ids([&"fire_potion"] as Array[StringName], _potions)
	var controller := BattleController.create_from_data(Factory.combatant(&"player", 80), Factory.fillers(10),
			[Factory.dummy_enemy()] as Array[EnemyData], _statuses, 1, null, [] as Array[RelicData], belt)
	controller.start_battle()
	var filled := TooltipBuilder.for_potion(PotionView.build(0, controller))
	assert_eq(filled.title, _potions.get_potion(&"fire_potion").display_name)
	assert_eq(filled.body, _potions.get_potion(&"fire_potion").description)
	assert_false(TooltipBuilder.for_potion(PotionView.build(1, controller)).has_content(), "ô trống: không có tooltip")


func test_card_tooltip_only_lists_keywords() -> void:
	var strike := TooltipBuilder.for_card(_cards.get_card(&"strike"), _statuses)
	assert_false(strike.has_content(), "thẻ không từ khóa: không bật tooltip")
	var bash := TooltipBuilder.for_card(_cards.get_card(&"bash"), _statuses)
	assert_true(bash.has_content())
	assert_eq(bash.title, "")
	assert_eq(bash.body, "")
	assert_eq(bash.entries.size(), 1)
	assert_eq(bash.entries[0].title, "Vulnerable")


func test_intent_tooltip_attack_single_and_multi_hit() -> void:
	assert_eq(TooltipBuilder.for_intent(_intent(Factory.attack_move(&"hit", 6))).body, "Will attack for 6 damage.")
	assert_eq(TooltipBuilder.for_intent(_intent(Factory.attack_move(&"flurry", 4, 1, 0, 3))).body,
			"Will attack for 4 damage, 3 times.")


func test_intent_tooltip_two_hits_is_already_multi_hit() -> void:
	assert_eq(TooltipBuilder.for_intent(_intent(Factory.attack_move(&"twin", 5, 1, 0, 2))).body,
			"Will attack for 5 damage, 2 times.")


func test_intent_tooltip_uses_the_damage_already_computed_with_strength() -> void:
	var tooltip := TooltipBuilder.for_intent(_intent(Factory.attack_move(&"hit", 6), 2))
	assert_eq(tooltip.body, "Will attack for 8 damage.")


func test_intent_tooltip_defend_buff_and_debuff() -> void:
	assert_eq(TooltipBuilder.for_intent(_intent(Factory.block_move(&"guard", 5))).body, "Will gain Block.")
	var buff := Factory.status_move(&"rage", &"strength", 2, EffectData.Target.SELF)
	assert_eq(TooltipBuilder.for_intent(_intent(buff)).body, "Will strengthen itself.")
	var debuff := Factory.status_move(&"curse", &"weak", 1, EffectData.Target.TARGET_ENEMY)
	assert_eq(TooltipBuilder.for_intent(_intent(debuff)).body, "Will weaken you.")


func test_intent_tooltip_combines_lines_in_a_fixed_order() -> void:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"weak"),
		Factory.damage_effect(5),
		EffectData.create(EffectData.Type.BLOCK, 4, EffectData.Target.SELF)]
	var tooltip := TooltipBuilder.for_intent(_intent(Factory.move(&"combo", effects)))
	assert_eq(tooltip.title, TooltipBuilder.INTENT_TITLE)
	assert_eq(tooltip.body, "Will attack for 5 damage.\nWill gain Block.\nWill weaken you.")


func test_intent_tooltip_with_all_four_kinds_keeps_attack_block_buff_debuff_order() -> void:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"weak"),
		EffectData.create(EffectData.Type.APPLY_STATUS, 2, EffectData.Target.SELF, 1, &"strength"),
		EffectData.create(EffectData.Type.BLOCK, 4, EffectData.Target.SELF),
		Factory.damage_effect(5)]
	var tooltip := TooltipBuilder.for_intent(_intent(Factory.move(&"all", effects)))
	assert_eq(tooltip.body, "Will attack for 5 damage.\nWill gain Block.\nWill strengthen itself.\nWill weaken you.")


func test_hidden_intent_is_unknown() -> void:
	assert_eq(TooltipBuilder.for_intent(null).body, TooltipBuilder.INTENT_UNKNOWN)


func test_null_inputs_give_null() -> void:
	assert_true(TooltipBuilder.for_status(null) == null)
	assert_true(TooltipBuilder.for_relic(null) == null)
	assert_true(TooltipBuilder.for_potion(null) == null)
	assert_true(TooltipBuilder.for_card(null, _statuses) == null)


func test_empty_tooltip_has_no_content() -> void:
	assert_false(TooltipView.new().has_content())
