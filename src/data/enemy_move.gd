class_name EnemyMove
extends Resource
## Một chiêu của quái (dữ liệu thuần), dùng lại EffectData của thẻ.
## Với quái: TARGET_ENEMY / ALL_ENEMIES / RANDOM_ENEMY = phe người chơi, SELF = chính nó.

@export var id: StringName = &""
@export var display_name: String = ""
@export var effects: Array[EffectData] = []
@export var weight: int = 1            ## trọng số khi chọn ngẫu nhiên (pattern WEIGHTED)
@export var max_consecutive: int = 0   ## số lần liên tiếp tối đa (0 = không giới hạn)


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if effects.is_empty():
		errors.append("chiêu phải có ít nhất 1 effect")
	if weight < 1:
		errors.append("weight phải >= 1 (hiện %d)" % weight)
	if max_consecutive < 0:
		errors.append("max_consecutive không được âm (hiện %d)" % max_consecutive)
	for i in effects.size():
		var effect := effects[i]
		if effect == null:
			errors.append("effects[%d] là null" % i)
			continue
		for message: String in effect.validate():
			errors.append("effects[%d]: %s" % [i, message])
		if effect.scales_with_x:
			errors.append("effects[%d]: scales_with_x chỉ dùng cho thẻ X-cost" % i)
		if effect.type == EffectData.Type.DRAW or effect.type == EffectData.Type.GAIN_ENERGY:
			errors.append("effects[%d]: quái không dùng DRAW/GAIN_ENERGY" % i)
	return errors
