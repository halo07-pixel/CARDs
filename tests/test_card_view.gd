extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _cards: CardRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")


func _instance(id: StringName) -> CardInstance:
	var ids: Array[StringName] = [id]
	return _cards.create_instances(ids)[0]


func test_build_copies_display_fields() -> void:
	var card := _instance(&"strike")
	var view := CardView.build(card)
	assert_eq(view.uid, card.uid)
	assert_eq(view.card_id, &"strike")
	assert_eq(view.title, card.data.display_name)
	assert_eq(view.card_type, card.data.card_type)
	assert_eq(view.rarity, card.data.rarity)
	assert_eq(view.cost_text, str(card.data.cost))
	assert_eq(view.cost_shift, 0)
	assert_true(view.is_playable)
	assert_false(view.is_upgraded)


func test_upgraded_card_is_flagged() -> void:
	assert_true(CardView.build(_instance(&"strike+")).is_upgraded)


func test_x_cost_card_shows_x() -> void:
	assert_eq(CardView.build(_instance(&"whirlwind")).cost_text, CardView.COST_X)


func test_unplayable_card_shows_dash_and_is_not_playable() -> void:
	var card := Factory.card_inst(&"curse", [] as Array[EffectData], CardData.TargetMode.NONE, {"unplayable": true})
	var view := CardView.build(card)
	assert_eq(view.cost_text, CardView.COST_UNPLAYABLE)
	assert_false(view.is_playable)


func test_cost_override_sets_cost_shift() -> void:
	var cheaper := _instance(&"bash")
	cheaper.set_cost_override(0)
	var view := CardView.build(cheaper)
	assert_eq(view.cost_text, "0")
	assert_eq(view.cost_shift, -1, "rẻ hơn gốc")
	var dearer := _instance(&"strike")
	dearer.set_cost_override(3)
	assert_eq(CardView.build(dearer).cost_shift, 1, "đắt hơn gốc")


func test_playable_flag_is_passed_through() -> void:
	assert_false(CardView.build(_instance(&"strike"), null, null, false).is_playable)


func test_description_uses_owner_stats_with_color() -> void:
	var owner := Factory.combatant(&"p", 50)
	owner.add_status(StatusRegistry.load_from_dir("res://data/statuses").get_status(&"strength"), 3)
	var view := CardView.build(_instance(&"strike"), owner)
	assert_true(view.description.contains("[color="))


func test_null_card_returns_null() -> void:
	assert_true(CardView.build(null) == null)
