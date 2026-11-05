extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const Outcome := PlayIntent.Outcome
const SCREEN := Vector2(1920, 1080)


func _started(enemy_count: int) -> BattleController:
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(&"dummy", 20, 6))
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func _aoe() -> CardInstance:
	var effects: Array[EffectData] = [Factory.damage_effect(5)]
	return Factory.card_inst(&"aoe", effects, CardData.TargetMode.ALL_ENEMIES)


## --- Thẻ nhắm một quái ---

func test_dropping_on_a_living_enemy_plays_on_that_enemy() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	for in_zone in [true, false]:
		var decision := DropIntent.decide(card, controller.enemies[1], in_zone, controller)
		assert_eq(decision.outcome, Outcome.PLAY_NOW)
		assert_eq(decision.target, controller.enemies[1])
		assert_eq(decision.card, card)


func test_dropping_on_nothing_with_several_enemies_cancels() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	for in_zone in [true, false]:
		assert_eq(DropIntent.decide(card, null, in_zone, controller).outcome, Outcome.CANCELLED)


func test_single_living_enemy_is_targeted_automatically_inside_the_zone_only() -> void:
	var controller := _started(2)
	controller.enemies[0].combatant.take_damage(999)
	var card := Factory.inject(controller, Factory.strike())
	var inside := DropIntent.decide(card, null, true, controller)
	assert_eq(inside.outcome, Outcome.PLAY_NOW)
	assert_eq(inside.target, controller.enemies[1])
	assert_eq(DropIntent.decide(card, null, false, controller).outcome, Outcome.CANCELLED, "ngoài vùng thả thì huỷ")


func test_a_stale_dead_enemy_under_the_pointer_is_an_invalid_target() -> void:
	var controller := _started(3)
	var card := Factory.inject(controller, Factory.strike())
	controller.enemies[0].combatant.take_damage(999)
	var decision := DropIntent.decide(card, controller.enemies[0], true, controller)
	assert_eq(decision.outcome, Outcome.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_INVALID_TARGET)


## --- Thẻ không nhắm ---

func test_self_card_plays_only_inside_the_zone() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.defend())
	var inside := DropIntent.decide(card, null, true, controller)
	assert_eq(inside.outcome, Outcome.PLAY_NOW)
	assert_true(inside.target == null)
	assert_eq(DropIntent.decide(card, null, false, controller).outcome, Outcome.CANCELLED)


func test_all_enemies_card_plays_only_inside_the_zone() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, _aoe())
	assert_eq(DropIntent.decide(card, null, true, controller).outcome, Outcome.PLAY_NOW)
	assert_eq(DropIntent.decide(card, null, false, controller).outcome, Outcome.CANCELLED)


func test_dropping_a_self_card_on_an_enemy_still_needs_the_zone() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.defend())
	var decision := DropIntent.decide(card, controller.enemies[0], false, controller)
	assert_eq(decision.outcome, Outcome.CANCELLED, "thẻ không nhắm không dùng quái làm mục tiêu")


## --- Từ chối (luôn hỏi controller trước) ---

func test_unaffordable_card_is_rejected_wherever_it_is_dropped() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	for in_zone in [true, false]:
		var decision := DropIntent.decide(card, controller.enemies[0], in_zone, controller)
		assert_eq(decision.outcome, Outcome.REJECTED)
		assert_eq(decision.reason, BattleController.REASON_NOT_ENOUGH_ENERGY)


func test_a_card_no_longer_in_hand_is_rejected() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	controller.deck.discard_card(card)
	var decision := DropIntent.decide(card, controller.enemies[0], true, controller)
	assert_eq(decision.reason, BattleController.REASON_CARD_NOT_IN_HAND)


func test_deciding_changes_nothing() -> void:
	var controller := _started(2)
	var card := Factory.inject(controller, Factory.strike())
	var energy := controller.energy
	var hand := controller.deck.count(Deck.HAND)
	DropIntent.decide(card, controller.enemies[0], true, controller)
	assert_eq(controller.energy, energy)
	assert_eq(controller.deck.count(Deck.HAND), hand)
	assert_eq(controller.enemies[0].combatant.hp, 20)


## --- Vùng thả ---

func test_play_zone_is_the_top_part_of_the_screen() -> void:
	var zone := DropIntent.play_zone(SCREEN)
	assert_eq(zone.position, Vector2.ZERO)
	assert_eq(zone.size.x, SCREEN.x)
	assert_almost_eq(zone.size.y, SCREEN.y * DropIntent.PLAY_ZONE_HEIGHT_RATIO, 0.01)
	assert_true(DropIntent.is_in_play_zone(Vector2(960, 100), SCREEN))
	assert_true(DropIntent.is_in_play_zone(Vector2(0, 0), SCREEN))
	assert_false(DropIntent.is_in_play_zone(Vector2(960, zone.size.y), SCREEN), "mép dưới nằm ngoài")
	assert_false(DropIntent.is_in_play_zone(Vector2(960, 900), SCREEN), "vùng tay bài")
	assert_false(DropIntent.is_in_play_zone(Vector2(-1, 100), SCREEN))


func test_play_zone_ends_before_the_hand_starts() -> void:
	assert_true(DropIntent.play_zone(SCREEN).end.y <= BattleScene.HAND_POSITION.y)


## --- Mục tiêu đang trỏ tới ---

func test_hover_target_is_a_valid_single_target_only() -> void:
	var controller := _started(2)
	var strike := Factory.inject(controller, Factory.strike())
	assert_eq(DropIntent.hover_target(strike, controller.enemies[1], controller), controller.enemies[1])
	assert_true(DropIntent.hover_target(strike, null, controller) == null)
	assert_true(DropIntent.hover_target(null, controller.enemies[1], controller) == null)
	var defend := Factory.inject(controller, Factory.defend())
	assert_true(DropIntent.hover_target(defend, controller.enemies[1], controller) == null, "thẻ không nhắm")
	assert_true(DropIntent.hover_target(Factory.inject(controller, _aoe()), controller.enemies[1], controller) == null)
	controller.enemies[0].combatant.take_damage(999)
	assert_true(DropIntent.hover_target(strike, controller.enemies[0], controller) == null, "quái chết")
