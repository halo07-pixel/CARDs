extends "res://tests/test_case.gd"


func test_load_default_fills_every_registry() -> void:
	var data := GameData.load_default()
	assert_true(data.is_complete())
	assert_true(data.cards.size() >= 38)
	assert_true(data.enemies.size() >= 5)
	assert_true(data.statuses.size() >= 11)
	assert_true(data.relics.size() >= 10)
	assert_true(data.potions.size() >= 8)


func test_empty_game_data_is_not_complete() -> void:
	assert_false(GameData.new().is_complete())


func test_factory_builds_a_battle_from_game_data() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemy_ids: Array[StringName] = [&"slime", &"spiker"]
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemy_ids, data)
	assert_true(controller != null)
	assert_eq(controller.enemies.size(), 2)
	assert_eq(controller.player.max_hp, warrior.max_hp)
	assert_eq(controller.enemies[1].combatant.get_status(&"thorns"), 3, "status đầu trận được áp dụng")


func test_factory_passes_hp_seed_relics_and_potions() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemy_ids: Array[StringName] = [&"slime"]
	var relic_ids: Array[StringName] = [data.relics.all_ids()[0]]
	var potion_ids: Array[StringName] = [data.potions.all_ids()[0]]
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemy_ids, data, 7,
			relic_ids, potion_ids, 30)
	assert_eq(controller.player.hp, 30)
	assert_eq(controller.relics.size(), 1)
	assert_eq(controller.potions.count(), 1)


func test_factory_returns_null_on_bad_input() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var bad_enemy: Array[StringName] = [&"khong_ton_tai"]
	var good_enemy: Array[StringName] = [&"slime"]
	assert_true(BattleFactory.create_from_game_data(warrior, warrior.starting_deck, bad_enemy, data) == null)
	assert_true(BattleFactory.create_from_game_data(warrior, warrior.starting_deck, good_enemy, null) == null)
	assert_true(BattleFactory.create_from_game_data(null, warrior.starting_deck, good_enemy, data) == null)


func _draw_order(seed_value: int) -> Array[StringName]:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemy_ids: Array[StringName] = [&"slime"]
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemy_ids, data, seed_value)
	controller.config.draw_per_turn = 10
	controller.start_battle()
	var order: Array[StringName] = []
	for card in controller.deck.get_pile(Deck.HAND):
		order.append(card.data.id)
	return order


func test_seed_controls_the_shuffle() -> void:
	assert_eq(_draw_order(7), _draw_order(7), "cùng seed thì cùng thứ tự")
	assert_ne(_draw_order(7), _draw_order(1), "khác seed thì khác thứ tự")
