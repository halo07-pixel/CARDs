extends "res://tests/test_case.gd"
## Các nguồn phát tooltip/click mới: StatusIconUI, CombatantUI, EnemyUI (ý định), HandUI (hover thẻ), PileCounterUI.

const Factory := preload("res://tests/combat_factory.gd")
const Hud := preload("res://tests/hud_factory.gd")
const UiInput := preload("res://tests/ui_input.gd")

var _statuses: StatusRegistry
var _cards: CardRegistry
var _enemies: EnemyRegistry
var _node: Node = null


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")


func after_each() -> void:
	if _node != null:
		_node.free()
		_node = null


## --- StatusIconUI ---

func _status_icon(status_id: StringName = &"weak", amount: int = 2) -> StatusIconUI:
	var owner := Factory.combatant(&"p", 50)
	owner.add_status(_statuses.get_status(status_id), amount)
	var icon := StatusIconUI.new()
	icon.show_view(StatusView.build(owner, status_id))
	_node = icon
	return icon


func test_status_icon_receives_hover_but_lets_clicks_pass_up() -> void:
	var icon := _status_icon()
	assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_PASS)
	for child in icon.get_children():
		assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_status_icon_hover_requests_the_status_tooltip_then_clears() -> void:
	var icon := _status_icon(&"weak")
	var requests: Array = []
	var cleared: Array = []
	icon.tooltip_requested.connect(func(tooltip: TooltipView, _a: Rect2) -> void: requests.append(tooltip))
	icon.tooltip_cleared.connect(func() -> void: cleared.append(1))
	icon.mouse_entered.emit()
	assert_true(icon.is_hovered())
	assert_eq((requests[0] as TooltipView).title, _statuses.get_status(&"weak").display_name)
	assert_eq((requests[0] as TooltipView).body, _statuses.get_status(&"weak").description)
	icon.mouse_exited.emit()
	assert_false(icon.is_hovered())
	assert_eq(cleared.size(), 1)


func test_status_icon_without_a_view_requests_nothing() -> void:
	var icon := StatusIconUI.new()
	_node = icon
	var requests: Array = []
	icon.tooltip_requested.connect(func(_t: TooltipView, _a: Rect2) -> void: requests.append(1))
	icon.mouse_entered.emit()
	assert_eq(requests.size(), 0)


## --- CombatantUI ---

func test_combatant_ui_forwards_icon_tooltips() -> void:
	var owner := Factory.combatant(&"p", 50)
	owner.add_status(_statuses.get_status(&"strength"), 2)
	var combatant_ui := CombatantUI.new()
	_node = combatant_ui
	combatant_ui.bind(owner)
	var requests: Array = []
	var cleared: Array = []
	combatant_ui.tooltip_requested.connect(func(tooltip: TooltipView, _a: Rect2) -> void: requests.append(tooltip))
	combatant_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	var icon := combatant_ui.status_row.get_child(0) as StatusIconUI
	icon.mouse_entered.emit()
	icon.mouse_exited.emit()
	assert_eq((requests[0] as TooltipView).title, "Strength")
	assert_eq(cleared.size(), 1)


func test_status_row_rebuild_while_hovering_clears_the_tooltip() -> void:
	var owner := Factory.combatant(&"p", 50)
	owner.add_status(_statuses.get_status(&"strength"), 2)
	var combatant_ui := CombatantUI.new()
	_node = combatant_ui
	combatant_ui.bind(owner)
	var cleared: Array = []
	combatant_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	(combatant_ui.status_row.get_child(0) as StatusIconUI).mouse_entered.emit()
	owner.add_status(_statuses.get_status(&"weak"), 1)  # dựng lại hàng status, icon đang trỏ bị thay
	assert_eq(cleared.size(), 1, "không để tooltip mồ côi")


func test_status_row_rebuild_without_hover_stays_silent() -> void:
	var owner := Factory.combatant(&"p", 50)
	var combatant_ui := CombatantUI.new()
	_node = combatant_ui
	combatant_ui.bind(owner)
	var cleared: Array = []
	combatant_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	owner.add_status(_statuses.get_status(&"weak"), 1)
	owner.add_status(_statuses.get_status(&"strength"), 1)
	assert_eq(cleared.size(), 0)


## --- EnemyUI: ý định ---

func _enemy_ui(enemy_id: StringName = &"spiker") -> EnemyUI:
	var ids: Array[StringName] = [enemy_id]
	var warrior := (load("res://data/characters/warrior.tres") as CharacterData).duplicate() as CharacterData
	var controller := BattleFactory.create(warrior, BattleFactory.create_player(warrior), warrior.starting_deck, ids,
			_cards, _enemies, _statuses)
	controller.start_battle()
	var enemy_ui := EnemyUI.new()
	enemy_ui.bind(controller.enemies[0])
	Engine.get_main_loop().root.add_child(enemy_ui)  # cần bố cục để biết vùng ý định
	_node = enemy_ui
	return enemy_ui


func _wait_layout() -> void:
	await Engine.get_main_loop().process_frame


func test_hovering_the_intent_requests_the_intent_tooltip() -> void:
	var enemy_ui := _enemy_ui()
	await _wait_layout()
	var requests: Array = []
	enemy_ui.tooltip_requested.connect(func(tooltip: TooltipView, anchor: Rect2) -> void: requests.append([tooltip, anchor]))
	enemy_ui._gui_input(UiInput.motion(enemy_ui._intent_rect().get_center()))
	assert_eq(requests.size(), 1)
	assert_eq((requests[0][0] as TooltipView).title, TooltipBuilder.INTENT_TITLE)
	assert_true((requests[0][0] as TooltipView).body.begins_with("Will attack for"))
	var anchor: Rect2 = requests[0][1]
	assert_true(anchor.size.x > 0 and anchor.size.y > 0, "neo là vùng thật của ý định")


func test_moving_inside_the_intent_does_not_repeat_the_request() -> void:
	var enemy_ui := _enemy_ui()
	await _wait_layout()
	var requests: Array = []
	enemy_ui.tooltip_requested.connect(func(_t: TooltipView, _a: Rect2) -> void: requests.append(1))
	var rect := enemy_ui._intent_rect()
	enemy_ui._gui_input(UiInput.motion(rect.get_center()))
	enemy_ui._gui_input(UiInput.motion(rect.get_center() + Vector2(1, 0)))
	assert_eq(requests.size(), 1)


func test_leaving_the_intent_area_clears_the_tooltip() -> void:
	var enemy_ui := _enemy_ui()
	await _wait_layout()
	var cleared: Array = []
	enemy_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	enemy_ui._gui_input(UiInput.motion(enemy_ui._intent_rect().get_center()))
	enemy_ui._gui_input(UiInput.motion(Vector2(enemy_ui.size.x / 2.0, enemy_ui.size.y - 5)))  # xuống phần máu
	assert_eq(cleared.size(), 1)


func test_mouse_leaving_the_enemy_clears_the_tooltip() -> void:
	var enemy_ui := _enemy_ui()
	await _wait_layout()
	var cleared: Array = []
	enemy_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	enemy_ui._gui_input(UiInput.motion(enemy_ui._intent_rect().get_center()))
	enemy_ui._notification(Control.NOTIFICATION_MOUSE_EXIT)
	assert_eq(cleared.size(), 1)
	enemy_ui._notification(Control.NOTIFICATION_MOUSE_EXIT)
	assert_eq(cleared.size(), 1, "không trỏ thì không phát lại")


func test_intent_change_while_hovered_refreshes_the_tooltip() -> void:
	var enemy_ui := _enemy_ui()
	await _wait_layout()
	var requests: Array = []
	enemy_ui.tooltip_requested.connect(func(tooltip: TooltipView, _a: Rect2) -> void: requests.append(tooltip))
	enemy_ui._gui_input(UiInput.motion(enemy_ui._intent_rect().get_center()))
	enemy_ui.show_intent(IntentView.build(enemy_ui.unit.intent))
	assert_eq(requests.size(), 2, "ý định được vẽ lại khi đang trỏ")


func test_defeated_enemy_has_no_intent_tooltip() -> void:
	var enemy_ui := _enemy_ui()
	await _wait_layout()
	var requests: Array = []
	var cleared: Array = []
	enemy_ui.tooltip_requested.connect(func(_t: TooltipView, _a: Rect2) -> void: requests.append(1))
	enemy_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	enemy_ui._gui_input(UiInput.motion(enemy_ui._intent_rect().get_center()))
	enemy_ui.unit.combatant.take_damage(9999)
	assert_eq(cleared.size(), 1, "chết khi đang trỏ: tooltip tắt")
	enemy_ui._gui_input(UiInput.motion(enemy_ui._intent_rect().get_center()))
	assert_eq(requests.size(), 1, "quái chết không hiện tooltip ý định nữa")


func test_enemy_status_tooltips_are_forwarded() -> void:
	var enemy_ui := _enemy_ui(&"spiker")  # mang sẵn Thorns
	var requests: Array = []
	enemy_ui.tooltip_requested.connect(func(tooltip: TooltipView, _a: Rect2) -> void: requests.append(tooltip))
	(enemy_ui.combatant_ui.status_row.get_child(0) as StatusIconUI).mouse_entered.emit()
	assert_eq((requests[0] as TooltipView).title, "Thorns")


func test_clicking_the_enemy_still_works_after_the_motion_handling() -> void:
	var enemy_ui := _enemy_ui()
	var clicks: Array = []
	enemy_ui.clicked.connect(func(unit: EnemyUnit) -> void: clicks.append(unit))
	enemy_ui._gui_input(UiInput.press())
	assert_eq(clicks.size(), 1)


## --- HandUI: hover thẻ ---

func _hand(controller: BattleController) -> HandUI:
	var hand := HandUI.new()
	hand.bind(controller)
	_node = hand
	return hand


func test_hand_hover_reports_the_card_and_its_rect_then_the_end() -> void:
	var controller := Hud.controller()
	var hand := _hand(controller)
	var hovered: Array = []
	var ended: Array = []
	hand.card_hovered.connect(func(card: CardInstance, anchor: Rect2) -> void: hovered.append([card, anchor]))
	hand.card_hover_ended.connect(func() -> void: ended.append(1))
	hand.card_uis[1].mouse_entered.emit()
	assert_eq(hovered.size(), 1)
	assert_eq((hovered[0][0] as CardInstance).uid, hand.card_uis[1].view.uid)
	assert_eq(hovered[0][1], hand.card_uis[1].get_global_rect())
	hand.card_uis[1].mouse_exited.emit()
	assert_eq(ended.size(), 1)


func test_hand_moving_from_one_card_to_the_next_never_hides_the_new_tooltip() -> void:
	var hand := _hand(Hud.controller())
	var log: Array = []
	hand.card_hovered.connect(func(card: CardInstance, _a: Rect2) -> void: log.append("in:%d" % card.uid))
	hand.card_hover_ended.connect(func() -> void: log.append("end"))
	hand.card_uis[0].mouse_entered.emit()
	hand.card_uis[1].mouse_entered.emit()   # vào thẻ mới TRƯỚC khi rời thẻ cũ
	hand.card_uis[0].mouse_exited.emit()    # thẻ cũ rời sau: không được tắt tooltip của thẻ mới
	assert_eq(log, ["in:%d" % hand.card_uis[0].view.uid, "in:%d" % hand.card_uis[1].view.uid])
	hand.card_uis[1].mouse_exited.emit()
	assert_eq(log.back(), "end")


func test_hand_starting_a_drag_ends_the_hover() -> void:
	var controller := Hud.controller()
	var hand := _hand(controller)
	var ended: Array = []
	hand.card_hover_ended.connect(func() -> void: ended.append(1))
	hand.card_uis[0].mouse_entered.emit()
	hand.begin_drag(controller.deck.get_pile(Deck.HAND)[0], true)
	assert_eq(ended.size(), 1)
	hand.begin_drag(controller.deck.get_pile(Deck.HAND)[1], true)
	assert_eq(ended.size(), 1, "không còn trỏ thẻ nào thì không phát lại")


func test_hand_rebuild_while_hovering_ends_the_hover() -> void:
	var hand := _hand(Hud.controller())
	var ended: Array = []
	hand.card_hover_ended.connect(func() -> void: ended.append(1))
	hand.refresh()
	assert_eq(ended.size(), 0, "không trỏ thẻ nào thì dựng lại không phát gì")
	hand.card_uis[0].mouse_entered.emit()
	hand.refresh()
	assert_eq(ended.size(), 1)


## --- PileCounterUI: bấm ---

func test_pile_counter_click_reports_its_pile() -> void:
	for pile in [Deck.DRAW, Deck.DISCARD, Deck.EXHAUST]:
		var counter := PileCounterUI.new(pile)
		var clicks: Array = []
		counter.clicked.connect(func(pile_name: StringName) -> void: clicks.append(pile_name))
		counter._gui_input(UiInput.press())
		counter._gui_input(UiInput.release())
		counter._gui_input(UiInput.press(Vector2.ZERO, MOUSE_BUTTON_RIGHT))
		assert_eq(clicks, [pile] as Array, "chỉ chuột trái lúc bấm: %s" % pile)
		counter.free()
