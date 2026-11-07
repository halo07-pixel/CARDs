class_name PotionView
extends RefCounted
## Dữ liệu HIỂN THỊ của một ô potion (view-model): UI chỉ đọc cái này, không biết luật chơi.
## Ô trống: is_empty = true, usable = false. `usable` do controller quyết định (PotionIntent.slot_blocker).

var slot: int = 0
var is_empty: bool = true
var potion_id: StringName = &""
var title: String = ""
var description: String = ""
var icon_id: StringName = &""
var rarity: PotionData.Rarity = PotionData.Rarity.COMMON
var needs_target: bool = false  ## potion nhắm một quái: dùng xong phải chọn mục tiêu
var usable: bool = false


## Một ô của dây potion. Null (kèm log) nếu thiếu controller hoặc dây potion.
static func build(slot_index: int, controller: BattleController) -> PotionView:
	if controller == null or controller.potions == null:
		push_error("PotionView.build: thiếu controller hoặc dây potion")
		return null
	var view := PotionView.new()
	view.slot = slot_index
	var potion := controller.potions.get_at(slot_index)
	if potion == null:
		return view
	view.is_empty = false
	view.potion_id = potion.id
	view.title = potion.display_name
	view.description = potion.description
	view.icon_id = potion.icon_id
	view.rarity = potion.rarity
	view.needs_target = potion.target_mode == CardData.TargetMode.SINGLE_ENEMY
	view.usable = PotionIntent.slot_blocker(slot_index, controller) == &""
	return view


## Mọi ô theo thứ tự (kể cả ô trống). Rỗng nếu thiếu controller hoặc dây potion.
static func build_all(controller: BattleController) -> Array[PotionView]:
	var views: Array[PotionView] = []
	if controller == null or controller.potions == null:
		push_error("PotionView.build_all: thiếu controller hoặc dây potion")
		return views
	for slot_index in controller.potions.capacity:
		views.append(build(slot_index, controller))
	return views
