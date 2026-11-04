extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _cards: CardRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _with_status(id: StringName, amount: int) -> Combatant:
	var unit := Factory.combatant(&"unit", 50)
	unit.add_status(_statuses.get_status(id), amount)
	return unit


func _card(id: StringName) -> CardData:
	return _cards.get_card(id)


func _base_damage(id: StringName) -> int:
	return CardTextFormatter.base_values(_card(id))[&"damage"]


## --- Giá trị gốc ---

func test_base_values_come_from_effects() -> void:
	var values := CardTextFormatter.base_values(_card(&"iron_wave"))
	assert_eq(values[&"block"], _card(&"iron_wave").effects[0].amount)
	assert_true(values.has(&"damage"))


func test_base_values_include_status_amounts_by_status_id() -> void:
	var values := CardTextFormatter.base_values(_card(&"deadly_poison"))
	assert_true(values.has(&"poison"), "Deadly Poison phải có token {poison}")
	assert_true(values[&"poison"] > 0)


func test_base_values_of_null_card_is_empty() -> void:
	assert_eq(CardTextFormatter.base_values(null).size(), 0)


## --- Thay số ---

func test_format_without_owner_shows_base_numbers() -> void:
	var text := CardTextFormatter.format(_card(&"strike"))
	assert_eq(text, "Deal %d damage." % _base_damage(&"strike"))


func test_strength_raises_damage_by_its_stacks() -> void:
	var text := CardTextFormatter.format(_card(&"strike"), _with_status(&"strength", 3))
	assert_eq(text, "Deal %d damage." % (_base_damage(&"strike") + 3))


func test_vulnerable_target_raises_damage() -> void:
	var target := _with_status(&"vulnerable", 1)
	var plain := CardTextFormatter.format(_card(&"strike"), Factory.combatant(&"p", 50))
	var boosted := CardTextFormatter.format(_card(&"strike"), Factory.combatant(&"p", 50), target)
	assert_ne(boosted, plain)


func test_weak_owner_lowers_damage() -> void:
	var text := CardTextFormatter.format(_card(&"strike"), _with_status(&"weak", 1))
	assert_true(int(text.get_slice(" ", 1)) < _base_damage(&"strike"), "Weak làm giảm sát thương: " + text)


func test_dexterity_raises_block_and_frail_lowers_it() -> void:
	var base := CardTextFormatter.base_values(_card(&"defend"))[&"block"] as int
	assert_eq(CardTextFormatter.final_values(_card(&"defend"), _with_status(&"dexterity", 2))[&"block"], base + 2)
	assert_true(CardTextFormatter.final_values(_card(&"defend"), _with_status(&"frail", 1))[&"block"] < base)


func test_damage_never_shown_below_zero() -> void:
	var weakling := _with_status(&"strength", -50)
	assert_eq(CardTextFormatter.final_values(_card(&"strike"), weakling)[&"damage"], 0)


## --- BBCode và token lạ ---

func test_bbcode_colors_only_changed_numbers() -> void:
	var buffed := CardTextFormatter.format(_card(&"strike"), _with_status(&"strength", 3), null, true)
	assert_true(buffed.contains("[color=%s]" % CardTextFormatter.COLOR_UP))
	var weakened := CardTextFormatter.format(_card(&"strike"), _with_status(&"weak", 1), null, true)
	assert_true(weakened.contains("[color=%s]" % CardTextFormatter.COLOR_DOWN))
	var unchanged := CardTextFormatter.format(_card(&"strike"), Factory.combatant(&"p", 50), null, true)
	assert_false(unchanged.contains("[color"), "không đổi thì không tô màu")


func test_plain_text_has_no_markup_even_when_changed() -> void:
	var text := CardTextFormatter.format(_card(&"strike"), _with_status(&"strength", 3))
	assert_false(text.contains("["))


func test_unknown_token_is_kept_and_reported() -> void:
	var card := CardData.new()
	card.description = "Deal {damage} damage. Frobnicate {nope}."
	card.effects = [Factory.damage_effect(5)] as Array[EffectData]
	assert_eq(CardTextFormatter.format(card), "Deal 5 damage. Frobnicate {nope}.")
	assert_eq(CardTextFormatter.unresolved_tokens(card), ["nope"] as Array[String])


func test_format_does_not_mutate_card_data() -> void:
	var card := _card(&"strike")
	var amount_before := card.effects[0].amount
	var description_before := card.description
	CardTextFormatter.format(card, _with_status(&"strength", 5), null, true)
	assert_eq(card.effects[0].amount, amount_before)
	assert_eq(card.description, description_before)


func test_null_card_formats_to_empty_string() -> void:
	assert_eq(CardTextFormatter.format(null), "")


## --- Dữ liệu thật ---

func test_every_real_card_description_resolves_all_tokens() -> void:
	for id in _cards.all_ids():
		var card := _cards.get_card(id)
		assert_eq(CardTextFormatter.unresolved_tokens(card), [] as Array[String], "thẻ %s" % id)
		var text := CardTextFormatter.format(card, null, null, false)
		assert_false(text.contains("{"), "thẻ %s còn token chưa thay: %s" % [id, text])
		assert_false(text.strip_edges().is_empty(), "thẻ %s mô tả trống" % id)
