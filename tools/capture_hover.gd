extends SceneTree
## Chụp hover + xem trước theo Vulnerable + hình mũi tên (ArrowGeometry) trên BattleScene thật.
##   xvfb-run -a godot --path . -s res://tools/capture_hover.gd --resolution 1920x1080 -- --out=/tmp/hover.png
## Mũi tên ở đây chỉ vẽ tạm để xem hình học; TargetArrowUI thật làm ở mốc 3.4b.

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const HAND_SIZE := 10
const HOVER_INDEX_ATTEMPT := 3
const TARGET_INDEX := 1
const VULNERABLE_STACKS := 2
const ARROW_COLOR := Color("ff5a5a")
const ARROW_WIDTH := 14.0


class ArrowPreview extends Control:
	var shape: ArrowShape

	func _draw() -> void:
		draw_polyline(shape.shaft, ARROW_COLOR, ARROW_WIDTH, true)
		draw_colored_polygon(shape.head, ARROW_COLOR)


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data, 3)
	controller.config.draw_per_turn = HAND_SIZE
	var scene := BattleScene.new()
	root.add_child(scene)
	scene.setup(controller)
	controller.start_battle()
	var target := controller.enemies[TARGET_INDEX]
	target.combatant.add_status(data.statuses.get_status(&"vulnerable"), VULNERABLE_STACKS)
	await _frames(4)
	scene.hand_ui.flush_pending_refresh()

	var strike_index := 0
	for i in controller.deck.get_pile(Deck.HAND).size():
		if controller.deck.get_pile(Deck.HAND)[i].data.id == &"strike" and i >= HOVER_INDEX_ATTEMPT:
			strike_index = i
			break
	var strike := controller.deck.get_pile(Deck.HAND)[strike_index]
	scene.hand_ui.set_hovered(strike)
	scene.hand_ui.set_preview_target(strike, target)
	scene.enemy_uis[TARGET_INDEX].set_targetable(true)
	await _frames(3)

	var from := scene.hand_ui.card_uis[strike_index].get_global_rect()
	var tip := scene.enemy_uis[TARGET_INDEX].art_rect.get_global_rect().get_center()
	var overlay := ArrowPreview.new()
	overlay.shape = ArrowGeometry.build(Vector2(from.get_center().x, from.position.y), tip)
	scene.add_child(overlay)
	await _frames(3)
	var path := _out_path()
	print("đã lưu ", path, " (lỗi=", root.get_texture().get_image().save_png(path), ") thẻ trỏ chuột: vị trí ", strike_index)
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _out_path() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/hover.png"
