extends "res://tests/test_case.gd"
## Thẻ X-cost: tiêu hết năng lượng, các effect scales_with_x lặp X (+ x_bonus) lần.

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")
const T := EffectData.Type
const G := EffectData.Target

var _cards: CardRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_statuses = Factory.registry()


func _real(id: StringName) -> CardInstance:
	return _cards.create_instances([id] as Array[StringName])[0]


func _battle(hps: Array, damage: int = 1) -> BattleController:
	var datas: Array[EnemyData] = []
	for i in hps.size():
		datas.append(Factory.dummy_enemy(StringName("e%d" % i), hps[i], damage))
	var controller := Factory.battle(Factory.fillers(10), datas, 1, null, 80, _statuses)
	controller.start_battle()
	return controller


func _hp(controller: BattleController, index: int = 0) -> int:
	return controller.enemies[index].combatant.hp


func _scaling(effect: EffectData) -> EffectData:
	effect.scales_with_x = true
	return effect


func test_whirlwind_repeats_its_damage_once_per_energy_spent() -> void:
	var controller := _battle([100, 100])
	var whirlwind := Factory.inject(controller, _real(&"whirlwind"))
	assert_true(controller.play_card(whirlwind))
	assert_eq(_hp(controller, 0), 85, "3 lần x 5")
	assert_eq(_hp(controller, 1), 85)
	assert_eq(controller.energy, 0)
	assert_eq(controller.deck.find_pile(whirlwind), Deck.DISCARD)


func test_x_equals_the_energy_you_have_not_the_card_cost() -> void:
	var controller := _battle([100])
	controller.play_card(Factory.inject(controller, Factory.strike(&"s1", 6)), controller.enemies[0])  # còn 2 năng lượng
	controller.play_card(Factory.inject(controller, _real(&"whirlwind")))
	assert_eq(_hp(controller), 100 - 6 - 10, "X = 2 -> 2 lần x 5")


func test_x_cost_with_zero_energy_is_playable_but_does_nothing() -> void:
	var controller := _battle([100])
	var rec := Recorder.new(controller)
	for i in 3:
		controller.play_card(Factory.inject(controller, Factory.strike(&"s%d" % i, 6)), controller.enemies[0])
	assert_eq(controller.energy, 0)
	var hp_before := _hp(controller)
	var whirlwind := Factory.inject(controller, _real(&"whirlwind"))
	assert_true(controller.play_card(whirlwind), "chơi được với 0 năng lượng")
	assert_eq(_hp(controller), hp_before, "X = 0 nên không có gì xảy ra")
	assert_eq(controller.deck.find_pile(whirlwind), Deck.DISCARD)
	assert_true(rec.has_event("played:whirlwind"))
	assert_eq(rec.count("rejected:"), 0)


func test_skewer_hits_a_single_target_x_times_and_stops_when_it_dies() -> void:
	var controller := _battle([100, 100])
	assert_true(controller.play_card(Factory.inject(controller, _real(&"skewer")), controller.enemies[0]))
	assert_eq(_hp(controller, 0), 79, "3 lần x 7")
	assert_eq(_hp(controller, 1), 100)
	var finisher := _battle([10, 100])
	var rec := Recorder.new(finisher)
	assert_true(finisher.play_card(Factory.inject(finisher, _real(&"skewer")), finisher.enemies[0]))
	assert_eq(_hp(finisher, 0), 0)
	assert_eq(_hp(finisher, 1), 100, "lần lặp thừa không chuyển sang quái khác")
	assert_eq(rec.count("defeated:"), 1)
	assert_eq(finisher.state.phase, BattleState.Phase.PLAYER_TURN)


func test_upgraded_x_cards_hit_harder_per_repetition() -> void:
	var controller := _battle([100])
	controller.play_card(Factory.inject(controller, _real(&"skewer+")), controller.enemies[0])
	assert_eq(_hp(controller), 70, "3 lần x 10")


func test_x_bonus_adds_extra_repetitions() -> void:
	var controller := _battle([100])
	var effects: Array[EffectData] = [_scaling(EffectData.create(T.DAMAGE, 4, G.TARGET_ENEMY))]
	var card := Factory.card_inst(&"plus_one", effects, CardData.TargetMode.SINGLE_ENEMY,
			{"is_x_cost": true, "cost": 0, "x_bonus": 1})
	controller.play_card(Factory.inject(controller, card), controller.enemies[0])
	assert_eq(_hp(controller), 100 - 4 * 4, "X = 3 và x_bonus = 1 -> 4 lần")


func test_only_effects_flagged_as_scaling_repeat() -> void:
	var controller := _battle([100])
	var effects: Array[EffectData] = [
		_scaling(EffectData.create(T.DAMAGE, 4, G.TARGET_ENEMY)),
		EffectData.create(T.BLOCK, 5, G.SELF),
	]
	var card := Factory.card_inst(&"mixed", effects, CardData.TargetMode.SINGLE_ENEMY, {"is_x_cost": true, "cost": 0})
	controller.play_card(Factory.inject(controller, card), controller.enemies[0])
	assert_eq(_hp(controller), 88, "sát thương lặp 3 lần")
	assert_eq(controller.player.block, 5, "giáp chỉ một lần")


func test_every_repetition_is_a_real_attack_for_thorns() -> void:
	var controller := _battle([100])
	controller.enemies[0].combatant.add_status(_statuses.get_status(&"thorns"), 2)
	controller.play_card(Factory.inject(controller, _real(&"skewer")), controller.enemies[0])
	assert_eq(controller.player.hp, 74, "3 lần đánh -> 3 lần Thorns x 2")


func test_energy_is_spent_in_one_step() -> void:
	var controller := _battle([100])
	var rec := Recorder.new(controller)
	controller.play_card(Factory.inject(controller, _real(&"whirlwind")))
	assert_eq(rec.with_prefix("energy:"), ["energy:3>0"])
