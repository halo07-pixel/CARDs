extends "res://tests/test_case.gd"
## Status quái mang sẵn khi vào trận (EnemyData.starting_statuses) + hai quái dùng nó/Poison.

const Factory := preload("res://tests/combat_factory.gd")

var _cards: CardRegistry
var _enemies: EnemyRegistry
var _statuses: StatusRegistry
var _warrior: CharacterData


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")
	# load() trả về Resource cache dùng chung: nhân bản cho chắc (test không sửa, nhưng giữ quy ước).
	_warrior = (load("res://data/characters/warrior.tres") as CharacterData).duplicate() as CharacterData


func _enemy_with(statuses: Dictionary) -> EnemyData:
	return Factory.dummy_enemy(&"dummy", 20, 6).duplicate() as EnemyData if statuses.is_empty() \
			else _with_statuses(statuses)


func _with_statuses(statuses: Dictionary) -> EnemyData:
	var data := Factory.dummy_enemy(&"dummy", 20, 6)
	data.starting_statuses = statuses
	return data


func _battle(datas: Array[EnemyData]) -> BattleController:
	return Factory.battle(Factory.fillers(10), datas)


## --- Kiểm tra dữ liệu (validate) ---

func test_validate_accepts_positive_integer_stacks() -> void:
	assert_eq(_with_statuses({&"thorns": 3, &"strength": 1}).validate(), [] as Array[String])


func test_validate_rejects_zero_negative_and_non_integer_stacks() -> void:
	assert_eq(_with_statuses({&"thorns": 0}).validate().size(), 1, "stack = 0")
	assert_eq(_with_statuses({&"thorns": -2}).validate().size(), 1, "stack âm")
	assert_eq(_with_statuses({&"thorns": 1.5}).validate().size(), 1, "stack không phải số nguyên")


func test_validate_rejects_empty_status_id() -> void:
	assert_eq(_with_statuses({&"": 2}).validate().size(), 1)


## --- Áp dụng khi dựng trận ---

func test_starting_statuses_are_applied_with_exact_stacks() -> void:
	var controller := _battle([_with_statuses({&"thorns": 3, &"strength": 2})] as Array[EnemyData])
	var combatant := controller.enemies[0].combatant
	assert_eq(combatant.get_status(&"thorns"), 3)
	assert_eq(combatant.get_status(&"strength"), 2)


func test_no_starting_statuses_means_no_statuses() -> void:
	var controller := _battle([_enemy_with({})] as Array[EnemyData])
	assert_eq(controller.enemies[0].combatant.get_status_ids().size(), 0)


func test_statuses_apply_to_each_unit_independently() -> void:
	var data := _with_statuses({&"thorns": 3})
	var controller := _battle([data, data] as Array[EnemyData])
	controller.enemies[0].combatant.add_status(_statuses.get_status(&"thorns"), 4)
	assert_eq(controller.enemies[0].combatant.get_status(&"thorns"), 7)
	assert_eq(controller.enemies[1].combatant.get_status(&"thorns"), 3, "quái kia không bị ảnh hưởng")
	assert_eq(data.starting_statuses[&"thorns"], 3, "dữ liệu dùng chung không bị sửa")


func test_unknown_starting_status_makes_battle_creation_fail() -> void:
	var controller := _battle([_with_statuses({&"khong_ton_tai": 1})] as Array[EnemyData])
	assert_true(controller == null)


func test_starting_thorns_hurt_the_player_who_attacks() -> void:
	var controller := _battle([_with_statuses({&"thorns": 3})] as Array[EnemyData])
	controller.start_battle()
	var strike := Factory.inject(controller, Factory.strike(&"hit", 6))
	var hp_before := controller.player.hp
	assert_true(controller.play_card(strike, controller.enemies[0]))
	assert_eq(controller.player.hp, hp_before - 3, "Thorns 3 phản lại 3 sát thương")


## --- Quái dữ liệu thật ---

func test_new_enemies_are_valid_and_registered() -> void:
	for id: StringName in [&"spiker", &"toxic_slug"]:
		assert_true(_enemies.has_enemy(id), "thiếu quái %s" % id)
		assert_eq(_enemies.get_enemy(id).validate(), [] as Array[String], "quái %s không hợp lệ" % id)


func test_spiker_starts_with_thorns_and_gains_more() -> void:
	var data := _enemies.get_enemy(&"spiker")
	assert_eq(data.starting_statuses.get(&"thorns", 0), 3)
	var gains_thorns := false
	for move in data.moves:
		for effect in move.effects:
			if effect.type == EffectData.Type.APPLY_STATUS and effect.status_id == &"thorns" \
					and effect.target == EffectData.Target.SELF:
				gains_thorns = true
	assert_true(gains_thorns, "Spiker phải có chiêu tự tăng Thorns")


func _real_battle(enemy_id: StringName) -> BattleController:
	var ids: Array[StringName] = [enemy_id]
	var player := BattleFactory.create_player(_warrior)
	return BattleFactory.create(_warrior, player, _warrior.starting_deck, ids, _cards, _enemies, _statuses)


func test_spiker_battle_has_thorns_on_the_unit() -> void:
	var controller := _real_battle(&"spiker")
	assert_true(controller != null)
	assert_eq(controller.enemies[0].combatant.get_status(&"thorns"), 3)


func test_toxic_slug_opens_with_spit_and_poisons_the_player() -> void:
	var controller := _real_battle(&"toxic_slug")
	controller.start_battle()
	assert_eq(String(controller.enemies[0].current_move.id), "spit", "chiêu mở màn")
	assert_eq(controller.player.get_status(&"poison"), 0, "chưa bị độc trước khi quái ra đòn")
	assert_true(controller.end_player_turn())
	assert_true(controller.player.has_status(&"poison"), "sau Spit người chơi phải bị Poison")
