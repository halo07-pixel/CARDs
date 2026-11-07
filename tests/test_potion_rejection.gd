extends "res://tests/test_case.gd"
## BattleController.potion_rejection_reason / valid_potion_targets: hỏi trước khi dùng potion.
## Quan trọng nhất: câu trả lời của việc HỎI phải khớp đúng lý do use_potion từ chối (không lệch luật).

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")

var _potions: PotionRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_potions = PotionRegistry.load_from_dir("res://data/potions")
	_statuses = Factory.registry()


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


func test_usable_potions_have_no_rejection_reason() -> void:
	var controller := _battle([&"fire_potion", &"block_potion", &"explosive_potion"])
	assert_eq(controller.potion_rejection_reason(0, controller.enemies[0]), &"", "nhắm một quái + có mục tiêu")
	assert_eq(controller.potion_rejection_reason(1), &"", "potion SELF không cần mục tiêu")
	assert_eq(controller.potion_rejection_reason(2), &"", "potion đánh tất cả không cần mục tiêu")


func test_single_target_potion_needs_a_living_target_that_belongs_to_this_battle() -> void:
	var controller := _battle([&"fire_potion"])
	assert_eq(controller.potion_rejection_reason(0), BattleController.REASON_INVALID_TARGET, "thiếu mục tiêu")
	var stranger := EnemyUnit.create(Factory.dummy_enemy(&"stranger"), Factory.rng())
	assert_eq(controller.potion_rejection_reason(0, stranger), BattleController.REASON_INVALID_TARGET, "quái ngoài trận")
	controller.enemies[1].combatant.take_damage(999)
	assert_eq(controller.potion_rejection_reason(0, controller.enemies[1]), BattleController.REASON_INVALID_TARGET, "quái đã chết")
	assert_eq(controller.potion_rejection_reason(0, controller.enemies[0]), &"")


func test_empty_or_out_of_range_slot_is_no_potion() -> void:
	var controller := _battle([&"fire_potion"])
	for slot in [1, 2, -1, 3, 99]:
		assert_eq(controller.potion_rejection_reason(slot), BattleController.REASON_NO_POTION, "slot %d" % slot)


func test_not_player_turn_before_the_battle_starts() -> void:
	var controller := _battle([&"block_potion"], 1, false)
	assert_eq(controller.potion_rejection_reason(0), BattleController.REASON_NOT_PLAYER_TURN)


func test_battle_over_takes_priority() -> void:
	var controller := _battle([&"block_potion", &"fire_potion"], 1)
	controller.enemies[0].combatant.take_damage(999)
	assert_true(controller.use_potion(0), "dùng potion là một hành động: controller kiểm tra thắng/thua sau đó")
	assert_eq(controller.state.phase, BattleState.Phase.VICTORY)
	assert_eq(controller.potion_rejection_reason(1, controller.enemies[0]), BattleController.REASON_BATTLE_OVER)


func test_asking_changes_nothing() -> void:
	var controller := _battle([&"fire_potion", &"block_potion"])
	var rec := Recorder.new(controller)
	for slot in [0, 1, 2, 9]:
		controller.potion_rejection_reason(slot, controller.enemies[0])
		controller.valid_potion_targets(slot)
	assert_eq(controller.potions.count(), 2)
	assert_eq(controller.energy, 3)
	assert_eq(rec.events.size(), 0, "hỏi không phát signal nào")


func test_reason_matches_what_use_potion_actually_rejects() -> void:
	var cases: Array = []
	for slot in [0, 1, 2, -1, 7]:
		cases.append([slot, false])
		cases.append([slot, true])
	for case: Array in cases:
		var controller := _battle([&"fire_potion", &"block_potion"])
		var rec := Recorder.new(controller)
		var target: EnemyUnit = controller.enemies[0] if case[1] else null
		var expected := controller.potion_rejection_reason(case[0], target)
		var used := controller.use_potion(case[0], target)
		assert_eq(used, expected == &"", "slot %d target %s: dùng được <=> không có lý do" % [case[0], case[1]])
		if expected != &"":
			assert_eq(rec.last_rejection(), String(expected), "lý do bị từ chối khớp lý do đã hỏi")
			assert_eq(controller.potions.count(), 2, "bị từ chối thì không mất potion")


func test_reason_matches_use_potion_outside_the_player_turn_and_after_the_end() -> void:
	var controller := _battle([&"block_potion"], 1, false)
	var rec := Recorder.new(controller)
	var expected := controller.potion_rejection_reason(0)
	assert_false(controller.use_potion(0))
	assert_eq(rec.last_rejection(), String(expected))
	assert_eq(controller.potions.count(), 1)


func test_valid_potion_targets_are_the_living_enemies_for_single_target_potions_only() -> void:
	var controller := _battle([&"fire_potion", &"block_potion", &"explosive_potion"], 3)
	assert_eq(controller.valid_potion_targets(0).size(), 3)
	controller.enemies[1].combatant.take_damage(999)
	var targets := controller.valid_potion_targets(0)
	assert_eq(targets.size(), 2)
	assert_false(targets.has(controller.enemies[1]), "quái đã chết bị loại")
	assert_eq(controller.valid_potion_targets(1).size(), 0, "SELF không cần mục tiêu")
	assert_eq(controller.valid_potion_targets(2).size(), 0, "đánh tất cả không cần mục tiêu")
	assert_eq(controller.valid_potion_targets(5).size(), 0, "ô không tồn tại")
