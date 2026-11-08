extends "res://tests/test_case.gd"
## PileViewerUI: lớp phủ xem pile; chặn chuột khi mở; chỉ vẽ danh sách CardView được đưa vào.

const CardFactory := preload("res://tests/card_factory.gd")

var _viewer: PileViewerUI = null


func before_each() -> void:
	_viewer = PileViewerUI.new()


func after_each() -> void:
	_viewer.free()


func _views(count: int) -> Array[CardView]:
	var views: Array[CardView] = []
	for i in count:
		views.append(CardView.build(CardFactory.instance(StringName("c%d" % i))))
	return views


func test_starts_closed_and_blocks_the_mouse_when_open() -> void:
	assert_false(_viewer.is_open())
	assert_false(_viewer.visible)
	assert_eq(_viewer.mouse_filter, Control.MOUSE_FILTER_STOP)


func test_show_pile_builds_one_card_per_view_with_the_title() -> void:
	_viewer.show_pile("Draw pile (3)", _views(3))
	assert_true(_viewer.is_open())
	assert_eq(_viewer.title_label.text, "Draw pile (3)")
	assert_eq(_viewer.grid.get_child_count(), 3)
	assert_eq((_viewer.grid.get_child(0) as CardUI).view.title, CardFactory.card(&"c0").display_name)
	assert_true(_viewer.scroll.visible)
	assert_false(_viewer.empty_label.visible)


func test_cards_do_not_steal_the_wheel_from_the_scroll_container() -> void:
	_viewer.show_pile("x", _views(2))
	for card_ui in _viewer.grid.get_children():
		assert_eq((card_ui as CardUI).mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_empty_pile_shows_the_empty_message() -> void:
	_viewer.show_pile("Exhaust pile (0)", _views(0))
	assert_true(_viewer.is_open())
	assert_true(_viewer.empty_label.visible)
	assert_false(_viewer.scroll.visible)
	assert_eq(_viewer.grid.get_child_count(), 0)


func test_showing_again_replaces_the_cards() -> void:
	_viewer.show_pile("a", _views(4))
	_viewer.show_pile("b", _views(2))
	assert_eq(_viewer.grid.get_child_count(), 2)
	assert_eq(_viewer.title_label.text, "b")


func test_close_frees_cards_and_emits_closed_once() -> void:
	var closes: Array = []
	_viewer.closed.connect(func() -> void: closes.append(1))
	_viewer.show_pile("a", _views(3))
	assert_true(_viewer.close())
	assert_false(_viewer.is_open())
	assert_eq(_viewer.grid.get_child_count(), 0)
	assert_eq(closes.size(), 1)
	assert_false(_viewer.close(), "đã đóng: không làm gì")
	assert_eq(closes.size(), 1)


func test_close_button_closes() -> void:
	_viewer.show_pile("a", _views(1))
	_viewer.close_button.pressed.emit()
	assert_false(_viewer.is_open())


func test_repeated_open_close_does_not_leak_nodes() -> void:
	_viewer.show_pile("a", _views(3))
	_viewer.close()
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 5:
		_viewer.show_pile("a", _views(3))
		_viewer.close()
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)


func test_more_cards_than_a_row_wrap_into_the_grid_columns() -> void:
	_viewer.show_pile("a", _views(PileViewerUI.COLUMNS + 2))
	assert_eq(_viewer.grid.get_child_count(), PileViewerUI.COLUMNS + 2)
	assert_eq(_viewer.grid.columns, PileViewerUI.COLUMNS)
