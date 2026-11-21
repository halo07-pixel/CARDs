extends "res://tests/test_case.gd"
## Trigger chạy trong trận thật: Poison, Thorns, Metallicize, Artifact, Barricade, Demon Form, Power,
## các sự kiện đầu/cuối trận, bộ lọc/bộ đếm, và các chốt an toàn (hàng đợi, vòng lặp).

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target
const P := BattleState.Phase

var _statuses: StatusRegistry


func before_each() -> void:
	_statuses = Factory.registry()


func _real(id: StringName) -> StatusData:
	return _statuses.get_status(id)


func _one(hp: int = 20, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(&"dummy", hp, damage)] as Array[EnemyData]


func _two(hp: int = 20, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(&"a", hp, damage), Factory.dummy_enemy(&"b", hp, damage)] as Array[EnemyData]


func _battle(datas: Array[EnemyData], start: bool = true, player_hp: int = 80) -> BattleController:
	var controller := Factory.battle(Factory.fillers(10), datas, 1, null, player_hp, _statuses)
	if start:
		controller.start_battle()
	return controller


func _enemy(controller: BattleController, index: int = 0) -> Combatant:
	return controller.enemies[index].combatant


func _custom(id: StringName, triggers: Array, props: Dictionary = {}) -> StatusData:
	var typed: Array[TriggerData] = []
	typed.assign(triggers)
	return Factory.status_with_triggers(id, typed, props)


func _block_effect(amount: int) -> EffectData:
	return EffectData.create(T.BLOCK, amount, G.SELF)


## --- Poison ---

func test_poison_ticks_at_the_start_of_the_enemy_turn_then_decays() -> void:
	var controller := _battle(_one())
	_enemy(controller).add_status(_real(&"poison"), 3)
	controller.end_player_turn()
	assert_eq(_enemy(controller).hp, 17)
	assert_eq(_enemy(controller).get_status(&"poison"), 2)
	assert_eq(controller.player.hp, 74, "quái vẫn đánh sau khi chịu độc")


func test_poison_can_kill_an_enemy_before_it_acts() -> void:
	var controller := _battle(_one(3))
	var rec := Recorder.new(controller)
	_enemy(controller).add_status(_real(&"poison"), 5)
	controller.end_player_turn()
	assert_false(_enemy(controller).is_alive())
	assert_eq(rec.count("acted:"), 0)
	assert_eq(controller.state.phase, P.VICTORY)
	assert_eq(rec.with_prefix("ended:"), ["ended:true"])
	assert_eq(rec.count("defeated:"), 1)
	assert_eq(controller.player.hp, 80, "quái chết trước khi kịp đánh")


func test_poison_on_the_player_ticks_at_the_start_of_the_player_turn() -> void:
	var controller := _battle(_one())
	controller.player.add_status(_real(&"poison"), 4)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 70, "6 sát thương của quái + 4 độc")
	assert_eq(controller.player.get_status(&"poison"), 3)


func test_poison_can_kill_the_player_at_the_start_of_the_turn() -> void:
	var controller := _battle(_one(20, 1), true, 5)
	var rec := Recorder.new(controller)
	controller.player.add_status(_real(&"poison"), 5)
	controller.end_player_turn()
	assert_eq(controller.state.phase, P.DEFEAT)
	assert_true(rec.has_event("state:PLAYER_START>DEFEAT"))
	assert_eq(rec.with_prefix("ended:"), ["ended:false"])
	assert_eq(controller.end_reason, BattleController.END_DEFEAT)
	assert_eq(controller.deck.count(Deck.HAND), 0, "chết trước khi rút bài")


func test_one_enemy_dying_to_poison_does_not_stop_the_others() -> void:
	var controller := _battle(_two(20, 6))
	var rec := Recorder.new(controller)
	_enemy(controller, 0).add_status(_real(&"poison"), 50)
	_enemy(controller, 0).take_damage(18)  # còn 2 máu
	controller.end_player_turn()
	assert_false(_enemy(controller, 0).is_alive())
	assert_true(rec.has_event("acted:b_1:hit"), "quái thứ hai vẫn đánh")
	assert_eq(rec.count("acted:"), 1)
	assert_eq(controller.state.phase, P.PLAYER_TURN)


## --- Metallicize / Barricade / Demon Form / Artifact ---

func test_metallicize_gives_block_at_end_of_turn_before_enemies_act() -> void:
	var controller := _battle(_one())
	controller.player.add_status(_real(&"metallicize"), 3)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 77, "3 giáp chặn 3 trong 6 sát thương")
	assert_eq(controller.player.block, 0, "giáp bị xóa ở đầu lượt kế tiếp")


func test_barricade_keeps_block_across_turns() -> void:
	var controller := _battle(_one())
	controller.player.add_status(_real(&"barricade"), 1)
	controller.player.gain_block(10)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 80)
	assert_eq(controller.player.block, 4, "10 - 6, và không bị xóa đầu lượt")


func test_demon_form_grants_strength_every_turn() -> void:
	var controller := _battle(_one(200))
	controller.player.add_status(_real(&"demon_form"), 2)
	var strengths: Array = []
	for i in 2:
		controller.end_player_turn()
		strengths.append(controller.player.get_status(&"strength"))
	assert_eq(strengths, [2, 4])
	controller.play_card(Factory.inject(controller, Factory.strike(&"s", 6)), controller.enemies[0])
	assert_eq(_enemy(controller).hp, 190, "6 + 4 Strength")


func test_enemy_demon_form_makes_its_attacks_grow() -> void:
	var controller := _battle(_one(200))
	_enemy(controller).add_status(_real(&"demon_form"), 1)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 73, "đầu lượt quái +1 Strength rồi đánh 6+1")
	controller.end_player_turn()
	assert_eq(controller.player.hp, 65, "lượt sau 6+2")


func test_artifact_blocks_the_first_debuff_only() -> void:
	var hexer: Array[EnemyData] = [Factory.enemy(&"hexer", 50,
			[Factory.status_move(&"hex", &"weak", 1, G.TARGET_ENEMY)] as Array[EnemyMove])]
	var controller := _battle(hexer)
	controller.player.add_status(_real(&"artifact"), 1)
	controller.end_player_turn()
	assert_false(controller.player.has_status(&"weak"), "Artifact chặn debuff đầu")
	assert_false(controller.player.has_status(&"artifact"), "hết stack")
	controller.end_player_turn()
	assert_eq(controller.player.get_status(&"weak"), 1, "debuff thứ hai lọt qua")


## --- Thorns (ATTACKED) ---

func test_thorns_hurt_the_attacker() -> void:
	var controller := _battle(_one())
	var rec := Recorder.new(controller)
	controller.player.add_status(_real(&"thorns"), 3)
	controller.end_player_turn()
	assert_eq(_enemy(controller).hp, 17)
	assert_eq(controller.player.hp, 74)
	assert_true(rec.has_event("triggered:player:status:thorns"))


func test_thorns_trigger_even_when_block_absorbs_everything() -> void:
	var controller := _battle(_one())
	controller.player.add_status(_real(&"thorns"), 3)
	controller.player.gain_block(20)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 80, "giáp chặn hết")
	assert_eq(_enemy(controller).hp, 17, "nhưng vẫn bị đánh nên Thorns vẫn nổ")


func test_thorns_against_thorns_cannot_loop() -> void:
	var controller := _battle(_one())
	var rec := Recorder.new(controller)
	controller.player.add_status(_real(&"thorns"), 2)
	_enemy(controller).add_status(_real(&"thorns"), 2)
	controller.end_player_turn()
	assert_eq(_enemy(controller).hp, 18, "chỉ bị Thorns của người chơi một lần")
	assert_eq(controller.player.hp, 74, "Thorns của quái không nổ vì sát thương do trigger không phải đòn tấn công")
	assert_eq(rec.count("triggered:"), 1)
	assert_false(controller.trigger_overflowed())


func test_attacking_a_thorns_enemy_hurts_the_player() -> void:
	var controller := _battle(_one())
	_enemy(controller).add_status(_real(&"thorns"), 2)
	controller.play_card(Factory.inject(controller, Factory.strike(&"s", 6)), controller.enemies[0])
	assert_eq(_enemy(controller).hp, 14)
	assert_eq(controller.player.hp, 78)


func test_each_hit_of_a_multi_hit_attack_triggers_thorns() -> void:
	var controller := _battle(_one())
	_enemy(controller).add_status(_real(&"thorns"), 2)
	var effects: Array[EffectData] = [Factory.damage_effect(5, G.TARGET_ENEMY, 2)]
	var twin := Factory.inject(controller, Factory.card_inst(&"twin", effects, CardData.TargetMode.SINGLE_ENEMY))
	controller.play_card(twin, controller.enemies[0])
	assert_eq(_enemy(controller).hp, 10)
	assert_eq(controller.player.hp, 76, "hai hit, hai lần Thorns")


func test_aoe_triggers_thorns_on_every_enemy() -> void:
	var controller := _battle(_two())
	_enemy(controller, 0).add_status(_real(&"thorns"), 2)
	_enemy(controller, 1).add_status(_real(&"thorns"), 2)
	controller.play_card(Factory.inject(controller, Factory.aoe(&"sweep", 5)))
	assert_eq(controller.player.hp, 76)
	assert_eq(_enemy(controller, 0).hp, 15)
	assert_eq(_enemy(controller, 1).hp, 15)


func test_thorns_can_kill_the_attacker_and_win_the_battle() -> void:
	var controller := _battle(_one(3))
	var rec := Recorder.new(controller)
	controller.player.add_status(_real(&"thorns"), 5)
	controller.end_player_turn()
	assert_true(rec.has_event("acted:dummy_0:hit"), "quái vẫn kịp đánh")
	assert_false(_enemy(controller).is_alive())
	assert_eq(controller.state.phase, P.VICTORY)
	assert_eq(rec.with_prefix("ended:"), ["ended:true"])
	assert_eq(controller.player.hp, 74)


## --- Power cards ---

func test_power_card_leaves_the_cycle_and_its_effect_persists() -> void:
	var cards := CardRegistry.load_from_dir("res://data/cards")
	var controller := _battle(_one(200))
	var inflame := Factory.inject(controller, cards.create_instances([&"inflame"] as Array[StringName])[0])
	var total := controller.deck.total_count()
	assert_true(controller.play_card(inflame))
	assert_eq(controller.player.get_status(&"strength"), 2)
	assert_eq(controller.deck.find_pile(inflame), Deck.EXHAUST)
	controller.end_player_turn()
	controller.end_player_turn()
	assert_eq(controller.player.get_status(&"strength"), 2, "Strength vẫn còn qua các lượt")
	assert_eq(controller.deck.find_pile(inflame), Deck.EXHAUST, "Power không quay lại tay")
	assert_eq(controller.deck.total_count(), total)


func test_metallicize_card_gives_block_each_end_of_turn() -> void:
	var cards := CardRegistry.load_from_dir("res://data/cards")
	var controller := _battle(_one())
	var card := Factory.inject(controller, cards.create_instances([&"metallicize"] as Array[StringName])[0])
	assert_true(controller.play_card(card))
	assert_eq(controller.player.get_status(&"metallicize"), 3)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 77)


## --- Sự kiện đầu/cuối trận ---

func test_battle_start_block_survives_into_turn_one() -> void:
	var controller := _battle(_one(), false)
	var anchor := _custom(&"anchor", [Factory.trigger1(E.BATTLE_START, _block_effect(5))])
	controller.player.add_status(anchor, 1)
	controller.start_battle()
	assert_eq(controller.player.block, 5, "giáp đầu trận còn nguyên ở lượt 1")
	controller.end_player_turn()
	assert_eq(controller.player.hp, 79, "5 giáp chặn 5 trong 6 sát thương")


func test_battle_victory_triggers_run_before_battle_ended_is_emitted() -> void:
	var controller := _battle(_one(6), false)
	controller.player.take_damage(30)
	var burning := _custom(&"burning", [Factory.trigger1(E.BATTLE_VICTORY, EffectData.create(T.HEAL, 6, G.SELF))])
	controller.player.add_status(burning, 1)
	var seen: Array = []
	var player := controller.player  # bắt `player` chứ KHÔNG bắt `controller`: lambda nối vào tín hiệu của controller mà bắt controller tạo vòng tham chiếu (rò rỉ)
	controller.battle_ended.connect(func(_victory: bool) -> void: seen.append(player.hp))
	controller.start_battle()
	controller.play_card(Factory.inject(controller, Factory.strike(&"finisher", 6)), controller.enemies[0])
	assert_eq(seen, [56], "người nhận battle_ended thấy máu ĐÃ được hồi")
	assert_eq(controller.player.hp, 56)


func test_battle_victory_triggers_do_not_run_on_defeat() -> void:
	var controller := _battle(_one(20, 99), false)
	var burning := _custom(&"burning", [Factory.trigger1(E.BATTLE_VICTORY, EffectData.create(T.HEAL, 6, G.SELF))])
	controller.player.add_status(burning, 1)
	var rec := Recorder.new(controller)
	controller.start_battle()
	controller.end_player_turn()
	assert_eq(controller.state.phase, P.DEFEAT)
	assert_eq(rec.count("triggered:"), 0)


func test_battle_start_triggers_run_player_first_then_enemies() -> void:
	var controller := _battle(_one(), false)
	var rec := Recorder.new(controller)
	var mark := func(key: StringName) -> StatusData:
		return _custom(key, [Factory.trigger1(E.BATTLE_START, _block_effect(1))])
	controller.player.add_status(mark.call(&"a"), 1)
	_enemy(controller).add_status(mark.call(&"b"), 1)
	controller.start_battle()
	assert_eq(rec.with_prefix("triggered:"), ["triggered:player:status:a", "triggered:dummy_0:status:b"])


func test_enemy_turn_end_trigger_leaves_block_for_the_player_turn() -> void:
	var controller := _battle(_one())
	_enemy(controller).add_status(_real(&"metallicize"), 4)
	controller.end_player_turn()
	assert_eq(_enemy(controller).block, 4)
	controller.play_card(Factory.inject(controller, Factory.strike(&"s", 6)), controller.enemies[0])
	assert_eq(_enemy(controller).hp, 18, "6 sát thương - 4 giáp")


## --- Bộ lọc và bộ đếm trong trận ---

func test_card_type_filter_reacts_only_to_the_chosen_card_type() -> void:
	var controller := _battle(_one(200))
	var watcher := _custom(&"watcher", [Factory.trigger1(E.CARD_PLAYED, _block_effect(2),
			{"filter_card_type": true, "card_type": CardData.CardType.ATTACK})])
	controller.player.add_status(watcher, 1)
	controller.play_card(Factory.inject(controller, Factory.defend(&"d", 5)))
	assert_eq(controller.player.block, 5, "thẻ kỹ năng không kích hoạt")
	controller.play_card(Factory.inject(controller, Factory.strike(&"s", 6)), controller.enemies[0])
	assert_eq(controller.player.block, 7, "thẻ tấn công cộng thêm 2")


func test_every_n_trigger_fires_on_the_third_turn() -> void:
	var controller := _battle(_one(500, 1), false)
	var flower := _custom(&"flower", [Factory.trigger1(E.TURN_START, EffectData.create(T.GAIN_ENERGY, 1, G.SELF), {"every_n": 3})])
	controller.player.add_status(flower, 1)
	controller.start_battle()
	var energies: Array = [controller.energy]
	for i in 3:
		controller.end_player_turn()
		energies.append(controller.energy)
	assert_eq(energies, [3, 3, 4, 3])


func test_requires_zero_block_trigger() -> void:
	var make := func() -> BattleController:
		var controller := _battle(_one())
		controller.player.add_status(_custom(&"orichalcum", [Factory.trigger1(E.TURN_END, _block_effect(6),
				{"requires_zero_block": true})]), 1)
		return controller
	var empty_block: BattleController = make.call()
	empty_block.end_player_turn()
	assert_eq(empty_block.player.hp, 80, "0 giáp: nhận 6 giáp, chặn hết đòn")
	var has_block: BattleController = make.call()
	has_block.player.gain_block(1)
	has_block.end_player_turn()
	assert_eq(has_block.player.hp, 75, "đã có giáp: không nổ, chỉ chặn 1")


func test_lose_hp_and_unblocked_damage_raise_hp_lost_but_fully_blocked_damage_does_not() -> void:
	var controller := _battle(_one(), true)
	var rec := Recorder.new(controller)
	var lust := _custom(&"bloodlust", [Factory.trigger1(E.HP_LOST, _block_effect(2))])
	controller.player.add_status(lust, 1)
	controller.player.gain_block(20)
	controller.end_player_turn()
	assert_eq(rec.count("triggered:"), 0, "đòn bị giáp chặn hết thì không mất máu")
	controller.player.add_status(_real(&"poison"), 3)
	controller.end_player_turn()
	assert_true(rec.count("triggered:player:status:bloodlust") >= 1, "Poison làm mất máu nên HP_LOST nổ")


## --- Chốt an toàn ---

func test_runaway_trigger_chain_is_stopped_by_the_queue_limit() -> void:
	var controller := _battle(_one(200))
	var effects: Array[EffectData] = [EffectData.create(T.HEAL, 1, G.SELF), EffectData.create(T.LOSE_HP, 1, G.SELF)]
	var feedback := _custom(&"feedback", [Factory.trigger(E.HP_LOST, effects)])
	controller.player.add_status(feedback, 1)
	var cut: Array[EffectData] = [EffectData.create(T.LOSE_HP, 3, G.SELF)]
	var cost_card := Factory.inject(controller, Factory.card_inst(&"cut", cut, CardData.TargetMode.SELF, {"cost": 0}))
	assert_true(controller.play_card(cost_card), "hành động gốc vẫn thành công")
	assert_true(controller.trigger_overflowed())
	assert_eq(controller.trigger_queue_size(), 0, "hàng đợi đã được dọn")
	assert_eq(controller.state.phase, P.PLAYER_TURN, "trận vẫn chơi tiếp được")
	assert_true(controller.player.hp > 0 and controller.player.hp <= 80)


func test_queue_is_empty_after_every_resolved_action() -> void:
	var controller := _battle(_one(200))
	controller.player.add_status(_real(&"thorns"), 2)
	controller.player.add_status(_real(&"metallicize"), 2)
	_enemy(controller).add_status(_real(&"poison"), 4)
	for i in 3:
		controller.play_card(Factory.inject(controller, Factory.strike(&"s%d" % i, 6)), controller.enemies[0])
		assert_eq(controller.trigger_queue_size(), 0)
		controller.end_player_turn()
		assert_eq(controller.trigger_queue_size(), 0)
	assert_false(controller.trigger_overflowed())
