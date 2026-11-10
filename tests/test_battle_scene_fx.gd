extends "res://tests/test_case.gd"
## BattleScene + hiệu ứng 3.6a: chữ nổi, nảy khi trúng, thanh máu mượt, rung khi bị từ chối. Mặc định TẮT.

const Hud := preload("res://tests/hud_factory.gd")

var _scene: BattleScene = null


func after_each() -> void:
	if _scene != null:
		_scene.free()
		_scene = null


func _scene_for(controller: BattleController, speed: float = EffectsConfig.NORMAL_SPEED) -> BattleScene:
	_scene = BattleScene.new()
	_scene.effects.speed = speed
	Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(controller)
	return _scene


func _texts(scene: BattleScene) -> Array:
	var texts: Array = []
	for child in scene.effects_layer.get_children():
		texts.append((child as FloatingTextUI).text)
	return texts


func _play_first_card(scene: BattleScene, controller: BattleController) -> void:
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])


## Hiệu ứng bật: lượt quái diễn theo nhịp; đẩy nhịp tay tới hết lượt.
func _finish_enemy_turn(scene: BattleScene) -> void:
	for i in 30:
		if not scene.enemy_turn_player.is_playing():
			return
		scene.enemy_turn_player.fire_now()


func _has_fx(control: Control) -> bool:
	return control.has_meta(UiFx.TWEEN_META)


## --- Mặc định tắt ---

func test_a_new_scene_has_effects_off_and_nothing_happens() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	_scene = BattleScene.new()
	assert_false(_scene.effects.is_enabled())
	Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(controller)
	_play_first_card(_scene, controller)
	_scene.potion_belt_ui.slot_uis[0].pressed.emit()
	assert_eq(_scene.effects_layer.get_child_count(), 0)
	assert_false(_has_fx(_scene.enemy_uis[0].art_rect))
	assert_false(_scene.enemy_uis[0].combatant_ui.health_bar.is_animating())


func test_effects_layer_sits_between_the_playfield_and_the_tooltip() -> void:
	var scene := _scene_for(Hud.controller())
	var order := scene.get_children()
	assert_true(order.find(scene.effects_layer) > order.find(scene.hand_ui))
	assert_true(order.find(scene.effects_layer) < order.find(scene.tooltip_ui))
	assert_true(order.find(scene.result_overlay) > order.find(scene.pile_viewer))
	assert_true(scene.effects_layer.config == scene.effects, "dùng chung một đối tượng cài đặt")


## --- Chữ nổi và nảy ---

func test_playing_an_attack_shows_the_damage_number_and_pops_the_enemy() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_play_first_card(scene, controller)
	var lost := 40 - controller.enemies[0].combatant.hp
	assert_true(lost > 0)
	assert_eq(_texts(scene), [str(lost)])
	assert_true(_has_fx(scene.enemy_uis[0].art_rect), "hình quái nảy/nháy")
	assert_false(_has_fx(scene.hero_ui), "người chơi không bị trúng")


func test_block_potion_shows_block_on_the_hero_without_popping() -> void:
	var controller := Hud.controller([&"block_potion"])
	var scene := _scene_for(controller)
	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	assert_eq(_texts(scene), ["+12 Block"])
	assert_false(_has_fx(scene.hero_ui), "thêm giáp không phải trúng đòn")


func test_status_cue_uses_the_status_display_name() -> void:
	var controller := Hud.controller([&"weak_potion"], [], 1)
	var scene := _scene_for(controller)
	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	var weak_name := StatusRegistry.load_from_dir("res://data/statuses").get_status(&"weak").display_name
	assert_true(_texts(scene)[0].begins_with(weak_name), "tên status từ dữ liệu: %s" % [_texts(scene)])


func test_relic_trigger_at_battle_start_shows_its_effect() -> void:
	var controller := Hud.controller([], [&"anchor"], 1, false)
	var scene := _scene_for(controller)
	controller.start_battle()
	assert_true(_texts(scene).has("+10 Block"), "Anchor: %s" % [_texts(scene)])


func test_enemy_turn_shows_a_number_on_the_hero_for_each_attacker() -> void:
	var controller := Hud.controller([], [], 2)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	assert_eq(_texts(scene), [], "chưa quái nào đi: chưa có chữ")
	scene.enemy_turn_player.fire_now()  # hết nhịp chuẩn bị của quái đầu
	assert_eq(_texts(scene), ["6"], "quái đầu đánh: chỉ một số")
	_finish_enemy_turn(scene)
	assert_eq(_texts(scene), ["6", "6"])
	assert_true(_has_fx(scene.hero_ui), "người chơi bị trúng: nảy")
	var owners: Array = []
	for child in scene.effects_layer.get_children():
		owners.append(child.get_meta(EffectsLayerUI.OWNER_META))
	assert_true(owners[0] == controller.player and owners[1] == controller.player)


func test_a_blocked_attack_says_blocked_and_does_not_pop() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	var scene := _scene_for(controller)
	scene.potion_belt_ui.slot_uis[0].pressed.emit()  # 12 giáp > đòn 6
	scene.effects_layer.clear()
	UiFx.reset(scene.hero_ui)
	scene.end_turn_button.pressed.emit()
	_finish_enemy_turn(scene)
	assert_eq(_texts(scene), [EffectCueBuilder.BLOCKED_TEXT])
	assert_false(_has_fx(scene.hero_ui))


func test_teardown_clears_the_floating_texts() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_play_first_card(scene, controller)
	assert_true(scene.effects_layer.get_child_count() > 0)
	scene.teardown()
	assert_eq(scene.effects_layer.get_child_count(), 0)


func test_triggered_signal_is_disconnected_on_teardown() -> void:
	var controller := Hud.controller()
	var scene := _scene_for(controller)
	assert_eq(controller.get_signal_connection_list("triggered").size(), 1)
	scene.teardown()
	assert_eq(controller.get_signal_connection_list("triggered").size(), 0)


func test_texts_drain_away_on_their_own() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller, 300.0)
	_play_first_card(scene, controller)
	for i in 300:
		if scene.effects_layer.get_child_count() == 0:
			break
		await Engine.get_main_loop().process_frame
	assert_eq(scene.effects_layer.get_child_count(), 0)


## --- Thanh máu mượt ---

func test_enemy_and_hero_health_bars_slide_but_text_is_exact() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_play_first_card(scene, controller)
	var enemy_bar := scene.enemy_uis[0].combatant_ui.health_bar
	assert_true(enemy_bar.is_animating())
	assert_eq(enemy_bar.hp_label.text, "%d/40" % controller.enemies[0].combatant.hp)
	scene.end_turn_button.pressed.emit()
	_finish_enemy_turn(scene)
	var hero_bar := scene.hero_ui.health_bar
	assert_true(hero_bar.is_animating())
	assert_eq(hero_bar.hp_label.text, "%d/80" % controller.player.hp)


func test_a_fresh_scene_does_not_slide_the_bars_on_the_first_draw() -> void:
	var scene := _scene_for(Hud.controller([], [], 2))
	assert_false(scene.hero_ui.health_bar.is_animating())
	for enemy_ui in scene.enemy_uis:
		assert_false(enemy_ui.combatant_ui.health_bar.is_animating())


## --- Rung khi bị từ chối ---

func _assert_only_this_card_shakes(scene: BattleScene, card: CardInstance) -> void:
	assert_true(scene.hand_ui.card_uis.size() > 1, "cần nhiều thẻ để phân biệt")
	for card_ui in scene.hand_ui.card_uis:
		assert_eq(_has_fx(card_ui), card_ui.view.uid == card.uid, "chỉ thẻ bị bấm rung (uid %d)" % card_ui.view.uid)


func _exhaust_energy(scene: BattleScene, controller: BattleController) -> void:
	for i in controller.config.max_energy:
		_play_first_card(scene, controller)
		scene.hand_ui.flush_pending_refresh()


func test_clicking_an_unaffordable_card_shakes_it() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_exhaust_energy(scene, controller)
	assert_eq(controller.energy, 0)
	var hand := controller.deck.get_pile(Deck.HAND)
	var card := hand[hand.size() - 1]  # thẻ cuối tay: không trùng thẻ đầu tiên
	scene.hand_ui.card_clicked.emit(card)
	_assert_only_this_card_shakes(scene, card)
	assert_eq(scene.message_label.text, RejectionText.for_reason(BattleController.REASON_NOT_ENOUGH_ENERGY))


func test_starting_a_drag_on_an_unaffordable_card_shakes_it() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_exhaust_energy(scene, controller)
	var hand := controller.deck.get_pile(Deck.HAND)
	var card := hand[hand.size() - 1]
	scene._on_drag_started(card, Vector2(500, 300))
	_assert_only_this_card_shakes(scene, card)
	assert_false(scene.is_dragging())


func test_clicking_an_empty_potion_slot_shakes_that_slot() -> void:
	var scene := _scene_for(Hud.controller([&"block_potion"]))
	scene.potion_belt_ui.slot_uis[2].pressed.emit()
	assert_true(_has_fx(scene.potion_belt_ui.slot_uis[2]))
	assert_false(_has_fx(scene.potion_belt_ui.slot_uis[0]))


func test_rejections_do_not_shake_when_effects_are_off() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	var scene := _scene_for(controller, 0.0)
	_exhaust_energy(scene, controller)
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	scene.potion_belt_ui.slot_uis[2].pressed.emit()
	for card_ui in scene.hand_ui.card_uis:
		assert_false(_has_fx(card_ui))
	assert_false(_has_fx(scene.potion_belt_ui.slot_uis[2]))


func test_hand_and_belt_shake_helpers_report_whether_they_played() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	var scene := _scene_for(controller)
	var config := scene.effects
	assert_true(scene.hand_ui.shake_card(controller.deck.get_pile(Deck.HAND)[0], config))
	assert_false(scene.hand_ui.shake_card(null, config))
	assert_false(scene.hand_ui.shake_card(CardInstance.create(CardRegistry.load_from_dir("res://data/cards").get_card(&"strike")), config), "thẻ không ở trong tay")
	assert_true(scene.potion_belt_ui.shake_slot(0, config))
	assert_false(scene.potion_belt_ui.shake_slot(-1, config))
	assert_false(scene.potion_belt_ui.shake_slot(9, config))
	assert_false(scene.potion_belt_ui.shake_slot(0, EffectsConfig.new()))
