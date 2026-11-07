extends "res://tests/test_case.gd"
## KeywordGlossary: chú giải từ khóa của thẻ + test tham chiếu chéo trên dữ liệu thật.

const CardFactory := preload("res://tests/card_factory.gd")
const Factory := preload("res://tests/combat_factory.gd")

var _cards: CardRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _titles(entries: Array[GlossaryEntry]) -> Array:
	var titles: Array = []
	for entry in entries:
		titles.append(entry.title)
	return titles


func test_every_fixed_keyword_has_a_title_and_text() -> void:
	for keyword in KeywordGlossary.KEYWORD_ORDER:
		var entry := KeywordGlossary.entry(keyword)
		assert_true(entry != null, "%s: có mục" % keyword)
		assert_false(entry.title.strip_edges().is_empty(), "%s: tiêu đề" % keyword)
		assert_false(entry.text.strip_edges().is_empty(), "%s: lời giải thích" % keyword)


func test_unknown_keyword_gives_null() -> void:
	assert_true(KeywordGlossary.entry(&"nonsense") == null)


func test_card_keywords_follow_the_fixed_order_not_the_flag_order() -> void:
	var card := CardFactory.card(&"all", {"exhaust": true, "ethereal": true, "retain": true, "innate": true})
	assert_eq(KeywordGlossary.keywords_for_card(card),
			[&"innate", &"retain", &"ethereal", &"exhaust"] as Array[StringName])


func test_x_cost_and_block_keywords() -> void:
	var x_card := CardFactory.card(&"x", {"is_x_cost": true, "cost": 0})
	assert_true(KeywordGlossary.keywords_for_card(x_card).has(KeywordGlossary.X_COST))
	var block_effects: Array[EffectData] = [EffectData.create(EffectData.Type.BLOCK, 5, EffectData.Target.SELF)]
	var block_card := CardFactory.card(&"b", {"effects": block_effects, "target_mode": CardData.TargetMode.SELF})
	assert_eq(KeywordGlossary.keywords_for_card(block_card), [KeywordGlossary.BLOCK] as Array[StringName])


func test_plain_card_has_no_keywords() -> void:
	assert_eq(KeywordGlossary.keywords_for_card(CardFactory.card(&"plain")).size(), 0)
	assert_eq(KeywordGlossary.keywords_for_card(null).size(), 0)


func test_status_entry_uses_status_data_text() -> void:
	var entry := KeywordGlossary.status_entry(&"vulnerable", _statuses)
	var data := _statuses.get_status(&"vulnerable")
	assert_eq(entry.title, data.display_name)
	assert_eq(entry.text, data.description)
	assert_true(KeywordGlossary.status_entry(&"nope", _statuses) == null)
	assert_true(KeywordGlossary.status_entry(&"vulnerable", null) == null)


func test_status_ids_are_unique_and_in_effect_order() -> void:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"weak"),
		EffectData.create(EffectData.Type.APPLY_STATUS, 2, EffectData.Target.TARGET_ENEMY, 1, &"vulnerable"),
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"weak")]
	var card := CardFactory.card(&"two", {"effects": effects})
	assert_eq(KeywordGlossary.status_ids_for_card(card), [&"weak", &"vulnerable"] as Array[StringName])


func test_real_cards_get_the_expected_entries() -> void:
	assert_eq(_titles(KeywordGlossary.entries_for_card(_cards.get_card(&"strike"), _statuses)).size(), 0)
	assert_eq(_titles(KeywordGlossary.entries_for_card(_cards.get_card(&"defend"), _statuses)), ["Block"])
	assert_eq(_titles(KeywordGlossary.entries_for_card(_cards.get_card(&"bash"), _statuses)), ["Vulnerable"])
	assert_true(_titles(KeywordGlossary.entries_for_card(_cards.get_card(&"bandage_up"), _statuses)).has("Exhaust"))
	assert_true(_titles(KeywordGlossary.entries_for_card(_cards.get_card(&"whirlwind"), _statuses)).has("X"))


func test_entries_put_fixed_keywords_before_statuses() -> void:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"weak")]
	var card := CardFactory.card(&"mix", {"effects": effects, "exhaust": true})
	assert_eq(_titles(KeywordGlossary.entries_for_card(card, _statuses)), ["Exhaust", "Weak"])


func test_unknown_status_in_a_card_is_skipped_not_fatal() -> void:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, EffectData.Target.TARGET_ENEMY, 1, &"nope")]
	var card := CardFactory.card(&"odd", {"effects": effects})
	assert_eq(KeywordGlossary.entries_for_card(card, _statuses).size(), 0)


## Dữ liệu thật: mọi từ khóa và mọi status mà thẻ nhắc tới đều phải có chú giải đầy đủ chữ.
func test_every_real_card_has_complete_glossary_entries() -> void:
	for id in _cards.all_ids():
		var card := _cards.get_card(id)
		for keyword in KeywordGlossary.keywords_for_card(card):
			assert_true(KeywordGlossary.entry(keyword) != null, "%s: từ khóa %s" % [id, keyword])
		for status_id in KeywordGlossary.status_ids_for_card(card):
			var entry := KeywordGlossary.status_entry(status_id, _statuses)
			assert_true(entry != null, "%s: status %s có trong registry" % [id, status_id])
			if entry != null:
				assert_false(entry.text.strip_edges().is_empty(), "%s: mô tả status %s" % [id, status_id])
