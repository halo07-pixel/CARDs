class_name RelicBarUI
extends HFlowContainer
## Thanh relic: một RelicIconUI cho mỗi relic của trận (xuống dòng khi nhiều). Relic không đổi trong trận
## nên dựng một lần khi bind. Chỉ báo hover (tooltip) lên trên.

signal tooltip_requested(tooltip: TooltipView, anchor: Rect2)
signal tooltip_cleared

const BAR_WIDTH := 420.0
const SEPARATION := 8

var controller: BattleController = null
var icon_uis: Array[RelicIconUI] = []


func _init() -> void:
	custom_minimum_size = Vector2(BAR_WIDTH, 0)
	add_theme_constant_override("h_separation", SEPARATION)
	add_theme_constant_override("v_separation", SEPARATION)


## Gắn vào một trận (bỏ gắn trận cũ nếu có). Null -> không đổi gì (kèm log).
func bind(p_controller: BattleController) -> void:
	if p_controller == null:
		push_error("RelicBarUI.bind: controller null")
		return
	unbind()
	controller = p_controller
	for view in RelicView.build_all(controller.relics):
		var icon_ui := RelicIconUI.new()
		icon_ui.show_view(view)
		icon_ui.tooltip_requested.connect(_on_icon_tooltip_requested)
		icon_ui.tooltip_cleared.connect(_on_icon_tooltip_cleared)
		add_child(icon_ui)
		icon_uis.append(icon_ui)


func unbind() -> void:
	if controller == null:
		return
	controller = null
	for icon_ui in icon_uis:
		remove_child(icon_ui)
		icon_ui.free()
	icon_uis.clear()
	tooltip_cleared.emit()


func _on_icon_tooltip_requested(tooltip: TooltipView, anchor: Rect2) -> void:
	tooltip_requested.emit(tooltip, anchor)


func _on_icon_tooltip_cleared() -> void:
	tooltip_cleared.emit()
