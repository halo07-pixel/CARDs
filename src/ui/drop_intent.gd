class_name DropIntent
extends RefCounted
## Quyết định khi người chơi NHẢ một thẻ đang kéo. Thuần logic: nhận thẻ, quái đang nằm dưới con trỏ,
## con trỏ có trong vùng thả hay không; luôn HỎI controller trước (play_rejection_reason / valid_targets).
## Trả PlayIntent.Decision: PLAY_NOW (chơi, kèm mục tiêu nếu có), CANCELLED (thẻ quay về tay, không tốn gì)
## hoặc REJECTED (kèm lý do). Việc thực thi (controller.play_card) do nơi gọi làm.

const PLAY_ZONE_HEIGHT_RATIO := 0.6  ## vùng thả = phần trên của màn hình, kết thúc trước tay bài


static func play_zone(screen_size: Vector2) -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(screen_size.x, screen_size.y * PLAY_ZONE_HEIGHT_RATIO))


static func is_in_play_zone(point: Vector2, screen_size: Vector2) -> bool:
	return play_zone(screen_size).has_point(point)


static func decide(card: CardInstance, enemy_under_pointer: EnemyUnit, in_play_zone: bool,
		controller: BattleController) -> PlayIntent.Decision:
	var reason := controller.play_rejection_reason(card)
	if reason != &"":
		return PlayIntent.make_decision(PlayIntent.Outcome.REJECTED, card, null, reason)
	if card.data.target_mode != CardData.TargetMode.SINGLE_ENEMY:
		var outcome := PlayIntent.Outcome.PLAY_NOW if in_play_zone else PlayIntent.Outcome.CANCELLED
		return PlayIntent.make_decision(outcome, card)
	var targets := controller.valid_targets(card)
	if enemy_under_pointer != null:
		if targets.has(enemy_under_pointer):
			return PlayIntent.make_decision(PlayIntent.Outcome.PLAY_NOW, card, enemy_under_pointer)
		return PlayIntent.make_decision(PlayIntent.Outcome.REJECTED, card, null, BattleController.REASON_INVALID_TARGET)
	if in_play_zone and targets.size() == 1:
		return PlayIntent.make_decision(PlayIntent.Outcome.PLAY_NOW, card, targets[0])  # tự nhắm như khi click
	return PlayIntent.make_decision(PlayIntent.Outcome.CANCELLED, card)


## Quái đang nằm dưới con trỏ mà là mục tiêu HỢP LỆ của thẻ (để tô nổi mũi tên và xem trước số); không thì null.
static func hover_target(card: CardInstance, enemy_under_pointer: EnemyUnit,
		controller: BattleController) -> EnemyUnit:
	if card == null or enemy_under_pointer == null or card.data.target_mode != CardData.TargetMode.SINGLE_ENEMY:
		return null
	return enemy_under_pointer if controller.valid_targets(card).has(enemy_under_pointer) else null
