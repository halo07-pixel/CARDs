class_name PotionBeltUI
extends HBoxContainer
## Dây potion: một PotionSlotUI cho mỗi ô, tạo MỘT lần khi bind (vẽ lại chỉ đổi nội dung ô, không giải phóng
## ô nào, nên bấm ô -> dùng potion -> dây đổi không giải phóng chính ô đang phát tín hiệu). Chỉ báo lên
## (slot_clicked, tooltip); việc dùng potion do BattleScene quyết (qua PotionIntent) và đổi trạng thái ở lõi.

signal slot_clicked(slot: int)
signal tooltip_requested(tooltip: TooltipView, anchor: Rect2)
signal tooltip_cleared

const SEPARATION := 12

var controller: BattleController = null
var slot_uis: Array[PotionSlotUI] = []


func _init() -> void:
	add_theme_constant_override("separation", SEPARATION)


## Gắn vào một trận (bỏ gắn trận cũ nếu có). Null -> không đổi gì (kèm log).
func bind(p_controller: BattleController) -> void:
	if p_controller == null:
		push_error("PotionBeltUI.bind: controller null")
		return
	unbind()
	controller = p_controller
	for i in controller.potions.capacity:
		var slot_ui := PotionSlotUI.new()
		slot_ui.clicked.connect(_on_slot_clicked)
		slot_ui.tooltip_requested.connect(_on_slot_tooltip_requested)
		slot_ui.tooltip_cleared.connect(_on_slot_tooltip_cleared)
		add_child(slot_ui)
		slot_uis.append(slot_ui)
	controller.potions.changed.connect(refresh)
	refresh()


func unbind() -> void:
	if controller == null:
		return
	controller.potions.changed.disconnect(refresh)
	controller = null
	for slot_ui in slot_uis:
		remove_child(slot_ui)
		slot_ui.free()
	slot_uis.clear()
	tooltip_cleared.emit()


## Vẽ lại mọi ô theo trạng thái hiện tại của trận (kể cả "dùng được hay không" theo lượt).
func refresh() -> void:
	if controller == null:
		return
	var views := PotionView.build_all(controller)
	for i in slot_uis.size():
		slot_uis[i].show_view(views[i])


## Ô đang chờ chọn mục tiêu được viền sáng; PotionIntent.NO_SLOT (hoặc -1) = không ô nào.
func set_selected_slot(slot: int) -> void:
	for i in slot_uis.size():
		slot_uis[i].set_selected(i == slot)


## Rung ô `slot` (bị từ chối). Trả false nếu ô không tồn tại hoặc hiệu ứng tắt.
func shake_slot(slot: int, effects: EffectsConfig) -> bool:
	if slot < 0 or slot >= slot_uis.size():
		return false
	return UiFx.shake(slot_uis[slot], effects)


func _on_slot_clicked(slot: int) -> void:
	slot_clicked.emit(slot)


func _on_slot_tooltip_requested(tooltip: TooltipView, anchor: Rect2) -> void:
	tooltip_requested.emit(tooltip, anchor)


func _on_slot_tooltip_cleared() -> void:
	tooltip_cleared.emit()
