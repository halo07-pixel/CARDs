extends "res://tests/test_case.gd"


func test_hidden_until_a_result_is_shown() -> void:
	var overlay := ResultOverlayUI.new()
	assert_false(overlay.visible)
	overlay.free()


func test_victory_and_defeat_texts() -> void:
	var overlay := ResultOverlayUI.new()
	overlay.show_result(true)
	assert_true(overlay.visible)
	assert_eq(overlay.title_label.text, ResultOverlayUI.VICTORY_TEXT)
	overlay.show_result(false)
	assert_eq(overlay.title_label.text, ResultOverlayUI.DEFEAT_TEXT)
	overlay.hide_result()
	assert_false(overlay.visible)
	overlay.free()


func test_play_again_button_emits_the_signal() -> void:
	var overlay := ResultOverlayUI.new()
	var presses: Array[int] = []
	overlay.play_again_pressed.connect(func() -> void: presses.append(1))
	overlay.play_again_button.pressed.emit()
	assert_eq(presses.size(), 1)
	overlay.free()


func test_overlay_blocks_clicks_behind_it() -> void:
	var overlay := ResultOverlayUI.new()
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_STOP)
	overlay.free()
