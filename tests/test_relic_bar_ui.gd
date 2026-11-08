extends "res://tests/test_case.gd"
## RelicBarUI: một icon cho mỗi relic của trận, chỉ để xem (hover -> tooltip báo lên).

const Hud := preload("res://tests/hud_factory.gd")


func _bar(controller: BattleController) -> RelicBarUI:
	var bar := RelicBarUI.new()
	bar.bind(controller)
	return bar


func test_bind_builds_icons_in_relic_order() -> void:
	var bar := _bar(Hud.controller([], [&"vajra", &"anchor", &"lantern"]))
	assert_eq(bar.icon_uis.size(), 3)
	assert_eq(bar.get_child_count(), 3)
	assert_eq(bar.icon_uis[0].view.relic_id, &"vajra")
	assert_eq(bar.icon_uis[1].view.relic_id, &"anchor")
	assert_eq(bar.icon_uis[2].view.relic_id, &"lantern")
	bar.free()


func test_no_relics_gives_an_empty_bar() -> void:
	var bar := _bar(Hud.controller())
	assert_eq(bar.icon_uis.size(), 0)
	bar.free()


func test_icon_shows_abbreviation_and_rarity_border() -> void:
	var bar := _bar(Hud.controller([], [&"anchor"]))
	var icon := bar.icon_uis[0]
	assert_eq(icon.fallback_label.text, "ANC")
	assert_eq((icon.get_theme_stylebox("panel") as StyleBoxFlat).border_color, RelicIconUI.RARITY_COLORS[icon.view.rarity])
	bar.free()


func test_hover_forwards_a_tooltip_with_the_relic_text_then_clears() -> void:
	var controller := Hud.controller([], [&"anchor"])
	var bar := _bar(controller)
	var requests: Array = []
	var cleared: Array = []
	bar.tooltip_requested.connect(func(tooltip: TooltipView, _a: Rect2) -> void: requests.append(tooltip))
	bar.tooltip_cleared.connect(func() -> void: cleared.append(1))
	bar.icon_uis[0].mouse_entered.emit()
	assert_eq(requests.size(), 1)
	assert_eq((requests[0] as TooltipView).title, controller.relics[0].display_name)
	assert_eq((requests[0] as TooltipView).body, controller.relics[0].description)
	bar.icon_uis[0].mouse_exited.emit()
	assert_eq(cleared.size(), 1)
	bar.free()


func test_unbind_frees_icons_and_clears_the_tooltip() -> void:
	var bar := _bar(Hud.controller([], [&"anchor", &"vajra"]))
	var cleared: Array = []
	bar.tooltip_cleared.connect(func() -> void: cleared.append(1))
	bar.unbind()
	assert_eq(bar.icon_uis.size(), 0)
	assert_eq(bar.get_child_count(), 0)
	assert_eq(cleared.size(), 1)
	bar.unbind()
	assert_eq(cleared.size(), 1, "lần hai không làm gì")
	bar.free()


func test_rebinding_shows_only_the_new_relics_and_does_not_leak() -> void:
	var bar := _bar(Hud.controller([], [&"anchor", &"vajra"]))
	bar.bind(Hud.controller([], [&"lantern"]))
	assert_eq(bar.icon_uis.size(), 1)
	assert_eq(bar.icon_uis[0].view.relic_id, &"lantern")
	bar.bind(Hud.controller([], [&"anchor", &"vajra"]))
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)  # cùng số relic mỗi lần
	for i in 5:
		bar.bind(Hud.controller([], [&"anchor", &"vajra"]))
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)
	bar.free()


func test_bind_null_changes_nothing() -> void:
	var bar := _bar(Hud.controller([], [&"anchor"]))
	bar.bind(null)
	assert_eq(bar.icon_uis.size(), 1)
	bar.free()
