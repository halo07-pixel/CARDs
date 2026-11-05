extends SceneTree
## Chụp BattleScene qua luồng thật (bằng tín hiệu click như người chơi): đầu lượt, chọn mục tiêu, sau khi chơi,
## sau End Turn, thắng. Riêng ảnh thắng dùng take_damage để rút gọn.
##   xvfb-run -a godot --path . -s res://tools/capture_battle.gd --resolution 1920x1080 -- --out=/tmp/battle
## Ra các ảnh <out>_1_start.png ... <out>_5_victory.png

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const SEED := 5
const HIT_ENEMY_INDEX := 0


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data, SEED)
	var scene := BattleScene.new()
	root.add_child(scene)
	scene.setup(controller)
	controller.start_battle()
	await _snap(scene, "1_start")

	var attack := _first_in_hand(controller, true)
	scene.hand_ui.card_clicked.emit(attack)
	await _snap(scene, "2_targeting")

	scene.enemy_uis[HIT_ENEMY_INDEX].clicked.emit(controller.enemies[HIT_ENEMY_INDEX])
	var skill := _first_in_hand(controller, false)
	if skill != null:
		scene.hand_ui.card_clicked.emit(skill)
	await _snap(scene, "3_played")

	scene.end_turn_button.pressed.emit()
	await _snap(scene, "4_after_end_turn")

	for unit in controller.enemies:
		unit.combatant.take_damage(9999)
	# Controller chỉ kiểm tra thắng/thua sau một hành động: chơi một thẻ qua giao diện như người chơi.
	var finisher := _first_in_hand(controller, false)
	if finisher != null:
		scene.hand_ui.card_clicked.emit(finisher)
	await _snap(scene, "5_victory")
	quit()


func _first_in_hand(controller: BattleController, needs_target: bool) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if (card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY) == needs_target and controller.can_play(card):
			return card
	return null


func _snap(scene: BattleScene, suffix: String) -> void:
	for i in 4:
		await process_frame
	scene.hand_ui.flush_pending_refresh()
	await process_frame
	var path := "%s_%s.png" % [_out_prefix(), suffix]
	print("đã lưu ", path, " (lỗi=", root.get_texture().get_image().save_png(path), ")")


func _out_prefix() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/battle"
