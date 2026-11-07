extends "res://tests/test_case.gd"
## PotionIntent: máy trạng thái bấm ô potion (dùng ngay / chọn mục tiêu / từ chối / hủy), luôn hỏi controller trước.

const Factory := preload("res://tests/combat_factory.gd")
const O := PotionIntent.Outcome

var _potions: PotionRegistry
var _statuses: StatusRegistry
var _intent: PotionIntent


func before_each() -> void:
	_potions = PotionRegistry.load_from_dir("res://data/potions")
	_statuses = Factory.registry()
	_intent = PotionIntent.new()


func _battle(potion_ids: Array, enemy_count: int = 2, start: bool = true) -> BattleController:
	var ids: Array[StringName] = []
	ids.assign(potion_ids)
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(StringName("e%d" % i), 30, 1))
	var controller := BattleController.create_from_data(Factory.combatant(&"player", 80), Factory.fillers(10),
			datas, _statuses, 1, null, [] as Array[RelicData], PotionBelt.from_ids(ids, _potions))
	if start:
		controller.start_battle()
	return controller


func test_self_potion_is_used_immediately_without_target() -> void:
	var controller := _battle([&"block_potion"])
	var decision := _intent.select_slot(0, controller)
	assert_eq(decision.outcome, O.USE_NOW)
	assert_eq(decision.slot, 0)
	assert_true(decision.target == null)
	assert_false(_intent.is_targeting())


func test_aoe_potion_is_used_immediately() -> void:
	var decision := _intent.select_slot(0, _battle([&"explosive_potion"], 3))
	assert_eq(decision.outcome, O.USE_NOW)
	assert_true(decision.target == null)


func test_single_target_potion_auto_targets_the_only_living_enemy() -> void:
	var controller := _battle([&"fire_potion"], 1)
	var decision := _intent.select_slot(0, controller)
	assert_eq(decision.outcome, O.USE_NOW)
	assert_true(decision.target == controller.enemies[0])
	assert_false(_intent.is_targeting())


func test_single_target_potion_with_two_enemies_waits_for_a_target() -> void:
	var controller := _battle([&"fire_potion"], 2)
	var decision := _intent.select_slot(0, controller)
	assert_eq(decision.outcome, O.NEED_TARGET)
	assert_true(_intent.is_targeting())
	assert_eq(_intent.selected_slot, 0)
	var chosen := _intent.choose_target(controller.enemies[1], controller)
	assert_eq(chosen.outcome, O.USE_NOW)
	assert_eq(chosen.slot, 0)
	assert_true(chosen.target == controller.enemies[1])
	assert_false(_intent.is_targeting(), "chọn xong thì thoát chế độ chọn mục tiêu")


func test_only_one_living_enemy_left_after_a_kill_auto_targets() -> void:
	var controller := _battle([&"fire_potion"], 2)
	controller.enemies[0].combatant.take_damage(999)
	var decision := _intent.select_slot(0, controller)
	assert_eq(decision.outcome, O.USE_NOW)
	assert_true(decision.target == controller.enemies[1])


func test_selecting_the_same_slot_again_cancels() -> void:
	var controller := _battle([&"fire_potion"])
	_intent.select_slot(0, controller)
	var decision := _intent.select_slot(0, controller)
	assert_eq(decision.outcome, O.CANCELLED)
	assert_false(_intent.is_targeting())


func test_rejected_selection_keeps_the_previous_choice() -> void:
	var controller := _battle([&"fire_potion"])
	_intent.select_slot(0, controller)
	var decision := _intent.select_slot(2, controller)
	assert_eq(decision.outcome, O.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_NO_POTION)
	assert_eq(_intent.selected_slot, 0, "bấm nhầm ô trống không làm mất lựa chọn")


func test_empty_slot_is_rejected_with_no_potion() -> void:
	var decision := _intent.select_slot(1, _battle([&"fire_potion"]))
	assert_eq(decision.outcome, O.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_NO_POTION)


func test_not_player_turn_is_rejected_and_nothing_is_selected() -> void:
	var decision := _intent.select_slot(0, _battle([&"fire_potion"], 2, false))
	assert_eq(decision.outcome, O.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_NOT_PLAYER_TURN)
	assert_false(_intent.is_targeting())


func test_choose_target_without_a_selection_does_nothing() -> void:
	var controller := _battle([&"fire_potion"])
	assert_eq(_intent.choose_target(controller.enemies[0], controller).outcome, O.NOTHING)


func test_wrong_target_is_rejected_but_selection_stays() -> void:
	var controller := _battle([&"fire_potion"], 3)
	_intent.select_slot(0, controller)
	controller.enemies[2].combatant.take_damage(999)
	var decision := _intent.choose_target(controller.enemies[2], controller)
	assert_eq(decision.outcome, O.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_INVALID_TARGET)
	assert_true(_intent.is_targeting(), "vẫn còn quái hợp lệ để chọn")
	assert_eq(_intent.choose_target(controller.enemies[0], controller).outcome, O.USE_NOW)


func test_potion_gone_before_choosing_the_target_clears_the_selection() -> void:
	var controller := _battle([&"fire_potion"])
	_intent.select_slot(0, controller)
	controller.potions.remove_at(0)
	var decision := _intent.choose_target(controller.enemies[0], controller)
	assert_eq(decision.outcome, O.REJECTED)
	assert_eq(decision.reason, BattleController.REASON_NO_POTION)
	assert_false(_intent.is_targeting())


func test_cancel_reports_whether_something_was_selected() -> void:
	var controller := _battle([&"fire_potion"])
	assert_false(_intent.cancel())
	_intent.select_slot(0, controller)
	assert_true(_intent.cancel())
	assert_false(_intent.is_targeting())


func test_sync_drops_a_selection_that_is_no_longer_usable() -> void:
	var controller := _battle([&"fire_potion"])
	assert_false(_intent.sync(controller), "không chọn gì thì không có gì để đổi")
	_intent.select_slot(0, controller)
	assert_false(_intent.sync(controller), "vẫn dùng được thì giữ nguyên")
	controller.potions.remove_at(0)
	assert_true(_intent.sync(controller))
	assert_false(_intent.is_targeting())


func test_slot_blocker_for_each_situation() -> void:
	var controller := _battle([&"fire_potion", &"block_potion"], 2)
	assert_eq(PotionIntent.slot_blocker(0, controller), &"", "nhắm một quái: thử với quái sống đầu tiên")
	assert_eq(PotionIntent.slot_blocker(1, controller), &"")
	assert_eq(PotionIntent.slot_blocker(2, controller), BattleController.REASON_NO_POTION)
	for unit in controller.enemies:
		unit.combatant.take_damage(999)
	assert_eq(PotionIntent.slot_blocker(0, controller), BattleController.REASON_INVALID_TARGET, "hết quái sống")
	assert_eq(PotionIntent.slot_blocker(1, controller), &"", "potion SELF không cần quái")
