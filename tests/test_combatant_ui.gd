extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _statuses: StatusRegistry


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _ui_for(combatant: Combatant) -> CombatantUI:
	var combatant_ui := CombatantUI.new()
	combatant_ui.bind(combatant)
	return combatant_ui


func test_bind_shows_name_health_and_hides_empty_block() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	assert_eq(combatant_ui.name_label.text, unit.display_name)
	assert_eq(combatant_ui.health_bar.hp_label.text, "80/80")
	assert_false(combatant_ui.health_bar.block_box.visible)
	combatant_ui.free()


func test_health_changes_update_the_bar() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	unit.take_damage(30)
	assert_eq(combatant_ui.health_bar.hp_label.text, "50/80")
	assert_almost_eq(combatant_ui.health_bar.bar.value, 50.0)
	combatant_ui.free()


func test_block_appears_and_disappears() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	unit.gain_block(7)
	assert_true(combatant_ui.health_bar.block_box.visible)
	assert_eq(combatant_ui.health_bar.block_label.text, "7")
	unit.take_damage(7)
	assert_false(combatant_ui.health_bar.block_box.visible, "giáp về 0 thì ẩn")
	combatant_ui.free()


func test_status_icons_follow_adds_changes_and_removals() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	assert_eq(combatant_ui.status_row.get_child_count(), 0)
	unit.add_status(_statuses.get_status(&"strength"), 2)
	unit.add_status(_statuses.get_status(&"weak"), 1)
	assert_eq(combatant_ui.status_row.get_child_count(), 2)
	unit.add_status(_statuses.get_status(&"strength"), 1)
	var first := combatant_ui.status_row.get_child(0) as StatusIconUI
	assert_eq(first.view.status_id, &"strength", "buff đứng trước debuff")
	assert_eq(first.amount_label.text, "3", "số stack cập nhật")
	unit.remove_status(&"strength")
	assert_eq(combatant_ui.status_row.get_child_count(), 1)
	combatant_ui.free()


func test_binding_a_unit_that_already_has_statuses_shows_them() -> void:
	var unit := Factory.combatant(&"hero", 80)
	unit.add_status(_statuses.get_status(&"thorns"), 3)
	var combatant_ui := _ui_for(unit)
	assert_eq(combatant_ui.status_row.get_child_count(), 1)
	combatant_ui.free()


func test_death_dims_the_unit() -> void:
	var unit := Factory.combatant(&"hero", 10)
	var combatant_ui := _ui_for(unit)
	unit.take_damage(99)
	assert_almost_eq(combatant_ui.modulate.a, CombatantUI.DEFEATED_ALPHA)
	combatant_ui.free()


func test_binding_a_dead_unit_starts_dimmed() -> void:
	var unit := Factory.combatant(&"hero", 10)
	unit.take_damage(99)
	var combatant_ui := _ui_for(unit)
	assert_almost_eq(combatant_ui.modulate.a, CombatantUI.DEFEATED_ALPHA)
	combatant_ui.free()


func test_rebinding_stops_listening_to_the_old_combatant() -> void:
	var old_unit := Factory.combatant(&"a", 80)
	var new_unit := Factory.combatant(&"b", 40)
	var combatant_ui := _ui_for(old_unit)
	combatant_ui.bind(new_unit)
	old_unit.take_damage(30)
	assert_eq(combatant_ui.health_bar.hp_label.text, "40/40", "đổi máu của quái cũ không được ảnh hưởng UI")
	combatant_ui.free()


func test_unbind_stops_updates() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	combatant_ui.unbind()
	unit.take_damage(30)
	assert_eq(combatant_ui.health_bar.hp_label.text, "80/80")
	combatant_ui.free()


func test_binding_null_keeps_current_binding() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	combatant_ui.bind(null)
	unit.take_damage(10)
	assert_eq(combatant_ui.health_bar.hp_label.text, "70/80")
	combatant_ui.free()


func _connection_count(unit: Combatant) -> int:
	return unit.health_changed.get_connections().size() + unit.block_changed.get_connections().size() \
			+ unit.status_changed.get_connections().size() + unit.died.get_connections().size()


func test_unbind_and_rebind_leave_no_connections_on_the_old_combatant() -> void:
	var old_unit := Factory.combatant(&"a", 80)
	var new_unit := Factory.combatant(&"b", 40)
	var combatant_ui := _ui_for(old_unit)
	assert_eq(_connection_count(old_unit), 4, "đang gắn: đủ 4 Signal")
	combatant_ui.bind(new_unit)
	assert_eq(_connection_count(old_unit), 0, "gắn sang unit khác phải ngắt hết unit cũ")
	assert_eq(_connection_count(new_unit), 4)
	combatant_ui.unbind()
	assert_eq(_connection_count(new_unit), 0)
	combatant_ui.free()


func test_rebuilding_statuses_does_not_leak_nodes() -> void:
	var unit := Factory.combatant(&"hero", 80)
	var combatant_ui := _ui_for(unit)
	unit.add_status(_statuses.get_status(&"strength"), 1)  # trạng thái ổn định: 1 icon hợp lệ
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 5:
		unit.add_status(_statuses.get_status(&"weak"), 1)
		unit.remove_status(&"weak")
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001,
			"icon status cũ phải được giải phóng")
	combatant_ui.free()
