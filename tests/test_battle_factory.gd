extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _warrior: CharacterData
var _cards: CardRegistry
var _enemies: EnemyRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	# load() trả về Resource được cache dùng chung: nhân bản để test sửa chỉ số không rò sang test khác.
	_warrior = (load("res://data/characters/warrior.tres") as CharacterData).duplicate() as CharacterData
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _create(enemy_ids: Array[StringName], player_hp: int = -1, seed_value: int = 1,
		turn_cap: int = 0) -> BattleController:
	var player := BattleFactory.create_player(_warrior, player_hp)
	return BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids,
			_cards, _enemies, _statuses, seed_value, turn_cap)


func test_create_player_defaults_to_full_hp_and_clamps() -> void:
	assert_eq(BattleFactory.create_player(_warrior).hp, 80)
	assert_eq(BattleFactory.create_player(_warrior, 50).hp, 50)
	assert_eq(BattleFactory.create_player(_warrior, 999).hp, 80, "không vượt máu tối đa")
	assert_eq(BattleFactory.create_player(_warrior, 50).max_hp, 80)


func test_creates_a_playable_battle_from_data() -> void:
	var controller := _create([&"slime", &"goblin"] as Array[StringName])
	assert_true(controller != null)
	assert_eq(controller.enemies.size(), 2)
	assert_eq(controller.deck.total_count(), 10)
	assert_true(controller.start_battle())
	assert_eq(controller.energy, 3)
	assert_eq(controller.deck.count(Deck.HAND), 5)
	assert_eq(controller.player.hp, 80)


func test_current_hp_carries_into_the_battle() -> void:
	var controller := _create([&"slime"] as Array[StringName], 33)
	assert_eq(controller.player.hp, 33)


func test_character_stats_drive_the_battle_config() -> void:
	_warrior.max_energy = 4
	_warrior.draw_per_turn = 7
	var controller := _create([&"slime"] as Array[StringName])
	controller.start_battle()
	assert_eq(controller.energy, 4)
	assert_eq(controller.deck.count(Deck.HAND), 7)


func test_turn_cap_is_passed_through() -> void:
	var controller := _create([&"slime"] as Array[StringName], -1, 1, 9)
	assert_eq(controller.config.turn_cap, 9)


func test_unknown_enemy_or_card_or_missing_registry_returns_null() -> void:
	var player := BattleFactory.create_player(_warrior)
	var enemy_ids: Array[StringName] = [&"slime"]
	assert_true(_create([&"dragon"] as Array[StringName]) == null, "quái không tồn tại")
	var bad_deck: Array[StringName] = [&"strike", &"ghost_card"]
	assert_true(BattleFactory.create(_warrior, player, bad_deck, enemy_ids, _cards, _enemies, _statuses) == null,
			"thẻ không tồn tại")
	var empty_deck: Array[StringName] = []
	assert_true(BattleFactory.create(_warrior, player, empty_deck, enemy_ids, _cards, _enemies, _statuses) == null,
			"bộ bài rỗng")
	assert_true(BattleFactory.create(null, player, _warrior.starting_deck, enemy_ids, _cards, _enemies, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, null, _warrior.starting_deck, enemy_ids, _cards, _enemies, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, null, _enemies, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, _cards, null, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, _cards, _enemies, null) == null)


func test_dead_player_cannot_start_a_battle() -> void:
	assert_true(_create([&"slime"] as Array[StringName], 0) == null)


func test_same_seed_gives_same_opening_hand() -> void:
	var first := _create([&"slime"] as Array[StringName], -1, 42)
	var second := _create([&"slime"] as Array[StringName], -1, 42)
	first.start_battle()
	second.start_battle()
	var a: Array = []
	var b: Array = []
	for card in first.deck.get_pile(Deck.HAND):
		a.append(String(card.data.id))
	for card in second.deck.get_pile(Deck.HAND):
		b.append(String(card.data.id))
	assert_eq(a, b)


func test_relic_static_bonuses_change_the_battle_config() -> void:
	var relics := RelicRegistry.load_from_dir("res://data/relics")
	var player := BattleFactory.create_player(_warrior)
	var relic_ids: Array[StringName] = [&"energy_crystal", &"wide_lens"]
	var controller := BattleFactory.create(_warrior, player, _warrior.starting_deck,
			[&"slime"] as Array[StringName], _cards, _enemies, _statuses, 1, 0, relic_ids, relics)
	assert_eq(controller.config.max_energy, 4)
	assert_eq(controller.config.draw_per_turn, 6)
	controller.start_battle()
	assert_eq(controller.energy, 4)
	assert_eq(controller.deck.count(Deck.HAND), 6)
	assert_eq(controller.relics.size(), 2)


func test_relics_do_not_change_the_character_resource_itself() -> void:
	var relics := RelicRegistry.load_from_dir("res://data/relics")
	var relic_ids: Array[StringName] = [&"energy_crystal"]
	BattleFactory.create(_warrior, BattleFactory.create_player(_warrior), _warrior.starting_deck,
			[&"slime"] as Array[StringName], _cards, _enemies, _statuses, 1, 0, relic_ids, relics)
	assert_eq(_warrior.max_energy, 3, "bonus chỉ áp vào cấu hình trận, không sửa dữ liệu nhân vật")


func test_unknown_relic_or_missing_registry_returns_null() -> void:
	var relics := RelicRegistry.load_from_dir("res://data/relics")
	var player := BattleFactory.create_player(_warrior)
	var enemy_ids: Array[StringName] = [&"slime"]
	var ghost: Array[StringName] = [&"ghost_relic"]
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, _cards, _enemies,
			_statuses, 1, 0, ghost, relics) == null, "relic không tồn tại")
	var real: Array[StringName] = [&"anchor"]
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, _cards, _enemies,
			_statuses, 1, 0, real, null) == null, "có relic_ids nhưng thiếu registry")


func test_no_relics_means_no_change() -> void:
	var controller := _create([&"slime"] as Array[StringName])
	assert_eq(controller.relics.size(), 0)
	assert_eq(controller.config.max_energy, 3)


func _create_with_potions(potion_ids: Array, registry: PotionRegistry, slots: int = 3) -> BattleController:
	var ids: Array[StringName] = []
	ids.assign(potion_ids)
	return BattleFactory.create(_warrior, BattleFactory.create_player(_warrior), _warrior.starting_deck,
			[&"slime"] as Array[StringName], _cards, _enemies, _statuses, 1, 0,
			[] as Array[StringName], null, ids, registry, slots)


func test_potion_ids_fill_the_belt_in_order() -> void:
	var potions := PotionRegistry.load_from_dir("res://data/potions")
	var controller := _create_with_potions([&"fire_potion", &"swift_potion"], potions)
	assert_eq(controller.potions.to_ids(), [&"fire_potion", &"swift_potion"] as Array[StringName])
	assert_eq(controller.potions.capacity, 3)


func test_unknown_potion_overflow_or_missing_registry_returns_null() -> void:
	var potions := PotionRegistry.load_from_dir("res://data/potions")
	assert_true(_create_with_potions([&"ghost_potion"], potions) == null, "potion không tồn tại")
	assert_true(_create_with_potions([&"fire_potion", &"block_potion", &"swift_potion", &"weak_potion"], potions) == null,
			"nhiều hơn số ô")
	assert_true(_create_with_potions([&"fire_potion"], null) == null, "thiếu registry")


func test_slot_count_is_configurable() -> void:
	var potions := PotionRegistry.load_from_dir("res://data/potions")
	var four := [&"fire_potion", &"block_potion", &"swift_potion", &"weak_potion"]
	assert_eq(_create_with_potions(four, potions, 4).potions.count(), 4)
	assert_eq(_create_with_potions([], potions, 5).potions.capacity, 5, "không có potion vẫn có dây rỗng đủ ô")
