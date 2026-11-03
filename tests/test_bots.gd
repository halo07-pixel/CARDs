extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")


func _config(energy: int = 3) -> BattleConfig:
	var config := BattleConfig.new()
	config.max_energy = energy
	return config


func _started(cards: Array[CardInstance], datas: Array[EnemyData], config: BattleConfig = null,
		seed_value: int = 1, hp: int = 80) -> BattleController:
	var controller := Factory.battle(cards, datas, seed_value, config, hp)
	controller.start_battle()
	return controller


func _dummy(id: StringName = &"dummy", hp: int = 100, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(id, hp, damage)] as Array[EnemyData]


## --- RandomBot ---

func test_random_bot_only_makes_legal_moves_and_battles_finish() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	for battle_index in 30:
		var cards: Array[CardInstance] = Factory.fillers(6)
		cards.append(Factory.defend(&"d1"))
		cards.append(Factory.draw_card(&"dr1"))
		cards.append(Factory.aoe(&"a1"))
		var datas: Array[EnemyData] = [registry.get_enemy(&"slime"), registry.get_enemy(&"goblin")]
		var config := _config()
		config.turn_cap = 40
		var controller := _started(cards, datas, config, battle_index + 1)
		var rec := Recorder.new(controller)
		var rng := Factory.rng(battle_index + 100)
		var bot := RandomBot.new(rng)
		var steps := 0
		while not controller.state.is_terminal() and steps < 500:
			steps += 1
			bot.act(controller)
		assert_true(controller.state.is_terminal(), "trận %d phải kết thúc" % battle_index)
		assert_eq(rec.count("rejected:"), 0, "RandomBot chỉ được chơi hành động hợp lệ (trận %d)" % battle_index)
		if not failures.is_empty():
			return


func _bot_log(kind: StringName, bot_seed: int) -> Array:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 60, 4), Factory.dummy_enemy(&"b", 60, 5)]
	var controller := _started(Factory.fillers(12), datas, _config(), 5)
	var rec := Recorder.new(controller)
	var bot := BattleSimulator.make_bot(kind, Factory.rng(bot_seed))
	for i in 25:
		if controller.state.is_terminal():
			break
		bot.act(controller)
	return rec.events


func test_random_bot_is_deterministic_per_seed_and_varies_between_seeds() -> void:
	assert_eq(_bot_log(BattleSimulator.BOT_RANDOM, 9), _bot_log(BattleSimulator.BOT_RANDOM, 9))
	assert_ne(_bot_log(BattleSimulator.BOT_RANDOM, 9), _bot_log(BattleSimulator.BOT_RANDOM, 10))


func test_greedy_bot_is_deterministic() -> void:
	assert_eq(_bot_log(BattleSimulator.BOT_GREEDY, 1), _bot_log(BattleSimulator.BOT_GREEDY, 2),
			"GreedyBot không dùng RNG nên kết quả không phụ thuộc seed của bot")


## --- GreedyBot ---

func test_greedy_takes_lethal_and_wins() -> void:
	var controller := _started(Factory.fillers(10), _dummy(&"weak", 6))
	GreedyBot.new().act(controller)
	assert_eq(controller.state.phase, BattleState.Phase.VICTORY)


func test_greedy_kills_the_killable_enemy_first() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"tank", 50), Factory.dummy_enemy(&"weak", 6)]
	var controller := _started(Factory.fillers(10), datas)
	GreedyBot.new().act(controller)
	assert_false(controller.enemies[1].is_alive(), "ưu tiên hạ con đang hạ được")
	assert_true(controller.enemies[0].is_alive())


func test_greedy_blocks_when_big_damage_is_coming_and_attack_is_weak() -> void:
	var cards: Array[CardInstance] = [Factory.defend(&"d", 8), Factory.strike(&"s", 2)]
	var controller := _started(cards, _dummy(&"brute", 100, 20), _config(1))
	GreedyBot.new().act(controller)
	assert_eq(controller.player.block, 8)


func test_greedy_attacks_instead_of_wasting_block_when_nothing_is_coming() -> void:
	var guard_only: Array[EnemyMove] = [Factory.block_move(&"guard", 5)]
	var datas: Array[EnemyData] = [Factory.enemy(&"turtle", 100, guard_only)]
	var cards: Array[CardInstance] = [Factory.defend(&"d", 8), Factory.strike(&"s", 6)]
	var controller := _started(cards, datas, _config(1))
	GreedyBot.new().act(controller)
	assert_eq(controller.player.block, 0)
	assert_eq(controller.enemies[0].combatant.hp, 94)


func test_greedy_ends_the_turn_when_nothing_is_playable() -> void:
	var cards: Array[CardInstance] = [Factory.strike(&"too_expensive", 6, {"cost": 4})]
	var controller := _started(cards, _dummy())
	GreedyBot.new().act(controller)
	assert_eq(controller.turn, 2)


func test_greedy_plays_free_energy_before_spending() -> void:
	var cards: Array[CardInstance] = [Factory.strike(&"s", 6), Factory.energy_card(&"surge", 2)]
	var controller := _started(cards, _dummy())
	var rec := Recorder.new(controller)
	GreedyBot.new().act(controller)
	assert_eq(rec.with_prefix("played:")[0], "played:surge")


func test_greedy_prefers_aoe_against_a_group() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 60), Factory.dummy_enemy(&"b", 60),
			Factory.dummy_enemy(&"c", 60)]
	var cards: Array[CardInstance] = [Factory.strike(&"s", 6), Factory.aoe(&"sweep", 5)]
	var controller := _started(cards, datas)
	var rec := Recorder.new(controller)
	GreedyBot.new().act(controller)
	assert_eq(rec.with_prefix("played:")[0], "played:sweep")


func test_greedy_targets_the_vulnerable_enemy_for_more_damage() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 60), Factory.dummy_enemy(&"b", 60)]
	var cards: Array[CardInstance] = [Factory.strike(&"s", 6)]
	var controller := _started(cards, datas, _config(1))
	controller.enemies[1].combatant.add_status(Factory.vulnerable(), 2)
	GreedyBot.new().act(controller)
	assert_eq(controller.enemies[1].combatant.hp, 51, "6 x 1.5 = 9 lên con đang Vulnerable")
	assert_eq(controller.enemies[0].combatant.hp, 60)


func test_greedy_never_plays_a_card_that_would_kill_the_player() -> void:
	var cards := CardRegistry.load_from_dir("res://data/cards").create_instances([&"bloodletting"] as Array[StringName])
	var controller := _started(cards, _dummy(&"dummy", 100, 1), null, 1, 3)
	var rec := Recorder.new(controller)
	GreedyBot.new().act(controller)
	assert_eq(rec.count("played:"), 0, "ở 3 máu, Bloodletting là tự sát")
	assert_true(controller.player.is_alive())
	assert_eq(controller.turn, 2, "thay vào đó bot kết thúc lượt")


## --- Potion ---

func _with_potions(cards: Array[CardInstance], datas: Array[EnemyData], potion_ids: Array, hp: int = 80) -> BattleController:
	var registry := PotionRegistry.load_from_dir("res://data/potions")
	var ids: Array[StringName] = []
	ids.assign(potion_ids)
	var controller := BattleController.create_from_data(Factory.combatant(&"player", hp), cards, datas,
			Factory.registry(), 1, null, [] as Array[RelicData], PotionBelt.from_ids(ids, registry))
	controller.start_battle()
	return controller


func test_greedy_uses_a_potion_that_wins_the_battle() -> void:
	var controller := _with_potions(Factory.fillers(10), _dummy(&"dummy", 20, 6), [&"fire_potion"])
	GreedyBot.new().act(controller)
	assert_eq(controller.state.phase, BattleState.Phase.VICTORY, "Fire Potion 20 sát thương hạ quái 20 máu")
	assert_eq(controller.potions.count(), 0)


func test_greedy_drinks_a_defensive_potion_when_in_danger() -> void:
	var controller := _with_potions(Factory.fillers(10), _dummy(&"brute", 500, 50), [&"block_potion"], 60)
	GreedyBot.new().act(controller)
	assert_eq(controller.player.block, 12)
	assert_eq(controller.potions.count(), 0)


func test_greedy_saves_its_potions_when_it_is_safe() -> void:
	var controller := _with_potions(Factory.fillers(10), _dummy(&"tank", 500, 1), [&"fire_potion", &"block_potion"])
	var rec := Recorder.new(controller)
	for i in 3:
		GreedyBot.new().act(controller)
	assert_eq(rec.count("potion:"), 0)
	assert_eq(controller.potions.count(), 2)


func test_random_bot_uses_potions_legally() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var used := 0
	for battle_index in 20:
		var datas: Array[EnemyData] = [registry.get_enemy(&"slime"), registry.get_enemy(&"goblin")]
		var config := _config()
		config.turn_cap = 40
		var controller := _with_potions(Factory.fillers(10), datas, [&"fire_potion", &"block_potion", &"weak_potion"])
		var rec := Recorder.new(controller)
		var bot := RandomBot.new(Factory.rng(battle_index + 7))
		var steps := 0
		while not controller.state.is_terminal() and steps < 400:
			steps += 1
			bot.act(controller)
		assert_eq(rec.count("rejected:"), 0, "RandomBot chỉ dùng potion hợp lệ (trận %d)" % battle_index)
		used += rec.count("potion:")
	assert_true(used > 0, "RandomBot phải thực sự dùng potion")
