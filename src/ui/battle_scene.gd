class_name BattleScene
extends Control
## Màn chiến đấu: ghép HandUI, EnemyUI, CombatantUI, EnergyUI, PileCounterUI, nút End Turn, lớp phủ kết quả.
## Sở hữu PlayIntent (thao tác chơi thẻ bằng click). UI KHÔNG đổi lõi: chỉ gọi controller.play_card /
## end_player_turn và vẽ lại theo Signal (call down, signal up). Lượt quái chạy tức thì (animation: mốc 3.6).
## Dùng: scene.setup(controller) -> controller.start_battle(); đổi trận: setup(controller_mới); dọn: teardown().

signal restart_requested

const BACKGROUND_COLOR := Color("1c2030")
const ENEMY_ROW_Y := 40.0
const ENEMY_GAP := 90
const SCREEN_WIDTH := 1920.0
const HERO_POSITION := Vector2(60, 500)
const HERO_WIDTH := 420.0
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
var enemy_row: HBoxContainer
var enemy_uis: Array[EnemyUI] = []
var hero_ui: CombatantUI
var hand_ui: HandUI
var energy_ui: EnergyUI
var draw_counter: PileCounterUI
var discard_counter: PileCounterUI
var exhaust_counter: PileCounterUI
var end_turn_button: Button
var turn_label: Label
var message_label: Label
var result_overlay: ResultOverlayUI


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	enemy_row = HBoxContainer.new()
	enemy_row.position = Vector2(0, ENEMY_ROW_Y)
	enemy_row.custom_minimum_size = Vector2(SCREEN_WIDTH, 0)
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", ENEMY_GAP)
	add_child(enemy_row)

	hero_ui = CombatantUI.new()
	hero_ui.position = HERO_POSITION
	hero_ui.custom_minimum_size = Vector2(HERO_WIDTH, 0)
	add_child(hero_ui)

	hand_ui = HandUI.new()
	hand_ui.position = HAND_POSITION
	hand_ui.card_clicked.connect(_on_card_clicked)
	add_child(hand_ui)

	energy_ui = _place(EnergyUI.new(), ENERGY_POSITION)
	draw_counter = _place(PileCounterUI.new(Deck.DRAW), DRAW_POSITION)
	discard_counter = _place(PileCounterUI.new(Deck.DISCARD), DISCARD_POSITION)
	exhaust_counter = _place(PileCounterUI.new(Deck.EXHAUST), EXHAUST_POSITION)

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
		enemy_row.add_child(enemy_ui)
		enemy_uis.append(enemy_ui)
	hero_ui.bind(controller.player)
	hand_ui.bind(controller)
	energy_ui.bind(controller)
	draw_counter.bind(controller.deck)
	discard_counter.bind(controller.deck)
	exhaust_counter.bind(controller.deck)
	controller.turn_started.connect(_on_state_event)
	controller.intent_changed.connect(_on_intent_changed)
	controller.card_played.connect(_on_card_played)
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
		controller.enemy_acted.disconnect(_on_enemy_acted)
		controller.enemy_defeated.disconnect(_on_enemy_defeated)
		controller.battle_ended.disconnect(_on_battle_ended)
		controller.action_rejected.disconnect(_on_action_rejected)
		controller.state.changed.disconnect(_on_phase_changed)
		controller = null
	hero_ui.unbind()
	hand_ui.unbind()
	energy_ui.unbind()
	for counter in [draw_counter, discard_counter, exhaust_counter]:
		counter.unbind()
	for enemy_ui in enemy_uis:
		enemy_row.remove_child(enemy_ui)
		enemy_ui.free()
	enemy_uis.clear()
	intent.cancel()
	hand_ui.set_selected(null)
	result_overlay.hide_result()
	message_label.text = ""
	turn_label.text = ""


func show_message(text: String) -> void:
	message_label.text = text


## Bỏ chọn thẻ đang chờ mục tiêu (chuột phải hoặc Esc). Trả true nếu có gì để bỏ.
func cancel_targeting() -> bool:
	var cancelled := intent.cancel()
	if cancelled:
		show_message("")
		_sync_targeting()
	return cancelled


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var key := event as InputEventKey
	var wants_cancel := (click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT) \
			or (key != null and key.pressed and key.keycode == KEY_ESCAPE)
	if wants_cancel and cancel_targeting():
		get_viewport().set_input_as_handled()


func _place(control: Control, at: Vector2) -> Control:
	control.position = at
	add_child(control)
	return control


## Bấm thẻ: PlayIntent hỏi controller trước rồi mới quyết định; việc thực thi do ta làm.
func _on_card_clicked(card: CardInstance) -> void:
	if controller != null:
		_apply(intent.select_card(card, controller))


func _on_enemy_clicked(unit: EnemyUnit) -> void:
	if controller != null:
		_apply(intent.choose_target(unit, controller))


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


func _on_end_turn_pressed() -> void:
	if controller == null:
		return
	intent.cancel()  # tường minh; sync cũng sẽ bỏ chọn khi sang lượt quái
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
	_sync_targeting()


func _refresh_intents() -> void:
	for enemy_ui in enemy_uis:
		enemy_ui.show_intent(IntentView.build(enemy_ui.unit.intent))


func _sync_targeting() -> void:
	intent.sync(controller)
	hand_ui.set_selected(intent.selected)
	var valid: Array[EnemyUnit] = []
	if intent.is_targeting():
		valid = controller.valid_targets(intent.selected)
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


func _on_enemy_acted(_unit: EnemyUnit, _move: EnemyMove, _results: Array[EffectResult]) -> void:
	_refresh_all()


func _on_enemy_defeated(_unit: EnemyUnit) -> void:
	_refresh_all()


func _on_battle_ended(_victory: bool) -> void:
	_refresh_all()


func _on_action_rejected(reason: StringName) -> void:
	show_message(RejectionText.for_reason(reason))
