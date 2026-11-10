extends SceneTree
## Chụp HUD ĐANG chạy hiệu ứng (chữ nổi, nảy/nháy, thanh máu mượt, rung thẻ bị từ chối) bằng thời gian thật.
##   xvfb-run -a godot --path . -s res://tools/capture_fx.gd --resolution 1920x1080 -- --out=/tmp/fx
## Ra các ảnh <out>_1_damage.png ... <out>_8_enemy_turn_done.png

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const RELIC_IDS: Array[StringName] = [&"burning_blood", &"anchor", &"vajra", &"bronze_scales"]
const POTION_IDS: Array[StringName] = [&"fire_potion", &"weak_potion", &"block_potion"]
const SEED := 5
const SLOW_SPEED := 0.35  ## chậm hơn thật để bắt được khung hình giữa chừng


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data, SEED,
			RELIC_IDS, POTION_IDS)
	var scene := BattleScene.new()
	scene.effects.speed = SLOW_SPEED
	root.add_child(scene)
	scene.setup(controller)
	controller.start_battle()
	await _wait(0.5)

	scene.hand_ui.card_clicked.emit(_first_in_hand(controller, true))
	scene.enemy_uis[0].clicked.emit(controller.enemies[0])
	await _wait(0.7)
	await _snap("1_damage")

	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	scene.enemy_uis[1].clicked.emit(controller.enemies[1])
	await _wait(0.9)
	await _snap("2_potion")

	var defend := _first_in_hand(controller, false)
	if defend != null:
		scene.hand_ui.card_clicked.emit(defend)
	await _wait(0.6)
	await _snap("3_block")

	for card in controller.deck.get_pile(Deck.HAND):  # gạt hết năng lượng rồi bấm thẻ để bị từ chối
		if controller.can_play(card):
			scene.hand_ui.card_clicked.emit(card)
			if card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY:
				scene.enemy_uis[2].clicked.emit(controller.enemies[2])
	await _wait(1.2)
	for card in controller.deck.get_pile(Deck.HAND):
		if not controller.can_play(card):
			scene.hand_ui.card_clicked.emit(card)
			break
	await _wait(0.08)
	await _snap("4_rejected_shake")

	await _wait(1.2)
	scene.end_turn_button.pressed.emit()
	await _wait(0.45)
	await _snap("5_enemy_windup")  # quái đầu nảy lên báo sắp đi, chưa đánh
	await _wait(1.0)
	await _snap("6_enemy_first_acted")  # chỉ quái đầu đã đánh: chỉ có số của nó
	await _wait(2.6)
	await _snap("7_enemy_mid_turn")  # quái kế tiếp đang đi
	await _wait(5.0)
	await _snap("8_enemy_turn_done")  # hết lượt quái, sang lượt người chơi
	quit()


func _first_in_hand(controller: BattleController, needs_target: bool) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if (card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY) == needs_target and controller.can_play(card):
			return card
	return null


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _snap(suffix: String) -> void:
	await process_frame
	var path := "%s_%s.png" % [_out_prefix(), suffix]
	print("đã lưu ", path, " (lỗi=", root.get_texture().get_image().save_png(path), ")")


func _out_prefix() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/fx"
