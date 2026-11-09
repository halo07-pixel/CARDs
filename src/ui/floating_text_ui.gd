class_name FloatingTextUI
extends Label
## Chữ nổi: hiện tại một điểm, bay lên và mờ dần rồi tự giải phóng. Không nhận chuột.

const RISE := 70.0
const DURATION := 0.9
const FONT_SIZE := 64
const OUTLINE_SIZE := 10


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_constant_override("outline_size", OUTLINE_SIZE)
	add_theme_color_override("font_outline_color", Color.BLACK)


## Hiện `text` màu `color` với tâm đáy tại `origin` (toạ độ cục bộ của cha), sau `delay` giây (đã theo tốc độ).
## Gọi SAU khi đã add_child. config tắt -> tự giải phóng ngay.
func play(p_text: String, color: Color, origin: Vector2, delay: float, config: EffectsConfig) -> void:
	text = p_text
	add_theme_color_override("font_color", color)
	reset_size()
	position = origin - Vector2(size.x / 2.0, size.y)
	if config == null or not config.is_enabled() or not is_inside_tree():
		queue_free()
		return
	var duration := config.duration(DURATION)
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(_appear)
	tween.tween_property(self, "position:y", position.y - RISE, duration).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	tween.tween_callback(queue_free)


func _appear() -> void:
	modulate.a = 1.0
