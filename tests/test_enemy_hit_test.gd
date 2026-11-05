extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _uis: Array[EnemyUI] = []


func after_each() -> void:
	for enemy_ui in _uis:
		enemy_ui.free()
	_uis.clear()


## Hai quái giả; mỗi EnemyUI đặt cạnh nhau, đủ kích thước tối thiểu.
func _setup() -> BattleController:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 20, 6), Factory.dummy_enemy(&"b", 20, 6)]
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	for i in controller.enemies.size():
		var enemy_ui := EnemyUI.new()
		enemy_ui.bind(controller.enemies[i])
		Engine.get_main_loop().root.add_child(enemy_ui)
		enemy_ui.position = Vector2(100 + 400 * i, 50)
		enemy_ui.size = enemy_ui.get_combined_minimum_size()
		_uis.append(enemy_ui)
	return controller


func test_a_point_inside_an_enemy_finds_it() -> void:
	var controller := _setup()
	for i in 2:
		var inside := _uis[i].get_global_rect().get_center()
		assert_eq(EnemyHitTest.unit_at(inside, _uis), controller.enemies[i])


func test_a_point_outside_every_enemy_finds_nothing() -> void:
	_setup()
	assert_true(EnemyHitTest.unit_at(Vector2(5, 5), _uis) == null)
	assert_true(EnemyHitTest.unit_at(Vector2(350, 300), _uis) == null, "khoảng trống giữa hai quái")


func test_a_dead_enemy_is_never_hit() -> void:
	var controller := _setup()
	controller.enemies[0].combatant.take_damage(999)
	assert_true(EnemyHitTest.unit_at(_uis[0].get_global_rect().get_center(), _uis) == null)
	assert_eq(EnemyHitTest.unit_at(_uis[1].get_global_rect().get_center(), _uis), controller.enemies[1])


func test_empty_list_finds_nothing() -> void:
	var none: Array[EnemyUI] = []
	assert_true(EnemyHitTest.unit_at(Vector2(100, 100), none) == null)
