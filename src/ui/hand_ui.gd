class_name HandUI
extends Control
## Tay bài: một hàng CardUI xếp chồng nhẹ cho vừa khung (tối đa 10 thẻ). Tự dựng lại khi controller đổi
## tay bài/năng lượng/chỉ số người chơi. Dựng lại bị TRÌ HOÃN tới cuối khung hình: bấm thẻ -> controller đổi
## tay -> nếu giải phóng ngay thì sẽ giải phóng chính CardUI đang phát tín hiệu click.

signal card_clicked(card: CardInstance)

const WIDTH := 1500.0
const CARD_GAP := 14.0
const SELECTED_RAISE := 40.0  ## thẻ thường nằm thấp hơn thẻ đang chọn đúng chừng này

var controller: BattleController = null
var card_uis: Array[CardUI] = []
var _cards_by_uid: Dictionary = {}
var _selected_uid: int = -1
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
	refresh()


## Dựng lại NGAY từ trạng thái hiện tại. Không gọi trong lúc đang xử lý tín hiệu của chính các thẻ
## (dùng request_refresh()).
func refresh() -> void:
	_refresh_pending = false
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
		add_child(card_ui)
		card_uis.append(card_ui)
		_cards_by_uid[card.uid] = card
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


func _apply_selection() -> void:
	for card_ui in card_uis:
		card_ui.set_highlighted(card_ui.view.uid == _selected_uid)
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
		var raised := card_ui.view.uid == _selected_uid
		card_ui.position = Vector2(start + step * i, 0.0 if raised else SELECTED_RAISE)


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
