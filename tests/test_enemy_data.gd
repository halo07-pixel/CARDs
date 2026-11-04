extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const ENEMY_DIR := "res://data/enemies"
const P := EnemyData.PatternKind


func _simple() -> EnemyData:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"hit", 6), Factory.block_move(&"guard", 5)]
	return Factory.enemy(&"dummy", 20, moves)


func test_simple_enemy_is_valid() -> void:
	assert_eq(_simple().validate(), [] as Array[String])


func test_basic_field_rules() -> void:
	var no_moves: Array[EnemyMove] = []
	assert_false(Factory.enemy(&"", 20, no_moves).validate().is_empty())
	var data := _simple()
	data.max_hp = 0
	assert_false(data.validate().is_empty())
	data = _simple()
	data.display_name = "  "
	assert_false(data.validate().is_empty())
	assert_false(Factory.enemy(&"nomoves", 20, no_moves).validate().is_empty())


func test_duplicate_move_ids_and_null_move_are_invalid() -> void:
	var dup: Array[EnemyMove] = [Factory.attack_move(&"hit", 6), Factory.attack_move(&"hit", 9)]
	assert_false(Factory.enemy(&"d", 20, dup).validate().is_empty())
	var with_null: Array[EnemyMove] = [null]
	assert_false(Factory.enemy(&"n", 20, with_null).validate().is_empty())


func test_invalid_move_is_reported_with_context() -> void:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"bad", 0)]
	var errors := Factory.enemy(&"e", 20, moves).validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("moves[0]"))


func test_opening_move_must_exist() -> void:
	var data := _simple()
	data.opening_move_id = &"missing"
	assert_false(data.validate().is_empty())
	data.opening_move_id = &"guard"
	assert_true(data.validate().is_empty())


func test_sequence_rules() -> void:
	var data := _simple()
	var order: Array[StringName] = [&"hit", &"hit", &"guard"]
	data.sequence = order
	assert_true(data.validate().is_empty(), "sequence được phép lặp chiêu")
	var bad_order: Array[StringName] = [&"hit", &"nope"]
	data.sequence = bad_order
	assert_false(data.validate().is_empty(), "sequence trỏ chiêu không tồn tại")
	data.sequence = order
	data.pattern = P.WEIGHTED
	assert_false(data.validate().is_empty(), "WEIGHTED không dùng sequence")


func test_get_sequence_defaults_to_move_order() -> void:
	assert_eq(_simple().get_sequence(), [&"hit", &"guard"] as Array[StringName])
	var data := _simple()
	data.sequence = [&"guard", &"guard", &"hit"] as Array[StringName]
	assert_eq(data.get_sequence(), [&"guard", &"guard", &"hit"] as Array[StringName])


func test_find_move() -> void:
	var data := _simple()
	assert_eq(data.find_move(&"guard").id, &"guard")
	assert_true(data.find_move(&"nope") == null)


func test_registry_loads_valid_starter_enemies() -> void:
	var registry := EnemyRegistry.load_from_dir(ENEMY_DIR)
	assert_eq(registry.size(), 5, "phải nạp đủ 5 quái mẫu (file lỗi/trùng id bị loại)")
	for enemy_id in [&"slime", &"goblin", &"acolyte", &"spiker", &"toxic_slug"]:
		assert_true(registry.has_enemy(enemy_id), String(enemy_id))
		assert_eq(registry.get_enemy(enemy_id).validate(), [] as Array[String], String(enemy_id))
	assert_eq(registry.get_enemy(&"slime").max_hp, 22)
	assert_eq(registry.get_enemy(&"slime").pattern, P.WEIGHTED)
	assert_eq(registry.get_enemy(&"acolyte").get_sequence(), [&"ritual", &"slash", &"slash"] as Array[StringName])


func test_registry_rejects_wrong_type_duplicate_invalid_and_null() -> void:
	var registry := EnemyRegistry.new()
	assert_true(registry.register(_simple()))
	assert_false(registry.register(_simple()), "trùng id")
	assert_false(registry.register(EnemyData.new()), "không hợp lệ")
	assert_false(registry.register(Factory.weak()), "sai kiểu tài nguyên (StatusData)")
	assert_false(registry.register(null))
	assert_eq(registry.size(), 1)
	assert_true(registry.get_enemy(&"nope") == null)
