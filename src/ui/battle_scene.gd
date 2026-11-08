class_name BattleScene
extends Control
## Màn chiến đấu: ghép HandUI, EnemyUI, CombatantUI, EnergyUI, PileCounterUI, nút End Turn, lớp phủ kết quả.
## Cũng có dây potion, thanh relic, tooltip và lớp phủ xem pile. Sở hữu PlayIntent (chơi thẻ) và PotionIntent (dùng potion). UI KHÔNG đổi lõi: chỉ gọi controller.play_card /
## end_player_turn và vẽ lại theo Signal (call down, signal up). Lượt quái chạy tức thì (animation: mốc 3.6).
## Dùng: scene.setup(controller) -> controller.start_battle(); đổi trận: setup(controller_mới); dọn: teardown().

signal restart_requested

const BACKGROUND_COLOR := Color("1c2030")
const ENEMY_ROW_Y := 40.0
const ENEMY_GAP := 90
const SCREEN_WIDTH := 1920.0
const HERO_POSITION := Vector2(60, 500)
const HERO_WIDTH := 420.0
const POTION_BELT_POSITION := Vector2(60, 410)
const RELIC_BAR_POSITION := Vector2(40, 90)
const HAND_POSITION := Vector2(210, 720)
const ENERGY_POSITION := Vector2(40, 900)
const DRAW_POSITION := Vector2(40, 780)
const DISCARD_POSITION := Vector2(1750, 900)
const EXHAUST_POSITION := Vector2(1750, 790)
const END_TURN_POSITION := Vector2(1700, 660)
const END_TURN_SIZE := Vector2(190, 80)
const END_TURN_FONT_SIZE := 32
const TURN_POSITION := Vector2(40, 30)
const TURN_FONT_SIZE := 36
const MESSAGE_POSITION := Vector2(460, 630)
const MESSAGE_SIZE := Vector2(1000, 60)
const MESSAGE_FONT_SIZE := 36
const MESSAGE_COLOR := Color("ffd27a")

var controller: BattleController = null
var intent := PlayIntent.new()
var potion_intent := PotionIntent.new()
var enemy_row: HBoxContainer
var enemy_uis: Array[EnemyUI] = []
var hero_ui: CombatantUI
var hand_ui: HandUI
var potion_belt_ui: PotionBeltUI
var relic_bar_ui: RelicBarUI
var tooltip_ui: TooltipUI
var pile_viewer: PileViewerUI
var energy_ui: EnergyUI
var draw_counter: PileCounterUI
var discard_counter: PileCounterUI
var exhaust_counter: PileCounterUI
var end_turn_button: Button
var turn_label: Label
var message_label: Label
var result_overlay: ResultOverlayUI
var play_zone: PlayZoneUI
var target_arrow: TargetArrowUI
var _dragged: CardInstance = null
var _preview_unit: EnemyUnit = null


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	play_zone = PlayZoneUI.new()
	add_child(play_zone)

	enemy_row = HBoxContainer.new()
	enemy_row.position = Vector2(0, ENEMY_ROW_Y)
	enemy_row.custom_minimum_size = Vector2(SCREEN_WIDTH, 0)
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", ENEMY_GAP)
	add_child(enemy_row)

	hero_ui = CombatantUI.new()
	hero_ui.position = HERO_POSITION
	hero_ui.custom_minimum_size = Vector2(HERO_WIDTH, 0)
	hero_ui.tooltip_requested.connect(_on_tooltip_requested)
	hero_ui.tooltip_cleared.connect(_on_tooltip_cleared)
	add_child(hero_ui)

	relic_bar_ui = RelicBarUI.new()
	relic_bar_ui.position = RELIC_BAR_POSITION
	relic_bar_ui.tooltip_requested.connect(_on_tooltip_requested)
	relic_bar_ui.tooltip_cleared.connect(_on_tooltip_cleared)
	add_child(relic_bar_ui)

	potion_belt_ui = PotionBeltUI.new()
	potion_belt_ui.position = POTION_BELT_POSITION
	potion_belt_ui.slot_clicked.connect(_on_potion_slot_clicked)
	potion_belt_ui.tooltip_requested.connect(_on_tooltip_requested)
	potion_belt_ui.tooltip_cleared.connect(_on_tooltip_cleared)
	add_child(potion_belt_ui)

	hand_ui = HandUI.new()
	hand_ui.position = HAND_POSITION
	hand_ui.card_clicked.connect(_on_card_clicked)
	hand_ui.drag_started.connect(_on_drag_started)
	hand_ui.drag_moved.connect(_on_drag_moved)
	hand_ui.drag_ended.connect(_on_drag_ended)
	hand_ui.drag_cancelled.connect(_on_drag_cancelled)
	hand_ui.card_hovered.connect(_on_card_hovered)
	hand_ui.card_hover_ended.connect(_on_tooltip_cleared)
	add_child(hand_ui)

	energy_ui = _place(EnergyUI.new(), ENERGY_POSITION)
	draw_counter = _place(PileCounterUI.new(Deck.DRAW), DRAW_POSITION)
	discard_counter = _place(PileCounterUI.new(Deck.DISCARD), DISCARD_POSITION)
	exhaust_counter = _place(PileCounterUI.new(Deck.EXHAUST), EXHAUST_POSITION)
	for counter in [draw_counter, discard_counter, exhaust_counter]:
		counter.clicked.connect(_on_pile_clicked)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.position = END_TURN_POSITION
	end_turn_button.custom_minimum_size = END_TURN_SIZE
	end_turn_button.add_theme_font_size_override("font_size", END_TURN_FONT_SIZE)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	add_child(end_turn_button)

	turn_label = Label.new()
	turn_label.position = TURN_POSITION
	turn_label.add_theme_font_size_override("font_size", TURN_FONT_SIZE)
	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(turn_label)

	message_label = Label.new()
	message_label.position = MESSAGE_POSITION
	message_label.custom_minimum_size = MESSAGE_SIZE
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", MESSAGE_FONT_SIZE)
	message_label.add_theme_color_override("font_color", MESSAGE_COLOR)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message_label)

	target_arrow = TargetArrowUI.new()
	add_child(target_arrow)

	tooltip_ui = TooltipUI.new()
	add_child(tooltip_ui)

	pile_viewer = PileViewerUI.new()
	add_child(pile_viewer)

	result_overlay = ResultOverlayUI.new()
	result_overlay.play_again_pressed.connect(func() -> void: restart_requested.emit())
	add_child(result_overlay)


func _exit_tree() -> void:
	teardown()


## Gắn vào một trận (dọn trận cũ nếu có). Gọi trước hoặc sau controller.start_battle() đều được.
func setup(p_controller: BattleController) -> void:
	if p_controller == null:
		push_error("BattleScene.setup: controller null")
		return
	teardown()
	controller = p_controller
	for unit in controller.enemies:
		var enemy_ui := EnemyUI.new()
		enemy_ui.bind(unit)
		enemy_ui.clicked.connect(_on_enemy_clicked)
		enemy_ui.tooltip_requested.connect(_on_tooltip_requested)
		enemy_ui.tooltip_cleared.connect(_on_tooltip_cleared)
		enemy_row.add_child(enemy_ui)
		enemy_uis.append(enemy_ui)
	hero_ui.bind(controller.player)
	relic_bar_ui.bind(controller)
	potion_belt_ui.bind(controller)
	hand_ui.bind(controller)
	energy_ui.bind(controller)
	draw_counter.bind(controller.deck)
	discard_counter.bind(controller.deck)
	exhaust_counter.bind(controller.deck)
	controller.turn_started.connect(_on_state_event)
	controller.intent_changed.connect(_on_intent_changed)
	controller.card_played.connect(_on_card_played)
	controller.potion_used.connect(_on_potion_used)
	controller.enemy_acted.connect(_on_enemy_acted)
	controller.enemy_defeated.connect(_on_enemy_defeated)
	controller.battle_ended.connect(_on_battle_ended)
	controller.action_rejected.connect(_on_action_rejected)
	controller.state.changed.connect(_on_phase_changed)
	_refresh_all()


## Ngắt mọi kết nối với trận hiện tại và dọn giao diện. An toàn khi gọi nhiều lần.
func teardown() -> void:
	if controller != null:
		controller.turn_started.disconnect(_on_state_event)
		controller.intent_changed.disconnect(_on_intent_changed)
		controller.card_played.disconnect(_on_card_played)
		controller.potion_used.disconnect(_on_potion_used)
		controller.enemy_acted.disconnect(_on_enemy_acted)
		controller.enemy_defeated.disconnect(_on_enemy_defeated)
		controller.battle_ended.disconnect(_on_battle_ended)
		controller.action_rejected.disconnect(_on_action_rejected)
		controller.state.changed.disconnect(_on_phase_changed)
		controller = null
	hero_ui.unbind()
	relic_bar_ui.unbind()
	potion_belt_ui.unbind()
	hand_ui.unbind()  # nếu đang kéo thẻ: HandUI báo drag_cancelled và _finish_drag dọn
	_finish_drag()
	energy_ui.unbind()
	for counter in [draw_counter, discard_counter, exhaust_counter]:
		counter.unbind()
	for enemy_ui in enemy_uis:
		enemy_row.remove_child(enemy_ui)
		enemy_ui.free()
	enemy_uis.clear()
	intent.cancel()
	potion_intent.cancel()
	hand_ui.set_selected(null)
	pile_viewer.close()
	tooltip_ui.hide_tooltip()
	result_overlay.hide_result()
	message_label.text = ""
	turn_label.text = ""


func show_message(text: String) -> void:
	message_label.text = text


## Bỏ chọn thẻ đang chờ mục tiêu (chuột phải hoặc Esc). Trả true nếu có gì để bỏ.
func cancel_targeting() -> bool:
	var cancelled_card := intent.cancel()
	var cancelled_potion := potion_intent.cancel()
	var cancelled := cancelled_card or cancelled_potion
	if cancelled:
		show_message("")
		_sync_targeting()
	return cancelled


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var key := event as InputEventKey
	var wants_cancel := (click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT) \
			or (key != null and key.pressed and key.keycode == KEY_ESCAPE)
	if wants_cancel and pile_viewer.close():  # lớp phủ đang mở: Esc/chuột phải đóng nó trước
		get_viewport().set_input_as_handled()
		return
	if wants_cancel and (hand_ui.cancel_drag() or cancel_targeting()):
		get_viewport().set_input_as_handled()


func is_dragging() -> bool:
	return _dragged != null


func _place(control: Control, at: Vector2) -> Control:
	control.position = at
	add_child(control)
	return control


## Bấm thẻ: PlayIntent hỏi controller trước rồi mới quyết định; việc thực thi do ta làm.
func _on_card_clicked(card: CardInstance) -> void:
	if controller != null:
		potion_intent.cancel()  # chỉ một lựa chọn chờ mục tiêu tại một thời điểm
		_apply(intent.select_card(card, controller))


## Bấm quái: nếu đang chờ mục tiêu cho potion thì là mục tiêu của potion, không thì của thẻ.
func _on_enemy_clicked(unit: EnemyUnit) -> void:
	if controller == null:
		return
	if potion_intent.is_targeting():
		_apply_potion(potion_intent.choose_target(unit, controller))
	else:
		_apply(intent.choose_target(unit, controller))


## Bấm ô potion: PotionIntent hỏi controller trước rồi mới quyết định; việc thực thi do ta làm.
func _on_potion_slot_clicked(slot: int) -> void:
	if controller == null or pile_viewer.is_open():
		return
	intent.cancel()
	_apply_potion(potion_intent.select_slot(slot, controller))


func _apply_potion(decision: PotionIntent.Decision) -> void:
	match decision.outcome:
		PotionIntent.Outcome.USE_NOW:
			show_message("")
			controller.use_potion(decision.slot, decision.target)  # nếu bị từ chối, action_rejected hiện lý do
		PotionIntent.Outcome.NEED_TARGET:
			show_message(RejectionText.CHOOSE_TARGET)
		PotionIntent.Outcome.REJECTED:
			show_message(RejectionText.for_reason(decision.reason))
		PotionIntent.Outcome.CANCELLED:
			show_message("")
	_sync_targeting()


func _apply(decision: PlayIntent.Decision) -> void:
	match decision.outcome:
		PlayIntent.Outcome.PLAY_NOW:
			show_message("")
			controller.play_card(decision.card, decision.target)  # nếu bị từ chối, action_rejected hiện lý do
		PlayIntent.Outcome.NEED_TARGET:
			show_message(RejectionText.CHOOSE_TARGET)
		PlayIntent.Outcome.REJECTED:
			show_message(RejectionText.for_reason(decision.reason))
		PlayIntent.Outcome.CANCELLED:
			show_message("")
	_sync_targeting()


## --- Kéo thả thẻ ---

func _on_drag_started(card: CardInstance, pointer: Vector2) -> void:
	if controller == null:
		return
	var reason := controller.play_rejection_reason(card)
	if reason != &"":
		show_message(RejectionText.for_reason(reason))
		hand_ui.cancel_drag()  # không bắt đầu kéo thẻ không chơi được
		return
	intent.cancel()  # bỏ lựa chọn bằng click (nếu có)
	potion_intent.cancel()
	potion_belt_ui.set_selected_slot(PotionIntent.NO_SLOT)  # ô potion hết viền sáng ngay
	tooltip_ui.hide_tooltip()
	show_message("")
	_dragged = card
	var single_target := card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY
	hand_ui.begin_drag(card, not single_target)
	if single_target:
		var valid := controller.valid_targets(card)
		for enemy_ui in enemy_uis:
			enemy_ui.set_targetable(valid.has(enemy_ui.unit))
	else:
		play_zone.show_zone()
	_update_drag(pointer)


func _on_drag_moved(card: CardInstance, pointer: Vector2) -> void:
	if _dragged == card:
		_update_drag(pointer)


## Cập nhật theo con trỏ: thẻ nhắm -> mũi tên + xem trước số theo quái đang trỏ; thẻ khác -> thẻ bám theo + vùng thả.
func _update_drag(pointer: Vector2) -> void:
	var unit := EnemyHitTest.unit_at(pointer, enemy_uis)
	if _dragged.data.target_mode == CardData.TargetMode.SINGLE_ENEMY:
		var hovered := DropIntent.hover_target(_dragged, unit, controller)
		target_arrow.show_arrow(hand_ui.card_anchor(_dragged), pointer, hovered != null)
		if hovered != _preview_unit:
			_preview_unit = hovered
			hand_ui.set_preview_target(_dragged, hovered)
	else:
		hand_ui.move_drag(pointer)
		play_zone.set_active(DropIntent.is_in_play_zone(pointer, DropIntent.DESIGN_SCREEN))


func _on_drag_ended(card: CardInstance, pointer: Vector2) -> void:
	if _dragged != card or controller == null:
		return
	var unit := EnemyHitTest.unit_at(pointer, enemy_uis)
	var decision := DropIntent.decide(card, unit, DropIntent.is_in_play_zone(pointer, DropIntent.DESIGN_SCREEN), controller)
	_finish_drag()
	_apply(decision)


func _on_drag_cancelled(card: CardInstance) -> void:
	if _dragged == card:
		_finish_drag()


## Dọn mọi dấu vết của lần kéo (mũi tên, vùng thả, xem trước, viền sáng). An toàn khi không có lần kéo nào.
func _finish_drag() -> void:
	var card := _dragged
	_dragged = null
	_preview_unit = null
	target_arrow.hide_arrow()
	play_zone.hide_zone()
	if card != null:
		hand_ui.set_preview_target(card, null)
	hand_ui.end_drag()
	if controller != null:
		_sync_targeting()


func _on_end_turn_pressed() -> void:
	if controller == null:
		return
	intent.cancel()  # tường minh; sync cũng sẽ bỏ chọn khi sang lượt quái
	potion_intent.cancel()
	show_message("")
	controller.end_player_turn()
	_refresh_all()


## Vẽ lại các phần suy ra từ trạng thái trận (nhãn lượt, nút End Turn, ý định, trạng thái chọn mục tiêu).
func _refresh_all() -> void:
	if controller == null:
		return
	turn_label.text = "Turn %d" % controller.turn
	end_turn_button.disabled = not controller.state.is_player_turn()
	if controller.state.is_terminal():
		result_overlay.show_result(controller.state.phase == BattleState.Phase.VICTORY)
	_refresh_intents()  # dự phòng: controller đã phát intent_changed khi quái đổi chiêu hoặc đổi số
	potion_belt_ui.refresh()  # "dùng được hay không" đổi theo lượt
	_sync_targeting()


func _refresh_intents() -> void:
	for enemy_ui in enemy_uis:
		enemy_ui.show_intent(IntentView.build(enemy_ui.unit.intent))


func _sync_targeting() -> void:
	intent.sync(controller)
	potion_intent.sync(controller)
	hand_ui.set_selected(intent.selected)
	potion_belt_ui.set_selected_slot(potion_intent.selected_slot)
	var valid: Array[EnemyUnit] = []
	if intent.is_targeting():
		valid = controller.valid_targets(intent.selected)
	elif potion_intent.is_targeting():
		valid = controller.valid_potion_targets(potion_intent.selected_slot)
	for enemy_ui in enemy_uis:
		enemy_ui.set_targetable(valid.has(enemy_ui.unit))


func _on_state_event(_turn_number: int, _is_player: bool) -> void:
	_refresh_all()


func _on_phase_changed(_from_phase: BattleState.Phase, _to_phase: BattleState.Phase) -> void:
	_refresh_all()


func _on_intent_changed(_unit: EnemyUnit) -> void:
	_refresh_intents()


func _on_card_played(_card: CardInstance, _target: EnemyUnit, _results: Array[EffectResult]) -> void:
	_refresh_all()


func _on_potion_used(_slot: int, _potion: PotionData, _target: EnemyUnit, _results: Array[EffectResult]) -> void:
	_refresh_all()


func _on_enemy_acted(_unit: EnemyUnit, _move: EnemyMove, _results: Array[EffectResult]) -> void:
	_refresh_all()


func _on_enemy_defeated(_unit: EnemyUnit) -> void:
	_refresh_all()


func _on_battle_ended(_victory: bool) -> void:
	_refresh_all()


func _on_action_rejected(reason: StringName) -> void:
	show_message(RejectionText.for_reason(reason))


## --- Tooltip và xem pile ---

## Tooltip chỉ hiện khi không kéo thẻ và không có lớp phủ pile; nguồn nào cũng báo lên đây (signal up).
func _on_tooltip_requested(tooltip: TooltipView, anchor: Rect2) -> void:
	if is_dragging() or pile_viewer.is_open():
		return
	tooltip_ui.show_tooltip(tooltip, anchor)


func _on_tooltip_cleared() -> void:
	tooltip_ui.hide_tooltip()


func _on_card_hovered(card: CardInstance, anchor: Rect2) -> void:
	if controller != null:
		_on_tooltip_requested(TooltipBuilder.for_card_with(card.data, controller.get_status_data), anchor)


## Bấm bộ đếm pile: mở lớp phủ xem pile (xem PileView: sắp theo tên, không lộ thứ tự rút).
func _on_pile_clicked(pile_name: StringName) -> void:
	if controller == null or is_dragging() or result_overlay.visible:
		return
	intent.cancel()
	potion_intent.cancel()
	show_message("")
	_sync_targeting()
	tooltip_ui.hide_tooltip()
	var views := PileView.build(controller.deck, pile_name, controller.player)
	var title: String = PileCounterUI.TITLES.get(pile_name, String(pile_name).capitalize())
	pile_viewer.show_pile("%s pile (%d)" % [title, views.size()], views)
