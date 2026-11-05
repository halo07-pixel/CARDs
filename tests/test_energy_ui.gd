extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func _started() -> BattleController:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"dummy", 40, 6)]
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func test_shows_current_over_max() -> void:
	var energy_ui := EnergyUI.new()
	energy_ui.bind(_started())
	assert_eq(energy_ui.label.text, "3/3")
	energy_ui.free()


func test_follows_energy_changes() -> void:
	var controller := _started()
	var energy_ui := EnergyUI.new()
	energy_ui.bind(controller)
	var card := Factory.inject(controller, Factory.strike())
	controller.play_card(card, controller.enemies[0])
	assert_eq(energy_ui.label.text, "2/3")
	controller.gain_energy(2)
	assert_eq(energy_ui.label.text, "4/3", "năng lượng có thể vượt mức tối đa (thẻ cho thêm)")
	energy_ui.free()


func test_unbind_and_rebind_stop_listening() -> void:
	var old_controller := _started()
	var new_controller := _started()
	var energy_ui := EnergyUI.new()
	energy_ui.bind(old_controller)
	energy_ui.bind(new_controller)
	assert_eq(old_controller.energy_changed.get_connections().size(), 0)
	old_controller.gain_energy(1)
	assert_eq(energy_ui.label.text, "3/3", "trận cũ đổi không ảnh hưởng")
	energy_ui.unbind()
	assert_eq(new_controller.energy_changed.get_connections().size(), 0)
	energy_ui.free()


func test_binding_null_keeps_the_current_battle() -> void:
	var controller := _started()
	var energy_ui := EnergyUI.new()
	energy_ui.bind(controller)
	energy_ui.bind(null)
	controller.gain_energy(1)
	assert_eq(energy_ui.label.text, "4/3")
	energy_ui.free()
