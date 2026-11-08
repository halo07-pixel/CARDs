extends "res://tests/test_case.gd"
## PotionBeltUI: một ô cho mỗi chỗ trên dây, tự vẽ lại khi dây đổi, báo bấm/tooltip lên trên.

const Hud := preload("res://tests/hud_factory.gd")


func _belt(controller: BattleController) -> PotionBeltUI:
	var belt := PotionBeltUI.new()
	belt.bind(controller)
	return belt


func test_bind_builds_one_slot_per_belt_capacity() -> void:
	var belt := _belt(Hud.controller([&"fire_potion", &"block_potion"]))
	assert_eq(belt.slot_uis.size(), 3)
	assert_eq(belt.get_child_count(), 3)
	assert_eq(belt.slot_uis[0].view.potion_id, &"fire_potion")
	assert_eq(belt.slot_uis[1].view.potion_id, &"block_potion")
	assert_true(belt.slot_uis[2].view.is_empty)
	belt.free()


func test_using_a_potion_empties_its_slot_through_the_belt_signal() -> void:
	var controller := Hud.controller([&"block_potion", &"fire_potion"])
	var belt := _belt(controller)
	var slot_before := belt.slot_uis[0]
	controller.use_potion(0)
	assert_true(belt.slot_uis[0].view.is_empty)
	assert_eq(belt.slot_uis[1].view.potion_id, &"fire_potion")
	assert_true(belt.slot_uis[0] == slot_before, "ô được dùng lại, không bị giải phóng giữa tín hiệu của chính nó")
	belt.free()


func test_refresh_follows_the_turn_for_usable() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1, false)
	var belt := _belt(controller)
	assert_false(belt.slot_uis[0].view.usable)
	controller.start_battle()
	belt.refresh()
	assert_true(belt.slot_uis[0].view.usable)
	belt.free()


func test_slot_click_and_tooltip_signals_are_forwarded() -> void:
	var belt := _belt(Hud.controller([&"fire_potion"]))
	var clicks: Array = []
	var requests: Array = []
	var cleared: Array = []
	belt.slot_clicked.connect(func(slot: int) -> void: clicks.append(slot))
	belt.tooltip_requested.connect(func(_t: TooltipView, _a: Rect2) -> void: requests.append(1))
	belt.tooltip_cleared.connect(func() -> void: cleared.append(1))
	belt.slot_uis[0].pressed.emit()
	belt.slot_uis[0].mouse_entered.emit()
	belt.slot_uis[0].mouse_exited.emit()
	assert_eq(clicks, [0])
	assert_eq(requests.size(), 1)
	assert_eq(cleared.size(), 1)
	belt.free()


func test_set_selected_slot_marks_only_that_slot() -> void:
	var belt := _belt(Hud.controller([&"fire_potion", &"weak_potion"]))
	belt.set_selected_slot(1)
	assert_false(belt.slot_uis[0].selected)
	assert_true(belt.slot_uis[1].selected)
	belt.set_selected_slot(PotionIntent.NO_SLOT)
	assert_false(belt.slot_uis[1].selected)
	belt.free()


func test_unbind_disconnects_frees_slots_and_clears_the_tooltip() -> void:
	var controller := Hud.controller([&"fire_potion"])
	var belt := _belt(controller)
	var cleared: Array = []
	belt.tooltip_cleared.connect(func() -> void: cleared.append(1))
	belt.unbind()
	assert_eq(controller.potions.changed.get_connections().size(), 0)
	assert_eq(belt.slot_uis.size(), 0)
	assert_eq(belt.get_child_count(), 0)
	assert_eq(cleared.size(), 1)
	belt.unbind()  # gọi lần hai vẫn an toàn
	assert_eq(cleared.size(), 1)
	belt.free()


func test_rebinding_replaces_the_old_battle() -> void:
	var old_controller := Hud.controller([&"fire_potion"])
	var belt := _belt(old_controller)
	belt.bind(Hud.controller([&"block_potion"]))
	assert_eq(old_controller.potions.changed.get_connections().size(), 0)
	assert_eq(belt.slot_uis.size(), 3)
	assert_eq(belt.slot_uis[0].view.potion_id, &"block_potion")
	belt.free()


func test_repeated_bind_does_not_leak_nodes() -> void:
	var belt := _belt(Hud.controller([&"fire_potion"]))
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 5:
		belt.bind(Hud.controller([&"fire_potion"]))
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)
	belt.free()


func test_bind_null_changes_nothing() -> void:
	var controller := Hud.controller([&"fire_potion"])
	var belt := _belt(controller)
	belt.bind(null)
	assert_eq(belt.slot_uis.size(), 3)
	belt.free()
