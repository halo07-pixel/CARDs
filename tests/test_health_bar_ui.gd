extends "res://tests/test_case.gd"


func test_set_health_shows_text_and_bar_value() -> void:
	var bar_ui := HealthBarUI.new()
	bar_ui.set_health(30, 80)
	assert_eq(bar_ui.hp_label.text, "30/80")
	assert_almost_eq(bar_ui.bar.value, 30.0)
	assert_almost_eq(bar_ui.bar.max_value, 80.0)
	bar_ui.free()


func test_bar_value_is_clamped_but_text_stays_honest() -> void:
	var bar_ui := HealthBarUI.new()
	bar_ui.set_health(-5, 80)
	assert_almost_eq(bar_ui.bar.value, 0.0)
	bar_ui.set_health(200, 80)
	assert_almost_eq(bar_ui.bar.value, 80.0)
	assert_eq(bar_ui.hp_label.text, "200/80")
	bar_ui.free()


func test_zero_max_hp_does_not_break_the_bar() -> void:
	var bar_ui := HealthBarUI.new()
	bar_ui.set_health(0, 0)
	assert_true(bar_ui.bar.max_value >= 1.0)
	bar_ui.free()


func test_block_visibility_follows_amount() -> void:
	var bar_ui := HealthBarUI.new()
	assert_false(bar_ui.block_box.visible)
	bar_ui.set_block(4)
	assert_true(bar_ui.block_box.visible)
	assert_eq(bar_ui.block_label.text, "4")
	bar_ui.set_block(0)
	assert_false(bar_ui.block_box.visible)
	bar_ui.free()
