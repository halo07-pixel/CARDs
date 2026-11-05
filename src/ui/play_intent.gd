class_name PlayIntent
extends RefCounted
## Máy trạng thái thao tác "chơi một thẻ" của người chơi (click). Thuần logic, không node.
## Luôn HỎI controller trước (play_rejection_reason / valid_targets) rồi mới trả quyết định; việc thực thi
## (controller.play_card) do nơi gọi làm. Thẻ nhắm một quái: chỉ còn một quái sống thì tự nhắm,
## nhiều hơn thì chờ chọn mục tiêu (selected).

enum Outcome { NOTHING, PLAY_NOW, NEED_TARGET, REJECTED, CANCELLED }


class Decision extends RefCounted:
	var outcome: Outcome = Outcome.NOTHING
	var card: CardInstance = null
	var target: EnemyUnit = null
	var reason: StringName = &""


## Thẻ đang chờ chọn mục tiêu (null = không ở chế độ chọn mục tiêu).
var selected: CardInstance = null


func is_targeting() -> bool:
	return selected != null


func select_card(card: CardInstance, controller: BattleController) -> Decision:
	if card != null and card == selected:
		selected = null
		return make_decision(Outcome.CANCELLED, card)
	var reason := controller.play_rejection_reason(card)
	if reason != &"":
		return make_decision(Outcome.REJECTED, card, null, reason)  # giữ nguyên lựa chọn cũ (nếu có)
	if card.data.target_mode != CardData.TargetMode.SINGLE_ENEMY:
		selected = null
		return make_decision(Outcome.PLAY_NOW, card)
	var targets := controller.valid_targets(card)
	if targets.is_empty():
		return make_decision(Outcome.REJECTED, card, null, BattleController.REASON_INVALID_TARGET)
	if targets.size() == 1:
		selected = null
		return make_decision(Outcome.PLAY_NOW, card, targets[0])
	selected = card
	return make_decision(Outcome.NEED_TARGET, card)


func choose_target(unit: EnemyUnit, controller: BattleController) -> Decision:
	if selected == null:
		return make_decision(Outcome.NOTHING)
	var card := selected
	var reason := controller.play_rejection_reason(card)
	if reason != &"":
		selected = null  # thẻ không còn chơi được (hết năng lượng, đổi lượt...)
		return make_decision(Outcome.REJECTED, card, null, reason)
	if not controller.valid_targets(card).has(unit):
		return make_decision(Outcome.REJECTED, card, null, BattleController.REASON_INVALID_TARGET)
	selected = null
	return make_decision(Outcome.PLAY_NOW, card, unit)


## Bỏ chọn mục tiêu. Trả true nếu đang có thẻ được chọn.
func cancel() -> bool:
	var was_targeting := selected != null
	selected = null
	return was_targeting


## Bỏ lựa chọn nếu thẻ không còn chơi được. Trả true nếu có đổi.
func sync(controller: BattleController) -> bool:
	if selected != null and controller.play_rejection_reason(selected) != &"":
		selected = null
		return true
	return false


static func make_decision(outcome: Outcome, card: CardInstance = null, target: EnemyUnit = null,
		reason: StringName = &"") -> Decision:
	var decision := Decision.new()
	decision.outcome = outcome
	decision.card = card
	decision.target = target
	decision.reason = reason
	return decision
