extends "res://tests/test_case.gd"
## PotionView: dữ liệu hiển thị từng ô potion; "usable" do controller quyết định.

const Factory := preload("res://tests/combat_factory.gd")

var _potions: PotionRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_potions = PotionRegistry.load_from_dir("res://data/potions")
	_statuses = Factory.registry()


func _battle(potion_ids: Array, start: bool = true, capacity: int = 3) -> BattleController:
	var ids: Array[StringName] = []
	ids.assign(potion_ids)
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 30, 1), Factory.dummy_enemy(&"b", 30, 1)]
	var controller := BattleController.create_from_data(Factory.combatant(&"player", 80), Factory.fillers(10),
			datas, _statuses, 1, null, [] as Array[RelicData], PotionBelt.from_ids(ids, _potions, capacity))
	if start:
		controller.start_battle()
	return controller


func test_build_all_gives_one_view_per_slot_including_empty_ones() -> void:
	var views := PotionView.build_all(_battle([&"fire_potion", &"block_potion"]))
	assert_eq(views.size(), 3)
	assert_false(views[0].is_empty)
	assert_false(views[1].is_empty)
	assert_true(views[2].is_empty)
	assert_false(views[2].usable, "ô trống không dùng được")
	for i in views.size():
		assert_eq(views[i].slot, i)


func test_slot_count_follows_belt_capacity() -> void:
	assert_eq(PotionView.build_all(_battle([&"fire_potion"], true, 5)).size(), 5)


func test_filled_slot_copies_potion_data() -> void:
	var view := PotionView.build(0, _battle([&"fire_potion"]))
	var data := _potions.get_potion(&"fire_potion")
	assert_eq(view.potion_id, &"fire_potion")
	assert_eq(view.title, data.display_name)
	assert_eq(view.description, data.description)
	assert_eq(view.icon_id, data.icon_id)
	assert_eq(view.rarity, data.rarity)


func test_needs_target_only_for_single_enemy_potions() -> void:
	var views := PotionView.build_all(_battle([&"fire_potion", &"block_potion", &"explosive_potion"]))
	assert_true(views[0].needs_target)
	assert_false(views[1].needs_target)
	assert_false(views[2].needs_target)


func test_usable_during_the_player_turn() -> void:
	for view in PotionView.build_all(_battle([&"fire_potion", &"block_potion", &"weak_potion"])):
		assert_true(view.usable, "ô %d" % view.slot)


func test_not_usable_before_the_battle_starts() -> void:
	var views := PotionView.build_all(_battle([&"fire_potion", &"block_potion"], false))
	assert_false(views[0].usable)
	assert_false(views[1].usable)


func test_single_target_potion_not_usable_when_no_enemy_is_alive() -> void:
	var controller := _battle([&"fire_potion", &"block_potion"])
	for unit in controller.enemies:
		unit.combatant.take_damage(999)
	var views := PotionView.build_all(controller)
	assert_false(views[0].usable)
	assert_true(views[1].usable)


func test_view_follows_the_belt_after_a_potion_is_used() -> void:
	var controller := _battle([&"block_potion", &"fire_potion"])
	controller.use_potion(0)
	var views := PotionView.build_all(controller)
	assert_true(views[0].is_empty)
	assert_eq(views[1].potion_id, &"fire_potion")


func test_missing_controller_gives_null_and_empty_list() -> void:
	assert_true(PotionView.build(0, null) == null)
	assert_eq(PotionView.build_all(null).size(), 0)
