extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func _started(enemy_hp: int = 20) -> BattleController:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"dummy", enemy_hp, 6)]
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func test_playable_card_has_no_reason() -> void:
	var controller := _started()
	var card := Factory.inject(controller, Factory.strike())
	assert_eq(controller.play_rejection_reason(card), &"")
	assert_true(controller.can_play(card), "nhất quán với can_play")


func test_null_or_foreign_card_is_not_in_hand() -> void:
	var controller := _started()
	assert_eq(controller.play_rejection_reason(null), BattleController.REASON_CARD_NOT_IN_HAND)
	assert_eq(controller.play_rejection_reason(Factory.strike()), BattleController.REASON_CARD_NOT_IN_HAND)


func test_unplayable_card_reason() -> void:
	var controller := _started()
	var card := Factory.inject(controller, Factory.strike(&"curse", 6, {"unplayable": true}))
	assert_eq(controller.play_rejection_reason(card), BattleController.REASON_UNPLAYABLE)


func test_too_expensive_card_reason() -> void:
	var controller := _started()
	var card := Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	assert_eq(controller.play_rejection_reason(card), BattleController.REASON_NOT_ENOUGH_ENERGY)


func test_before_battle_starts_it_is_not_the_players_turn() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy()]
	var controller := Factory.battle(Factory.fillers(10), datas)
	assert_eq(controller.play_rejection_reason(Factory.strike()), BattleController.REASON_NOT_PLAYER_TURN)


func test_after_the_battle_is_over() -> void:
	var controller := _started(1)
	var killer := Factory.inject(controller, Factory.strike(&"killer", 99))
	var spare := Factory.inject(controller, Factory.strike(&"spare", 6))
	assert_true(controller.play_card(killer, controller.enemies[0]))
	assert_eq(controller.play_rejection_reason(spare), BattleController.REASON_BATTLE_OVER)


func test_asking_changes_nothing() -> void:
	var controller := _started()
	var card := Factory.inject(controller, Factory.strike())
	var energy_before := controller.energy
	var hand_before := controller.deck.count(Deck.HAND)
	controller.play_rejection_reason(card)
	assert_eq(controller.energy, energy_before)
	assert_eq(controller.deck.count(Deck.HAND), hand_before)
