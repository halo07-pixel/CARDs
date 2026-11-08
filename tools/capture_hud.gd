extends SceneTree
## Chụp các phần HUD mới của mốc 3.5: thanh relic, dây potion, tooltip (potion, relic, thẻ, ý định, status),
## chọn mục tiêu cho potion, dùng potion, lớp phủ xem pile. Đi qua tín hiệu như người chơi (sandbox không có chuột thật).
##   xvfb-run -a godot --path . -s res://tools/capture_hud.gd --resolution 1920x1080 -- --out=/tmp/hud
## Ra các ảnh <out>_1_hud.png ... <out>_8_pile.png

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const RELIC_IDS: Array[StringName] = [&"burning_blood", &"anchor", &"vajra", &"bronze_scales"]
const POTION_IDS: Array[StringName] = [&"fire_potion", &"weak_potion", &"block_potion"]
const SEED := 5


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data, SEED,
			RELIC_IDS, POTION_IDS)
	var scene := BattleScene.new()
	root.add_child(scene)
	scene.setup(controller)
	controller.start_battle()
	await _snap(scene, "1_hud")

	scene.potion_belt_ui.slot_uis[0].mouse_entered.emit()
	await _snap(scene, "2_potion_tooltip")
	scene.potion_belt_ui.slot_uis[0].mouse_exited.emit()

	scene.relic_bar_ui.icon_uis[1].mouse_entered.emit()
	await _snap(scene, "3_relic_tooltip")
	scene.relic_bar_ui.icon_uis[1].mouse_exited.emit()

	var keyword_card := _card_with_keywords(scene, controller)
	if keyword_card != null:
		scene.hand_ui.card_hovered.emit(keyword_card, _card_rect(scene, keyword_card))
		await _snap(scene, "4_card_tooltip")
		scene.hand_ui.card_hover_ended.emit()

	scene.enemy_uis[0]._gui_input(_motion(scene.enemy_uis[0]._intent_rect().get_center()))
	await _snap(scene, "5_intent_tooltip")
	scene.enemy_uis[0]._notification(Control.NOTIFICATION_MOUSE_EXIT)

	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	await _snap(scene, "6_potion_targeting")

	scene.enemy_uis[1].clicked.emit(controller.enemies[1])
	await _snap(scene, "7_potion_used")

	scene.draw_counter.clicked.emit(Deck.DRAW)
	await _snap(scene, "8_pile")
	quit()


func _card_with_keywords(scene: BattleScene, controller: BattleController) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if TooltipBuilder.for_card_with(card.data, controller.get_status_data).has_content():
			return card
	return null


func _card_rect(scene: BattleScene, card: CardInstance) -> Rect2:
	for card_ui in scene.hand_ui.card_uis:
		if card_ui.view.uid == card.uid:
			return card_ui.get_global_rect()
	return Rect2()


func _motion(at: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	return event


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
	return "/tmp/hud"
