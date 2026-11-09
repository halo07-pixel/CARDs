class_name UiFx
extends RefCounted
## Hiệu ứng ngắn dùng chung cho control: rung (lắc xoay) và nảy (phóng to rồi về, có thể kèm nháy sáng).
## Chỉ đổi rotation/scale/modulate (container không ghi đè các thuộc tính này, khác position).
## Luôn về đúng trạng thái gốc kể cả khi bị ngắt giữa chừng bằng hiệu ứng mới. Tắt (speed 0) hoặc control chưa
## ở trong cây -> không làm gì (trả false). Tween gắn vào control nên tự hủy khi control bị giải phóng.

const SHAKE_DURATION := 0.3
const SHAKE_ANGLE := 0.07  ## radian
const POP_DURATION := 0.2
const POP_SCALE := 1.08
const FLASH_COLOR := Color(1.7, 1.7, 1.7)
const TWEEN_META := &"ui_fx_tween"
const MODULATE_META := &"ui_fx_modulate"


static func shake(control: Control, config: EffectsConfig) -> bool:
	if not _can_play(control, config):
		return false
	_reset(control)
	control.pivot_offset = control.size / 2.0
	var step := config.duration(SHAKE_DURATION) / 4.0
	var tween := _start(control)
	tween.tween_property(control, "rotation", SHAKE_ANGLE, step)
	tween.tween_property(control, "rotation", -SHAKE_ANGLE, step)
	tween.tween_property(control, "rotation", SHAKE_ANGLE / 2.0, step)
	tween.tween_property(control, "rotation", 0.0, step)
	return true


## flash = true: nháy sáng bằng modulate (chỉ dùng cho control không dùng modulate để làm mờ).
static func pop(control: Control, config: EffectsConfig, flash: bool = false) -> bool:
	if not _can_play(control, config):
		return false
	_reset(control)
	control.pivot_offset = control.size / 2.0
	var half := config.duration(POP_DURATION) / 2.0
	var tween := _start(control)
	tween.tween_property(control, "scale", Vector2.ONE * POP_SCALE, half)
	tween.tween_property(control, "scale", Vector2.ONE, half)
	if flash:
		control.set_meta(MODULATE_META, control.modulate)
		control.modulate = FLASH_COLOR
		tween.parallel().tween_property(control, "modulate", control.get_meta(MODULATE_META), half * 2.0)
	return true


## Đưa control về trạng thái gốc và hủy hiệu ứng đang chạy (an toàn khi gọi nhiều lần).
static func reset(control: Control) -> void:
	if control != null:
		_reset(control)


static func _can_play(control: Control, config: EffectsConfig) -> bool:
	return control != null and config != null and config.is_enabled() and control.is_inside_tree()


static func _start(control: Control) -> Tween:
	var tween := control.create_tween()
	control.set_meta(TWEEN_META, tween)
	tween.finished.connect(_on_finished.bind(control))
	return tween


static func _reset(control: Control) -> void:
	var running := control.get_meta(TWEEN_META, null) as Tween
	if running != null and running.is_valid():
		running.kill()
	control.remove_meta(TWEEN_META)
	control.rotation = 0.0
	control.scale = Vector2.ONE
	if control.has_meta(MODULATE_META):
		control.modulate = control.get_meta(MODULATE_META)
		control.remove_meta(MODULATE_META)


static func _on_finished(control: Control) -> void:
	if is_instance_valid(control):
		control.remove_meta(TWEEN_META)
		control.remove_meta(MODULATE_META)
