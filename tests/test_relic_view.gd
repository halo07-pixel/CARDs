extends "res://tests/test_case.gd"
## RelicView: dữ liệu hiển thị của relic.

var _relics: RelicRegistry


func before_each() -> void:
	_relics = RelicRegistry.load_from_dir("res://data/relics")


func test_build_copies_relic_fields() -> void:
	var data := _relics.get_relic(&"anchor")
	var view := RelicView.build(data)
	assert_eq(view.relic_id, &"anchor")
	assert_eq(view.title, data.display_name)
	assert_eq(view.description, data.description)
	assert_eq(view.icon_id, data.icon_id)
	assert_eq(view.rarity, data.rarity)


func test_build_all_keeps_order_and_skips_null() -> void:
	var list: Array[RelicData] = [_relics.get_relic(&"vajra"), null, _relics.get_relic(&"anchor")]
	var views := RelicView.build_all(list)
	assert_eq(views.size(), 2)
	assert_eq(views[0].relic_id, &"vajra")
	assert_eq(views[1].relic_id, &"anchor")


func test_null_relic_gives_null_and_empty_input_gives_empty_list() -> void:
	assert_true(RelicView.build(null) == null)
	assert_eq(RelicView.build_all([] as Array[RelicData]).size(), 0)


func test_every_relic_in_data_builds_a_view_with_title_and_description() -> void:
	for id in _relics.all_ids():
		var view := RelicView.build(_relics.get_relic(id))
		assert_false(view.title.strip_edges().is_empty(), "%s: tên" % id)
		assert_false(view.description.strip_edges().is_empty(), "%s: mô tả" % id)
