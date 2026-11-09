extends "res://tests/test_case.gd"
## EffectsConfig: tắt/bật và đổi tốc độ hiệu ứng.


func test_default_is_off() -> void:
	var config := EffectsConfig.new()
	assert_false(config.is_enabled())
	assert_almost_eq(config.duration(0.9), 0.0, 0.0001)


func test_normal_speed_keeps_the_designed_duration() -> void:
	var config := EffectsConfig.new()
	config.speed = EffectsConfig.NORMAL_SPEED
	assert_true(config.is_enabled())
	assert_almost_eq(config.duration(0.9), 0.9, 0.0001)


func test_faster_speed_shortens_and_slower_lengthens() -> void:
	var config := EffectsConfig.new()
	config.speed = 2.0
	assert_almost_eq(config.duration(1.0), 0.5, 0.0001)
	config.speed = 0.5
	assert_almost_eq(config.duration(1.0), 2.0, 0.0001)


func test_zero_or_negative_speed_is_off() -> void:
	var config := EffectsConfig.new()
	for speed_value in [0.0, -1.0]:
		config.speed = speed_value
		assert_false(config.is_enabled())
		assert_almost_eq(config.duration(5.0), 0.0, 0.0001)
