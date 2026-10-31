extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target


func _block(amount: int = 3) -> EffectData:
	return EffectData.create(T.BLOCK, amount, G.SELF)


func test_valid_triggers() -> void:
	assert_eq(Factory.trigger1(E.TURN_END, _block()).validate(), [] as Array[String])
	var thorns := Factory.trigger1(E.ATTACKED, EffectData.create(T.DAMAGE, 2, G.EVENT_SOURCE), {"scale_by_stacks": true})
	assert_eq(thorns.validate(), [] as Array[String])
	var hp_lost := Factory.trigger1(E.HP_LOST, EffectData.create(T.DAMAGE, 1, G.EVENT_SOURCE))
	assert_eq(hp_lost.validate(), [] as Array[String])
	var opening := Factory.trigger1(E.BATTLE_START, EffectData.create(T.DAMAGE, 3, G.ALL_ENEMIES))
	assert_eq(opening.validate(), [] as Array[String])
	var skill_watch := Factory.trigger1(E.CARD_PLAYED, _block(),
			{"filter_card_type": true, "card_type": CardData.CardType.SKILL, "every_n": 3, "max_per_turn": 1})
	assert_eq(skill_watch.validate(), [] as Array[String])


func test_needs_effects_and_rejects_null_effect() -> void:
	var none: Array[EffectData] = []
	assert_false(Factory.trigger(E.TURN_START, none).validate().is_empty())
	var with_null: Array[EffectData] = [null]
	assert_false(Factory.trigger(E.TURN_START, with_null).validate().is_empty())


func test_target_enemy_is_not_allowed_in_triggers() -> void:
	var effect := EffectData.create(T.DAMAGE, 3, G.TARGET_ENEMY)
	assert_false(Factory.trigger1(E.TURN_START, effect).validate().is_empty())


func test_event_source_only_makes_sense_for_attacked_and_hp_lost() -> void:
	var effect := EffectData.create(T.DAMAGE, 2, G.EVENT_SOURCE)
	for bad_event: int in [E.TURN_START, E.TURN_END, E.CARD_PLAYED, E.BATTLE_START, E.BATTLE_VICTORY]:
		assert_false(Factory.trigger1(bad_event, effect).validate().is_empty(), "event %d" % bad_event)
	for good_event: int in [E.ATTACKED, E.HP_LOST]:
		assert_true(Factory.trigger1(good_event, effect).validate().is_empty(), "event %d" % good_event)


func test_negative_counters_are_invalid() -> void:
	for key in ["every_n", "max_per_turn", "max_per_battle"]:
		assert_false(Factory.trigger1(E.TURN_START, _block(), {key: -1}).validate().is_empty(), key)


func test_card_type_filter_only_with_card_played() -> void:
	assert_false(Factory.trigger1(E.TURN_START, _block(), {"filter_card_type": true}).validate().is_empty())
	assert_true(Factory.trigger1(E.CARD_PLAYED, _block(), {"filter_card_type": true}).validate().is_empty())


func test_effect_errors_are_prefixed_with_index() -> void:
	var errors := Factory.trigger1(E.TURN_START, EffectData.create(T.BLOCK, 0, G.SELF)).validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("effects[0]"))


func test_triggers_cannot_scale_with_x() -> void:
	var effect := EffectData.create(T.BLOCK, 5, G.SELF)
	effect.scales_with_x = true
	assert_false(Factory.trigger1(E.TURN_START, effect).validate().is_empty())
