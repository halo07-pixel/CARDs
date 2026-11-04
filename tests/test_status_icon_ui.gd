extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _statuses: StatusRegistry


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _view(id: StringName, amount: int) -> StatusView:
	var unit := Factory.combatant(&"unit", 50)
	unit.add_status(_statuses.get_status(id), amount)
	return StatusView.build(unit, id)


func _border(icon_ui: StatusIconUI) -> Color:
	return (icon_ui.get_theme_stylebox("panel") as StyleBoxFlat).border_color


func test_shows_icon_and_amount_without_fallback_text() -> void:
	var icon_ui := StatusIconUI.new()
	icon_ui.show_view(_view(&"strength", 3))
	assert_true(icon_ui.icon_rect.texture != null)
	assert_false(icon_ui.fallback_label.visible)
	assert_eq(icon_ui.amount_label.text, "3")
	icon_ui.free()


func test_missing_icon_falls_back_to_abbreviation() -> void:
	var view := _view(&"strength", 2)
	view.icon_id = &"khong_co_icon_nay"
	var icon_ui := StatusIconUI.new()
	icon_ui.show_view(view)
	assert_true(icon_ui.icon_rect.texture == null)
	assert_true(icon_ui.fallback_label.visible)
	assert_eq(icon_ui.fallback_label.text, "STR")
	icon_ui.free()


func test_debuff_has_a_different_border_than_buff() -> void:
	var buff := StatusIconUI.new()
	buff.show_view(_view(&"strength", 1))
	var debuff := StatusIconUI.new()
	debuff.show_view(_view(&"weak", 1))
	assert_eq(_border(buff), StatusIconUI.BORDER_COLOR)
	assert_eq(_border(debuff), StatusIconUI.DEBUFF_BORDER_COLOR)
	buff.free()
	debuff.free()


func test_negative_amount_is_displayed_with_sign() -> void:
	var icon_ui := StatusIconUI.new()
	icon_ui.show_view(_view(&"strength", -2))
	assert_eq(icon_ui.amount_label.text, "-2")
	icon_ui.free()


func test_null_view_changes_nothing() -> void:
	var icon_ui := StatusIconUI.new()
	icon_ui.show_view(_view(&"strength", 3))
	icon_ui.show_view(null)
	assert_eq(icon_ui.amount_label.text, "3")
	icon_ui.free()
