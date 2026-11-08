class_name PotionSlotUI
extends BadgeUI
## Một ô potion trên dây. Chỉ vẽ PotionView và báo lên: bấm (clicked) và hover (tooltip_requested/cleared).
## Ô trống mờ và trơn; potion chưa dùng được (sai lượt...) bị làm mờ. Không tự dùng potion.

signal clicked(slot: int)
signal tooltip_requested(tooltip: TooltipView, anchor: Rect2)
signal tooltip_cleared

const RARITY_COLORS := {
	PotionData.Rarity.COMMON: Color("b8bcc4"),
	PotionData.Rarity.UNCOMMON: Color("5aa9ff"),
	PotionData.Rarity.RARE: Color("ffc94a"),
}
const EMPTY_BORDER_COLOR := Color("454a55")
const SELECTED_BORDER_COLOR := Color(1, 1, 1)
const EMPTY_ALPHA := 0.5
const UNUSABLE_ALPHA := 0.45

var view: PotionView = null
var selected: bool = false


func _init() -> void:
	super()
	pressed.connect(_on_pressed)
	hover_started.connect(_emit_tooltip)
	hover_ended.connect(tooltip_cleared.emit)


## Vẽ lại theo view. Đang trỏ chuột vào ô thì tooltip cũng cập nhật (hoặc tắt khi ô vừa trống).
func show_view(new_view: PotionView) -> void:
	if new_view == null:
		push_error("PotionSlotUI.show_view: view null")
		return
	view = new_view
	_redraw()
	if is_hovered():
		_emit_tooltip()


## Viền trắng cho ô đang chờ chọn mục tiêu.
func set_selected(on: bool) -> void:
	selected = on
	if view != null:
		_redraw()


func _redraw() -> void:
	if view.is_empty:
		show_badge(&"", "", EMPTY_BORDER_COLOR, EMPTY_ALPHA)
		return
	var border: Color = SELECTED_BORDER_COLOR if selected else RARITY_COLORS.get(view.rarity, Color.WHITE)
	show_badge(view.icon_id, view.title, border, 1.0 if view.usable or selected else UNUSABLE_ALPHA)


func _emit_tooltip() -> void:
	if view == null or view.is_empty:
		tooltip_cleared.emit()
		return
	tooltip_requested.emit(TooltipBuilder.for_potion(view), get_global_rect())


func _on_pressed() -> void:
	if view != null:
		clicked.emit(view.slot)
