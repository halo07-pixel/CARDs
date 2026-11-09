extends "res://tests/test_case.gd"
## HealthBarUI trượt mượt: chữ hp/max luôn đúng ngay, thanh chỉ trượt khi hiệu ứng bật và thanh ở trong cây.

var _bar_ui: HealthBarUI = null
var _config := EffectsConfig.new()


func before_each() -> void:
	_config.speed = EffectsConfig.NORMAL_SPEED
	_bar_ui = HealthBarUI.new()
	Engine.get_main_loop().root.add_child(_bar_ui)
	_bar_ui.set_health(80, 80)


func after_each() -> void:
	_bar_ui.free()


func _finish() -> void:
	var tween := _bar_ui._tween
	tween.pause()
	tween.custom_step(HealthBarUI.BAR_TWEEN_DURATION * 10.0)


func test_without_a_config_the_bar_jumps_at_once() -> void:
	_bar_ui.set_health(30, 80)
	assert_almost_eq(_bar_ui.bar.value, 30.0, 0.0001)
	assert_false(_bar_ui.is_animating())


func test_with_an_off_config_the_bar_jumps_at_once() -> void:
	_bar_ui.set_health(30, 80, EffectsConfig.new())
	assert_almost_eq(_bar_ui.bar.value, 30.0, 0.0001)
	assert_false(_bar_ui.is_animating())


func test_outside_the_tree_the_bar_jumps_at_once() -> void:
	var loose := HealthBarUI.new()
	loose.set_health(80, 80)
	loose.set_health(30, 80, _config)
	assert_almost_eq(loose.bar.value, 30.0, 0.0001)
	assert_false(loose.is_animating())
	loose.free()


func test_text_is_exact_immediately_while_the_bar_slides() -> void:
	_bar_ui.set_health(30, 80, _config)
	assert_eq(_bar_ui.hp_label.text, "30/80")
	assert_true(_bar_ui.is_animating())
	assert_almost_eq(_bar_ui.bar.value, 80.0, 0.0001, "thanh chưa trượt ngay")
	_finish()
	assert_almost_eq(_bar_ui.bar.value, 30.0, 0.0001)
	assert_false(_bar_ui.is_animating())


func test_unchanged_health_starts_no_animation() -> void:
	_bar_ui.set_health(80, 80, _config)
	assert_false(_bar_ui.is_animating())


func test_a_new_value_mid_slide_restarts_from_the_current_value() -> void:
	_bar_ui.set_health(30, 80, _config)
	var first := _bar_ui._tween
	first.pause()
	first.custom_step(HealthBarUI.BAR_TWEEN_DURATION * 0.5)
	var midway := _bar_ui.bar.value
	assert_true(midway < 80.0 and midway > 30.0, "đang trượt giữa chừng")
	_bar_ui.set_health(60, 80, _config)
	assert_false(first.is_valid(), "tween cũ bị hủy")
	_finish()
	assert_almost_eq(_bar_ui.bar.value, 60.0, 0.0001)


func test_a_plain_set_mid_slide_cancels_the_slide() -> void:
	_bar_ui.set_health(30, 80, _config)
	_bar_ui.set_health(50, 80)
	assert_false(_bar_ui.is_animating())
	assert_almost_eq(_bar_ui.bar.value, 50.0, 0.0001)


func test_negative_and_overflowing_values_are_clamped_but_the_text_is_honest() -> void:
	_bar_ui.set_health(-5, 80, _config)
	_finish()
	assert_almost_eq(_bar_ui.bar.value, 0.0, 0.0001)
	assert_eq(_bar_ui.hp_label.text, "-5/80")


func test_combatant_ui_slides_on_damage_but_not_on_the_first_bind() -> void:
	var combatant := Combatant.create(&"p", "Hero", 50)
	var combatant_ui := CombatantUI.new()
	combatant_ui.effects = _config
	Engine.get_main_loop().root.add_child(combatant_ui)
	combatant_ui.bind(combatant)
	assert_false(combatant_ui.health_bar.is_animating(), "dựng lần đầu: không trượt")
	combatant.take_damage(20)
	assert_true(combatant_ui.health_bar.is_animating())
	assert_eq(combatant_ui.health_bar.hp_label.text, "30/50")
	combatant_ui.free()


func test_combatant_ui_without_effects_does_not_slide() -> void:
	var combatant := Combatant.create(&"p", "Hero", 50)
	var combatant_ui := CombatantUI.new()
	Engine.get_main_loop().root.add_child(combatant_ui)
	combatant_ui.bind(combatant)
	combatant.take_damage(20)
	assert_false(combatant_ui.health_bar.is_animating())
	assert_almost_eq(combatant_ui.health_bar.bar.value, 30.0, 0.0001)
	combatant_ui.free()
