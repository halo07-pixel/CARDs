class_name IntentView
extends RefCounted
## Dữ liệu HIỂN THỊ ý định của quái: danh sách icon + chuỗi số ("6 x 2", "12" hoặc "?").
## Dựng từ IntentInfo (số đã tính Strength/Weak/Vulnerable); không có info -> ý định ẩn "?".

const ICON_ATTACK := &"intent_attack"
const ICON_DEFEND := &"intent_defend"
const ICON_BUFF := &"intent_buff"
const ICON_DEBUFF := &"intent_debuff"
const ICON_UNKNOWN := &"intent_unknown"
const UNKNOWN_TEXT := "?"

var icon_ids: Array[StringName] = []
var text: String = ""


static func build(info: IntentInfo) -> IntentView:
	var view := IntentView.new()
	if info == null:
		view.icon_ids.append(ICON_UNKNOWN)
		view.text = UNKNOWN_TEXT
		return view
	if info.attacks:
		view.icon_ids.append(ICON_ATTACK)
		view.text = _attack_text(info)
	if info.defends:
		view.icon_ids.append(ICON_DEFEND)
	if info.buffs:
		view.icon_ids.append(ICON_BUFF)
	if info.debuffs:
		view.icon_ids.append(ICON_DEBUFF)
	if view.icon_ids.is_empty():
		view.icon_ids.append(ICON_UNKNOWN)
		view.text = UNKNOWN_TEXT
	return view


static func _attack_text(info: IntentInfo) -> String:
	if info.hit_count > 1:
		return "%d x %d" % [info.damage_per_hit, info.hit_count]
	return str(info.damage_per_hit)
