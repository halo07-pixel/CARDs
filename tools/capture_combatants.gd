extends SceneTree
## Chụp ảnh người chơi (đủ 11 status) và 4 quái (có ý định, giáp, bị thương, đã chết).
##   xvfb-run -a godot --path . -s res://tools/capture_combatants.gd --resolution 1920x1080 -- --out=/tmp/combatants.png

const BACKGROUND := Color("1c2030")
const ENEMY_IDS: Array[StringName] = [&"slime", &"goblin", &"spiker", &"toxic_slug"]
const DEAD_SLOT := 1
const HURT_SLOT := 3
const HURT_AMOUNT := 8
const BLOCKED_SLOT := 0
const BLOCK_AMOUNT := 6
const HERO_DAMAGE := 18
const HERO_BLOCK := 12
const HERO_STATUSES := {
	&"strength": 3, &"dexterity": 2, &"metallicize": 4, &"demon_form": 1, &"barricade": 1,
	&"thorns": 3, &"weak": 2, &"vulnerable": 1, &"frail": 1, &"poison": 5,
	&"artifact": 1,  # cuối cùng: Artifact chặn debuff gắn SAU nó (đúng luật lõi)
}


func _initialize() -> void:
	var cards := CardRegistry.load_from_dir("res://data/cards")
	var enemies := EnemyRegistry.load_from_dir("res://data/enemies")
	var statuses := StatusRegistry.load_from_dir("res://data/statuses")
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var player := BattleFactory.create_player(warrior)
	var controller := BattleFactory.create(warrior, player, warrior.starting_deck, ENEMY_IDS, cards, enemies, statuses)
	controller.start_battle()

	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var enemy_row := HBoxContainer.new()
	enemy_row.position = Vector2(80, 60)
	enemy_row.add_theme_constant_override("separation", 60)
	root.add_child(enemy_row)
	var enemy_uis: Array[EnemyUI] = []
	for unit in controller.enemies:
		var enemy_ui := EnemyUI.new()
		enemy_ui.bind(unit)
		enemy_row.add_child(enemy_ui)
		enemy_uis.append(enemy_ui)

	var hero_ui := CombatantUI.new()
	hero_ui.position = Vector2(80, 600)
	hero_ui.custom_minimum_size = Vector2(640, 0)
	root.add_child(hero_ui)
	hero_ui.bind(player)

	# Đổi trạng thái SAU khi gắn UI: chứng minh UI tự cập nhật bằng Signal.
	controller.enemies[BLOCKED_SLOT].combatant.gain_block(BLOCK_AMOUNT)
	controller.enemies[HURT_SLOT].combatant.take_damage(HURT_AMOUNT)
	controller.enemies[DEAD_SLOT].combatant.take_damage(9999)
	player.take_damage(HERO_DAMAGE)
	player.gain_block(HERO_BLOCK)
	for id: StringName in HERO_STATUSES:
		player.add_status(statuses.get_status(id), HERO_STATUSES[id])

	for i in 3:
		await process_frame
	var path := _out_path()
	var err := root.get_texture().get_image().save_png(path)
	print("đã lưu ", path, " (lỗi=", err, ")")
	quit(0 if err == OK else 1)


func _out_path() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/combatants.png"
