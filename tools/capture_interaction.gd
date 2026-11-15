extends SceneTree
## Chụp TẤT ĐỊNH các cảnh tương tác: kéo thả thẻ (mũi tên, vùng chơi, thả hỏng) và hiệu ứng trình diễn (chữ nổi, thanh máu,
## rung, lượt quái). Mọi tween bị đóng băng ở một mốc thời gian cố định (custom_step) nên hai lần chụp cho ảnh giống từng byte.
## Dùng để chứng minh refactor BattleScene không đổi hình ảnh:
##   xvfb-run -a godot --audio-driver Dummy --path . -s res://tools/capture_interaction.gd --resolution 1920x1080 -- --out=/tmp/ia
## Ra các ảnh <out>_1_drag_target.png ... <out>_9_enemy_turn.png

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const RELIC_IDS: Array[StringName] = [&"burning_blood", &"anchor", &"vajra", &"bronze_scales"]
const POTION_IDS: Array[StringName] = [&"fire_potion", &"weak_potion", &"block_potion"]
const SEED := 5
const FREEZE_SECONDS := 0.4


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data, SEED,
			RELIC_IDS, POTION_IDS)
	var scene := BattleScene.new()
	scene.effects.speed = EffectsConfig.NORMAL_SPEED
	root.add_child(scene)
	scene.setup(controller)
	controller.start_battle()
	await _settle(scene)

	var strike := _card(controller, &"strike")
	var defend := _card(controller, &"defend")
	var enemy_center := scene.enemy_uis[1].get_global_rect().get_center()

	# 1. Kéo thẻ nhắm quái: mũi tên + quái được tô nổi + số xem trước
	scene._on_drag_started(strike, scene.hand_ui.get_global_rect().get_center())
	scene._on_drag_moved(strike, enemy_center)
	await _snap(scene, "1_drag_target")
	scene._on_drag_ended(strike, enemy_center)  # thả vào quái: chơi thẻ
	await _snap(scene, "2_drop_on_enemy", true)

	# 3. Kéo thẻ thường qua vùng chơi
	scene._on_drag_started(defend, scene.hand_ui.get_global_rect().get_center())
	scene._on_drag_moved(defend, scene.play_zone.get_global_rect().get_center())
	await _snap(scene, "3_drag_play_zone")
	scene._on_drag_ended(defend, scene.play_zone.get_global_rect().get_center())
	await _snap(scene, "4_drop_in_zone", true)

	# 5. Kéo rồi thả ra ngoài: hủy
	var other := _any_card(controller)
	scene._on_drag_started(other, scene.hand_ui.get_global_rect().get_center())
	scene._on_drag_moved(other, Vector2(900, 600))
	await _snap(scene, "5_drag_outside")
	scene._on_drag_ended(other, Vector2(900, 600))
	await _snap(scene, "6_drop_outside", true)

	# 7. Dùng potion nhắm quái (chọn mục tiêu rồi dùng)
	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	await _snap(scene, "7_potion_targeting")
	scene.enemy_uis[2].clicked.emit(controller.enemies[2])
	await _snap(scene, "8_potion_used", true)

	# 9. Hết năng lượng, bấm thẻ bị từ chối (rung) rồi End Turn: lượt quái tuần tự
	scene.end_turn_button.pressed.emit()
	scene.enemy_turn_player.fire_now()
	await _snap(scene, "9_enemy_turn", true)
	quit()


func _card(controller: BattleController, card_id: StringName) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if card.data.id == card_id:
			return card
	return _any_card(controller)


func _any_card(controller: BattleController) -> CardInstance:
	return controller.deck.get_pile(Deck.HAND)[0]


## Vài khung hình cho bố cục ổn định.
func _settle(scene: BattleScene) -> void:
	for i in 4:
		await process_frame
	scene.hand_ui.flush_pending_refresh()
	await process_frame


## Đóng băng NGAY mọi tween ở mốc FREEZE_SECONDS (trước khi chờ khung hình thật, để không phụ thuộc thời gian thực),
## rồi chờ bố cục ổn định và chụp.
func _snap(scene: BattleScene, suffix: String, _unused: bool = false) -> void:
	for tween in get_processed_tweens():
		if tween.is_valid():
			tween.pause()
			tween.custom_step(FREEZE_SECONDS)
	await _settle(scene)
	var path := "%s_%s.png" % [_out_prefix(), suffix]
	print("đã lưu ", path, " (lỗi=", root.get_texture().get_image().save_png(path), ")")


func _out_prefix() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/ia"
