extends "res://tests/test_case.gd"

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
