extends "res://tests/test_case.gd"
## Mỗi relic (đọc từ data/relics/*.tres thật) chạy trong một trận thật qua BattleController.

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target
const P := BattleState.Phase

var _relics: RelicRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_relics = RelicRegistry.load_from_dir("res://data/relics")
	_statuses = Factory.registry()


func _one(hp: int = 20, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(&"dummy", hp, damage)] as Array[EnemyData]


func _battle(relic_ids: Array, datas: Array[EnemyData], start: bool = true) -> BattleController:
	var ids: Array[StringName] = []
	ids.assign(relic_ids)
	var controller := BattleController.create_from_data(Factory.combatant(&"player", 80), Factory.fillers(10),
			datas, _statuses, 1, null, _relics.resolve(ids))
	if start:
		controller.start_battle()
	return controller


func _enemy(controller: BattleController) -> Combatant:
	return controller.enemies[0].combatant


func test_burning_blood_heals_after_victory_before_battle_ended() -> void:
	var controller := _battle([&"burning_blood"], _one(6), false)
	controller.player.take_damage(30)
	var seen: Array = []
	var player := controller.player  # bắt `player` chứ KHÔNG bắt `controller`: lambda nối vào tín hiệu của controller mà bắt controller tạo vòng tham chiếu (rò rỉ)
	controller.battle_ended.connect(func(_victory: bool) -> void: seen.append(player.hp))
	controller.start_battle()
	controller.play_card(Factory.inject(controller, Factory.strike(&"finisher", 6)), controller.enemies[0])
	assert_eq(seen, [56], "người nhận battle_ended thấy máu ĐÃ được hồi 6")


func test_burning_blood_does_nothing_on_defeat_and_never_overheals() -> void:
	var losing := _battle([&"burning_blood"], _one(20, 99))
	var rec := Recorder.new(losing)
	losing.end_player_turn()
	assert_eq(losing.state.phase, P.DEFEAT)
	assert_eq(rec.count("triggered:"), 0)
	var healthy := _battle([&"burning_blood"], _one(6))
	healthy.play_card(Factory.inject(healthy, Factory.strike(&"finisher", 6)), healthy.enemies[0])
	assert_eq(healthy.player.hp, 80, "đầy máu thì không hồi quá mức tối đa")


func test_anchor_gives_ten_block_that_survives_turn_one() -> void:
	var controller := _battle([&"anchor"], _one())
	assert_eq(controller.player.block, 10)
	controller.end_player_turn()
	assert_eq(controller.player.hp, 80, "10 giáp chặn hết 6 sát thương")
	assert_eq(controller.player.block, 0, "giáp bị xóa như bình thường từ lượt 2")


func test_vajra_gives_strength_for_the_whole_battle() -> void:
	var controller := _battle([&"vajra"], _one(200))
	assert_eq(controller.player.get_status(&"strength"), 1)
	controller.play_card(Factory.inject(controller, Factory.strike(&"s", 6)), controller.enemies[0])
	assert_eq(_enemy(controller).hp, 193, "6 + 1 Strength")
	controller.end_player_turn()
	assert_eq(controller.player.get_status(&"strength"), 1, "không cộng dồn thêm mỗi lượt")


func test_lantern_gives_energy_on_the_first_turn_only() -> void:
	var controller := _battle([&"lantern"], _one(500, 1))
	var energies: Array = [controller.energy]
	for i in 2:
		controller.end_player_turn()
		energies.append(controller.energy)
	assert_eq(energies, [4, 3, 3])


func test_lantern_works_again_in_the_next_battle() -> void:
	for battle_index in 2:
		assert_eq(_battle([&"lantern"], _one()).energy, 4, "bộ đếm theo trận, mỗi trận mới được +1")


func test_bag_of_preparation_draws_two_extra_cards_on_turn_one() -> void:
	var controller := _battle([&"bag_of_preparation"], _one(500, 1))
	assert_eq(controller.deck.count(Deck.HAND), 7, "2 từ relic + 5 rút thường")
	controller.end_player_turn()
	assert_eq(controller.deck.count(Deck.HAND), 5, "chỉ lượt đầu")


func test_happy_flower_gives_energy_every_third_turn() -> void:
	var controller := _battle([&"happy_flower"], _one(500, 1))
	var energies: Array = [controller.energy]
	for i in 5:
		controller.end_player_turn()
		energies.append(controller.energy)
	assert_eq(energies, [3, 3, 4, 3, 3, 4])


func test_orichalcum_gives_block_only_when_you_end_the_turn_without_any() -> void:
	var bare := _battle([&"orichalcum"], _one())
	bare.end_player_turn()
	assert_eq(bare.player.hp, 80, "0 giáp: nhận 6 giáp, chặn hết đòn")
	var guarded := _battle([&"orichalcum"], _one())
	guarded.player.gain_block(1)
	guarded.end_player_turn()
	assert_eq(guarded.player.hp, 75, "đã có giáp: không nổ")


func test_bronze_scales_start_the_battle_with_thorns() -> void:
	var controller := _battle([&"bronze_scales"], _one())
	assert_eq(controller.player.get_status(&"thorns"), 3)
	controller.end_player_turn()
	assert_eq(_enemy(controller).hp, 17, "quái đánh người chơi nên bị Thorns 3")


func test_relics_fire_in_the_order_they_were_given_and_before_statuses() -> void:
	var ids: Array[StringName] = [&"anchor", &"vajra", &"bronze_scales"]
	var controller := _battle(ids, _one(), false)
	var rec := Recorder.new(controller)
	var mark := Factory.status_with_triggers(&"mark",
			[Factory.trigger1(E.BATTLE_START, EffectData.create(T.BLOCK, 1, G.SELF))] as Array[TriggerData])
	controller.player.add_status(mark, 1)
	controller.start_battle()
	assert_eq(rec.with_prefix("triggered:"), [
		"triggered:player:relic:anchor", "triggered:player:relic:vajra",
		"triggered:player:relic:bronze_scales", "triggered:player:status:mark"])


func test_several_relics_work_together() -> void:
	var ids: Array[StringName] = [&"anchor", &"vajra", &"lantern", &"bag_of_preparation"]
	var controller := _battle(ids, _one(500, 1))
	assert_eq(controller.player.block, 10)
	assert_eq(controller.player.get_status(&"strength"), 1)
	assert_eq(controller.energy, 4)
	assert_eq(controller.deck.count(Deck.HAND), 7)


func test_relics_never_leave_work_in_the_trigger_queue() -> void:
	var ids: Array[StringName] = [&"burning_blood", &"anchor", &"vajra", &"lantern", &"bag_of_preparation",
			&"happy_flower", &"orichalcum", &"bronze_scales"]
	var controller := _battle(ids, _one(40, 5))
	for i in 4:
		controller.play_card(Factory.inject(controller, Factory.strike(&"s%d" % i, 6)), controller.enemies[0])
		assert_eq(controller.trigger_queue_size(), 0)
		if not controller.state.is_terminal():
			controller.end_player_turn()
		assert_eq(controller.trigger_queue_size(), 0)
	assert_false(controller.trigger_overflowed())
