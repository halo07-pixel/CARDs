extends "res://tests/test_case.gd"
## Scene demo (F6) phải dựng được một trận chơi được từ tệp .tscn thật.


func test_demo_scene_builds_a_playable_battle() -> void:
	var packed := load("res://scenes/battle/battle_demo.tscn") as PackedScene
	assert_true(packed != null)
	var demo := packed.instantiate()
	Engine.get_main_loop().root.add_child(demo)
	var battle_scene: BattleScene = demo.battle_scene
	assert_true(battle_scene != null)
	assert_eq(battle_scene.enemy_uis.size(), 3)
	assert_true(battle_scene.effects.is_enabled(), "demo bật hiệu ứng")
	battle_scene.hand_ui.flush_pending_refresh()
	assert_eq(battle_scene.hand_ui.card_uis.size(), 5)
	assert_false(battle_scene.end_turn_button.disabled)
	battle_scene.end_turn_button.pressed.emit()
	for i in 30:  # hiệu ứng bật: quái đi từng con theo nhịp; đẩy nhịp tay cho test
		battle_scene.enemy_turn_player.fire_now()
	assert_eq(battle_scene.turn_label.text, "Turn 2")
	demo.free()


func test_restart_builds_a_fresh_battle_on_the_next_frame() -> void:
	var demo := (load("res://scenes/battle/battle_demo.tscn") as PackedScene).instantiate()
	Engine.get_main_loop().root.add_child(demo)
	var first: BattleScene = demo.battle_scene
	first.restart_requested.emit()
	assert_eq(demo.battle_scene, first, "dựng lại bị trì hoãn (không giải phóng cảnh trong tín hiệu của chính nó)")
	await Engine.get_main_loop().process_frame
	var second: BattleScene = demo.battle_scene
	assert_ne(second, first)
	assert_true(second.effects.is_enabled(), "trận dựng lại cũng bật hiệu ứng")
	assert_eq(second.enemy_uis.size(), 3)
	assert_false(second.result_overlay.visible)
	await Engine.get_main_loop().process_frame
	assert_false(is_instance_valid(first), "cảnh cũ đã được giải phóng")
	demo.free()
