extends "res://tests/test_case.gd"
## Lượt quái chạy từng bước: begin_enemy_turn / peek_next_enemy / run_next_enemy / is_enemy_turn_in_progress.

const Hud := preload("res://tests/hud_factory.gd")
const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")

var _statuses: StatusRegistry


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _ids(units: Array) -> Array:
	return units.map(func(unit: EnemyUnit) -> String: return unit.combatant.id)


## --- begin_enemy_turn ---

func test_begin_moves_to_the_enemy_turn_without_letting_anyone_act() -> void:
	var controller := Hud.controller([], [], 3)
	var rec := Recorder.new(controller)
	assert_true(controller.begin_enemy_turn())
	assert_eq(controller.state.phase, BattleState.Phase.ENEMY_TURN)
	assert_true(controller.is_enemy_turn_in_progress())
	assert_eq(rec.count("acted:"), 0)
	assert_true(rec.has_event("turn:1:enemy"))
	assert_eq(controller.deck.count(Deck.HAND), 0, "tay đã bỏ")
	assert_eq(controller.player.hp, 80, "chưa ai đánh")


func test_begin_is_rejected_outside_the_player_turn_and_changes_nothing() -> void:
	var controller := Hud.controller([], [], 2)
	controller.begin_enemy_turn()
	var rec := Recorder.new(controller)
	assert_false(controller.begin_enemy_turn())
	assert_false(controller.end_player_turn())
	assert_eq(rec.last_rejection(), String(BattleController.REASON_NOT_PLAYER_TURN))
	assert_eq(rec.count("acted:"), 0)
	assert_true(controller.is_enemy_turn_in_progress())


func test_begin_after_the_battle_is_over_is_rejected() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	controller.enemies[0].combatant.take_damage(999)
	controller.use_potion(0)  # hành động kiểm tra thắng/thua
	assert_true(controller.state.is_terminal())
	var rec := Recorder.new(controller)
	assert_false(controller.begin_enemy_turn())
	assert_eq(rec.last_rejection(), String(BattleController.REASON_BATTLE_OVER))
	assert_false(controller.is_enemy_turn_in_progress())


## --- run_next_enemy ---

func test_each_call_runs_exactly_one_enemy_in_order() -> void:
	var controller := Hud.controller([], [], 3)
	var rec := Recorder.new(controller)
	controller.begin_enemy_turn()
	var order: Array = []
	for i in 3:
		var unit := controller.run_next_enemy()
		order.append(String(unit.combatant.id))
		assert_eq(rec.count("acted:"), i + 1, "mỗi lần gọi chỉ một quái đi")
	assert_eq(order, ["dummy_0", "dummy_1", "dummy_2"])


func test_the_last_enemy_closes_the_turn_and_starts_the_next_player_turn() -> void:
	var controller := Hud.controller([], [], 2)
	var rec := Recorder.new(controller)
	controller.begin_enemy_turn()
	controller.run_next_enemy()
	assert_true(controller.is_enemy_turn_in_progress(), "còn một quái")
	assert_eq(controller.state.phase, BattleState.Phase.ENEMY_TURN)
	controller.run_next_enemy()
	assert_false(controller.is_enemy_turn_in_progress())
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)
	assert_eq(controller.turn, 2)
	assert_true(rec.has_event("turn:2:player"))
	assert_eq(controller.deck.count(Deck.HAND), 5, "đã rút bài lượt mới")
	assert_eq(controller.energy, 3)


func test_peek_names_the_next_living_enemy_without_running_it() -> void:
	var controller := Hud.controller([], [], 3)
	assert_true(controller.peek_next_enemy() == null, "chưa có lượt quái")
	controller.begin_enemy_turn()
	var rec := Recorder.new(controller)
	assert_true(controller.peek_next_enemy() == controller.enemies[0])
	assert_true(controller.peek_next_enemy() == controller.enemies[0], "peek không tiêu thụ")
	assert_eq(rec.count("acted:"), 0)
	controller.run_next_enemy()
	assert_true(controller.peek_next_enemy() == controller.enemies[1])
	controller.run_next_enemy()
	controller.run_next_enemy()
	assert_true(controller.peek_next_enemy() == null, "hết lượt quái")


func test_dead_enemies_are_skipped() -> void:
	var controller := Hud.controller([], [], 3)
	controller.enemies[1].combatant.take_damage(999)
	controller.begin_enemy_turn()
	assert_eq(_ids([controller.peek_next_enemy()]), ["dummy_0"])
	var order: Array = []
	while controller.is_enemy_turn_in_progress():
		order.append(String(controller.run_next_enemy().combatant.id))
	assert_eq(order, ["dummy_0", "dummy_2"])


func test_enemy_killed_by_poison_at_turn_start_takes_its_turn_without_acting_and_others_continue() -> void:
	var controller := Hud.controller([], [], 3)
	controller.enemies[1].combatant.lose_hp(controller.enemies[1].combatant.hp - 1)
	controller.enemies[1].combatant.add_status(_statuses.get_status(&"poison"), 5)
	var rec := Recorder.new(controller)
	controller.begin_enemy_turn()
	var order: Array = []
	while controller.is_enemy_turn_in_progress():
		order.append(String(controller.run_next_enemy().combatant.id))
	assert_eq(order, ["dummy_0", "dummy_1", "dummy_2"], "quái chết vì độc vẫn có lượt")
	assert_eq(rec.with_prefix("acted:"), ["acted:dummy_0:hit", "acted:dummy_2:hit"], "nhưng không đánh")
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)


func test_player_dying_mid_turn_stops_the_remaining_enemies() -> void:
	var controller := Hud.controller([], [], 3)
	controller.player.lose_hp(controller.player.hp - 3)
	var rec := Recorder.new(controller)
	controller.begin_enemy_turn()
	assert_true(controller.run_next_enemy() == controller.enemies[0])
	assert_eq(controller.state.phase, BattleState.Phase.DEFEAT)
	assert_false(controller.is_enemy_turn_in_progress())
	assert_true(controller.peek_next_enemy() == null)
	assert_true(controller.run_next_enemy() == null)
	assert_eq(rec.count("acted:"), 1, "các quái sau không đi")
	assert_eq(controller.end_reason, BattleController.END_DEFEAT)


func test_turn_cap_ends_the_battle_when_the_last_enemy_finishes() -> void:
	var controller := Hud.controller([], [], 2)
	controller.config.turn_cap = 1
	controller.begin_enemy_turn()
	controller.run_next_enemy()
	assert_eq(controller.state.phase, BattleState.Phase.ENEMY_TURN, "chưa tới quái cuối")
	controller.run_next_enemy()
	assert_eq(controller.end_reason, BattleController.END_TURN_CAP)
	assert_false(controller.is_enemy_turn_in_progress())


func test_run_next_enemy_without_an_enemy_turn_does_nothing() -> void:
	var controller := Hud.controller([], [], 2)
	var rec := Recorder.new(controller)
	assert_true(controller.run_next_enemy() == null)
	assert_eq(rec.events.size(), 0)
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)


func test_the_turn_close_refreshes_intents_with_the_players_new_state() -> void:
	var warrior := Factory.combatant(&"player", 80)
	var attacker := Factory.enemy(&"attacker", 40, [Factory.attack_move(&"hit", 6)] as Array[EnemyMove])
	var debuffer := Factory.enemy(&"debuffer", 40, [Factory.status_move(&"curse", &"vulnerable", 2, EffectData.Target.TARGET_ENEMY)] as Array[EnemyMove])
	var controller := BattleController.create_from_data(warrior, Factory.fillers(10), [attacker, debuffer] as Array[EnemyData],
			_statuses, 1, null, [] as Array[RelicData], PotionBelt.from_ids([] as Array[StringName], PotionRegistry.load_from_dir("res://data/potions")))
	controller.start_battle()
	assert_eq(controller.enemies[0].intent.total_damage, 6)
	var rec := Recorder.new(controller)
	controller.begin_enemy_turn()
	controller.run_next_enemy()
	controller.run_next_enemy()  # quái sau gắn Vulnerable lên người chơi, SAU khi quái đầu đã vạch ý định
	assert_true(controller.player.has_status(&"vulnerable"))
	assert_eq(controller.enemies[0].intent.total_damage, 9, "ý định theo trạng thái mới của người chơi")
	var updated := rec.events.find("intent:%s:9" % controller.enemies[0].combatant.id)
	assert_true(updated >= 0 and updated < rec.events.find("turn:2:player"),
			"đóng lượt quái cập nhật ý định TRƯỚC khi lượt người chơi mới bắt đầu (thứ tự sự kiện giữ như cũ): %s" % [rec.events])


func test_run_next_enemy_closes_safely_when_every_remaining_enemy_died_in_between() -> void:
	var controller := Hud.controller([], [], 2)
	controller.begin_enemy_turn()
	for unit in controller.enemies:
		unit.combatant.take_damage(999)  # chết ngoài luồng giữa hai bước
	assert_true(controller.run_next_enemy() == null)
	assert_false(controller.is_enemy_turn_in_progress(), "không kẹt (end_player_turn lặp đến khi hết lượt)")
	assert_eq(controller.state.phase, BattleState.Phase.VICTORY)


func test_intents_are_planned_again_after_each_enemy_acts() -> void:
	var controller := Hud.controller([], [], 2)
	var rec := Recorder.new(controller)
	controller.begin_enemy_turn()
	controller.run_next_enemy()
	assert_true(rec.has_event("intent:dummy_0:6"), "ý định của quái vừa đi được vạch lại ngay")
	assert_false(rec.has_event("intent:dummy_1:6"), "quái chưa đi thì chưa đổi")


## --- Trong lúc quái đi, người chơi không làm được gì ---

func test_player_actions_are_rejected_while_the_enemy_turn_is_in_progress() -> void:
	var controller := Hud.controller([&"block_potion"], [], 2)
	var card := controller.deck.get_pile(Deck.HAND)[0]
	controller.begin_enemy_turn()
	var rec := Recorder.new(controller)
	var hp_before := controller.player.hp
	assert_false(controller.play_card(card, controller.enemies[0]))
	assert_false(controller.use_potion(0))
	assert_eq(rec.count("rejected:"), 2)
	assert_eq(rec.last_rejection(), String(BattleController.REASON_NOT_PLAYER_TURN))
	assert_eq(controller.potions.count(), 1)
	assert_eq(controller.player.hp, hp_before)


## --- Tương đương với end_player_turn() ---

func test_stepwise_run_matches_end_player_turn_event_for_event() -> void:
	var stepwise := Hud.controller([], [&"anchor"], 3)
	var shortcut := Hud.controller([], [&"anchor"], 3)
	var rec_a := Recorder.new(stepwise)
	var rec_b := Recorder.new(shortcut)
	for i in 3:  # nhiều lượt liền
		stepwise.begin_enemy_turn()
		while stepwise.is_enemy_turn_in_progress():
			stepwise.run_next_enemy()
		shortcut.end_player_turn()
	assert_eq(rec_a.events, rec_b.events)
	assert_eq(stepwise.player.hp, shortcut.player.hp)
	assert_eq(stepwise.turn, shortcut.turn)
