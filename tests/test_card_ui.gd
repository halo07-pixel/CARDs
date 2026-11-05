extends "res://tests/test_case.gd"

const UiInput := preload("res://tests/ui_input.gd")

var _cards: CardRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")


func _instance(id: StringName) -> CardInstance:
	var ids: Array[StringName] = [id]
	return _cards.create_instances(ids)[0]


func test_show_view_fills_labels() -> void:
	var card_ui := CardUI.new()
	card_ui.show_view(CardView.build(_instance(&"strike")))
	assert_eq(card_ui.name_label.text, "Strike")
	assert_eq(card_ui.cost_label.text, "1")
	assert_eq(card_ui.type_label.text, "Attack")
	assert_true(card_ui.description_label.text.contains("damage"))
	card_ui.free()


func test_unplayable_view_is_dimmed_and_playable_is_not() -> void:
	var card_ui := CardUI.new()
	card_ui.show_view(CardView.build(_instance(&"strike"), null, null, false))
	assert_almost_eq(card_ui.modulate.a, CardUI.UNPLAYABLE_ALPHA)
	card_ui.show_view(CardView.build(_instance(&"strike")))
	assert_almost_eq(card_ui.modulate.a, 1.0, 0.0001, "hiển thị lại thẻ chơi được phải hết mờ")
	card_ui.free()


func test_null_view_changes_nothing() -> void:
	var card_ui := CardUI.new()
	card_ui.show_view(CardView.build(_instance(&"strike")))
	card_ui.show_view(null)
	assert_eq(card_ui.name_label.text, "Strike")
	card_ui.free()


func test_every_real_card_can_be_displayed() -> void:
	var card_ui := CardUI.new()
	for id in _cards.all_ids():
		card_ui.show_view(CardView.build(_instance(id)))
		assert_eq(card_ui.name_label.text, _cards.get_card(id).display_name, "thẻ %s" % id)
		assert_false(card_ui.description_label.text.contains("{"), "thẻ %s còn token" % id)
	card_ui.free()


func test_left_click_emits_clicked_with_the_view() -> void:
	var card_ui := CardUI.new()
	var view := CardView.build(_instance(&"strike"))
	card_ui.show_view(view)
	var received: Array[CardView] = []
	card_ui.clicked.connect(func(clicked_view: CardView) -> void: received.append(clicked_view))
	card_ui._gui_input(UiInput.click())
	assert_eq(received.size(), 1)
	assert_eq(received[0], view)
	card_ui._gui_input(UiInput.click(MOUSE_BUTTON_RIGHT))
	assert_eq(received.size(), 1, "chuột phải không phát clicked")
	card_ui.free()


func test_click_before_any_view_is_ignored() -> void:
	var card_ui := CardUI.new()
	var received: Array[CardView] = []
	card_ui.clicked.connect(func(clicked_view: CardView) -> void: received.append(clicked_view))
	card_ui._gui_input(UiInput.click())
	assert_eq(received.size(), 0)
	card_ui.free()


func test_child_controls_never_block_clicks() -> void:
	var card_ui := CardUI.new()
	for control: Control in [card_ui.cost_label, card_ui.name_label, card_ui.art_label, card_ui.type_label,
			card_ui.description_label]:
		assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	card_ui.free()


func test_highlight_changes_the_border() -> void:
	var card_ui := CardUI.new()
	card_ui.show_view(CardView.build(_instance(&"strike")))
	var normal := card_ui.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(normal.border_width_left, CardUI.BORDER_WIDTH)
	card_ui.set_highlighted(true)
	var lit := card_ui.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(lit.border_width_left, CardUI.HIGHLIGHT_BORDER_WIDTH)
	assert_eq(lit.border_color, CardUI.HIGHLIGHT_COLOR)
	card_ui.set_highlighted(false)
	assert_eq((card_ui.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left, CardUI.BORDER_WIDTH)
	card_ui.free()
