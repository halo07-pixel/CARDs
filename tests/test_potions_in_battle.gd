extends "res://tests/test_case.gd"
## Potion (đọc từ data/potions/*.tres thật) dùng trong trận thật qua BattleController.use_potion.

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target
const P := BattleState.Phase

var _potions: PotionRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_potions = PotionRegistry.load_from_dir("res://data/potions")
	_statuses = Factory.registry()


func _one(hp: int = 20, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(&"dummy", hp, damage)] as Array[EnemyData]


func _two(hp: int = 20, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(&"a", hp, damage), Factory.dummy_enemy(&"b", hp, damage)] as Array[EnemyData]


func _battle(potion_ids: Array, datas: Array[EnemyData], start: bool = true) -> BattleController:
	var ids: Array[StringName] = []
	ids.assign(potion_ids)
	var controller := BattleController.create_from_data(Factory.combatant(&"player", 80), Factory.fillers(10),
			datas, _statuses, 1, null, [] as Array[RelicData], PotionBelt.from_ids(ids, _potions))
	if start:
		controller.start_battle()
	return controller


func _enemy_hp(controller: BattleController, index: int = 0) -> int:
	return controller.enemies[index].combatant.hp


## --- Hiệu ứng từng potion ---

func test_fire_potion_hits_one_enemy_costs_no_energy_and_is_consumed() -> void:
	var controller := _battle([&"fire_potion"], _two(40))
	var rec := Recorder.new(controller)
	assert_true(controller.use_potion(0, controller.enemies[1]))
	assert_eq(_enemy_hp(controller, 1), 20)
	assert_eq(_enemy_hp(controller, 0), 40, "chỉ mục tiêu được chọn bị trúng")
	assert_eq(controller.potions.count(), 0)
	assert_eq(controller.energy, 3, "potion không tốn năng lượng")
	assert_true(rec.has_event("potion:fire_potion:slot0"))
	assert_eq(rec.count("played:"), 0, "potion không phải thẻ")
	assert_eq(controller.trigger_queue_size(), 0)


func test_fire_potion_can_win_the_battle() -> void:
	var controller := _battle([&"fire_potion"], _one(20))
	var rec := Recorder.new(controller)
	assert_true(controller.use_potion(0, controller.enemies[0]))
	assert_eq(controller.state.phase, P.VICTORY)
	assert_eq(rec.with_prefix("ended:"), ["ended:true"])


func test_explosive_potion_hits_everyone_and_ignores_the_target() -> void:
	var controller := _battle([&"explosive_potion"], _two(30))
	assert_true(controller.use_potion(0))
	assert_eq(_enemy_hp(controller, 0), 20)
	assert_eq(_enemy_hp(controller, 1), 20)


func test_self_potions() -> void:
	var controller := _battle([&"block_potion", &"energy_potion", &"swift_potion"], _one(500, 1))
	var hand_before := controller.deck.count(Deck.HAND)
	assert_true(controller.use_potion(0))
	assert_eq(controller.player.block, 12)
	assert_true(controller.use_potion(1))
	assert_eq(controller.energy, 5)
	assert_true(controller.use_potion(2))
	assert_eq(controller.deck.count(Deck.HAND), hand_before + 3)
	assert_eq(controller.potions.count(), 0)


func test_strength_potion_boosts_the_next_attack() -> void:
	var controller := _battle([&"strength_potion"], _one(500, 1))
	controller.use_potion(0)
	assert_eq(controller.player.get_status(&"strength"), 2)
	controller.play_card(Factory.inject(controller, Factory.strike(&"s", 6)), controller.enemies[0])
	assert_eq(_enemy_hp(controller), 492, "6 + 2 Strength")


func test_weak_potion_lowers_the_announced_damage() -> void:
	var controller := _battle([&"weak_potion"], _one(500, 6))
	var rec := Recorder.new(controller)
	assert_true(controller.use_potion(0, controller.enemies[0]))
	assert_eq(controller.enemies[0].combatant.get_status(&"weak"), 3)
	assert_eq(controller.enemies[0].intent.damage_per_hit, 4, "6 x 0.75 = 4")
	assert_true(rec.has_event("intent:dummy_0:4"))


func test_blood_potion_heals_but_never_above_max() -> void:
	var controller := _battle([&"blood_potion", &"blood_potion"], _one(500, 1))
	controller.player.take_damage(30)
	controller.use_potion(0)
	assert_eq(controller.player.hp, 62)
	controller.use_potion(1)
	assert_eq(controller.player.hp, 74)
	controller.player.heal(999)
	assert_eq(controller.player.hp, 80)


## --- Từ chối hành động sai (không đổi gì) ---

func _assert_rejected(controller: BattleController, rec: Recorder, slot: int, target: EnemyUnit, reason: String) -> void:
	var energy := controller.energy
	var count := controller.potions.count()
	var hp := _enemy_hp(controller)
	assert_false(controller.use_potion(slot, target), reason)
	assert_eq(rec.last_rejection(), reason)
	assert_eq(controller.energy, energy, reason + ": năng lượng không đổi")
	assert_eq(controller.potions.count(), count, reason + ": dây potion không đổi")
	assert_eq(_enemy_hp(controller), hp, reason + ": máu quái không đổi")


func test_invalid_potion_use_is_rejected_without_side_effects() -> void:
	var controller := _battle([&"fire_potion", &"block_potion"], _two(30))
	var rec := Recorder.new(controller)
	var outsider := EnemyUnit.create(Factory.dummy_enemy(&"x"), Factory.rng())
	_assert_rejected(controller, rec, 2, null, "no_potion")     # ô trống
	_assert_rejected(controller, rec, -1, null, "no_potion")    # ngoài phạm vi
	_assert_rejected(controller, rec, 3, null, "no_potion")
	_assert_rejected(controller, rec, 0, null, "invalid_target")      # fire cần mục tiêu
	_assert_rejected(controller, rec, 0, outsider, "invalid_target")  # không thuộc trận này
	controller.enemies[1].combatant.take_damage(999)
	_assert_rejected(controller, rec, 0, controller.enemies[1], "invalid_target")  # đã chết


func test_a_used_slot_cannot_be_reused() -> void:
	var controller := _battle([&"block_potion"], _one())
	var rec := Recorder.new(controller)
	assert_true(controller.use_potion(0))
	_assert_rejected(controller, rec, 0, null, "no_potion")


func test_potions_cannot_be_used_before_the_battle_or_after_it_ends() -> void:
	var controller := _battle([&"fire_potion", &"block_potion"], _one(20), false)
	var rec := Recorder.new(controller)
	assert_false(controller.use_potion(1))
	assert_eq(rec.last_rejection(), "not_player_turn")
	controller.start_battle()
	controller.use_potion(0, controller.enemies[0])  # hạ quái -> thắng
	assert_false(controller.use_potion(1))
	assert_eq(rec.last_rejection(), "battle_over")
	assert_eq(controller.potions.count(), 1, "potion còn lại không bị tiêu")


## --- Tương tác với trigger ---

func test_potion_damage_does_not_count_as_an_attack_so_thorns_stay_silent() -> void:
	var controller := _battle([&"fire_potion"], _one(40))
	controller.enemies[0].combatant.add_status(_statuses.get_status(&"thorns"), 3)
	controller.use_potion(0, controller.enemies[0])
	assert_eq(_enemy_hp(controller), 20)
	assert_eq(controller.player.hp, 80, "potion không phải đòn tấn công nên không bị Thorns phản")


func test_potion_damage_still_raises_hp_lost() -> void:
	var controller := _battle([&"fire_potion"], _one(40))
	var rec := Recorder.new(controller)
	var lust := Factory.status_with_triggers(&"bloodlust", [Factory.trigger1(E.HP_LOST,
			EffectData.create(T.BLOCK, 2, G.SELF))] as Array[TriggerData])
	controller.enemies[0].combatant.add_status(lust, 1)
	controller.use_potion(0, controller.enemies[0])
	assert_true(rec.has_event("triggered:dummy_0:status:bloodlust"))
	assert_eq(controller.enemies[0].combatant.block, 2)


## --- Vòng đời ---

func test_unused_potions_persist_and_can_be_used_on_later_turns() -> void:
	var controller := _battle([&"block_potion", &"fire_potion"], _one(500, 1))
	controller.end_player_turn()
	controller.end_player_turn()
	assert_eq(controller.potions.to_ids(), [&"block_potion", &"fire_potion"] as Array[StringName])
	assert_true(controller.use_potion(1, controller.enemies[0]))
	assert_eq(controller.potions.to_ids(), [&"block_potion"] as Array[StringName],
			"danh sách id còn lại là thứ nơi gọi lưu lại vào RunState")


func test_all_three_potions_can_be_used_in_one_turn_and_the_belt_signals_changes() -> void:
	var controller := _battle([&"block_potion", &"energy_potion", &"strength_potion"], _one(500, 1))
	var changes: Array = []
	controller.potions.changed.connect(func() -> void: changes.append(1))
	for slot in 3:
		assert_true(controller.use_potion(slot))
	assert_eq(changes.size(), 3)
	assert_eq(controller.potions.count(), 0)
	assert_eq(controller.state.phase, P.PLAYER_TURN)


func test_a_battle_without_potions_has_an_empty_belt() -> void:
	var controller := Factory.battle(Factory.fillers(10), _one(), 1, null, 80, _statuses)
	assert_eq(controller.potions.count(), 0)
	assert_eq(controller.potions.capacity, 3)
