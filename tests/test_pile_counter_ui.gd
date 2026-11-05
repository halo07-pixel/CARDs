extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func _started() -> BattleController:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"dummy", 40, 6)]
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func _counter(pile: StringName, controller: BattleController) -> PileCounterUI:
	var counter := PileCounterUI.new(pile)
	counter.bind(controller.deck)
	return counter


func test_titles_and_initial_counts() -> void:
	var controller := _started()
	var draw := _counter(Deck.DRAW, controller)
	var discard := _counter(Deck.DISCARD, controller)
	var exhaust := _counter(Deck.EXHAUST, controller)
	assert_eq(draw.title_label.text, "Draw")
	assert_eq(draw.count_label.text, "5", "10 thẻ, rút 5 vào tay")
	assert_eq(discard.count_label.text, "0")
	assert_eq(exhaust.title_label.text, "Exhaust")
	for counter in [draw, discard, exhaust]:
		counter.free()


func test_counts_follow_playing_discarding_and_exhausting() -> void:
	var controller := _started()
	var draw := _counter(Deck.DRAW, controller)
	var discard := _counter(Deck.DISCARD, controller)
	var exhaust := _counter(Deck.EXHAUST, controller)
	var played := Factory.inject(controller, Factory.strike())
	assert_true(controller.play_card(played, controller.enemies[0]))
	assert_eq(discard.count_label.text, "1", "thẻ đã chơi vào pile bỏ")
	var burned := Factory.inject(controller, Factory.strike(&"burn"))
	controller.deck.exhaust_card(burned)
	assert_eq(exhaust.count_label.text, "1")
	controller.end_player_turn()
	assert_eq(draw.count_label.text, str(controller.deck.count(Deck.DRAW)))
	assert_eq(discard.count_label.text, str(controller.deck.count(Deck.DISCARD)))
	for counter in [draw, discard, exhaust]:
		counter.free()


func test_each_counter_only_listens_to_its_own_pile() -> void:
	var controller := _started()
	var exhaust := _counter(Deck.EXHAUST, controller)
	var played := Factory.inject(controller, Factory.strike())
	controller.play_card(played, controller.enemies[0])
	assert_eq(exhaust.count_label.text, "0")
	exhaust.free()


func test_unbind_and_rebind_leave_no_connections() -> void:
	var old_controller := _started()
	var new_controller := _started()
	var counter := _counter(Deck.DRAW, old_controller)
	counter.bind(new_controller.deck)
	assert_eq(old_controller.deck.pile_changed.get_connections().size(), 0)
	counter.unbind()
	assert_eq(new_controller.deck.pile_changed.get_connections().size(), 0)
	counter.free()


func test_binding_null_keeps_the_current_deck() -> void:
	var controller := _started()
	var counter := _counter(Deck.DRAW, controller)
	counter.bind(null)
	assert_eq(counter.deck, controller.deck)
	counter.free()
