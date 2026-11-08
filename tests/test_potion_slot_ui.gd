extends "res://tests/test_case.gd"
## PotionSlotUI: vẽ PotionView, báo bấm và tooltip lên trên; không tự dùng potion.

const Hud := preload("res://tests/hud_factory.gd")
const UiInput := preload("res://tests/ui_input.gd")


func _border(slot_ui: PotionSlotUI) -> Color:
	return (slot_ui.get_theme_stylebox("panel") as StyleBoxFlat).border_color


func test_filled_slot_shows_abbreviation_and_rarity_border() -> void:
	var controller := Hud.controller([&"fire_potion"])
	var view := PotionView.build(0, controller)
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(view)
	assert_eq(slot_ui.fallback_label.text, "FIR")
	assert_eq(_border(slot_ui), PotionSlotUI.RARITY_COLORS[view.rarity])
	assert_almost_eq(slot_ui.modulate.a, 1.0, 0.0001)
	slot_ui.free()


func test_empty_slot_is_plain_and_dim() -> void:
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(PotionView.build(2, Hud.controller([&"fire_potion"])))
	assert_eq(slot_ui.fallback_label.text, "")
	assert_eq(_border(slot_ui), PotionSlotUI.EMPTY_BORDER_COLOR)
	assert_almost_eq(slot_ui.modulate.a, PotionSlotUI.EMPTY_ALPHA, 0.0001)
	slot_ui.free()


func test_potion_that_cannot_be_used_now_is_dimmed() -> void:
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(PotionView.build(0, Hud.controller([&"block_potion"], [], 1, false)))
	assert_almost_eq(slot_ui.modulate.a, PotionSlotUI.UNUSABLE_ALPHA, 0.0001, "chưa tới lượt người chơi")
	slot_ui.free()


func test_selected_slot_gets_a_white_border_and_stays_bright() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 1, false)  # chưa dùng được
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(PotionView.build(0, controller))
	slot_ui.set_selected(true)
	assert_eq(_border(slot_ui), PotionSlotUI.SELECTED_BORDER_COLOR)
	slot_ui.set_selected(false)
	assert_ne(_border(slot_ui), PotionSlotUI.SELECTED_BORDER_COLOR)
	slot_ui.free()


func test_click_emits_the_slot_index_for_filled_and_empty_slots() -> void:
	var controller := Hud.controller([&"fire_potion"])
	var clicked: Array = []
	for slot in [0, 2]:
		var slot_ui := PotionSlotUI.new()
		slot_ui.show_view(PotionView.build(slot, controller))
		slot_ui.clicked.connect(func(index: int) -> void: clicked.append(index))
		slot_ui._gui_input(UiInput.press())
		slot_ui.free()
	assert_eq(clicked, [0, 2], "ô trống cũng báo để BattleScene hiện lý do")


func test_click_before_any_view_does_nothing() -> void:
	var slot_ui := PotionSlotUI.new()
	var clicked: Array = []
	slot_ui.clicked.connect(func(index: int) -> void: clicked.append(index))
	slot_ui._gui_input(UiInput.press())
	assert_eq(clicked.size(), 0)
	slot_ui.free()


func test_hover_requests_a_tooltip_with_the_potion_text() -> void:
	var controller := Hud.controller([&"fire_potion"])
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(PotionView.build(0, controller))
	var requests: Array = []
	var cleared: Array = []
	slot_ui.tooltip_requested.connect(func(tooltip: TooltipView, anchor: Rect2) -> void: requests.append([tooltip, anchor]))
	slot_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	slot_ui.mouse_entered.emit()
	assert_eq(requests.size(), 1)
	assert_eq((requests[0][0] as TooltipView).title, "Fire Potion")
	slot_ui.mouse_exited.emit()
	assert_eq(cleared.size(), 1)
	slot_ui.free()


func test_hovering_an_empty_slot_shows_no_tooltip() -> void:
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(PotionView.build(1, Hud.controller([&"fire_potion"])))
	var requests: Array = []
	var cleared: Array = []
	slot_ui.tooltip_requested.connect(func(_t: TooltipView, _a: Rect2) -> void: requests.append(1))
	slot_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	slot_ui.mouse_entered.emit()
	assert_eq(requests.size(), 0)
	assert_eq(cleared.size(), 1)
	slot_ui.free()


func test_potion_used_while_hovered_clears_the_tooltip() -> void:
	var controller := Hud.controller([&"block_potion"])
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(PotionView.build(0, controller))
	slot_ui.mouse_entered.emit()
	var cleared: Array = []
	slot_ui.tooltip_cleared.connect(func() -> void: cleared.append(1))
	controller.use_potion(0)
	slot_ui.show_view(PotionView.build(0, controller))  # dây vừa đổi: ô trống
	assert_eq(cleared.size(), 1, "tooltip của potion đã dùng không được ở lại")
	slot_ui.free()


func test_null_view_is_ignored() -> void:
	var slot_ui := PotionSlotUI.new()
	slot_ui.show_view(null)
	assert_true(slot_ui.view == null)
	slot_ui.free()
