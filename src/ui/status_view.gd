class_name StatusView
extends RefCounted
## Dữ liệu HIỂN THỊ của một status đang có trên một Combatant (view-model, UI chỉ đọc).

var status_id: StringName = &""
var title: String = ""
var description: String = ""
var amount: int = 0
var icon_id: StringName = &""
var is_debuff: bool = false


## Null nếu owner không có status đó (số stack = 0). Null owner -> null kèm log.
static func build(owner: Combatant, status_id: StringName) -> StatusView:
	if owner == null:
		push_error("StatusView.build: thiếu owner")
		return null
	if not owner.has_status(status_id):
		return null
	var data := owner.get_status_data(status_id)
	var view := StatusView.new()
	view.status_id = status_id
	view.title = data.display_name
	view.description = data.description
	view.amount = owner.get_status(status_id)
	view.icon_id = data.icon_id
	view.is_debuff = data.is_debuff
	return view


## Mọi status của owner: buff trước, debuff sau; mỗi nhóm theo thứ tự chữ cái của id (ổn định giữa các lần chạy).
static func build_all(owner: Combatant) -> Array[StatusView]:
	var views: Array[StatusView] = []
	if owner == null:
		return views
	var ids := owner.get_status_ids()
	# Không dùng ids.sort(): StringName so sánh theo địa chỉ bộ nhớ nên thứ tự đổi giữa các lần chạy.
	ids.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	for debuffs in [false, true]:
		for id in ids:
			var view := build(owner, id)
			if view != null and view.is_debuff == debuffs:
				views.append(view)
	return views
