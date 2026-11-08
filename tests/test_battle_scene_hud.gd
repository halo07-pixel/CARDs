extends "res://tests/test_case.gd"
## BattleScene + HUD mốc 3.5: dây potion, thanh relic, tooltip, xem pile. Mọi thao tác đi qua tín hiệu như người chơi.

const Factory := preload("res://tests/combat_factory.gd")
const Hud := preload("res://tests/hud_factory.gd")

var _scene: BattleScene = null
var _cards: CardRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")


func after_each() -> void:
	if _scene != null:
		_scene.free()
		_scene = null


func _scene_for(controller: BattleController, in_tree: bool = false) -> BattleScene:
	_scene = BattleScene.new()
	if in_tree:
		Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(controller)
	return _scene


func _slot(scene: BattleScene, index: int) -> PotionSlotUI:
	return scene.potion_belt_ui.slot_uis[index]


func _escape() -> InputEventKey:
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	return escape


func _targetable(scene: BattleScene) -> Array:
	var result: Array = []
	for enemy_ui in scene.enemy_uis:
		result.append(enemy_ui.art_rect.color == EnemyUI.ART_TARGETABLE_COLOR)
	return result


func _hp(controller: BattleController, index: int) -> int:
	return controller.enemies[index].combatant.hp


## --- Dựng giao diện ---

func test_setup_shows_relics_and_potions() -> void:
	var scene := _scene_for(Hud.controller([&"fire_potion", &"block_potion"], [&"anchor", &"vajra"]))
	assert_eq(scene.relic_bar_ui.icon_uis.size(), 2)
	assert_eq(scene.potion_belt_ui.slot_uis.size(), 3)
	assert_eq(_slot(scene, 0).view.potion_id, &"fire_potion")
	assert_true(_slot(scene, 2).view.is_empty)
	assert_false(scene.tooltip_ui.visible)
	assert_false(scene.pile_viewer.is_open())


## --- Dùng potion ---

func test_self_potion_is_used_on_click_without_energy_cost() -> void:
	var controller := Hud.controller([&"block_potion"])
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	assert_eq(controller.player.block, 12)
	assert_eq(controller.energy, 3, "potion không tốn năng lượng")
	assert_eq(controller.potions.count(), 0)
	assert_true(_slot(scene, 0).view.is_empty, "dây vẽ lại theo lõi")
	assert_eq(scene.message_label.text, "")
	assert_false(scene.potion_intent.is_targeting())


func test_aoe_potion_hits_everyone_immediately() -> void:
	var controller := Hud.controller([&"explosive_potion"], [], 3)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	for i in 3:
		assert_eq(_hp(controller, i), 40 - 10 if _hp(controller, i) == 30 else _hp(controller, i), "đã trúng")
		assert_true(_hp(controller, i) < 40)
	assert_false(scene.potion_intent.is_targeting())


func test_single_target_potion_waits_for_a_target_when_there_are_several_enemies() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	assert_true(scene.potion_intent.is_targeting())
	assert_eq(scene.message_label.text, RejectionText.CHOOSE_TARGET)
	assert_true(_slot(scene, 0).selected, "ô được chọn viền sáng")
	assert_eq(_targetable(scene), [true, true])
	assert_eq(controller.potions.count(), 1, "chưa dùng")
	scene.enemy_uis[1].clicked.emit(controller.enemies[1])
	assert_eq(_hp(controller, 1), 20, "20 sát thương vào quái được chọn")
	assert_eq(_hp(controller, 0), 40, "quái kia không bị đụng")
	assert_eq(controller.potions.count(), 0)
	assert_false(scene.potion_intent.is_targeting())
	assert_false(_slot(scene, 0).selected)
	assert_eq(_targetable(scene), [false, false], "tô nổi mục tiêu đã dọn")
	assert_eq(scene.message_label.text, "")


func test_single_target_potion_auto_targets_the_only_enemy() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 1)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	assert_eq(_hp(controller, 0), 20)
	assert_false(scene.potion_intent.is_targeting())


func test_clicking_the_selected_slot_again_cancels() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	_slot(scene, 0).pressed.emit()
	assert_false(scene.potion_intent.is_targeting())
	assert_false(_slot(scene, 0).selected)
	assert_eq(_targetable(scene), [false, false])
	assert_eq(controller.potions.count(), 1)


func test_clicking_a_dead_enemy_does_not_use_the_potion() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 3)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	controller.enemies[2].combatant.take_damage(999)
	scene.enemy_uis[2].clicked.emit(controller.enemies[2])
	assert_eq(controller.potions.count(), 1)
	assert_true(scene.potion_intent.is_targeting(), "vẫn đang chọn")
	assert_eq(scene.message_label.text, RejectionText.for_reason(BattleController.REASON_INVALID_TARGET))


func test_potion_cannot_be_used_outside_the_player_turn() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1, false)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	assert_eq(controller.potions.count(), 1)
	assert_eq(scene.message_label.text, RejectionText.for_reason(BattleController.REASON_NOT_PLAYER_TURN))


func test_empty_slot_shows_the_reason() -> void:
	var scene := _scene_for(Hud.controller([&"block_potion"]))
	_slot(scene, 2).pressed.emit()
	assert_eq(scene.message_label.text, RejectionText.for_reason(BattleController.REASON_NO_POTION))


func test_potion_that_wins_the_battle_shows_the_result() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 1, true, 20)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	assert_true(scene.result_overlay.visible)
	assert_eq(scene.result_overlay.title_label.text, ResultOverlayUI.VICTORY_TEXT)


func test_belt_goes_dim_when_the_turn_passes_and_bright_again() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	var scene := _scene_for(controller)
	assert_almost_eq(_slot(scene, 0).modulate.a, 1.0, 0.0001)
	controller.state.transition(BattleState.Phase.ENEMY_TURN)  # đổi pha: BattleScene vẽ lại theo state.changed
	assert_almost_eq(_slot(scene, 0).modulate.a, PotionSlotUI.UNUSABLE_ALPHA, 0.0001)


## --- Loại trừ lẫn nhau, hủy ---

func test_cancel_targeting_cancels_a_potion_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	assert_true(scene.cancel_targeting())
	assert_false(scene.potion_intent.is_targeting())
	assert_false(_slot(scene, 0).selected)
	assert_eq(scene.message_label.text, "")
	assert_false(scene.cancel_targeting(), "không còn gì để hủy")


func test_escape_cancels_a_potion_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller, true)
	_slot(scene, 0).pressed.emit()
	scene._unhandled_input(_escape())
	assert_false(scene.potion_intent.is_targeting())


func test_clicking_a_card_drops_the_potion_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	assert_false(scene.potion_intent.is_targeting())
	assert_true(scene.intent.is_targeting(), "thẻ nhắm một quái được chọn")
	assert_false(_slot(scene, 0).selected)


func test_clicking_a_potion_drops_the_card_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	assert_true(scene.intent.is_targeting())
	_slot(scene, 0).pressed.emit()
	assert_false(scene.intent.is_targeting())
	assert_true(scene.potion_intent.is_targeting())
	assert_eq(_targetable(scene), [true, true])


func test_card_and_potion_are_never_targeting_at_the_same_time() -> void:
	var controller := Hud.controller([&"fire_potion", &"weak_potion"], [], 2)
	var scene := _scene_for(controller)
	var hand := controller.deck.get_pile(Deck.HAND)
	for i in 6:
		scene.hand_ui.card_clicked.emit(hand[i % hand.size()])
		assert_false(scene.intent.is_targeting() and scene.potion_intent.is_targeting())
		_slot(scene, i % 2).pressed.emit()
		assert_false(scene.intent.is_targeting() and scene.potion_intent.is_targeting())


func test_end_turn_cancels_the_potion_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	scene.end_turn_button.pressed.emit()
	assert_false(scene.potion_intent.is_targeting())
	assert_eq(_targetable(scene), [false, false])


func test_starting_a_drag_drops_the_potion_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	scene._on_drag_started(controller.deck.get_pile(Deck.HAND)[0], Vector2(500, 300))
	assert_false(scene.potion_intent.is_targeting())
	assert_false(_slot(scene, 0).selected)
	scene.hand_ui.cancel_drag()
	scene._on_drag_cancelled(controller.deck.get_pile(Deck.HAND)[0])


## --- Xem pile ---

func test_clicking_the_draw_counter_opens_the_pile_sorted_by_name() -> void:
	var controller := Hud.controller()
	var scene := _scene_for(controller)
	scene.draw_counter.clicked.emit(Deck.DRAW)
	assert_true(scene.pile_viewer.is_open())
	assert_eq(scene.pile_viewer.title_label.text, "Draw pile (%d)" % controller.deck.count(Deck.DRAW))
	assert_eq(scene.pile_viewer.grid.get_child_count(), controller.deck.count(Deck.DRAW))
	var titles: Array = []
	for card_ui in scene.pile_viewer.grid.get_children():
		titles.append((card_ui as CardUI).view.title)
	var sorted := titles.duplicate()
	sorted.sort()
	assert_eq(titles, sorted, "sắp theo tên, không lộ thứ tự rút")


func test_empty_pile_opens_with_the_empty_message() -> void:
	var scene := _scene_for(Hud.controller())
	scene.exhaust_counter.clicked.emit(Deck.EXHAUST)
	assert_true(scene.pile_viewer.is_open())
	assert_true(scene.pile_viewer.empty_label.visible)
	assert_eq(scene.pile_viewer.title_label.text, "Exhaust pile (0)")


func test_opening_a_pile_drops_any_pending_selection() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()
	scene.draw_counter.clicked.emit(Deck.DRAW)
	assert_false(scene.potion_intent.is_targeting())
	assert_eq(_targetable(scene), [false, false])
	scene.pile_viewer.close()
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	scene.discard_counter.clicked.emit(Deck.DISCARD)
	assert_false(scene.intent.is_targeting())


func test_escape_closes_the_pile_first() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 2)
	var scene := _scene_for(controller, true)
	scene.draw_counter.clicked.emit(Deck.DRAW)
	scene._unhandled_input(_escape())
	assert_false(scene.pile_viewer.is_open())


func test_potion_clicks_are_ignored_while_the_pile_is_open() -> void:
	var controller := Hud.controller([&"block_potion"])
	var scene := _scene_for(controller)
	scene.draw_counter.clicked.emit(Deck.DRAW)
	_slot(scene, 0).pressed.emit()
	assert_eq(controller.potions.count(), 1)


func test_pile_cannot_open_after_the_battle_is_over() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 1, true, 20)
	var scene := _scene_for(controller)
	_slot(scene, 0).pressed.emit()  # thắng
	scene.draw_counter.clicked.emit(Deck.DRAW)
	assert_false(scene.pile_viewer.is_open())


func test_pile_click_before_setup_is_ignored() -> void:
	_scene = BattleScene.new()
	_scene._on_pile_clicked(Deck.DRAW)
	_scene._on_potion_slot_clicked(0)
	assert_false(_scene.pile_viewer.is_open())


## --- Tooltip ---

func test_hovering_a_relic_shows_its_tooltip_and_leaving_hides_it() -> void:
	var controller := Hud.controller([], [&"anchor"])
	var scene := _scene_for(controller)
	scene.relic_bar_ui.icon_uis[0].mouse_entered.emit()
	assert_true(scene.tooltip_ui.visible)
	assert_eq(scene.tooltip_ui.title_label.text, controller.relics[0].display_name)
	scene.relic_bar_ui.icon_uis[0].mouse_exited.emit()
	assert_false(scene.tooltip_ui.visible)


func test_hovering_a_potion_shows_its_tooltip() -> void:
	var scene := _scene_for(Hud.controller([&"fire_potion"]))
	_slot(scene, 0).mouse_entered.emit()
	assert_true(scene.tooltip_ui.visible)
	assert_eq(scene.tooltip_ui.title_label.text, "Fire Potion")
	_slot(scene, 2).mouse_entered.emit()
	assert_false(scene.tooltip_ui.visible, "ô trống: không có tooltip")


func test_using_the_hovered_potion_hides_its_tooltip() -> void:
	var scene := _scene_for(Hud.controller([&"block_potion"]))
	_slot(scene, 0).mouse_entered.emit()
	_slot(scene, 0).pressed.emit()
	assert_false(scene.tooltip_ui.visible)


func test_hovering_a_card_with_keywords_shows_the_glossary_only() -> void:
	var scene := _scene_for(Hud.controller())
	var bash := CardInstance.create(_cards.get_card(&"bash"))
	scene.hand_ui.card_hovered.emit(bash, Rect2(300, 600, 220, 300))
	assert_true(scene.tooltip_ui.visible)
	assert_eq(scene.tooltip_ui.entries_box.get_child_count(), 1)
	assert_false(scene.tooltip_ui.title_label.visible)
	scene.hand_ui.card_hover_ended.emit()
	assert_false(scene.tooltip_ui.visible)


func test_hovering_a_card_without_keywords_shows_nothing() -> void:
	var scene := _scene_for(Hud.controller())
	scene.hand_ui.card_hovered.emit(CardInstance.create(_cards.get_card(&"strike")), Rect2(300, 600, 220, 300))
	assert_false(scene.tooltip_ui.visible)


func test_hovering_a_status_on_the_hero_shows_the_status_tooltip() -> void:
	var controller := Hud.controller([&"strength_potion"])
	var scene := _scene_for(controller)
	controller.use_potion(0)
	var icon := scene.hero_ui.status_row.get_child(0) as StatusIconUI
	icon.mouse_entered.emit()
	assert_true(scene.tooltip_ui.visible)
	assert_eq(scene.tooltip_ui.title_label.text, "Strength")


func test_tooltips_are_suppressed_while_dragging_and_a_drag_hides_the_current_one() -> void:
	var controller := Hud.controller([], [&"anchor"])
	var scene := _scene_for(controller)
	scene.relic_bar_ui.icon_uis[0].mouse_entered.emit()
	assert_true(scene.tooltip_ui.visible)
	var card := controller.deck.get_pile(Deck.HAND)[0]
	scene._on_drag_started(card, Vector2(500, 300))
	assert_true(scene.is_dragging())
	assert_false(scene.tooltip_ui.visible, "bắt đầu kéo thì tooltip tắt")
	scene.relic_bar_ui.icon_uis[0].mouse_entered.emit()
	assert_false(scene.tooltip_ui.visible, "đang kéo thì không hiện")
	scene.hand_ui.cancel_drag()


func test_tooltips_are_suppressed_while_the_pile_is_open_and_opening_hides_the_current_one() -> void:
	var controller := Hud.controller([], [&"anchor"])
	var scene := _scene_for(controller)
	scene.relic_bar_ui.icon_uis[0].mouse_entered.emit()
	scene.draw_counter.clicked.emit(Deck.DRAW)
	assert_false(scene.tooltip_ui.visible)
	scene.relic_bar_ui.icon_uis[0].mouse_entered.emit()
	assert_false(scene.tooltip_ui.visible)


## --- Vòng đời ---

func _hud_connection_count(controller: BattleController) -> int:
	return controller.potions.changed.get_connections().size() + controller.get_signal_connection_list("potion_used").size()


func test_teardown_disconnects_and_cleans_everything() -> void:
	var controller := Hud.controller([&"fire_potion"], [&"anchor"], 2)
	var scene := _scene_for(controller)
	assert_eq(_hud_connection_count(controller), 2, "belt.changed + potion_used")
	_slot(scene, 0).pressed.emit()
	scene.relic_bar_ui.icon_uis[0].mouse_entered.emit()
	scene.teardown()
	assert_eq(_hud_connection_count(controller), 0)
	assert_eq(scene.potion_belt_ui.slot_uis.size(), 0)
	assert_eq(scene.relic_bar_ui.icon_uis.size(), 0)
	assert_false(scene.potion_intent.is_targeting())
	assert_false(scene.tooltip_ui.visible)
	assert_false(scene.pile_viewer.is_open())
	scene.teardown()  # lần hai vẫn an toàn


func test_teardown_closes_an_open_pile() -> void:
	var scene := _scene_for(Hud.controller())
	scene.draw_counter.clicked.emit(Deck.DRAW)
	scene.teardown()
	assert_false(scene.pile_viewer.is_open())


func test_setup_with_a_new_battle_rebinds_the_hud_and_ignores_the_old_one() -> void:
	var old_controller := Hud.controller([&"fire_potion"], [&"anchor"])
	var new_controller := Hud.controller([&"block_potion"], [&"vajra", &"lantern"])
	var scene := _scene_for(old_controller)
	scene.setup(new_controller)
	assert_eq(_hud_connection_count(old_controller), 0)
	assert_eq(scene.relic_bar_ui.icon_uis.size(), 2)
	assert_eq(_slot(scene, 0).view.potion_id, &"block_potion")
	old_controller.use_potion(0, old_controller.enemies[0])
	assert_eq(_slot(scene, 0).view.potion_id, &"block_potion", "trận cũ chạy tiếp không ảnh hưởng")


func test_repeated_setup_does_not_leak_nodes() -> void:
	var scene := _scene_for(Hud.controller([&"fire_potion"], [&"anchor"]))
	scene.setup(Hud.controller([&"fire_potion"], [&"anchor"]))
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 4:
		scene.setup(Hud.controller([&"fire_potion"], [&"anchor"]))
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)
