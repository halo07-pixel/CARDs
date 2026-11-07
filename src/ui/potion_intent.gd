class_name PotionIntent
extends RefCounted
## Máy trạng thái thao tác "dùng một potion" của người chơi (click). Thuần logic, không node.
## Giống PlayIntent: luôn HỎI controller trước (potion_rejection_reason / valid_potion_targets) rồi mới
## trả quyết định; việc thực thi (controller.use_potion) do nơi gọi làm. Potion nhắm một quái: chỉ còn
## một quái sống thì tự nhắm, nhiều hơn thì chờ chọn mục tiêu (selected_slot).

enum Outcome { NOTHING, USE_NOW, NEED_TARGET, REJECTED, CANCELLED }

const NO_SLOT := -1


class Decision extends RefCounted:
	var outcome: Outcome = Outcome.NOTHING
	var slot: int = NO_SLOT
	var target: EnemyUnit = null
	var reason: StringName = &""


## Ô potion đang chờ chọn mục tiêu (NO_SLOT = không ở chế độ chọn mục tiêu).
var selected_slot: int = NO_SLOT


func is_targeting() -> bool:
	return selected_slot != NO_SLOT


## Lý do ô `slot` không dùng được lúc này (&"" = dùng được), CHƯA xét mục tiêu cụ thể: potion nhắm một
## quái được thử với quái sống đầu tiên (không có quái sống -> invalid_target). Không đổi gì.
static func slot_blocker(slot: int, controller: BattleController) -> StringName:
	var probe: EnemyUnit = null
	var targets := controller.valid_potion_targets(slot)
	if not targets.is_empty():
		probe = targets[0]
	return controller.potion_rejection_reason(slot, probe)


func select_slot(slot: int, controller: BattleController) -> Decision:
	if slot != NO_SLOT and slot == selected_slot:
		selected_slot = NO_SLOT
		return make_decision(Outcome.CANCELLED, slot)
	var reason := slot_blocker(slot, controller)
	if reason != &"":
		return make_decision(Outcome.REJECTED, slot, null, reason)  # giữ nguyên lựa chọn cũ (nếu có)
	var targets := controller.valid_potion_targets(slot)
	if targets.is_empty():  # potion không nhắm một quái
		selected_slot = NO_SLOT
		return make_decision(Outcome.USE_NOW, slot)
	if targets.size() == 1:
		selected_slot = NO_SLOT
		return make_decision(Outcome.USE_NOW, slot, targets[0])
	selected_slot = slot
	return make_decision(Outcome.NEED_TARGET, slot)


func choose_target(unit: EnemyUnit, controller: BattleController) -> Decision:
	if selected_slot == NO_SLOT:
		return make_decision(Outcome.NOTHING)
	var slot := selected_slot
	var reason := controller.potion_rejection_reason(slot, unit)
	if reason == BattleController.REASON_INVALID_TARGET and controller.valid_potion_targets(slot).size() > 0:
		return make_decision(Outcome.REJECTED, slot, null, reason)  # bấm nhầm quái: vẫn đang chọn
	selected_slot = NO_SLOT
	if reason != &"":  # potion không còn dùng được (hết lượt, ô trống...)
		return make_decision(Outcome.REJECTED, slot, null, reason)
	return make_decision(Outcome.USE_NOW, slot, unit)


## Bỏ chọn mục tiêu. Trả true nếu đang có ô được chọn.
func cancel() -> bool:
	var was_targeting := selected_slot != NO_SLOT
	selected_slot = NO_SLOT
	return was_targeting


## Bỏ lựa chọn nếu ô không còn dùng được. Trả true nếu có đổi.
func sync(controller: BattleController) -> bool:
	if selected_slot != NO_SLOT and slot_blocker(selected_slot, controller) != &"":
		selected_slot = NO_SLOT
		return true
	return false


static func make_decision(outcome: Outcome, slot: int = NO_SLOT, target: EnemyUnit = null,
		reason: StringName = &"") -> Decision:
	var decision := Decision.new()
	decision.outcome = outcome
	decision.slot = slot
	decision.target = target
	decision.reason = reason
	return decision
