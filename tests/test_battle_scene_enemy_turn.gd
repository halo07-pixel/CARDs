extends "res://tests/test_case.gd"
## BattleScene + lượt quái tuần tự (3.6b): với hiệu ứng bật quái đi từng con theo nhịp; tắt thì tức thì như cũ.

const Hud := preload("res://tests/hud_factory.gd")

var _scene: BattleScene = null


func after_each() -> void:
	if _scene != null:
		_scene.free()
		_scene = null


func _scene_for(controller: BattleController, speed: float = EffectsConfig.NORMAL_SPEED, in_tree: bool = true) -> BattleScene:
	_scene = BattleScene.new()
	_scene.effects.speed = speed
	if in_tree:
		Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(controller)
	return _scene


func _texts(scene: BattleScene) -> Array:
	var texts: Array = []
	for child in scene.effects_layer.get_children():
		texts.append((child as FloatingTextUI).text)
	return texts


func _finish(scene: BattleScene) -> void:
	for i in 40:
		if not scene.enemy_turn_player.is_playing():
			return
		scene.enemy_turn_player.fire_now()


func test_with_effects_on_end_turn_does_not_run_the_enemies_at_once() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	assert_eq(controller.state.phase, BattleState.Phase.ENEMY_TURN)
	assert_true(scene.enemy_turn_player.is_playing())
	assert_true(scene.end_turn_button.disabled)
	assert_eq(controller.player.hp, 80, "chưa quái nào đánh")
	assert_eq(scene.turn_label.text, "Turn 1")


func test_enemies_act_one_by_one_and_the_turn_ends_for_the_player() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	for expected_hp in [74, 68, 62]:
		scene.enemy_turn_player.fire_now()  # quái đi
		assert_eq(controller.player.hp, expected_hp, "từng quái đánh 6")
		scene.enemy_turn_player.fire_now()  # nghỉ rồi tới quái kế tiếp (hoặc xong)
	assert_false(scene.enemy_turn_player.is_playing())
	assert_eq(scene.turn_label.text, "Turn 2")
	assert_false(scene.end_turn_button.disabled)
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)


func test_each_enemy_gets_a_windup_pop_before_it_acts() -> void:
	var controller := Hud.controller([], [], 2)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	assert_true(scene.enemy_uis[0].art_rect.has_meta(UiFx.TWEEN_META), "quái đầu nảy lên")
	assert_false(scene.enemy_uis[1].art_rect.has_meta(UiFx.TWEEN_META), "quái sau chưa tới lượt")
	assert_eq(controller.player.hp, 80)


func test_numbers_appear_per_enemy_not_all_at_once() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	scene.enemy_turn_player.fire_now()
	assert_eq(_texts(scene).size(), 1)
	scene.enemy_turn_player.fire_now()
	scene.enemy_turn_player.fire_now()
	assert_eq(_texts(scene).size(), 2)


func test_player_actions_during_the_enemy_turn_are_rejected() -> void:
	var controller := Hud.controller([&"block_potion"], [], 2)
	var scene := _scene_for(controller)
	var hand := controller.deck.get_pile(Deck.HAND)
	scene.end_turn_button.pressed.emit()
	scene.hand_ui.card_clicked.emit(hand[0])
	assert_eq(scene.message_label.text, RejectionText.for_reason(BattleController.REASON_NOT_PLAYER_TURN))
	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	assert_eq(controller.potions.count(), 1, "không dùng được potion lúc quái đi")
	assert_true(scene.enemy_turn_player.is_playing(), "lượt quái vẫn tiếp tục")


func test_pressing_end_turn_again_mid_turn_does_not_restart_the_play() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller)
	var announced: Array = []
	scene.enemy_turn_player.step_started.connect(func(unit: EnemyUnit) -> void: announced.append(unit.combatant.id))
	scene.end_turn_button.pressed.emit()
	scene.enemy_turn_player.fire_now()
	scene.end_turn_button.pressed.emit()  # bấm lại (nút đã tắt nhưng tín hiệu vẫn có thể tới)
	assert_eq(scene.enemy_turn_player.phase, EnemyTurnPlayer.Phase.GAP, "bấm lại không làm mất nhịp nghỉ đang chờ")
	_finish(scene)
	assert_eq(announced.size(), 3, "mỗi quái được báo đúng một lần")
	assert_eq(controller.player.hp, 62)


func test_the_player_dying_mid_turn_shows_defeat_and_the_rest_do_not_act() -> void:
	var controller := Hud.controller([], [], 3)
	controller.player.lose_hp(controller.player.hp - 3)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	scene.enemy_turn_player.fire_now()  # quái đầu đánh và hạ người chơi
	assert_true(scene.result_overlay.visible)
	assert_eq(scene.result_overlay.title_label.text, ResultOverlayUI.DEFEAT_TEXT)
	_finish(scene)
	assert_false(scene.enemy_turn_player.is_playing())
	assert_eq(controller.state.phase, BattleState.Phase.DEFEAT)
	assert_true(scene.end_turn_button.disabled)


func test_effects_off_keeps_the_instant_enemy_turn() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller, 0.0)
	scene.end_turn_button.pressed.emit()
	assert_false(scene.enemy_turn_player.is_playing())
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)
	assert_eq(controller.turn, 2)
	assert_eq(controller.player.hp, 62)


func test_a_scene_outside_the_tree_falls_back_to_the_instant_enemy_turn() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller, EffectsConfig.NORMAL_SPEED, false)
	scene.end_turn_button.pressed.emit()
	assert_false(controller.is_enemy_turn_in_progress(), "không kẹt giữa lượt quái")
	assert_eq(controller.state.phase, BattleState.Phase.PLAYER_TURN)
	assert_eq(controller.turn, 2)


func test_teardown_mid_turn_stops_the_play() -> void:
	var controller := Hud.controller([], [], 3)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	scene.enemy_turn_player.fire_now()
	scene.teardown()
	assert_false(scene.enemy_turn_player.is_playing())
	assert_true(scene.enemy_turn_player._timer.is_stopped(), "dỡ màn không để lại timer")
	scene.enemy_turn_player.fire_now()
	assert_eq(controller.player.hp, 74, "không ai đi thêm sau khi dỡ màn")


func test_a_new_battle_mid_turn_replaces_the_old_play() -> void:
	var old_controller := Hud.controller([], [], 3)
	var scene := _scene_for(old_controller)
	scene.end_turn_button.pressed.emit()
	var new_controller := Hud.controller([], [], 2)
	scene.setup(new_controller)
	assert_false(scene.enemy_turn_player.is_playing())
	scene.end_turn_button.pressed.emit()
	_finish(scene)
	assert_eq(new_controller.turn, 2)
	assert_eq(new_controller.player.hp, 68)
	assert_eq(old_controller.player.hp, 80, "trận cũ bị bỏ giữa chừng, không chạy tiếp")


func test_battle_ending_before_any_enemy_acts_leaves_nothing_playing() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	var scene := _scene_for(controller)
	controller.enemies[0].combatant.take_damage(999)
	controller.use_potion(0)  # thắng
	scene.end_turn_button.pressed.emit()
	assert_false(scene.enemy_turn_player.is_playing())
	assert_true(scene.result_overlay.visible)
