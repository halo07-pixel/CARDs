extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const Outcome := PlayIntent.Outcome

var _intent: PlayIntent


func before_each() -> void:
	_intent = PlayIntent.new()


func _started(enemy_count: int) -> BattleController:
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(&"dummy", 20, 6))
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func test_card_without_target_plays_now() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.defend())
	var decision := _intent.select_card(card, controller)
	assert_eq(decision.outcome, Outcome.PLAY_NOW)
	assert_eq(decision.card, card)
	assert_true(decision.target == null)
	assert_false(_intent.is_targeting())


func test_single_target_card_auto_targets_the_only_living_enemy() -> void:
	var controller := _started(1)
	var card := Factory.inject(controller, Factory.strike())
	var decision := _intent.select_card(card, controller)
	assert_eq(decision.outcome, Outcome.PLAY_NOW)
	assert_eq(decision.target, controller.enemies[0])
	assert_false(_intent.is_targeting())


func test_auto_target_counts_only_living_enemies() -> void:
	var controller := _started(2)
	controller.enemies[0].combatant.take_damage(999)
	var card := Factory.inject(controller, Factory.strike())
	var decision := _intent.select_card(card, controller)
	assert_eq(decision.outcome, Outcome.PLAY_NOW)
	assert_eq(decision.target, controller.enemies[1])


func test_single_target_card_with_several_enemies_waits_for_a_target() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	var decision := _intent.select_card(card, controller)
	assert_eq(decision.outcome, Outcome.NEED_TARGET)
	assert_true(_intent.is_targeting())
	assert_eq(_intent.selected, card)


func test_choosing_a_valid_target_plays_and_clears_the_selection() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	_intent.select_card(card, controller)
	var decision := _intent.choose_target(controller.enemies[1], controller)
	assert_eq(decision.outcome, Outcome.PLAY_NOW)
	assert_eq(decision.card, card)
	assert_eq(decision.target, controller.enemies[1])
	assert_false(_intent.is_targeting())


func test_choosing_a_dead_enemy_is_rejected_and_keeps_the_selection() -> void:
	var controller := _started(3)
	var card := Factory.inject(controller, Factory.strike())
	_intent.select_card(card, controller)
	controller.enemies[0].combatant.take_damage(999)
	var decision := _intent.choose_target(controller.enemies[0], controller)
	assert_eq(decision.outcome, Outcome.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_INVALID_TARGET)
	assert_eq(_intent.selected, card, "vẫn chờ chọn lại mục tiêu")


func test_choosing_a_target_without_a_selection_does_nothing() -> void:
	var controller := _started(2)
	assert_eq(_intent.choose_target(controller.enemies[0], controller).outcome, Outcome.NOTHING)


func test_selecting_the_same_card_again_cancels() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	_intent.select_card(card, controller)
	var decision := _intent.select_card(card, controller)
	assert_eq(decision.outcome, Outcome.CANCELLED)
	assert_false(_intent.is_targeting())


func test_cancel_reports_whether_something_was_selected() -> void:
	var controller := _started(2)
	assert_false(_intent.cancel())
	_intent.select_card(Factory.inject(controller, Factory.strike()), controller)
	assert_true(_intent.cancel())
	assert_false(_intent.is_targeting())


func test_unaffordable_card_is_rejected_with_the_controllers_reason() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	var decision := _intent.select_card(card, controller)
	assert_eq(decision.outcome, Outcome.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_NOT_ENOUGH_ENERGY)


func test_card_outside_the_hand_is_rejected() -> void:
	var controller := _started(2)
	var decision := _intent.select_card(Factory.strike(), controller)
	assert_eq(decision.reason, BattleController.REASON_CARD_NOT_IN_HAND)
	assert_eq(_intent.select_card(null, controller).reason, BattleController.REASON_CARD_NOT_IN_HAND)


func test_a_rejected_card_does_not_drop_the_current_selection() -> void:
	var controller := _started(2)
	var first := Factory.inject(controller, Factory.strike(&"first"))
	_intent.select_card(first, controller)
	var big := Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	assert_eq(_intent.select_card(big, controller).outcome, Outcome.REJECTED)
	assert_eq(_intent.selected, first)


func test_selecting_another_targeted_card_replaces_the_selection() -> void:
	var controller := _started(2)
	var first := Factory.inject(controller, Factory.strike(&"first"))
	var second := Factory.inject(controller, Factory.strike(&"second"))
	_intent.select_card(first, controller)
	assert_eq(_intent.select_card(second, controller).outcome, Outcome.NEED_TARGET)
	assert_eq(_intent.selected, second)


func test_playing_a_card_without_target_drops_the_selection() -> void:
	var controller := _started(2)
	_intent.select_card(Factory.inject(controller, Factory.strike()), controller)
	var decision := _intent.select_card(Factory.inject(controller, Factory.defend()), controller)
	assert_eq(decision.outcome, Outcome.PLAY_NOW)
	assert_false(_intent.is_targeting())


func test_sync_drops_a_selection_that_is_no_longer_playable() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	_intent.select_card(card, controller)
	assert_false(_intent.sync(controller), "còn chơi được thì giữ nguyên")
	controller.deck.discard_card(card)
	assert_true(_intent.sync(controller))
	assert_false(_intent.is_targeting())


func test_choosing_a_target_rechecks_that_the_card_is_still_playable() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	_intent.select_card(card, controller)
	controller.deck.discard_card(card)
	var decision := _intent.choose_target(controller.enemies[0], controller)
	assert_eq(decision.outcome, Outcome.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_CARD_NOT_IN_HAND)
	assert_false(_intent.is_targeting(), "thẻ đã mất thì bỏ chọn")
