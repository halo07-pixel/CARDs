extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _warrior: CharacterData
var _cards: CardRegistry
var _enemies: EnemyRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_warrior = load("res://data/characters/warrior.tres") as CharacterData
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _sim(deck_ids: Array[StringName] = []) -> BattleSimulator:
	return BattleSimulator.new(_warrior, _cards, _enemies, _statuses, deck_ids)


func _ids(values: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(values)
	return ids


func test_stats_are_consistent_and_clean() -> void:
	var stats := _sim().run_scenario("slime", _ids([&"slime"]), BattleSimulator.BOT_GREEDY, 40, 1)
	assert_eq(stats.battles, 40)
	assert_eq(stats.wins + stats.defeats + stats.turn_caps, stats.battles)
	assert_eq(stats.violations, [] as Array[String])
	assert_true(stats.win_rate() >= 0.0 and stats.win_rate() <= 1.0)
	assert_true(stats.avg_turns() >= 1.0)
	assert_true(stats.avg_hp_lost() >= 0.0)


func test_same_seed_reproduces_exactly_and_other_seed_differs() -> void:
	var enemy_ids := _ids([&"slime", &"goblin"])
	var a := _sim().run_scenario("x", enemy_ids, BattleSimulator.BOT_RANDOM, 30, 7)
	var b := _sim().run_scenario("x", enemy_ids, BattleSimulator.BOT_RANDOM, 30, 7)
	var c := _sim().run_scenario("x", enemy_ids, BattleSimulator.BOT_RANDOM, 30, 9000)
	assert_eq([a.wins, a.total_turns, a.total_hp_lost], [b.wins, b.total_turns, b.total_hp_lost])
	assert_ne([a.total_turns, a.total_hp_lost], [c.total_turns, c.total_hp_lost])


func test_greedy_clearly_outplays_random_against_a_group() -> void:
	var trio := _ids([&"slime", &"goblin", &"acolyte"])
	var greedy := _sim().run_scenario("trio", trio, BattleSimulator.BOT_GREEDY, 30, 1)
	var random := _sim().run_scenario("trio", trio, BattleSimulator.BOT_RANDOM, 30, 1)
	assert_true(greedy.win_rate() >= 0.9, "greedy thắng %.0f%%" % (greedy.win_rate() * 100))
	assert_true(random.win_rate() <= 0.5, "random thắng %.0f%%" % (random.win_rate() * 100))
	assert_true(greedy.win_rate() > random.win_rate())


func test_unknown_enemy_is_reported_as_violation_not_a_crash() -> void:
	var stats := _sim().run_scenario("ghost", _ids([&"dragon"]), BattleSimulator.BOT_GREEDY, 3, 1)
	assert_eq(stats.battles, 0)
	assert_eq(stats.violations.size(), 3)


func test_unknown_bot_kind_returns_null() -> void:
	assert_true(BattleSimulator.make_bot(&"telepath", Factory.rng()) == null)


func test_stalled_battles_end_by_turn_cap() -> void:
	var sim := _sim(_ids([&"defend", &"defend", &"defend", &"defend", &"defend"]))
	sim.turn_cap = 6
	var stats := sim.run_scenario("stall", _ids([&"goblin"]), BattleSimulator.BOT_GREEDY, 5, 1)
	assert_eq(stats.turn_caps, 5, "chỉ phòng thủ nên không bao giờ thắng, phải dừng vì turn_cap")
	assert_eq(stats.wins, 0)
	assert_eq(stats.violations, [] as Array[String])


func test_every_new_card_in_one_deck_never_breaks_invariants() -> void:
	var deck := _ids([&"strike", &"strike", &"defend", &"defend", &"bash", &"bash", &"cleave", &"cleave",
			&"iron_wave", &"iron_wave", &"pommel_strike", &"pommel_strike", &"shrug_it_off", &"shrug_it_off",
			&"twin_strike", &"twin_strike", &"adrenaline", &"adrenaline", &"thunderclap", &"thunderclap"])
	var groups := [[&"slime"], [&"goblin", &"slime"], [&"slime", &"goblin", &"acolyte"]]
	for bot_kind in [BattleSimulator.BOT_GREEDY, BattleSimulator.BOT_RANDOM]:
		for group: Array in groups:
			var stats := _sim(deck).run_scenario("all", _ids(group), bot_kind, 40, 11)
			assert_eq(stats.violations, [] as Array[String], "%s %s" % [bot_kind, group])
			assert_eq(stats.battles, 40)


func test_running_many_battles_does_not_leak_objects() -> void:
	var sim := _sim()
	var enemy_ids := _ids([&"slime", &"goblin"])
	sim.run_scenario("warmup", enemy_ids, BattleSimulator.BOT_GREEDY, 20, 1)
	var before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	sim.run_scenario("measure", enemy_ids, BattleSimulator.BOT_RANDOM, 150, 500)
	var growth := int(Performance.get_monitor(Performance.OBJECT_COUNT)) - before
	assert_true(growth <= 20, "số đối tượng tăng %d sau 150 trận (nghi vòng tham chiếu)" % growth)


func test_stats_helpers() -> void:
	var stats := ScenarioStats.new()
	assert_almost_eq(stats.win_rate(), 0.0)
	stats.scenario = "demo"
	stats.bot = &"greedy"
	stats.record(BattleController.END_VICTORY, 4, 10)
	stats.record(BattleController.END_DEFEAT, 8, 80)
	stats.record(BattleController.END_TURN_CAP, 60, 0)
	assert_eq([stats.battles, stats.wins, stats.defeats, stats.turn_caps], [3, 1, 1, 1])
	assert_almost_eq(stats.win_rate(), 1.0 / 3.0, 0.001)
	assert_almost_eq(stats.avg_turns(), 24.0)
	assert_almost_eq(stats.avg_hp_lost(), 30.0)
	assert_true(stats.summary_line().contains("demo"))


func test_all_relics_never_break_invariants_and_make_the_player_sturdier() -> void:
	var relics := RelicRegistry.load_from_dir("res://data/relics")
	var trio := _ids([&"slime", &"goblin", &"acolyte"])
	var plain := _sim().run_scenario("trio", trio, BattleSimulator.BOT_GREEDY, 60, 3)
	var sim := _sim()
	sim.relics = relics
	sim.relic_ids = relics.all_ids()
	var geared := sim.run_scenario("trio", trio, BattleSimulator.BOT_GREEDY, 60, 3)
	assert_eq(geared.violations, [] as Array[String])
	assert_true(geared.avg_hp_lost() < plain.avg_hp_lost(),
			"mang relic phải mất ít máu hơn (%.1f so với %.1f)" % [geared.avg_hp_lost(), plain.avg_hp_lost()])
	for bot_kind in [BattleSimulator.BOT_GREEDY, BattleSimulator.BOT_RANDOM]:
		for group: Array in [[&"slime"], [&"goblin", &"slime"], [&"slime", &"goblin", &"acolyte"]]:
			var stats := sim.run_scenario("relics", _ids(group), bot_kind, 30, 21)
			assert_eq(stats.violations, [] as Array[String], "%s %s" % [bot_kind, group])


func _potion_sim() -> BattleSimulator:
	var sim := _sim()
	sim.potions = PotionRegistry.load_from_dir("res://data/potions")
	sim.potion_count = 3
	return sim


func test_potions_are_used_never_break_invariants_and_help_a_weak_player() -> void:
	var trio := _ids([&"slime", &"goblin", &"acolyte"])
	var plain := _sim().run_scenario("trio", trio, BattleSimulator.BOT_RANDOM, 60, 3)
	var stocked := _potion_sim().run_scenario("trio", trio, BattleSimulator.BOT_RANDOM, 60, 3)
	assert_eq(stocked.violations, [] as Array[String])
	assert_true(stocked.avg_potions_used() > 0.5, "bot ngẫu nhiên phải dùng potion (%.2f)" % stocked.avg_potions_used())
	assert_eq(plain.total_potions_used, 0)
	assert_true(stocked.win_rate() > plain.win_rate(),
			"có potion thắng nhiều hơn (%.2f so với %.2f)" % [stocked.win_rate(), plain.win_rate()])


func test_potion_runs_are_reproducible_and_potions_per_battle_are_distinct() -> void:
	var trio := _ids([&"slime", &"goblin", &"acolyte"])
	var a := _potion_sim().run_scenario("x", trio, BattleSimulator.BOT_RANDOM, 30, 9)
	var b := _potion_sim().run_scenario("x", trio, BattleSimulator.BOT_RANDOM, 30, 9)
	assert_eq([a.wins, a.total_turns, a.total_hp_lost, a.total_potions_used],
			[b.wins, b.total_turns, b.total_hp_lost, b.total_potions_used])
	var sim := _potion_sim()
	var picked := sim._roll_potions(5)
	assert_eq(picked.size(), 3)
	var unique := {}
	for id in picked:
		unique[id] = true
	assert_eq(unique.size(), 3, "3 potion khác nhau")
	assert_eq(picked, sim._roll_potions(5), "cùng seed cùng bộ potion")


func test_asking_for_more_potions_than_exist_is_clamped_and_zero_means_none() -> void:
	var sim := _potion_sim()
	sim.potion_count = 99
	assert_eq(sim._roll_potions(1).size(), sim.potions.size())
	sim.potion_count = 0
	assert_eq(sim._roll_potions(1).size(), 0)
	var none := _sim()
	none.potion_count = 3
	assert_eq(none._roll_potions(1).size(), 0, "thiếu registry thì không có potion")


func test_everything_enabled_at_once_never_breaks_invariants() -> void:
	var relics := RelicRegistry.load_from_dir("res://data/relics")
	var sim := _potion_sim()
	sim.relics = relics
	sim.relic_ids = relics.all_ids()
	var deck: Array[StringName] = []
	for id in _cards.all_ids():
		if not _cards.get_card(id).is_upgrade():
			deck.append(id)
	var full := BattleSimulator.new(_warrior, _cards, _enemies, _statuses, deck)
	full.relics = relics
	full.relic_ids = relics.all_ids()
	full.potions = sim.potions
	full.potion_count = 3
	for bot_kind in [BattleSimulator.BOT_GREEDY, BattleSimulator.BOT_RANDOM]:
		for group: Array in [[&"slime"], [&"goblin", &"slime"], [&"slime", &"goblin", &"acolyte"]]:
			var stats := full.run_scenario("everything", _ids(group), bot_kind, 25, 77)
			assert_eq(stats.violations, [] as Array[String], "%s %s" % [bot_kind, group])
