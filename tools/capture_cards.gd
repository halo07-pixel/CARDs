extends SceneTree
## Chụp ảnh bộ thẻ thật để xem bằng mắt. Chạy (cần màn hình ảo):
##   xvfb-run -a godot --path . -s res://tools/capture_cards.gd --resolution 1920x1080 -- --out=/tmp/cards.png
## Hàng trên: số gốc. Hàng dưới: người chơi có Strength 3, vài thẻ không đủ điều kiện, một thẻ bị giảm cost.

const SHOWN_IDS: Array[StringName] = [&"strike", &"defend", &"bash", &"iron_wave", &"cleave",
	&"whirlwind", &"inflame", &"deadly_poison"]
const BACKGROUND := Color("1c2030")
const GAP := 16
const STRENGTH_STACKS := 3
const UNPLAYABLE_SLOTS: Array[int] = [1, 5]
const CHEAPER_SLOT := 3


func _initialize() -> void:
	var cards := CardRegistry.load_from_dir("res://data/cards")
	var statuses := StatusRegistry.load_from_dir("res://data/statuses")
	var hero := Combatant.create(&"hero", "Hero", 80)
	hero.add_status(statuses.get_status(&"strength"), STRENGTH_STACKS)

	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var grid := GridContainer.new()
	grid.columns = SHOWN_IDS.size()
	grid.position = Vector2(GAP, GAP)
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	root.add_child(grid)

	for row in 2:
		for slot in SHOWN_IDS.size():
			var ids: Array[StringName] = [SHOWN_IDS[slot]]
			var instance := cards.create_instances(ids)[0]
			var owner: Combatant = hero if row == 1 else null
			var playable := not (row == 1 and UNPLAYABLE_SLOTS.has(slot))
			if row == 1 and slot == CHEAPER_SLOT:
				instance.set_cost_override(0)
			var card_ui := CardUI.new()
			card_ui.show_view(CardView.build(instance, owner, null, playable))
			grid.add_child(card_ui)

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
	return "/tmp/cards.png"
