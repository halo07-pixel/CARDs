extends SceneTree
## Chụp BattleScene khi đang kéo thẻ (bằng chuỗi sự kiện chuột giả như người chơi): kéo Strike tới quái
## (mũi tên đỏ + số theo Vulnerable) và kéo Defend (thẻ bám con trỏ + vùng thả sáng).
##   xvfb-run -a godot --path . -s res://tools/capture_drag.gd --resolution 1920x1080 -- --out=/tmp/drag
## Ra <out>_1_attack.png, <out>_2_skill.png, <out>_3_dropped.png

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const TARGET_INDEX := 1
const VULNERABLE_STACKS := 2
const SKILL_POINTER := Vector2(900, 300)
const START_DRAG_OFFSET := Vector2(0, -80)


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data, 3)
	controller.config.draw_per_turn = 8
	var scene := BattleScene.new()
	root.add_child(scene)
	scene.setup(controller)
	controller.start_battle()
	controller.enemies[TARGET_INDEX].combatant.add_status(data.statuses.get_status(&"vulnerable"), VULNERABLE_STACKS)
	await _frames(4)
	scene.hand_ui.flush_pending_refresh()
	await _frames(2)

	# 1) kéo một thẻ Strike tới quái
	var strike_ui := _card_ui(scene, controller, &"strike")
	var origin := strike_ui.get_global_rect().get_center()
	strike_ui._gui_input(_press(origin))
	strike_ui._gui_input(_motion(origin + START_DRAG_OFFSET))
	var target := scene.enemy_uis[TARGET_INDEX].get_global_rect().get_center()
	strike_ui._gui_input(_motion(target))
	await _snap("1_attack")
	strike_ui.cancel_drag()

	# 2) kéo một thẻ Defend vào vùng thả
	scene.hand_ui.flush_pending_refresh()
	await _frames(2)
	var defend_ui := _card_ui(scene, controller, &"defend")
	origin = defend_ui.get_global_rect().get_center()
	defend_ui._gui_input(_press(origin))
	defend_ui._gui_input(_motion(origin + START_DRAG_OFFSET))
	defend_ui._gui_input(_motion(SKILL_POINTER))
	await _snap("2_skill")

	# 3) nhả: thẻ được chơi, hero có giáp
	defend_ui._gui_input(_release(SKILL_POINTER))
	scene.hand_ui.flush_pending_refresh()
	await _snap("3_dropped")
	quit()


func _card_ui(scene: BattleScene, controller: BattleController, card_id: StringName) -> CardUI:
	for card_ui in scene.hand_ui.card_uis:
		if card_ui.view.card_id == card_id:
			return card_ui
	return null


func _press(at: Vector2) -> InputEventMouseButton:
	return _button(at, true)


func _release(at: Vector2) -> InputEventMouseButton:
	return _button(at, false)


func _button(at: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	return event


func _motion(to: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	return event


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _snap(suffix: String) -> void:
	await _frames(3)
	var path := "%s_%s.png" % [_out_prefix(), suffix]
	print("đã lưu ", path, " (lỗi=", root.get_texture().get_image().save_png(path), ")")


func _out_prefix() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/drag"
