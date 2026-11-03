extends "res://tests/test_case.gd"

var _registry: PotionRegistry


func before_each() -> void:
	_registry = PotionRegistry.load_from_dir("res://data/potions")


func _potion(id: StringName) -> PotionData:
	return _registry.get_potion(id)


func test_new_belt_is_empty_with_three_slots() -> void:
	var belt := PotionBelt.new()
	assert_eq(belt.capacity, 3)
	assert_eq(belt.count(), 0)
	assert_false(belt.is_full())
	assert_eq(belt.first_free_slot(), 0)
	assert_eq(PotionBelt.new(0).capacity, 1, "ít nhất một ô")


func test_add_fills_slots_in_order_then_refuses_when_full() -> void:
	var belt := PotionBelt.new()
	assert_eq(belt.add(_potion(&"fire_potion")), 0)
	assert_eq(belt.add(_potion(&"block_potion")), 1)
	assert_eq(belt.add(_potion(&"swift_potion")), 2)
	assert_true(belt.is_full())
	assert_eq(belt.first_free_slot(), -1)
	assert_eq(belt.add(_potion(&"weak_potion")), -1, "dây đã đầy")
	assert_eq(belt.count(), 3)
	assert_eq(belt.add(null), -1)


func test_remove_frees_the_slot_and_the_next_add_reuses_it() -> void:
	var belt := PotionBelt.new()
	belt.add(_potion(&"fire_potion"))
	belt.add(_potion(&"block_potion"))
	belt.add(_potion(&"swift_potion"))
	assert_eq(belt.remove_at(1).id, &"block_potion")
	assert_eq(belt.count(), 2)
	assert_true(belt.get_at(1) == null)
	assert_eq(belt.first_free_slot(), 1)
	assert_eq(belt.add(_potion(&"weak_potion")), 1, "dùng lại đúng ô vừa trống")
	assert_eq(belt.to_ids(), [&"fire_potion", &"weak_potion", &"swift_potion"] as Array[StringName])


func test_invalid_or_empty_slots_return_null_without_side_effects() -> void:
	var belt := PotionBelt.new()
	belt.add(_potion(&"fire_potion"))
	for slot in [-1, 1, 2, 3, 99]:
		assert_true(belt.get_at(slot) == null, "get_at(%d)" % slot)
		assert_true(belt.remove_at(slot) == null, "remove_at(%d)" % slot)
	assert_eq(belt.count(), 1)


func test_changed_is_emitted_only_when_something_really_changed() -> void:
	var belt := PotionBelt.new()
	var changes: Array = []
	belt.changed.connect(func() -> void: changes.append(1))
	belt.add(_potion(&"fire_potion"))
	belt.remove_at(2)  # ô trống: không đổi
	belt.remove_at(0)
	belt.add(null)     # bị từ chối
	assert_eq(changes.size(), 2)


func test_to_ids_skips_empty_slots_and_get_all_returns_a_copy() -> void:
	var belt := PotionBelt.new()
	belt.add(_potion(&"fire_potion"))
	belt.add(_potion(&"block_potion"))
	belt.remove_at(0)
	assert_eq(belt.to_ids(), [&"block_potion"] as Array[StringName])
	var copy := belt.get_all()
	assert_eq(copy.size(), 3, "kể cả ô trống")
	copy.clear()
	assert_eq(belt.count(), 1, "sửa bản sao không ảnh hưởng dây")


func test_from_ids_builds_in_order_and_rejects_bad_input() -> void:
	var ids: Array[StringName] = [&"fire_potion", &"energy_potion"]
	var belt := PotionBelt.from_ids(ids, _registry)
	assert_eq(belt.to_ids(), ids)
	var four: Array[StringName] = [&"fire_potion", &"block_potion", &"swift_potion", &"weak_potion"]
	assert_true(PotionBelt.from_ids(four, _registry) == null, "nhiều hơn số ô")
	assert_eq(PotionBelt.from_ids(four, _registry, 4).count(), 4, "đủ ô thì được")
	var ghost: Array[StringName] = [&"ghost"]
	assert_true(PotionBelt.from_ids(ghost, _registry) == null, "id lạ")
	assert_true(PotionBelt.from_ids(ids, null) == null, "thiếu registry")
	var none: Array[StringName] = []
	assert_eq(PotionBelt.from_ids(none, _registry).count(), 0)
