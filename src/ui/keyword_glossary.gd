class_name KeywordGlossary
extends RefCounted
## Chú giải từ khóa của thẻ. Từ khóa cố định (Exhaust, Block...) có chữ ở đây; chú giải status lấy
## từ StatusData (tên + mô tả) nên không chép lại chữ. Thuần dữ liệu: không node, không sửa thẻ.

const INNATE := &"innate"
const RETAIN := &"retain"
const ETHEREAL := &"ethereal"
const EXHAUST := &"exhaust"
const X_COST := &"x_cost"
const BLOCK := &"block"

## Thứ tự hiển thị cố định trong tooltip.
const KEYWORD_ORDER: Array[StringName] = [INNATE, RETAIN, ETHEREAL, EXHAUST, X_COST, BLOCK]

const TEXTS := {
	INNATE: ["Innate", "Starts in your opening hand."],
	RETAIN: ["Retain", "Not discarded at the end of your turn."],
	ETHEREAL: ["Ethereal", "If not played this turn, this card is Exhausted."],
	EXHAUST: ["Exhaust", "Removed from play until the end of combat."],
	X_COST: ["X", "Spends all your remaining energy."],
	BLOCK: ["Block", "Absorbs damage before health. Removed at the start of your turn."],
}


## Mục chú giải của một từ khóa cố định; null nếu không biết từ khóa đó.
static func entry(keyword: StringName) -> GlossaryEntry:
	if not TEXTS.has(keyword):
		return null
	var texts: Array = TEXTS[keyword]
	return GlossaryEntry.create(texts[0], texts[1])


## Mục chú giải của một status (tên + mô tả từ dữ liệu); null nếu registry không có status đó.
static func status_entry(status_id: StringName, statuses: StatusRegistry) -> GlossaryEntry:
	if statuses == null or not statuses.has_status(status_id):
		return null
	return status_entry_from(statuses.get_status(status_id))


## Như status_entry nhưng từ một StatusData có sẵn; null nếu data null.
static func status_entry_from(data: StatusData) -> GlossaryEntry:
	if data == null:
		return null
	return GlossaryEntry.create(data.display_name, data.description)


## Từ khóa cố định mà thẻ có (theo thứ tự KEYWORD_ORDER). Thẻ null -> rỗng.
static func keywords_for_card(card: CardData) -> Array[StringName]:
	var found: Array[StringName] = []
	if card == null:
		return found
	var flags := {
		INNATE: card.innate,
		RETAIN: card.retain,
		ETHEREAL: card.ethereal,
		EXHAUST: card.exhaust,
		X_COST: card.is_x_cost,
		BLOCK: _has_effect(card, EffectData.Type.BLOCK),
	}
	for keyword in KEYWORD_ORDER:
		if flags[keyword]:
			found.append(keyword)
	return found


## Id status mà thẻ gắn/cộng (APPLY_STATUS), không trùng, theo thứ tự xuất hiện trong effects.
static func status_ids_for_card(card: CardData) -> Array[StringName]:
	var ids: Array[StringName] = []
	if card == null:
		return ids
	for effect in card.effects:
		if effect.type == EffectData.Type.APPLY_STATUS and not ids.has(effect.status_id):
			ids.append(effect.status_id)
	return ids


## Chú giải đầy đủ cho một thẻ: từ khóa cố định trước, rồi status. Status lạ (không có trong registry) bị bỏ.
static func entries_for_card(card: CardData, statuses: StatusRegistry) -> Array[GlossaryEntry]:
	return entries_for_card_with(card, func(status_id: StringName) -> StatusData:
		return statuses.get_status(status_id) if statuses != null and statuses.has_status(status_id) else null)


## Như entries_for_card nhưng tra status bằng `lookup(status_id) -> StatusData` (null nếu không có),
## để nơi chỉ có controller (get_status_data) cũng dùng được mà không cần giữ registry.
static func entries_for_card_with(card: CardData, lookup: Callable) -> Array[GlossaryEntry]:
	var entries: Array[GlossaryEntry] = []
	for keyword in keywords_for_card(card):
		entries.append(entry(keyword))
	for status_id in status_ids_for_card(card):
		var status := status_entry_from(lookup.call(status_id) as StatusData)
		if status != null:
			entries.append(status)
	return entries


static func _has_effect(card: CardData, type: EffectData.Type) -> bool:
	for effect in card.effects:
		if effect.type == type:
			return true
	return false
