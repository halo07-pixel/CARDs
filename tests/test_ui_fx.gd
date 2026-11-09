extends "res://tests/test_case.gd"
## UiFx: rung và nảy. Tween được dừng rồi đẩy bằng custom_step để test không phụ thuộc thời gian thật.

var _control: Control = null
var _config := EffectsConfig.new()


func before_each() -> void:
	_config.speed = EffectsConfig.NORMAL_SPEED
	_control = Control.new()
	_control.size = Vector2(100, 60)
	Engine.get_main_loop().root.add_child(_control)


func after_each() -> void:
	_control.free()


func _tween() -> Tween:
	return _control.get_meta(UiFx.TWEEN_META, null) as Tween


## Dừng tween tự chạy rồi đẩy tay `seconds` giây.
func _advance(seconds: float) -> void:
	var tween := _tween()
	tween.pause()
	tween.custom_step(seconds)


func test_shake_swings_then_returns_to_zero() -> void:
	assert_true(UiFx.shake(_control, _config))
	_advance(UiFx.SHAKE_DURATION * 0.2)
	assert_true(absf(_control.rotation) > 0.0, "đang lắc")
	_advance(UiFx.SHAKE_DURATION * 2.0)
	assert_almost_eq(_control.rotation, 0.0, 0.0001)
	assert_true(_tween() == null, "xong thì dọn dấu vết")


func test_shake_pivots_around_the_center() -> void:
	UiFx.shake(_control, _config)
	assert_eq(_control.pivot_offset, Vector2(50, 30))


func test_pop_grows_then_returns_to_normal_scale() -> void:
	assert_true(UiFx.pop(_control, _config))
	_advance(UiFx.POP_DURATION * 0.5)
	assert_true(_control.scale.x > 1.0, "đang phóng to")
	_advance(UiFx.POP_DURATION * 2.0)
	assert_eq(_control.scale, Vector2.ONE)


func test_pop_with_flash_brightens_then_restores_the_original_modulate() -> void:
	var original := Color(0.9, 0.8, 0.7, 0.6)
	_control.modulate = original
	UiFx.pop(_control, _config, true)
	assert_eq(_control.modulate, UiFx.FLASH_COLOR, "nháy sáng ngay")
	_advance(UiFx.POP_DURATION * 2.0)
	assert_eq(_control.modulate, original, "về đúng màu (kể cả độ mờ) ban đầu")
	assert_false(_control.has_meta(UiFx.MODULATE_META))


func test_pop_without_flash_leaves_modulate_alone() -> void:
	var original := Color(1, 1, 1, 0.5)
	_control.modulate = original
	UiFx.pop(_control, _config)
	assert_eq(_control.modulate, original)


func test_new_effect_interrupts_the_old_one_and_starts_from_a_clean_state() -> void:
	UiFx.shake(_control, _config)
	var first := _tween()
	_advance(UiFx.SHAKE_DURATION * 0.2)
	UiFx.pop(_control, _config)
	assert_false(first.is_valid(), "tween cũ bị hủy")
	assert_almost_eq(_control.rotation, 0.0, 0.0001, "không để lại góc lắc dở")
	_advance(UiFx.POP_DURATION * 2.0)
	assert_eq(_control.scale, Vector2.ONE)


func test_interrupting_a_flash_restores_the_modulate_before_starting_again() -> void:
	var original := Color(1, 1, 1, 0.55)
	_control.modulate = original
	UiFx.pop(_control, _config, true)
	UiFx.pop(_control, _config, true)
	_advance(UiFx.POP_DURATION * 2.0)
	assert_eq(_control.modulate, original, "không bị kẹt màu sáng")


func test_reset_restores_everything_and_is_safe_to_repeat() -> void:
	_control.modulate = Color(1, 1, 1, 0.5)
	UiFx.pop(_control, _config, true)
	UiFx.reset(_control)
	assert_eq(_control.scale, Vector2.ONE)
	assert_eq(_control.modulate, Color(1, 1, 1, 0.5))
	UiFx.reset(_control)
	UiFx.reset(null)


func test_off_config_or_missing_pieces_do_nothing() -> void:
	var off := EffectsConfig.new()
	assert_false(UiFx.shake(_control, off))
	assert_false(UiFx.pop(_control, off, true))
	assert_false(UiFx.shake(_control, null))
	assert_false(UiFx.shake(null, _config))
	var loose := Control.new()  # chưa ở trong cây
	assert_false(UiFx.shake(loose, _config))
	assert_false(UiFx.pop(loose, _config))
	loose.free()
	assert_eq(_control.rotation, 0.0)
	assert_true(_tween() == null)


func test_freeing_the_control_mid_effect_is_safe() -> void:
	var other := Control.new()
	Engine.get_main_loop().root.add_child(other)
	UiFx.pop(other, _config, true)
	other.free()  # tween gắn vào control nên tự hủy theo
	await Engine.get_main_loop().process_frame
	assert_true(true, "không lỗi khi tween chạy tiếp một khung")
