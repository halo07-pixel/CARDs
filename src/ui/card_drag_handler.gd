class_name CardDragHandler
extends RefCounted
## Máy trạng thái kéo thả thẻ: bắt đầu (hỏi lõi trước), bám con trỏ (mũi tên + xem trước số, hoặc thẻ bám theo + vùng thả),
## thả (DropIntent quyết), huỷ. Giữ tham chiếu tới các phần giao diện (không sở hữu chúng). Mọi việc ngoài phạm vi kéo
## (bỏ lựa chọn bằng click, hiện thông báo, thực thi quyết định, đồng bộ chọn mục tiêu) báo lên bằng tín hiệu.

## Sắp bắt đầu kéo (đã qua kiểm tra của lõi, CHƯA dựng gì): bên nghe bỏ lựa chọn bằng click, ẩn tooltip, xoá thông báo.
signal started(card: CardInstance)
## Không bắt đầu kéo được (lõi từ chối); handler đã huỷ lần kéo bên HandUI.
signal rejected(card: CardInstance, reason: StringName)
## Thả xong và đã dọn: bên nghe thực thi quyết định (đúng thứ tự: `finished` rồi mới tới `dropped`).
signal dropped(decision: PlayIntent.Decision)
## Mọi dấu vết của lần kéo đã dọn (mũi tên, vùng thả, xem trước, viền sáng): bên nghe đồng bộ chọn mục tiêu.
signal finished

var _hand_ui: HandUI
var _play_zone: PlayZoneUI
var _arrow: TargetArrowUI
var _enemy_uis: Array[EnemyUI]  ## cùng đối tượng mảng với BattleScene.enemy_uis (chỉ clear/append nên tham chiếu bền)
var _controller: BattleController = null
var _dragged: CardInstance = null
var _preview_unit: EnemyUnit = null


func _init(hand_ui: HandUI, play_zone: PlayZoneUI, arrow: TargetArrowUI, enemy_uis: Array[EnemyUI]) -> void:
	_hand_ui = hand_ui
	_play_zone = play_zone
	_arrow = arrow
	_enemy_uis = enemy_uis


func bind(controller: BattleController) -> void:
	_controller = controller


## Dọn lần kéo đang dở (nếu có) rồi gỡ khỏi trận.
func unbind() -> void:
	finish()
	_controller = null


func is_dragging() -> bool:
	return _dragged != null


func start(card: CardInstance, pointer: Vector2) -> void:
	if _controller == null:
		return
	var reason := _controller.play_rejection_reason(card)
	if reason != &"":
		_hand_ui.cancel_drag()  # không bắt đầu kéo thẻ không chơi được
		rejected.emit(card, reason)
		return
	started.emit(card)
	_dragged = card
	var single_target := card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY
	_hand_ui.begin_drag(card, not single_target)
	if single_target:
		var valid := _controller.valid_targets(card)
		for enemy_ui in _enemy_uis:
			enemy_ui.set_targetable(valid.has(enemy_ui.unit))
	else:
		_play_zone.show_zone()
	_update(pointer)


func move(card: CardInstance, pointer: Vector2) -> void:
	if _dragged == card:
		_update(pointer)


func end(card: CardInstance, pointer: Vector2) -> void:
	if _dragged != card or _controller == null:
		return
	var unit := EnemyHitTest.unit_at(pointer, _enemy_uis)
	var decision := DropIntent.decide(card, unit, DropIntent.is_in_play_zone(pointer, DropIntent.DESIGN_SCREEN), _controller)
	finish()
	dropped.emit(decision)


func cancel(card: CardInstance) -> void:
	if _dragged == card:
		finish()


## Dọn mọi dấu vết của lần kéo rồi báo `finished`. An toàn khi không có lần kéo nào.
func finish() -> void:
	var card := _dragged
	_dragged = null
	_preview_unit = null
	_arrow.hide_arrow()
	_play_zone.hide_zone()
	if card != null:
		_hand_ui.set_preview_target(card, null)
	_hand_ui.end_drag()
	finished.emit()


## Cập nhật theo con trỏ: thẻ nhắm -> mũi tên + xem trước số theo quái đang trỏ; thẻ khác -> thẻ bám theo + vùng thả.
func _update(pointer: Vector2) -> void:
	var unit := EnemyHitTest.unit_at(pointer, _enemy_uis)
	if _dragged.data.target_mode == CardData.TargetMode.SINGLE_ENEMY:
		var hovered := DropIntent.hover_target(_dragged, unit, _controller)
		_arrow.show_arrow(_hand_ui.card_anchor(_dragged), pointer, hovered != null)
		if hovered != _preview_unit:
			_preview_unit = hovered
			_hand_ui.set_preview_target(_dragged, hovered)
	else:
		_hand_ui.move_drag(pointer)
		_play_zone.set_active(DropIntent.is_in_play_zone(pointer, DropIntent.DESIGN_SCREEN))
