class_name CardTextFormatter
extends RefCounted
## Biến mô tả thẻ ("Deal {damage} damage.") thành chữ hiển thị. Thuần dữ liệu: không node, không sửa thẻ.
## Mỗi {token} suy ra từ chính `effects` của thẻ: damage, block, draw, energy, heal, hp (LOSE_HP)
## và {<status_id>} cho APPLY_STATUS. Token xuất hiện nhiều lần trong effects -> lấy cái đầu tiên.
## Có owner thì {damage}/{block} đã tính Strength/Weak/Dexterity/Frail; có target thì tính cả Vulnerable.

const COLOR_UP := "#7ee06a"  ## số lớn hơn gốc (chỉ dùng khi bbcode = true)
const COLOR_DOWN := "#ff7070"  ## số nhỏ hơn gốc
const TOKEN_PATTERN := "\\{([a-z_]+)\\}"

static var _token_regex: RegEx = null


## Giá trị GỐC (trong dữ liệu) theo token. Rỗng nếu thẻ null.
static func base_values(card: CardData) -> Dictionary:
	var values: Dictionary = {}
	if card == null:
		return values
	for effect in card.effects:
		var key := _token_for(effect)
		if key != &"" and not values.has(key):
			values[key] = effect.amount
	return values


## Giá trị cuối cùng (đã tính chỉ số của owner/target). owner null -> trả giá trị gốc.
static func final_values(card: CardData, owner: Combatant = null, target: Combatant = null) -> Dictionary:
	var values := base_values(card)
	if owner == null:
		return values
	if values.has(&"damage"):
		var defender: Combatant = target if target != null else Combatant.create(&"neutral", "neutral", 1)
		values[&"damage"] = DamageCalculator.compute_damage(values[&"damage"], owner, defender)
	if values.has(&"block"):
		values[&"block"] = DamageCalculator.compute_block(values[&"block"], owner)
	return values


## Chữ mô tả đã thay số. Token lạ giữ nguyên (xem unresolved_tokens). bbcode = true: tô màu số đã bị đổi.
static func format(card: CardData, owner: Combatant = null, target: Combatant = null,
		bbcode: bool = false) -> String:
	if card == null:
		return ""
	var originals := base_values(card)
	var shown := final_values(card, owner, target)
	var text := card.description
	var result := ""
	var cursor := 0
	for found in _regex().search_all(text):
		result += text.substr(cursor, found.get_start() - cursor)
		var key := StringName(found.get_string(1))
		result += _render(key, originals, shown, bbcode) if shown.has(key) else found.get_string()
		cursor = found.get_end()
	return result + text.substr(cursor)


## Các token trong mô tả mà effects không cung cấp (lỗi dữ liệu). Rỗng = mọi token đều có giá trị.
static func unresolved_tokens(card: CardData) -> Array[String]:
	var missing: Array[String] = []
	if card == null:
		return missing
	var known := base_values(card)
	for found in _regex().search_all(card.description):
		var key := found.get_string(1)
		if not known.has(StringName(key)) and not missing.has(key):
			missing.append(key)
	return missing


static func _render(key: StringName, originals: Dictionary, shown: Dictionary, bbcode: bool) -> String:
	var value: int = shown[key]
	var original: int = originals[key]
	if not bbcode or value == original:
		return str(value)
	return "[color=%s]%d[/color]" % [COLOR_UP if value > original else COLOR_DOWN, value]


static func _token_for(effect: EffectData) -> StringName:
	match effect.type:
		EffectData.Type.DAMAGE:
			return &"damage"
		EffectData.Type.BLOCK:
			return &"block"
		EffectData.Type.DRAW:
			return &"draw"
		EffectData.Type.GAIN_ENERGY:
			return &"energy"
		EffectData.Type.HEAL:
			return &"heal"
		EffectData.Type.LOSE_HP:
			return &"hp"
		EffectData.Type.APPLY_STATUS:
			return effect.status_id
	return &""


static func _regex() -> RegEx:
	if _token_regex == null:
		_token_regex = RegEx.create_from_string(TOKEN_PATTERN)
	return _token_regex
