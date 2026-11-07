class_name TooltipBuilder
extends RefCounted
## Dựng TooltipView từ view-model/dữ liệu. Thuần logic: không node, không sửa dữ liệu đầu vào.
## Đầu vào null -> trả null kèm log (lỗi gọi); đầu vào hợp lệ nhưng không có gì để hiện -> TooltipView rỗng.

const INTENT_TITLE := "Intent"
const INTENT_UNKNOWN := "Its intention is unknown."
const INTENT_ATTACK := "Will attack for %d damage."
const INTENT_ATTACK_MULTI := "Will attack for %d damage, %d times."
const INTENT_DEFEND := "Will gain Block."
const INTENT_BUFF := "Will strengthen itself."
const INTENT_DEBUFF := "Will weaken you."


static func for_status(view: StatusView) -> TooltipView:
	if view == null:
		push_error("TooltipBuilder.for_status: view null")
		return null
	return _titled(view.title, view.description)


static func for_relic(view: RelicView) -> TooltipView:
	if view == null:
		push_error("TooltipBuilder.for_relic: view null")
		return null
	return _titled(view.title, view.description)


## Ô potion trống -> tooltip rỗng (không có gì để hiện).
static func for_potion(view: PotionView) -> TooltipView:
	if view == null:
		push_error("TooltipBuilder.for_potion: view null")
		return null
	if view.is_empty:
		return TooltipView.new()
	return _titled(view.title, view.description)


## Thẻ: CHỈ chú giải từ khóa (thẻ đã tự hiện mô tả của nó). Thẻ không có từ khóa nào -> rỗng.
static func for_card(card: CardData, statuses: StatusRegistry) -> TooltipView:
	if card == null:
		push_error("TooltipBuilder.for_card: thẻ null")
		return null
	var view := TooltipView.new()
	view.entries = KeywordGlossary.entries_for_card(card, statuses)
	return view


## Ý định quái. info null (ý định ẩn) -> "unknown".
static func for_intent(info: IntentInfo) -> TooltipView:
	var view := TooltipView.new()
	view.title = INTENT_TITLE
	var lines: Array[String] = []
	if info != null:
		if info.attacks:
			lines.append(_attack_line(info))
		if info.defends:
			lines.append(INTENT_DEFEND)
		if info.buffs:
			lines.append(INTENT_BUFF)
		if info.debuffs:
			lines.append(INTENT_DEBUFF)
	if lines.is_empty():
		lines.append(INTENT_UNKNOWN)
	view.body = "\n".join(lines)
	return view


static func _attack_line(info: IntentInfo) -> String:
	if info.hit_count > 1:
		return INTENT_ATTACK_MULTI % [info.damage_per_hit, info.hit_count]
	return INTENT_ATTACK % info.damage_per_hit


static func _titled(title: String, body: String) -> TooltipView:
	var view := TooltipView.new()
	view.title = title
	view.body = body
	return view
