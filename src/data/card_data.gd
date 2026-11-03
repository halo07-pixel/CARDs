class_name CardData
extends Resource
## Định nghĩa một loại thẻ (dữ liệu thuần). KHÔNG giữ Texture/Node: UI tự tra hình theo icon_id.
## Bản nâng cấp là một CardData riêng (id kết thúc bằng "+"), trỏ tới bằng upgraded_id.

enum CardType { ATTACK, SKILL, POWER }
enum Rarity { STARTER, COMMON, UNCOMMON, RARE }
enum TargetMode { SINGLE_ENEMY, ALL_ENEMIES, SELF, NONE }

const UPGRADE_SUFFIX := "+"

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var character_id: StringName = &""  ## rỗng = thẻ trung tính
@export var cost: int = 1
@export var is_x_cost: bool = false
@export var unplayable: bool = false
@export var x_bonus: int = 0  ## thẻ X-cost: các effect scales_with_x lặp X + x_bonus lần
@export var target_mode: TargetMode = TargetMode.SINGLE_ENEMY
@export var effects: Array[EffectData] = []
@export var exhaust: bool = false
@export var ethereal: bool = false
@export var innate: bool = false
@export var retain: bool = false
@export var upgraded_id: StringName = &""
@export var icon_id: StringName = &""


func is_upgrade() -> bool:
	return String(id).ends_with(UPGRADE_SUFFIX)


## Chế độ nhắm đúng suy ra từ các hiệu ứng (dùng để validate dữ liệu).
func expected_target_mode() -> TargetMode:
	return target_mode_for(effects)


## Chế độ nhắm suy ra từ danh sách effect (dùng chung cho thẻ và potion).
static func target_mode_for(effect_list: Array[EffectData]) -> TargetMode:
	var has_single := false
	var has_all := false
	var has_random := false
	for effect in effect_list:
		if effect == null:
			continue
		match effect.target:
			EffectData.Target.TARGET_ENEMY:
				has_single = true
			EffectData.Target.ALL_ENEMIES:
				has_all = true
			EffectData.Target.RANDOM_ENEMY:
				has_random = true
	if has_single:
		return TargetMode.SINGLE_ENEMY
	if has_all:
		return TargetMode.ALL_ENEMIES
	if has_random:
		return TargetMode.NONE
	return TargetMode.SELF


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if cost < 0:
		errors.append("cost không được âm (hiện %d)" % cost)
	if is_x_cost and cost != 0:
		errors.append("thẻ X-cost phải có cost = 0")
	if x_bonus < 0:
		errors.append("x_bonus không được âm (hiện %d)" % x_bonus)
	if x_bonus > 0 and not is_x_cost:
		errors.append("x_bonus chỉ dùng cho thẻ X-cost")
	if not unplayable and effects.is_empty():
		errors.append("thẻ chơi được phải có ít nhất 1 effect")
	for i in effects.size():
		var effect := effects[i]
		if effect == null:
			errors.append("effects[%d] là null" % i)
			continue
		for message: String in effect.validate():
			errors.append("effects[%d]: %s" % [i, message])
	var scaling_effects := 0
	for effect in effects:
		if effect != null and effect.scales_with_x:
			scaling_effects += 1
	if scaling_effects > 0 and not is_x_cost:
		errors.append("effect scales_with_x chỉ dùng cho thẻ X-cost")
	if is_x_cost and scaling_effects == 0:
		errors.append("thẻ X-cost phải có ít nhất 1 effect scales_with_x")
	if card_type == CardType.ATTACK and not _has_effect_type(EffectData.Type.DAMAGE):
		errors.append("thẻ ATTACK phải có effect DAMAGE")
	if not effects.is_empty() and target_mode != expected_target_mode():
		errors.append("target_mode %s không khớp effects (cần %s)" % [
			TargetMode.keys()[target_mode], TargetMode.keys()[expected_target_mode()]])
	if not upgraded_id.is_empty() and upgraded_id == id:
		errors.append("upgraded_id không được trùng id")
	if is_upgrade() and not upgraded_id.is_empty():
		errors.append("bản nâng cấp không được có upgraded_id")
	return errors


func _has_effect_type(type: EffectData.Type) -> bool:
	for effect in effects:
		if effect != null and effect.type == type:
			return true
	return false
