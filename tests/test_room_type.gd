extends "res://tests/test_case.gd"
## RoomType: tên, ký hiệu, loại hiếm.


func test_every_kind_has_a_unique_name_and_symbol() -> void:
	var names := {}
	var symbols := {}
	for kind in RoomType.Kind.values():
		var name := RoomType.name_of(kind)
		var symbol := RoomType.symbol_of(kind)
		assert_false(name.is_empty() or symbol.length() != 1, "kind %d" % kind)
		assert_false(names.has(name) or symbols.has(symbol), "trùng tên/ký hiệu: %s %s" % [name, symbol])
		names[name] = true
		symbols[symbol] = true
	assert_eq(RoomType.NAMES.size(), RoomType.Kind.size())
	assert_eq(RoomType.SYMBOLS.size(), RoomType.Kind.size())


func test_is_valid_accepts_exactly_the_enum_values() -> void:
	for value in RoomType.Kind.size():
		assert_true(RoomType.is_valid(value))
	assert_false(RoomType.is_valid(-1))
	assert_false(RoomType.is_valid(RoomType.Kind.size()))


func test_restricted_kinds_are_elite_shop_campfire() -> void:
	assert_eq(RoomType.RESTRICTED.size(), 3)
	for kind in [RoomType.Kind.ELITE, RoomType.Kind.SHOP, RoomType.Kind.CAMPFIRE]:
		assert_true(RoomType.RESTRICTED.has(kind))
