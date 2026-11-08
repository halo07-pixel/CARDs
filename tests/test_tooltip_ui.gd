extends "res://tests/test_case.gd"
## TooltipUI: khung tooltip duy nhất; không nhận chuột; luôn nằm trong màn hình.

const SCREEN := DropIntent.DESIGN_SCREEN

var _tooltip: TooltipUI = null


func after_each() -> void:
	if _tooltip != null:
		_tooltip.free()
		_tooltip = null


func _make() -> TooltipUI:
	_tooltip = TooltipUI.new()
	Engine.get_main_loop().root.add_child(_tooltip)
	return _tooltip


func _view(title: String, body: String, entries: Array = []) -> TooltipView:
	var view := TooltipView.new()
	view.title = title
	view.body = body
	for entry: GlossaryEntry in entries:
		view.entries.append(entry)
	return view


func _frame() -> void:
	await Engine.get_main_loop().process_frame


func test_starts_hidden_and_ignores_the_mouse() -> void:
	var tooltip := _make()
	assert_false(tooltip.visible)
	assert_eq(tooltip.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	for label in [tooltip.title_label, tooltip.body_label]:
		assert_eq(label.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_show_fills_title_body_and_entries() -> void:
	var tooltip := _make()
	var entries := [GlossaryEntry.create("Exhaust", "Gone for the combat."), GlossaryEntry.create("Block", "Absorbs damage.")]
	tooltip.show_tooltip(_view("Anchor", "Start each combat with 10 Block.", entries), Rect2(100, 100, 72, 72))
	assert_true(tooltip.visible)
	assert_eq(tooltip.title_label.text, "Anchor")
	assert_eq(tooltip.body_label.text, "Start each combat with 10 Block.")
	assert_eq(tooltip.entries_box.get_child_count(), 2)
	assert_true(tooltip.entries_box.visible)


func test_empty_parts_are_hidden() -> void:
	var tooltip := _make()
	tooltip.show_tooltip(_view("", "", [GlossaryEntry.create("Exhaust", "x")]), Rect2(100, 100, 72, 72))
	assert_false(tooltip.title_label.visible)
	assert_false(tooltip.body_label.visible)
	assert_true(tooltip.entries_box.visible)
	tooltip.show_tooltip(_view("Only title", ""), Rect2(100, 100, 72, 72))
	assert_true(tooltip.title_label.visible)
	assert_false(tooltip.entries_box.visible)


func test_showing_again_replaces_entries_instead_of_accumulating() -> void:
	var tooltip := _make()
	var entries := [GlossaryEntry.create("A", "a"), GlossaryEntry.create("B", "b")]
	tooltip.show_tooltip(_view("", "", entries), Rect2(100, 100, 72, 72))
	tooltip.show_tooltip(_view("", "", entries), Rect2(100, 100, 72, 72))
	assert_eq(tooltip.entries_box.get_child_count(), 2)


func test_null_or_empty_view_hides_it() -> void:
	var tooltip := _make()
	tooltip.show_tooltip(_view("Hi", "there"), Rect2(100, 100, 72, 72))
	tooltip.show_tooltip(TooltipView.new(), Rect2(100, 100, 72, 72))
	assert_false(tooltip.visible)
	tooltip.show_tooltip(_view("Hi", "there"), Rect2(100, 100, 72, 72))
	tooltip.show_tooltip(null, Rect2(100, 100, 72, 72))
	assert_false(tooltip.visible)


func test_hide_tooltip_hides_it() -> void:
	var tooltip := _make()
	tooltip.show_tooltip(_view("Hi", "there"), Rect2(100, 100, 72, 72))
	tooltip.hide_tooltip()
	assert_false(tooltip.visible)
	tooltip.hide_tooltip()  # lần hai an toàn
	assert_false(tooltip.visible)


func test_is_placed_to_the_right_of_the_anchor_once_laid_out() -> void:
	var tooltip := _make()
	var anchor := Rect2(100, 300, 72, 72)
	tooltip.show_tooltip(_view("Fire Potion", "Deal 20 damage to target enemy."), anchor)
	await _frame()
	assert_almost_eq(tooltip.position.x, anchor.end.x + TooltipPlacement.GAP, 0.01)
	assert_almost_eq(tooltip.position.y, anchor.position.y, 0.01)


func test_flips_to_the_left_near_the_right_screen_edge() -> void:
	var tooltip := _make()
	var anchor := Rect2(SCREEN.x - 120, 300, 72, 72)
	tooltip.show_tooltip(_view("Fire Potion", "Deal 20 damage to target enemy."), anchor)
	await _frame()
	assert_true(tooltip.position.x + tooltip.size.x <= anchor.position.x, "nằm bên trái neo, không đè lên neo")
	assert_true(tooltip.position.x >= TooltipPlacement.MARGIN)


func test_stays_inside_the_screen_for_a_tall_tooltip_near_the_bottom() -> void:
	var tooltip := _make()
	var entries := [GlossaryEntry.create("Exhaust", "Removed from play until the end of combat."),
			GlossaryEntry.create("Vulnerable", "Takes 50% more damage. Decreases each turn."),
			GlossaryEntry.create("Block", "Absorbs damage before health. Removed at the start of your turn.")]
	tooltip.show_tooltip(_view("", "", entries), Rect2(300, SCREEN.y - 90, 200, 80))
	await _frame()
	assert_true(tooltip.position.y + tooltip.size.y <= SCREEN.y - TooltipPlacement.MARGIN + 0.01, "không tràn đáy")
	assert_true(tooltip.position.y >= TooltipPlacement.MARGIN)


func test_growing_content_is_replaced_inside_the_screen() -> void:
	var tooltip := _make()
	var anchor := Rect2(300, SCREEN.y - 150, 200, 80)
	tooltip.show_tooltip(_view("Short", "x"), anchor)
	await _frame()
	var long_text := "A very long description that wraps over several lines because it is much longer than the fixed content width of the tooltip. ".repeat(3)
	tooltip.show_tooltip(_view("Long", long_text), anchor)
	await _frame()
	await _frame()
	assert_true(tooltip.position.y + tooltip.size.y <= SCREEN.y - TooltipPlacement.MARGIN + 0.01, "vị trí tính lại theo kích thước mới")


func test_layout_growth_after_showing_is_replaced_by_the_resized_hook() -> void:
	var tooltip := _make()
	var anchor := Rect2(300, SCREEN.y - 150, 200, 80)
	tooltip.show_tooltip(_view("Short", "x"), anchor)
	await _frame()
	# Chữ đổi sau khi đã hiện (vd. font nạp muộn): bố cục chạy lại, tooltip phải tự dời vào trong màn hình.
	tooltip.body_label.text = "A very long description that wraps over several lines because it is much longer than the width. ".repeat(4)
	await _frame()
	await _frame()
	assert_true(tooltip.size.y > 200, "nội dung đã dài ra")
	assert_true(tooltip.position.y + tooltip.size.y <= SCREEN.y - TooltipPlacement.MARGIN + 0.01, "không tràn đáy")
