class_name BadgeUI
extends PanelContainer
## Ô vuông nhỏ: icon (hoặc chữ viết tắt khi thiếu icon) + viền màu. Nền chung của ô potion và icon relic.
## Chỉ vẽ và báo chuột (hover/bấm) lên trên; ý nghĩa của ô do lớp con và nơi dùng quyết định.

signal hover_started
signal hover_ended
signal pressed

const BADGE_SIZE := Vector2(72, 72)
const FALLBACK_LENGTH := 3
const FALLBACK_FONT_SIZE := 24
const BACKGROUND_COLOR := Color(0, 0, 0, 0.45)
const BORDER_WIDTH := 3
const CORNER_RADIUS := 8

var icon_rect: TextureRect
var fallback_label: Label
var _hovered: bool = false


func _init() -> void:
	custom_minimum_size = BADGE_SIZE
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon_rect)
	fallback_label = Label.new()
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", FALLBACK_FONT_SIZE)
	add_child(fallback_label)
	UiUtil.ignore_mouse_in_children(self)  # để chính ô nhận hover và click
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## icon_id rỗng hoặc thiếu file -> hiện `title` viết tắt (title rỗng -> ô trơn). alpha < 1: ô bị làm mờ.
func show_badge(icon_id: StringName, title: String, border_color: Color, alpha: float = 1.0) -> void:
	var texture := IconLibrary.get_icon(icon_id)
	icon_rect.texture = texture
	fallback_label.visible = texture == null
	fallback_label.text = title.substr(0, FALLBACK_LENGTH).to_upper()
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND_COLOR
	style.border_color = border_color
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	add_theme_stylebox_override("panel", style)
	modulate.a = alpha


func is_hovered() -> bool:
	return _hovered


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _on_mouse_entered() -> void:
	_hovered = true
	hover_started.emit()


func _on_mouse_exited() -> void:
	_hovered = false
	hover_ended.emit()
