extends "res://tests/test_case.gd"
## BadgeUI: ô vuông icon/chữ viết tắt + viền; báo hover và bấm lên trên.

const UiInput := preload("res://tests/ui_input.gd")


func test_is_built_once_with_icon_and_fallback_children() -> void:
	var badge := BadgeUI.new()
	assert_eq(badge.get_child_count(), 2, "không bị dựng nhân đôi qua lớp con")
	assert_eq(PotionSlotUI.new().get_child_count(), 2)
	assert_eq(RelicIconUI.new().get_child_count(), 2)
	badge.free()


func test_missing_icon_falls_back_to_three_upper_case_letters() -> void:
	var badge := BadgeUI.new()
	badge.show_badge(&"no_such_icon", "Anchor", Color.RED)
	assert_true(badge.fallback_label.visible)
	assert_eq(badge.fallback_label.text, "ANC")
	assert_true(badge.icon_rect.texture == null)
	badge.free()


func test_known_icon_hides_the_fallback_text() -> void:
	var badge := BadgeUI.new()
	badge.show_badge(&"strength", "Strength", Color.RED)
	assert_false(badge.fallback_label.visible)
	assert_true(badge.icon_rect.texture != null)
	badge.free()


func test_empty_title_gives_a_plain_badge() -> void:
	var badge := BadgeUI.new()
	badge.show_badge(&"", "", Color.GRAY, 0.5)
	assert_eq(badge.fallback_label.text, "")
	assert_almost_eq(badge.modulate.a, 0.5, 0.0001)
	badge.free()


func test_border_color_comes_from_the_argument() -> void:
	var badge := BadgeUI.new()
	badge.show_badge(&"", "x", Color("ff0000"))
	assert_eq((badge.get_theme_stylebox("panel") as StyleBoxFlat).border_color, Color("ff0000"))
	badge.free()


func test_hover_signals_and_state() -> void:
	var badge := BadgeUI.new()
	var events: Array = []
	badge.hover_started.connect(func() -> void: events.append("in"))
	badge.hover_ended.connect(func() -> void: events.append("out"))
	assert_false(badge.is_hovered())
	badge.mouse_entered.emit()
	assert_true(badge.is_hovered())
	badge.mouse_exited.emit()
	assert_false(badge.is_hovered())
	assert_eq(events, ["in", "out"])
	badge.free()


func test_only_left_button_press_emits_pressed() -> void:
	var badge := BadgeUI.new()
	var presses: Array = []
	badge.pressed.connect(func() -> void: presses.append(1))
	badge._gui_input(UiInput.press())
	badge._gui_input(UiInput.release())
	badge._gui_input(UiInput.press(Vector2.ZERO, MOUSE_BUTTON_RIGHT))
	assert_eq(presses.size(), 1, "chỉ lúc bấm chuột trái")
	badge.free()
