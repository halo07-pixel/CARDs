class_name PlayZoneUI
extends Control
## Vùng thả mờ ("Release to play") hiện khi kéo thẻ không cần mục tiêu; sáng lên khi con trỏ nằm trong vùng.
## Hình dạng lấy từ DropIntent.play_zone (cùng nguồn với quyết định thả). Không nhận chuột.

const FILL_COLOR := Color(1, 1, 1, 0.05)
const ACTIVE_FILL_COLOR := Color(1.0, 0.85, 0.4, 0.09)
const BORDER_COLOR := Color(1, 1, 1, 0.25)
const ACTIVE_BORDER_COLOR := Color(1.0, 0.85, 0.4, 0.8)
const BORDER_WIDTH := 4.0
const LABEL_TEXT := "Release to play"
const LABEL_FONT_SIZE := 56
const LABEL_COLOR := Color(1, 1, 1, 0.45)
const LABEL_HEIGHT := 80.0
const LABEL_BOTTOM_MARGIN := 20.0  ## nhãn nằm sát đáy vùng thả để không bị quái/thẻ che

var active: bool = false
var label: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	label = Label.new()
	label.text = LABEL_TEXT
	label.size = Vector2(zone_rect().size.x, LABEL_HEIGHT)
	label.position = Vector2(0.0, zone_rect().size.y - LABEL_HEIGHT - LABEL_BOTTOM_MARGIN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	add_child(label)


func zone_rect() -> Rect2:
	return DropIntent.play_zone(DropIntent.DESIGN_SCREEN)


func show_zone() -> void:
	visible = true
	set_active(false)


func hide_zone() -> void:
	visible = false
	active = false
	queue_redraw()


func set_active(on: bool) -> void:
	active = on
	queue_redraw()


func _draw() -> void:
	draw_rect(zone_rect(), ACTIVE_FILL_COLOR if active else FILL_COLOR, true)
	draw_rect(zone_rect(), ACTIVE_BORDER_COLOR if active else BORDER_COLOR, false, BORDER_WIDTH)
