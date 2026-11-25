extends "res://tests/test_case.gd"
## MapConfig: mặc định hợp lệ, luật ép loại theo tầng, từ chối cấu hình vô lý.


func test_default_config_is_valid_and_slay_the_spire_shaped() -> void:
	var cfg := MapConfig.new()
	assert_eq(cfg.validate(), [] as Array[String])
	assert_eq([cfg.columns, cfg.floors, cfg.paths], [7, 15, 6])


func test_forced_kinds_by_floor() -> void:
	var cfg := MapConfig.new()
	assert_eq(cfg.forced_kind(0), RoomType.Kind.MONSTER)
	assert_eq(cfg.forced_kind(8), RoomType.Kind.TREASURE)
	assert_eq(cfg.forced_kind(14), RoomType.Kind.CAMPFIRE)
	assert_eq(cfg.forced_kind(15), RoomType.Kind.BOSS)
	for floor_index in [1, 2, 5, 7, 9, 13]:
		assert_eq(cfg.forced_kind(floor_index), MapConfig.NOT_FORCED, "tầng %d tự do" % floor_index)


func test_each_invalid_field_is_reported() -> void:
	var cases := {
		"columns": func(c: MapConfig) -> void: c.columns = 2,
		"columns_big": func(c: MapConfig) -> void: c.columns = 16,
		"floors": func(c: MapConfig) -> void: c.floors = 3,
		"paths": func(c: MapConfig) -> void: c.paths = 1,
		"min_start": func(c: MapConfig) -> void: c.min_start_columns = 0,
		"min_start_big": func(c: MapConfig) -> void: c.min_start_columns = 7,
		"treasure_low": func(c: MapConfig) -> void: c.treasure_floor = 0,
		"treasure_high": func(c: MapConfig) -> void: c.treasure_floor = 14,
		"elite_min": func(c: MapConfig) -> void: c.elite_min_floor = 15,
		"campfire_min": func(c: MapConfig) -> void: c.campfire_min_floor = 0,
		"no_monster": func(c: MapConfig) -> void: c.weights = {RoomType.Kind.EVENT: 1.0},
		"zero_monster": func(c: MapConfig) -> void: c.weights[RoomType.Kind.MONSTER] = 0.0,
		"boss_weight": func(c: MapConfig) -> void: c.weights[RoomType.Kind.BOSS] = 1.0,
		"negative": func(c: MapConfig) -> void: c.weights[RoomType.Kind.SHOP] = -1.0,
	}
	for label in cases:
		var cfg := MapConfig.new()
		cases[label].call(cfg)
		assert_false(cfg.validate().is_empty(), "phải báo lỗi: %s" % label)
