extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const UiInput := preload("res://tests/ui_input.gd")

var _scene: BattleScene = null


func after_each() -> void:
	if _scene != null:
		_scene.free()
		_scene = null


## Trận đã bắt đầu với n quái giả; người chơi có player_hp máu.
func _controller(enemy_count: int = 2, enemy_hp: int = 40, player_hp: int = 80) -> BattleController:
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(&"dummy", enemy_hp, 6))
	var controller := Factory.battle(Factory.fillers(10), datas, 1, null, player_hp)
	controller.start_battle()
	return controller


func _scene_for(controller: BattleController) -> BattleScene:
	_scene = BattleScene.new()
	_scene.setup(controller)
	return _scene


func _connection_count(controller: BattleController) -> int:
	var total := controller.deck.pile_changed.get_connections().size()
	for signal_name in ["energy_changed", "turn_started", "intent_changed", "card_played", "enemy_acted",
			"enemy_defeated", "action_rejected", "battle_ended"]:
		total += controller.get_signal_connection_list(signal_name).size()
	total += controller.state.changed.get_connections().size()
	total += controller.player.status_changed.get_connections().size()
	return total


## --- Dựng giao diện ---

func test_setup_shows_the_battle() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	assert_eq(scene.enemy_uis.size(), 2)
	assert_eq(scene.turn_label.text, "Turn 1")
	assert_eq(scene.energy_ui.label.text, "3/3")
	assert_eq(scene.hand_ui.card_uis.size(), 5)
	assert_eq(scene.draw_counter.count_label.text, "5")
	assert_eq(scene.hero_ui.health_bar.hp_label.text, "80/80")
	assert_false(scene.end_turn_button.disabled)
	assert_false(scene.result_overlay.visible)


func test_setup_before_start_battle_catches_up_through_signals() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"dummy", 40, 6)]
	var controller := Factory.battle(Factory.fillers(10), datas)
	var scene := _scene_for(controller)
	assert_true(scene.end_turn_button.disabled, "chưa tới lượt người chơi")
	controller.start_battle()
	scene.hand_ui.flush_pending_refresh()
	assert_false(scene.end_turn_button.disabled, "End Turn bật khi vào PLAYER_TURN")
	assert_eq(scene.hand_ui.card_uis.size(), 5)
	assert_eq(scene.energy_ui.label.text, "3/3")


## --- Chơi thẻ bằng click ---

func test_clicking_a_card_without_target_plays_it() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.defend())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	assert_eq(controller.energy, 2)
	assert_eq(controller.player.block, 5)
	assert_eq(scene.energy_ui.label.text, "2/3")
	assert_true(scene.hero_ui.health_bar.block_box.visible)
	scene.hand_ui.flush_pending_refresh()
	assert_eq(scene.hand_ui.card_uis.size(), controller.deck.count(Deck.HAND))


func test_attack_with_several_enemies_asks_for_a_target_then_hits_the_chosen_one() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	assert_eq(scene.message_label.text, RejectionText.CHOOSE_TARGET)
	assert_true(scene.intent.is_targeting())
	for enemy_ui in scene.enemy_uis:
		assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_TARGETABLE_COLOR)
	assert_eq(controller.energy, 3, "chưa tốn năng lượng khi chưa chọn mục tiêu")
	scene.enemy_uis[1].clicked.emit(controller.enemies[1])
	assert_eq(controller.enemies[1].combatant.hp, 34)
	assert_eq(controller.enemies[0].combatant.hp, 40)
	assert_false(scene.intent.is_targeting())
	assert_eq(scene.message_label.text, "")
	assert_eq(scene.enemy_uis[1].combatant_ui.health_bar.hp_label.text, "34/40")
	for enemy_ui in scene.enemy_uis:
		assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_COLOR, "hết chọn mục tiêu thì hết nổi bật")


func test_attack_with_one_enemy_targets_it_automatically() -> void:
	var controller := _controller(1)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	assert_eq(controller.enemies[0].combatant.hp, 34)
	assert_false(scene.intent.is_targeting())


func test_unaffordable_card_shows_the_reason_and_changes_nothing() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	scene.hand_ui.flush_pending_refresh()
	var hand_before := controller.deck.count(Deck.HAND)
	scene.hand_ui.card_clicked.emit(card)
	assert_eq(scene.message_label.text, "Not enough energy")
	assert_eq(controller.energy, 3)
	assert_eq(controller.deck.count(Deck.HAND), hand_before)


func test_clicking_a_dead_enemy_is_rejected_but_keeps_waiting_for_a_target() -> void:
	var controller := _controller(3)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	controller.enemies[0].combatant.take_damage(999)
	scene._on_enemy_clicked(controller.enemies[0])
	assert_eq(scene.message_label.text, "Invalid target")
	assert_true(scene.intent.is_targeting())
	assert_eq(scene.enemy_uis[0].art_rect.color, EnemyUI.ART_COLOR, "quái chết không nổi bật")
	assert_eq(scene.enemy_uis[1].art_rect.color, EnemyUI.ART_TARGETABLE_COLOR)


func test_clicking_an_enemy_without_a_selected_card_does_nothing() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	scene.enemy_uis[0].clicked.emit(controller.enemies[0])
	assert_eq(controller.energy, 3)
	assert_eq(scene.message_label.text, "")


## --- Huỷ chọn mục tiêu ---

func test_cancel_by_method_clears_selection_and_message() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	assert_true(scene.cancel_targeting())
	assert_false(scene.intent.is_targeting())
	assert_eq(scene.message_label.text, "")
	for card_ui in scene.hand_ui.card_uis:
		assert_false(card_ui.highlighted)
	assert_false(scene.cancel_targeting(), "không còn gì để huỷ")


func test_clicking_the_same_card_again_cancels() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	scene.hand_ui.card_clicked.emit(card)
	assert_false(scene.intent.is_targeting())
	assert_eq(controller.energy, 3)


func test_escape_and_right_click_cancel_but_other_keys_do_not() -> void:
	var controller := _controller(2)
	_scene_for(controller)
	Engine.get_main_loop().root.add_child(_scene)
	for cancel_event: InputEvent in [_key(KEY_ESCAPE), UiInput.click(MOUSE_BUTTON_RIGHT)]:
		var card := Factory.inject(controller, Factory.strike())
		_scene.hand_ui.flush_pending_refresh()
		_scene.hand_ui.card_clicked.emit(card)
		assert_true(_scene.intent.is_targeting())
		_scene._unhandled_input(cancel_event)
		assert_false(_scene.intent.is_targeting())
	var other := Factory.inject(controller, Factory.strike())
	_scene.hand_ui.flush_pending_refresh()
	_scene.hand_ui.card_clicked.emit(other)
	_scene._unhandled_input(_key(KEY_A))
	assert_true(_scene.intent.is_targeting(), "phím khác không huỷ")


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


## --- Kết thúc lượt ---

func test_end_turn_runs_the_enemy_turn_and_starts_the_next() -> void:
	var controller := _controller(1)
	var scene := _scene_for(controller)
	scene.show_message("cũ")
	scene.end_turn_button.pressed.emit()
	scene.hand_ui.flush_pending_refresh()
	assert_eq(controller.turn, 2)
	assert_eq(scene.turn_label.text, "Turn 2")
	assert_eq(scene.hero_ui.health_bar.hp_label.text, "%d/80" % controller.player.hp)
	assert_true(controller.player.hp < 80, "quái đã đánh")
	assert_false(scene.end_turn_button.disabled, "lượt mới: bật lại End Turn")
	assert_eq(scene.hand_ui.card_uis.size(), 5, "rút bài lượt mới")
	assert_eq(scene.message_label.text, "")
	assert_eq(scene.energy_ui.label.text, "3/3")


func test_end_turn_while_targeting_drops_the_selection() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(card)
	scene.end_turn_button.pressed.emit()
	assert_false(scene.intent.is_targeting())
	for enemy_ui in scene.enemy_uis:
		assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_COLOR)


func test_a_retained_card_loses_its_target_selection_when_the_turn_ends() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	var kept := Factory.inject(controller, Factory.strike(&"keep", 6, {"retain": true}))
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(kept)
	assert_true(scene.intent.is_targeting())
	scene.end_turn_button.pressed.emit()
	assert_true(controller.deck.get_pile(Deck.HAND).has(kept), "thẻ retain vẫn còn trên tay")
	assert_true(controller.can_play(kept), "và vẫn chơi được ở lượt mới")
	assert_false(scene.intent.is_targeting(), "nhưng lượt mới phải bắt đầu không ở chế độ chọn mục tiêu")
	for enemy_ui in scene.enemy_uis:
		assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_COLOR)


func test_intent_icons_follow_the_new_move_even_when_the_numbers_stay_the_same() -> void:
	# Chiêu A: đánh 6 + Weak; chiêu B: đánh 6. Con số giống nhau nên controller KHÔNG phát intent_changed.
	var attack_and_weaken := Factory.move(&"a", [
		Factory.damage_effect(6), EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"weak"),
	] as Array[EffectData])
	var plain_attack := Factory.attack_move(&"b", 6)
	var twin := Factory.enemy(&"twin", 40, [attack_and_weaken, plain_attack] as Array[EnemyMove],
			EnemyData.PatternKind.SEQUENCE, {"sequence": [&"a", &"b"] as Array[StringName]})
	var controller := Factory.battle(Factory.fillers(10), [twin] as Array[EnemyData])
	controller.start_battle()
	var scene := _scene_for(controller)
	assert_eq(scene.enemy_uis[0].intent_row.get_child_count(), 3, "đánh + debuff + nhãn số")
	scene.end_turn_button.pressed.emit()
	var expected := IntentView.build(controller.enemies[0].intent)
	assert_eq(expected.icon_ids.size(), 1, "chiêu B chỉ đánh")
	assert_eq(scene.enemy_uis[0].intent_row.get_child_count(), expected.icon_ids.size() + 1)


func test_enemy_intents_are_redrawn_after_the_enemy_turn() -> void:
	var datas: Array[EnemyData] = [GameData.load_default().enemies.get_enemy(&"spiker")]
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	var scene := _scene_for(controller)
	assert_eq(scene.enemy_uis[0].intent_label.text, "7", "Bash")
	scene.end_turn_button.pressed.emit()
	assert_eq(scene.enemy_uis[0].intent_label.text, IntentView.build(controller.enemies[0].intent).text)
	assert_eq(scene.enemy_uis[0].intent_label.text, "", "chiêu thứ hai là Bristle (chỉ buff)")


## --- Thắng / thua ---

func test_victory_shows_the_overlay_and_blocks_further_play() -> void:
	var controller := _controller(1, 1)
	var scene := _scene_for(controller)
	var killer := Factory.inject(controller, Factory.strike(&"killer", 99))
	var spare := Factory.inject(controller, Factory.strike(&"spare", 6))
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(killer)
	assert_true(scene.result_overlay.visible)
	assert_eq(scene.result_overlay.title_label.text, "Victory!")
	assert_true(scene.end_turn_button.disabled)
	scene.hand_ui.card_clicked.emit(spare)
	assert_eq(scene.message_label.text, "The battle is over")
	assert_eq(controller.energy, 2, "thẻ thứ hai không bị chơi")


func test_pressing_end_turn_after_the_battle_shows_the_controllers_reason() -> void:
	var controller := _controller(1, 1)
	var scene := _scene_for(controller)
	var killer := Factory.inject(controller, Factory.strike(&"killer", 99))
	scene.hand_ui.flush_pending_refresh()
	scene.hand_ui.card_clicked.emit(killer)
	scene.show_message("")
	scene.end_turn_button.pressed.emit()
	assert_eq(scene.message_label.text, "The battle is over", "lý do do controller phát qua action_rejected")


func test_defeat_shows_the_overlay() -> void:
	var controller := _controller(1, 40, 1)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	assert_true(scene.result_overlay.visible)
	assert_eq(scene.result_overlay.title_label.text, "Defeat")
	assert_true(scene.end_turn_button.disabled)


func test_play_again_button_requests_a_restart() -> void:
	var controller := _controller(1, 1)
	var scene := _scene_for(controller)
	var requests: Array[int] = []
	scene.restart_requested.connect(func() -> void: requests.append(1))
	scene.result_overlay.play_again_button.pressed.emit()
	assert_eq(requests.size(), 1)


## --- Vòng đời ---

func test_teardown_leaves_no_connections_and_clears_the_screen() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	assert_true(_connection_count(controller) > 0)
	scene.teardown()
	assert_eq(_connection_count(controller), 0, "không còn kết nối nào tới trận cũ")
	assert_eq(scene.enemy_uis.size(), 0)
	assert_eq(scene.hand_ui.card_uis.size(), 0)
	assert_eq(scene.turn_label.text, "")
	scene.teardown()  # gọi lần hai vẫn an toàn


func test_setup_with_a_new_battle_ignores_the_old_one() -> void:
	var old_controller := _controller(2)
	var new_controller := _controller(1)
	var scene := _scene_for(old_controller)
	scene.setup(new_controller)
	assert_eq(_connection_count(old_controller), 0)
	assert_eq(scene.enemy_uis.size(), 1)
	old_controller.player.take_damage(30)
	old_controller.end_player_turn()
	assert_eq(scene.turn_label.text, "Turn 1", "trận cũ chạy tiếp không ảnh hưởng")
	assert_eq(scene.hero_ui.health_bar.hp_label.text, "80/80")


func test_repeated_setup_does_not_leak_nodes() -> void:
	var scene := _scene_for(_controller(2))
	scene.setup(_controller(2))
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 4:
		scene.setup(_controller(2))
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)


func test_input_before_setup_is_ignored() -> void:
	_scene = BattleScene.new()
	_scene._on_end_turn_pressed()
	_scene._on_card_clicked(Factory.strike())
	_scene._on_enemy_clicked(null)
	assert_eq(_scene.turn_label.text, "")
	assert_eq(_scene.message_label.text, "")


func test_setup_null_keeps_the_current_battle() -> void:
	var controller := _controller(2)
	var scene := _scene_for(controller)
	scene.setup(null)
	assert_eq(scene.enemy_uis.size(), 2)
	assert_eq(scene.turn_label.text, "Turn 1")
