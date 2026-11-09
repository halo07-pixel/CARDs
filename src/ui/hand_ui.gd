class_name HandUI
extends Control
## Tay bài: một hàng CardUI xếp chồng nhẹ cho vừa khung (tối đa 10 thẻ). Tự dựng lại khi controller đổi
## tay bài/năng lượng/chỉ số người chơi. Dựng lại bị TRÌ HOÃN tới cuối khung hình: bấm thẻ -> controller đổi
## tay -> nếu giải phóng ngay thì sẽ giải phóng chính CardUI đang phát tín hiệu click.

signal card_clicked(card: CardInstance)
## Kéo thả một thẻ trong tay (con trỏ theo toạ độ toàn cục): bắt đầu, đang kéo, nhả, huỷ giữa chừng.
signal drag_started(card: CardInstance, pointer: Vector2)
signal drag_moved(card: CardInstance, pointer: Vector2)
signal drag_ended(card: CardInstance, pointer: Vector2)
signal drag_cancelled(card: CardInstance)
## Trỏ chuột vào một thẻ (kèm vùng của thẻ, toạ độ toàn cục) / không còn trỏ thẻ nào. BattleScene dùng để hiện tooltip.
signal card_hovered(card: CardInstance, anchor: Rect2)
signal card_hover_ended

const WIDTH := 1500.0
const CARD_GAP := 14.0
const SELECTED_RAISE := 40.0  ## thẻ thường nằm thấp hơn thẻ đang chọn đúng chừng này
const HOVER_RAISE := 24.0  ## thẻ đang trỏ chuột nhô lên chừng này (vẫn thấp hơn thẻ đang chọn)
const DRAG_GRAB_OFFSET := Vector2(CardUI.CARD_SIZE.x / 2.0, CardUI.CARD_SIZE.y / 2.0)  ## thẻ đi theo con trỏ: con trỏ ở giữa thẻ

var controller: BattleController = null
var card_uis: Array[CardUI] = []
var _cards_by_uid: Dictionary = {}
var _selected_uid: int = -1
var _hovered_uid: int = -1
var _dragging_uid: int = -1
var _drag_follows: bool = false
var _refresh_pending: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, CardUI.CARD_SIZE.y + SELECTED_RAISE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # vùng trống không chặn click


## Gắn vào một trận (bỏ gắn trận cũ nếu có). Null -> không đổi gì (kèm log).
func bind(p_controller: BattleController) -> void:
	if p_controller == null:
		push_error("HandUI.bind: controller null")
		return
	unbind()
	controller = p_controller
	controller.deck.pile_changed.connect(_on_pile_changed)
	controller.energy_changed.connect(_on_energy_changed)
	controller.card_played.connect(_on_card_played)
	controller.player.status_changed.connect(_on_player_status_changed)
	refresh()


func unbind() -> void:
	if controller == null:
		return
	controller.deck.pile_changed.disconnect(_on_pile_changed)
	controller.energy_changed.disconnect(_on_energy_changed)
	controller.card_played.disconnect(_on_card_played)
	controller.player.status_changed.disconnect(_on_player_status_changed)
	controller = null
	_selected_uid = -1
	_hovered_uid = -1
	refresh()


## Dựng lại NGAY từ trạng thái hiện tại. Không gọi trong lúc đang xử lý tín hiệu của chính các thẻ
## (dùng request_refresh()).
func refresh() -> void:
	_refresh_pending = false
	_abort_drag_for_rebuild()
	if _hovered_uid != -1:
		card_hover_ended.emit()  # thẻ đang trỏ sắp bị thay
	for child in get_children():
		remove_child(child)
		child.free()
	card_uis.clear()
	_cards_by_uid.clear()
	if controller == null:
		return
	for card in controller.deck.get_pile(Deck.HAND):
		var card_ui := CardUI.new()
		card_ui.show_view(CardView.build(card, controller.player, null, controller.can_play(card)))
		card_ui.clicked.connect(_on_card_ui_clicked)
		card_ui.drag_started.connect(_on_card_drag_started)
		card_ui.drag_moved.connect(_on_card_drag_moved)
		card_ui.drag_ended.connect(_on_card_drag_ended)
		card_ui.drag_cancelled.connect(_on_card_drag_cancelled)
		card_ui.mouse_entered.connect(_on_card_hover_changed.bind(card.uid, true))
		card_ui.mouse_exited.connect(_on_card_hover_changed.bind(card.uid, false))
		add_child(card_ui)
		card_uis.append(card_ui)
		_cards_by_uid[card.uid] = card
	if not _cards_by_uid.has(_hovered_uid):
		_hovered_uid = -1
	_apply_selection()


## Dựng lại ở cuối khung hình hiện tại (nhiều yêu cầu liên tiếp chỉ dựng một lần).
func request_refresh() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("flush_pending_refresh")


func has_pending_refresh() -> bool:
	return _refresh_pending


func flush_pending_refresh() -> void:
	if _refresh_pending:
		refresh()


## Thẻ đang được chọn (viền sáng, nhô lên). Null = không chọn.
func set_selected(card: CardInstance) -> void:
	_selected_uid = card.uid if card != null else -1
	_apply_selection()


## Thẻ đang được trỏ chuột (nhô lên, vẽ trên cùng). Null = không có.
func set_hovered(card: CardInstance) -> void:
	_hovered_uid = card.uid if card != null else -1
	_layout()


## Rung thẻ `card` (bị từ chối). Trả false nếu thẻ không có trong tay hoặc hiệu ứng tắt.
func shake_card(card: CardInstance, effects: EffectsConfig) -> bool:
	if card == null:
		return false
	for card_ui in card_uis:
		if card_ui.view.uid == card.uid:
			return UiFx.shake(card_ui, effects)
	return false


## Vẽ lại thẻ `card` với số đã tính theo mục tiêu `target` (Vulnerable...). target null = số thường.
func set_preview_target(card: CardInstance, target: EnemyUnit) -> void:
	if controller == null or card == null:
		return
	for card_ui in card_uis:
		if card_ui.view.uid == card.uid:
			card_ui.show_view(CardView.build(card, controller.player, target.combatant if target != null else null,
					controller.can_play(card)))


func is_dragging() -> bool:
	return _dragging_uid != -1


## Bắt đầu kéo thẻ `card`. follow_pointer = true: thẻ đi theo con trỏ (thẻ không nhắm); false: thẻ nằm yên,
## nhô lên và sáng viền (thẻ nhắm một quái, mũi tên do nơi khác vẽ). Trả false nếu thẻ không có trong tay.
func begin_drag(card: CardInstance, follow_pointer: bool) -> bool:
	if card == null or not _cards_by_uid.has(card.uid):
		return false
	_dragging_uid = card.uid
	_drag_follows = follow_pointer
	if _hovered_uid != -1:
		_hovered_uid = -1
		card_hover_ended.emit()
	_apply_selection()
	return true


## Thẻ đang kéo (kiểu đi theo con trỏ) bám theo con trỏ toàn cục.
func move_drag(pointer: Vector2) -> void:
	if _dragging_uid == -1 or not _drag_follows:
		return
	for card_ui in card_uis:
		if card_ui.view.uid == _dragging_uid:
			card_ui.position = pointer - get_global_rect().position - DRAG_GRAB_OFFSET


## Kết thúc kéo: thẻ về đúng chỗ của nó trong tay.
func end_drag() -> void:
	_dragging_uid = -1
	_drag_follows = false
	_apply_selection()


## Huỷ lần kéo/bấm đang diễn ra trên bất kỳ thẻ nào. Trả true nếu có thẻ đang kéo (khi đó phát drag_cancelled).
func cancel_drag() -> bool:
	var cancelled := false
	for card_ui in card_uis:
		if card_ui.cancel_drag():
			cancelled = true
	return cancelled


## Vị trí toàn cục giữa cạnh trên của thẻ (gốc của mũi tên nhắm); Vector2.ZERO nếu thẻ không có trong tay.
func card_anchor(card: CardInstance) -> Vector2:
	for card_ui in card_uis:
		if card != null and card_ui.view.uid == card.uid:
			var rect := card_ui.get_global_rect()
			return Vector2(rect.get_center().x, rect.position.y)
	return Vector2.ZERO


func _apply_selection() -> void:
	for card_ui in card_uis:
		card_ui.set_highlighted(card_ui.view.uid == _selected_uid or _is_target_drag(card_ui.view.uid))
	_layout()


## Xếp thẻ thành một hàng giữa khung; nhiều thẻ thì chồng lên nhau cho vừa WIDTH.
func _layout() -> void:
	var count := card_uis.size()
	if count == 0:
		return
	var card_width := CardUI.CARD_SIZE.x
	var step := 0.0
	if count > 1:
		step = minf(card_width + CARD_GAP, (WIDTH - card_width) / (count - 1))
	var start := (WIDTH - (card_width + step * (count - 1))) / 2.0
	for i in count:
		var card_ui := card_uis[i]
		card_ui.size = CardUI.CARD_SIZE
		if card_ui.view.uid == _dragging_uid and _drag_follows:
			continue  # đang bám theo con trỏ: move_drag lo vị trí
		card_ui.position = Vector2(start + step * i, _row_y(card_ui.view.uid))
	_restack()


func _is_target_drag(uid: int) -> bool:
	return uid == _dragging_uid and not _drag_follows


func _row_y(uid: int) -> float:
	if uid == _selected_uid or _is_target_drag(uid):
		return 0.0
	return SELECTED_RAISE - HOVER_RAISE if uid == _hovered_uid else SELECTED_RAISE


## Thứ tự vẽ: theo vị trí trong tay; thẻ đang chọn rồi thẻ đang trỏ chuột vẽ trên cùng.
func _restack() -> void:
	for i in card_uis.size():
		move_child(card_uis[i], i)
	for uid in [_selected_uid, _hovered_uid, _dragging_uid]:
		for card_ui in card_uis:
			if card_ui.view.uid == uid:
				move_child(card_ui, -1)


func _on_card_hover_changed(uid: int, hovered: bool) -> void:
	var cleared := false
	if hovered:
		_hovered_uid = uid
	elif _hovered_uid == uid:
		_hovered_uid = -1
		cleared = true
	_layout()
	if hovered:
		var card: CardInstance = _cards_by_uid.get(uid)
		for card_ui in card_uis:
			if card != null and card_ui.view.uid == uid:
				card_hovered.emit(card, card_ui.get_global_rect())
	elif cleared:
		card_hover_ended.emit()


## Dựng lại sẽ thay mọi CardUI (mất chuột đang giữ): báo huỷ để bên ngoài dọn trạng thái kéo.
func _abort_drag_for_rebuild() -> void:
	if _dragging_uid == -1:
		return
	var card: CardInstance = _cards_by_uid.get(_dragging_uid)
	_dragging_uid = -1
	_drag_follows = false
	if card != null:
		drag_cancelled.emit(card)


func _on_card_drag_started(view: CardView, pointer: Vector2) -> void:
	var card: CardInstance = _cards_by_uid.get(view.uid)
	if card != null:
		drag_started.emit(card, pointer)


func _on_card_drag_moved(view: CardView, pointer: Vector2) -> void:
	var card: CardInstance = _cards_by_uid.get(view.uid)
	if card != null:
		drag_moved.emit(card, pointer)


func _on_card_drag_ended(view: CardView, pointer: Vector2) -> void:
	var card: CardInstance = _cards_by_uid.get(view.uid)
	if card != null:
		drag_ended.emit(card, pointer)


func _on_card_drag_cancelled(view: CardView) -> void:
	var card: CardInstance = _cards_by_uid.get(view.uid)
	if view.uid == _dragging_uid:
		end_drag()
	if card != null:
		drag_cancelled.emit(card)


func _on_card_ui_clicked(view: CardView) -> void:
	var card: CardInstance = _cards_by_uid.get(view.uid)
	if card != null:
		card_clicked.emit(card)


func _on_pile_changed(pile: StringName) -> void:
	if pile == Deck.HAND:
		request_refresh()


func _on_energy_changed(_old_energy: int, _new_energy: int) -> void:
	request_refresh()


func _on_card_played(_card: CardInstance, _target: EnemyUnit, _results: Array[EffectResult]) -> void:
	request_refresh()


func _on_player_status_changed(_status_id: StringName, _old_amount: int, _new_amount: int) -> void:
	request_refresh()
