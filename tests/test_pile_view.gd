extends "res://tests/test_case.gd"
## PileView: xem nội dung pile mà KHÔNG lộ thứ tự rút.

const Factory := preload("res://tests/combat_factory.gd")
const CardFactory := preload("res://tests/card_factory.gd")

const NAMES: Array[StringName] = [&"zeta", &"alpha", &"mid", &"alpha", &"beta", &"zeta"]


func _cards() -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for id in NAMES:
		cards.append(CardFactory.instance(id))
	return cards


func _deck(seed_value: int) -> Deck:
	var deck := Deck.new(_cards(), CardFactory.rng(seed_value))
	deck.start_battle()
	return deck


func _titles(views: Array[CardView]) -> Array:
	var titles: Array = []
	for view in views:
		titles.append(view.title)
	return titles


func test_draw_pile_is_sorted_by_name_not_by_draw_order() -> void:
	var views := PileView.build(_deck(1), Deck.DRAW)
	assert_eq(_titles(views), ["Alpha", "Alpha", "Beta", "Mid", "Zeta", "Zeta"])


func test_different_shuffles_give_the_same_view() -> void:
	var first := PileView.build(_deck(1), Deck.DRAW)
	for seed_value in [2, 3, 7, 99]:
		var other := PileView.build(_deck(seed_value), Deck.DRAW)
		assert_eq(_titles(other), _titles(first), "seed %d không lộ thứ tự rút" % seed_value)


func test_equal_names_are_ordered_by_uid() -> void:
	var views := PileView.build(_deck(5), Deck.DRAW)
	assert_true(views[0].uid < views[1].uid)
	assert_true(views[4].uid < views[5].uid)


func test_view_matches_the_pile_contents() -> void:
	var deck := _deck(3)
	deck.draw(2)
	assert_eq(PileView.build(deck, Deck.DRAW).size(), deck.count(Deck.DRAW))
	assert_eq(PileView.build(deck, Deck.DISCARD).size(), 0)
	var hand := deck.get_pile(Deck.HAND)
	deck.discard_card(hand[0])
	deck.exhaust_card(hand[1])
	assert_eq(PileView.build(deck, Deck.DISCARD).size(), 1)
	assert_eq(PileView.build(deck, Deck.EXHAUST).size(), 1)
	assert_eq(PileView.build(deck, Deck.DISCARD)[0].uid, hand[0].uid)


func test_building_a_view_does_not_reorder_or_change_the_pile() -> void:
	var deck := _deck(4)
	var before := deck.get_pile(Deck.DRAW).map(func(c: CardInstance) -> int: return c.uid)
	PileView.build(deck, Deck.DRAW)
	var after := deck.get_pile(Deck.DRAW).map(func(c: CardInstance) -> int: return c.uid)
	assert_eq(after, before)


func test_only_draw_discard_and_exhaust_can_be_viewed() -> void:
	var deck := _deck(1)
	deck.draw(2)
	assert_eq(PileView.build(deck, Deck.HAND).size(), 0, "tay đang hiện sẵn, không xem như pile")
	assert_eq(PileView.build(deck, Deck.LIMBO).size(), 0)
	assert_eq(PileView.build(deck, &"nonsense").size(), 0)
	assert_eq(PileView.build(null, Deck.DRAW).size(), 0)


func test_owner_is_passed_to_the_card_text() -> void:
	var strong := Factory.combatant(&"p", 50)
	var statuses := Factory.registry()
	strong.add_status(statuses.get_status(&"strength"), 3)
	var cards: Array[CardInstance] = [CardFactory.instance(&"hit", {"description": "Deal {damage} damage."})]
	var deck := Deck.new(cards, CardFactory.rng())
	deck.start_battle()
	assert_true(PileView.build(deck, Deck.DRAW, strong)[0].description.contains("9"), "6 + 3 Strength")
	assert_true(PileView.build(deck, Deck.DRAW)[0].description.contains("6"))
