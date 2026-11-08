class_name StatusIconUI
extends PanelContainer
## Một status: icon + số stack ở góc dưới phải (debuff viền đỏ). Thiếu icon -> chữ viết tắt.

## Hover -> báo tooltip lên trên (không tự hiện); rời chuột -> báo tắt.
signal tooltip_requested(tooltip: TooltipView, anchor: Rect2)
signal tooltip_cleared

const ICON_SIZE := Vector2(56, 56)
const BORDER_COLOR := Color("8a8f98")
const DEBUFF_BORDER_COLOR := Color("ff5a5a")
const BACKGROUND_COLOR := Color(0, 0, 0, 0.35)
const FALLBACK_LENGTH := 3
const AMOUNT_FONT_SIZE := 24

var view: StatusView = null
var icon_rect: TextureRect
var amount_label: Label
var fallback_label: Label
var _hovered: bool = false


func _init() -> void:
	custom_minimum_size = ICON_SIZE
	var holder := Control.new()
	holder.custom_minimum_size = ICON_SIZE
	add_child(holder)

	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(icon_rect)

	fallback_label = Label.new()
	fallback_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(fallback_label)

	amount_label = Label.new()
	amount_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	amount_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	amount_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	amount_label.add_theme_font_size_override("font_size", AMOUNT_FONT_SIZE)
	amount_label.add_theme_constant_override("outline_size", 4)
	amount_label.add_theme_color_override("font_outline_color", Color.BLACK)
	holder.add_child(amount_label)
	# PASS: nhận hover nhưng click vẫn đi lên (bấm vào status trên quái vẫn là chọn quái làm mục tiêu).
	mouse_filter = Control.MOUSE_FILTER_PASS
	UiUtil.ignore_mouse_in_children(self)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func is_hovered() -> bool:
	return _hovered


func show_view(new_view: StatusView) -> void:
	if new_view == null:
		push_error("StatusIconUI.show_view: view null")
		return
	view = new_view
	var texture := IconLibrary.get_icon(view.icon_id)
	icon_rect.texture = texture
	fallback_label.visible = texture == null
	fallback_label.text = view.title.substr(0, FALLBACK_LENGTH).to_upper()
	amount_label.text = str(view.amount)
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND_COLOR
	style.border_color = DEBUFF_BORDER_COLOR if view.is_debuff else BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	_hovered = true
	if view != null:
		tooltip_requested.emit(TooltipBuilder.for_status(view), get_global_rect())


func _on_mouse_exited() -> void:
	_hovered = false
	tooltip_cleared.emit()
