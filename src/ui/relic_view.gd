class_name RelicView
extends RefCounted
## Dữ liệu HIỂN THỊ của một relic (view-model). Relic chỉ để xem (không bấm để dùng).

var relic_id: StringName = &""
var title: String = ""
var description: String = ""
var icon_id: StringName = &""
var rarity: RelicData.Rarity = RelicData.Rarity.COMMON


## Null (kèm log) nếu relic null.
static func build(relic: RelicData) -> RelicView:
	if relic == null:
		push_error("RelicView.build: relic null")
		return null
	var view := RelicView.new()
	view.relic_id = relic.id
	view.title = relic.display_name
	view.description = relic.description
	view.icon_id = relic.icon_id
	view.rarity = relic.rarity
	return view


## Mọi relic theo thứ tự nhặt (giữ nguyên thứ tự danh sách); bỏ qua phần tử null.
static func build_all(relics: Array[RelicData]) -> Array[RelicView]:
	var views: Array[RelicView] = []
	for relic in relics:
		var view := build(relic)
		if view != null:
			views.append(view)
	return views
