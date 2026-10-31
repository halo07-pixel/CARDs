class_name PotionData
extends Resource
## Định nghĩa một potion (dữ liệu thuần), dùng lại EffectData. Dùng được ở lượt người chơi, không
## tốn năng lượng. Sát thương của potion dùng công thức chuẩn nhưng KHÔNG tính là "đòn tấn công"
## (không kích hoạt Thorns...). LƯU Ý: enum lưu dạng số nguyên -> giá trị mới thêm vào CUỐI.

enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_id: StringName = &""
@export var rarity: Rarity = Rarity.COMMON
@export var target_mode: CardData.TargetMode = CardData.TargetMode.SELF
@export var effects: Array[EffectData] = []


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if effects.is_empty():
		errors.append("potion phải có ít nhất 1 effect")
	for i in effects.size():
		var effect := effects[i]
		if effect == null:
			errors.append("effects[%d] là null" % i)
			continue
		for message: String in effect.validate():
			errors.append("effects[%d]: %s" % [i, message])
		if effect.scales_with_x:
			errors.append("effects[%d]: scales_with_x chỉ dùng cho thẻ X-cost" % i)
	var expected := CardData.target_mode_for(effects)
	if not effects.is_empty() and target_mode != expected:
		errors.append("target_mode %s không khớp effects (cần %s)" % [
			CardData.TargetMode.keys()[target_mode], CardData.TargetMode.keys()[expected]])
	return errors
