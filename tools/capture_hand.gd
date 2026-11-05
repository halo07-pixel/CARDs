extends SceneTree
## Chụp tay bài + năng lượng + pile + quái (các thành phần của 3.3a ghép tay, chưa có BattleScene).
##   xvfb-run -a godot --path . -s res://tools/capture_hand.gd --resolution 1920x1080 -- --out=/tmp/hand
## Ra hai ảnh: <out>_a.png (đang chọn thẻ nhắm mục tiêu) và <out>_b.png (đã hết năng lượng, thẻ mờ).

const BACKGROUND := Color("1c2030")
const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
const HAND_SIZE := 10
const ENEMY_ROW_POSITION := Vector2(330, 40)
const HERO_POSITION := Vector2(60, 520)
const HAND_POSITION := Vector2(210, 720)
const ENERGY_POSITION := Vector2(40, 900)
const DRAW_POSITION := Vector2(40, 780)
const DISCARD_POSITION := Vector2(1750, 900)
const EXHAUST_POSITION := Vector2(1750, 790)
const DEFENDS_TO_PLAY := 3


func _initialize() -> void:
	var data := GameData.load_default()
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, ENEMY_IDS, data)
	controller.config.draw_per_turn = HAND_SIZE
	controller.start_battle()

	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var enemy_row := HBoxContainer.new()
	enemy_row.position = ENEMY_ROW_POSITION
	enemy_row.add_theme_constant_override("separation", 90)
	root.add_child(enemy_row)
	var enemy_uis: Array[EnemyUI] = []
	for unit in controller.enemies:
		var enemy_ui := EnemyUI.new()
		enemy_ui.bind(unit)
		enemy_row.add_child(enemy_ui)
		enemy_uis.append(enemy_ui)

	var hero_ui := CombatantUI.new()
	hero_ui.position = HERO_POSITION
	root.add_child(hero_ui)
	hero_ui.bind(controller.player)

	var hand := HandUI.new()
	hand.position = HAND_POSITION
	root.add_child(hand)
	hand.bind(controller)
	var energy_ui := EnergyUI.new()
	energy_ui.position = ENERGY_POSITION
	root.add_child(energy_ui)
	energy_ui.bind(controller)
	var piles := {DRAW_POSITION: Deck.DRAW, DISCARD_POSITION: Deck.DISCARD, EXHAUST_POSITION: Deck.EXHAUST}
	for pile_position: Vector2 in piles:
		var counter := PileCounterUI.new(piles[pile_position])
		counter.position = pile_position
		root.add_child(counter)
		counter.bind(controller.deck)

	# Ảnh A: đang chọn một thẻ cần mục tiêu.
	var intent := PlayIntent.new()
	var strike := _first_in_hand(controller, true)
	var decision := intent.select_card(strike, controller)
	print("quyết định chọn thẻ nhắm: ", PlayIntent.Outcome.keys()[decision.outcome])
	hand.set_selected(intent.selected)
	for enemy_ui in enemy_uis:
		enemy_ui.set_targetable(intent.is_targeting())
	await _snapshot("a")

	# Ảnh B: chơi 3 thẻ không cần mục tiêu để hết năng lượng.
	intent.cancel()
	hand.set_selected(null)
	for enemy_ui in enemy_uis:
		enemy_ui.set_targetable(false)
	for i in DEFENDS_TO_PLAY:
		var card := _first_in_hand(controller, false)
		var play := intent.select_card(card, controller)
		if play.outcome == PlayIntent.Outcome.PLAY_NOW:
			controller.play_card(play.card, play.target)
	hand.flush_pending_refresh()
	await _snapshot("b")
	quit()


func _first_in_hand(controller: BattleController, needs_target: bool) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if (card.data.target_mode == CardData.TargetMode.SINGLE_ENEMY) == needs_target:
			return card
	return null


func _snapshot(suffix: String) -> void:
	for i in 3:
		await process_frame
	var path := "%s_%s.png" % [_out_prefix(), suffix]
	print("đã lưu ", path, " (lỗi=", root.get_texture().get_image().save_png(path), ")")


func _out_prefix() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.trim_prefix("--out=")
	return "/tmp/hand"
