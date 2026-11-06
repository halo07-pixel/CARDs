class_name TargetArrowUI
extends Control
## Mũi tên nhắm từ thẻ tới con trỏ (hình học do ArrowGeometry tính). Trắng khi chưa trúng mục tiêu hợp lệ,
## đỏ khi đang trỏ vào quái hợp lệ. Không nhận chuột.

const NEUTRAL_COLOR := Color(1, 1, 1, 0.75)
const VALID_COLOR := Color("ff5a5a")
const SHAFT_WIDTH := 14.0

var shape: ArrowShape = null
var on_valid_target: bool = false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_arrow(from: Vector2, to: Vector2, p_on_valid_target: bool) -> void:
	shape = ArrowGeometry.build(from, to)
	on_valid_target = p_on_valid_target
	visible = true
	queue_redraw()


func hide_arrow() -> void:
	shape = null
	on_valid_target = false
	visible = false
	queue_redraw()


func current_color() -> Color:
	return VALID_COLOR if on_valid_target else NEUTRAL_COLOR


func _draw() -> void:
	if shape == null:
		return
	var color := current_color()
	if shape.shaft.size() >= 2 and shape.shaft[0] != shape.shaft[shape.shaft.size() - 1]:
		draw_polyline(shape.shaft, color, SHAFT_WIDTH, true)
	draw_colored_polygon(shape.head, color)
