extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _statuses: StatusRegistry


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _unit_with(pairs: Dictionary) -> Combatant:
	var unit := Factory.combatant(&"unit", 50)
	for id: StringName in pairs:
		unit.add_status(_statuses.get_status(id), pairs[id])
	return unit


func test_build_copies_status_fields() -> void:
	var view := StatusView.build(_unit_with({&"strength": 3}), &"strength")
	var data := _statuses.get_status(&"strength")
	assert_eq(view.status_id, &"strength")
	assert_eq(view.title, data.display_name)
	assert_eq(view.description, data.description)
	assert_eq(view.amount, 3)
	assert_eq(view.icon_id, data.icon_id)
	assert_false(view.is_debuff)


func test_debuff_flag_comes_from_data() -> void:
	assert_true(StatusView.build(_unit_with({&"weak": 2}), &"weak").is_debuff)


func test_missing_status_gives_null() -> void:
	assert_true(StatusView.build(_unit_with({}), &"strength") == null)


func test_null_owner_gives_null_and_empty_list() -> void:
	assert_true(StatusView.build(null, &"strength") == null)
	assert_eq(StatusView.build_all(null).size(), 0)


func test_negative_stacks_are_shown_as_negative() -> void:
	var view := StatusView.build(_unit_with({&"strength": -2}), &"strength")
	assert_eq(view.amount, -2)


func test_build_all_puts_buffs_first_then_debuffs_each_sorted_by_id() -> void:
	var unit := _unit_with({&"weak": 1, &"strength": 2, &"poison": 3, &"dexterity": 1})
	var ids: Array[StringName] = []
	for view in StatusView.build_all(unit):
		ids.append(view.status_id)
	assert_eq(ids, [&"dexterity", &"strength", &"poison", &"weak"] as Array[StringName])


func test_build_all_of_clean_unit_is_empty() -> void:
	assert_eq(StatusView.build_all(_unit_with({})).size(), 0)


func test_every_real_status_can_be_viewed() -> void:
	for id in _statuses.all_ids():
		var view := StatusView.build(_unit_with({id: 1}), id)
		assert_true(view != null, "status %s" % id)
		assert_false(view.title.is_empty(), "status %s thiếu tên" % id)


func test_build_all_order_is_alphabetical_regardless_of_insertion_order() -> void:
	# Không đưa Artifact vào: nó chặn debuff gắn sau nó nên làm mất status khỏi danh sách (đúng luật lõi).
	var expected: Array[StringName] = [&"barricade", &"dexterity", &"strength", &"thorns", &"frail", &"poison", &"weak"]
	var insertions := [expected.duplicate(), expected.duplicate()]
	insertions[0].reverse()
	insertions[1].shuffle()
	for ids in insertions:
		var unit := Factory.combatant(&"unit", 50)
		for id: StringName in ids:
			unit.add_status(_statuses.get_status(id), 1)
		var actual: Array[StringName] = []
		for view in StatusView.build_all(unit):
			actual.append(view.status_id)
		assert_eq(actual, expected, "thứ tự phải theo chữ cái, không phụ thuộc thứ tự gắn")
