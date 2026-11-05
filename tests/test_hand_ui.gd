extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const UiInput := preload("res://tests/ui_input.gd")


func _started() -> BattleController:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"dummy", 40, 6)]
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func _hand_for(controller: BattleController) -> HandUI:
	var hand := HandUI.new()
	hand.bind(controller)
	return hand


func _connection_count(controller: BattleController) -> int:
	return controller.deck.pile_changed.get_connections().size() + controller.energy_changed.get_connections().size() \
			+ controller.card_played.get_connections().size() + controller.player.status_changed.get_connections().size()


func test_bind_builds_one_card_per_hand_card_in_order() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var cards := controller.deck.get_pile(Deck.HAND)
	assert_eq(hand.card_uis.size(), cards.size())
	assert_eq(hand.card_uis.size(), 5)
	for i in cards.size():
		assert_eq(hand.card_uis[i].view.uid, cards[i].uid)
	hand.free()


func test_unaffordable_card_is_dimmed() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	hand.flush_pending_refresh()
	var dimmed := 0
	for card_ui in hand.card_uis:
		if card_ui.modulate.a < 1.0:
			dimmed += 1
			assert_eq(card_ui.view.card_id, &"big")
	assert_eq(dimmed, 1)
	hand.free()


func test_changes_only_rebuild_at_flush_and_requests_coalesce() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var before := hand.card_uis.size()
	Factory.inject(controller, Factory.strike(&"extra1"))
	Factory.inject(controller, Factory.strike(&"extra2"))
	assert_true(hand.has_pending_refresh())
	assert_eq(hand.card_uis.size(), before, "chưa dựng lại trước khi flush")
	hand.request_refresh()
	hand.request_refresh()
	hand.flush_pending_refresh()
	assert_false(hand.has_pending_refresh())
	assert_eq(hand.card_uis.size(), before + 2)
	hand.free()


func test_playing_a_card_requests_a_refresh() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var card := Factory.inject(controller, Factory.strike())
	hand.flush_pending_refresh()
	assert_false(hand.has_pending_refresh())
	assert_true(controller.play_card(card, controller.enemies[0]))
	assert_true(hand.has_pending_refresh())
	hand.flush_pending_refresh()
	for card_ui in hand.card_uis:
		assert_ne(card_ui.view.uid, card.uid, "thẻ đã chơi không còn trong tay")
	hand.free()


func test_ten_cards_fit_inside_the_width() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	for i in 5:
		Factory.inject(controller, Factory.strike(StringName("x%d" % i)))
	hand.flush_pending_refresh()
	assert_eq(hand.card_uis.size(), Deck.MAX_HAND_SIZE)
	for card_ui in hand.card_uis:
		assert_true(card_ui.position.x >= -0.01, "tràn trái")
		assert_true(card_ui.position.x + card_ui.size.x <= HandUI.WIDTH + 0.01, "tràn phải")
	hand.free()


func test_few_cards_are_centered() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var first := hand.card_uis[0]
	var last := hand.card_uis[hand.card_uis.size() - 1]
	var left_gap := first.position.x
	var right_gap := HandUI.WIDTH - (last.position.x + last.size.x)
	assert_almost_eq(left_gap, right_gap, 0.01)
	hand.free()


func test_selected_card_is_raised_and_highlighted_and_survives_refresh() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var chosen := controller.deck.get_pile(Deck.HAND)[2]
	hand.set_selected(chosen)
	for card_ui in hand.card_uis:
		var is_chosen := card_ui.view.uid == chosen.uid
		assert_eq(card_ui.highlighted, is_chosen)
		assert_almost_eq(card_ui.position.y, 0.0 if is_chosen else HandUI.SELECTED_RAISE, 0.01)
	hand.refresh()
	assert_true(hand.card_uis[2].highlighted, "vẫn được chọn sau khi dựng lại")
	hand.set_selected(null)
	assert_false(hand.card_uis[2].highlighted)
	hand.free()


func test_left_click_reports_the_right_card_and_other_clicks_do_not() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var clicked: Array[CardInstance] = []
	hand.card_clicked.connect(func(card: CardInstance) -> void: clicked.append(card))
	hand.card_uis[2]._gui_input(UiInput.click())
	assert_eq(clicked.size(), 1)
	assert_eq(clicked[0], controller.deck.get_pile(Deck.HAND)[2])
	hand.card_uis[2]._gui_input(UiInput.click(MOUSE_BUTTON_RIGHT))
	assert_eq(clicked.size(), 1, "chuột phải không phải click chơi thẻ")
	hand.free()


func test_hand_ignores_the_mouse_so_empty_space_does_not_block() -> void:
	var hand := HandUI.new()
	assert_eq(hand.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	hand.free()


func test_unbind_and_rebind_leave_no_connections_and_clear_the_hand() -> void:
	var old_controller := _started()
	var new_controller := _started()
	var hand := _hand_for(old_controller)
	assert_eq(_connection_count(old_controller), 4)
	hand.bind(new_controller)
	assert_eq(_connection_count(old_controller), 0, "gắn sang trận khác phải ngắt trận cũ")
	assert_eq(_connection_count(new_controller), 4)
	hand.unbind()
	assert_eq(_connection_count(new_controller), 0)
	assert_eq(hand.card_uis.size(), 0)
	hand.free()


func test_binding_null_keeps_the_current_battle() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	hand.bind(null)
	assert_eq(hand.card_uis.size(), 5)
	assert_eq(_connection_count(controller), 4)
	hand.free()


func test_refreshing_repeatedly_does_not_leak_nodes() -> void:
	var controller := _started()
	var hand := _hand_for(controller)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 6:
		hand.refresh()
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)
	hand.free()
