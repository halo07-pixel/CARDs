extends "res://tests/test_case.gd"
## Fuzz HUD mốc 3.5: thao tác ngẫu nhiên qua tín hiệu (bấm potion/quái/thẻ/pile, hover, Esc, End Turn, hủy).
## Sau MỖI bước so mọi thứ HUD với controller. Mọi chỗ lệch = lỗi (kèm seed + bước để tái hiện).

const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const STEPS_PER_SEED := 150
const EXTRA_STEPS_AFTER_END := 4
const ENEMY_SETS: Array = [
	[&"slime", &"goblin", &"acolyte"],
	[&"spiker", &"toxic_slug"],
	[&"slime"],
]
const RELIC_IDS: Array[StringName] = [&"anchor", &"burning_blood", &"vajra"]
const POTION_IDS: Array[StringName] = [&"fire_potion", &"weak_potion", &"block_potion"]

var _data: GameData
var _log: String = ""
var _stats := {"potions_used": 0, "potion_targeting": 0, "potion_rejected": 0, "piles_opened": 0, "tooltips": 0,
		"escapes": 0, "turns": 0, "fx_peak": 0, "fx_drained": 0}


func before_each() -> void:
	_data = GameData.load_default()


func test_hud_always_matches_the_controller_under_random_play() -> void:
	for seed_value in SEEDS:
		await _run_seed(seed_value)
	print("  [fuzz hud] ", _stats)
	assert_true(_stats["potions_used"] >= 15, "ít potion được dùng: %s" % [_stats])
	assert_true(_stats["potion_targeting"] >= 15, "ít lần vào chế độ chọn mục tiêu của potion: %s" % [_stats])
	assert_true(_stats["potion_rejected"] >= 5, "ít lần potion bị từ chối: %s" % [_stats])
	assert_true(_stats["piles_opened"] >= 20, "ít lần mở pile: %s" % [_stats])
	assert_true(_stats["tooltips"] >= 40, "ít lần tooltip hiện: %s" % [_stats])
	assert_true(_stats["escapes"] >= 10, "ít lần Esc: %s" % [_stats])
	assert_true(_stats["turns"] >= 20, "ít lượt: %s" % [_stats])
	assert_true(_stats["fx_peak"] >= 5, "hiệu ứng ít khi xuất hiện: %s" % [_stats])
	assert_eq(_stats["fx_drained"], SEEDS.size(), "mọi seed phải dọn sạch chữ nổi và thanh máu khi hết hiệu ứng")


func _run_seed(seed_value: int) -> void:
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemy_ids: Array[StringName] = []
	enemy_ids.assign(ENEMY_SETS[seed_value % ENEMY_SETS.size()])
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemy_ids, _data, seed_value,
			RELIC_IDS, POTION_IDS)
	var scene := BattleScene.new()
	scene.effects.speed = 80.0  # bật hiệu ứng (rất nhanh) để fuzz cả lớp trình diễn
	Engine.get_main_loop().root.add_child(scene)  # cần nằm trong cây để có toạ độ thật cho vùng ý định
	scene.setup(controller)
	controller.potion_used.connect(func(_s: int, _p: PotionData, _t: EnemyUnit, _r: Array[EffectResult]) -> void: _stats["potions_used"] += 1)
	controller.turn_started.connect(func(_n: int, is_player: bool) -> void: _stats["turns"] += 1 if is_player else 0)
	controller.action_rejected.connect(func(_reason: StringName) -> void: pass)
	controller.start_battle()
	var initial_potions := controller.potions.count()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var extra := 0
	await Engine.get_main_loop().process_frame
	_check(scene, controller, initial_potions, "seed %d: sau khi bắt đầu" % seed_value)
	var previous_potions := initial_potions
	for step in STEPS_PER_SEED:
		if controller.state.is_terminal():
			extra += 1
			if extra > EXTRA_STEPS_AFTER_END:
				break
		_log = "seed %d bước %d: %s" % [seed_value, step, _random_action(scene, controller, rng)]
		_stats["potion_targeting"] += 1 if scene.potion_intent.is_targeting() else 0
		_stats["tooltips"] += 1 if scene.tooltip_ui.visible else 0
		_check(scene, controller, previous_potions, _log)
		previous_potions = controller.potions.count()
	await _drain_effects(scene, seed_value)
	scene.free()


## Hết thao tác: chờ mọi chữ nổi và thanh máu trượt kết thúc (tốc độ rất nhanh nên vài chục khung là đủ).
func _drain_effects(scene: BattleScene, seed_value: int) -> void:
	for i in 600:
		if scene.effects_layer.get_child_count() == 0 and not _any_bar_animating(scene):
			_stats["fx_drained"] += 1
			return
		await Engine.get_main_loop().process_frame
	assert_true(false, "seed %d: hiệu ứng không tự kết thúc (chữ=%d)" % [seed_value, scene.effects_layer.get_child_count()])


func _any_bar_animating(scene: BattleScene) -> bool:
	if scene.hero_ui.health_bar.is_animating():
		return true
	for enemy_ui in scene.enemy_uis:
		if enemy_ui.combatant_ui.health_bar.is_animating():
			return true
	return false


func _random_action(scene: BattleScene, controller: BattleController, rng: RandomNumberGenerator) -> String:
	var roll := rng.randi_range(0, 99)
	var hand := controller.deck.get_pile(Deck.HAND)
	if roll < 15:
		var slot := rng.randi_range(0, 2)
		var count_before := controller.potions.count()
		scene.potion_belt_ui.slot_uis[slot].pressed.emit()
		if controller.potions.count() == count_before and not scene.potion_intent.is_targeting() \
				and not scene.message_label.text.is_empty():
			_stats["potion_rejected"] += 1
		return "bấm ô potion %d" % slot
	if roll < 25:
		var index := rng.randi_range(0, scene.enemy_uis.size() - 1)
		scene.enemy_uis[index].clicked.emit(scene.enemy_uis[index].unit)
		return "bấm quái %d" % index
	if roll < 40 and not hand.is_empty():
		var card := hand[rng.randi_range(0, hand.size() - 1)]
		scene.hand_ui.card_clicked.emit(card)
		return "bấm thẻ %s" % card.data.id
	if roll < 48:
		scene.end_turn_button.pressed.emit()
		return "End Turn"
	if roll < 55:
		scene.cancel_targeting()
		return "huỷ chọn"
	if roll < 60:
		_stats["escapes"] += 1
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		scene._unhandled_input(escape)
		return "Esc"
	if roll < 68:
		var counters := [scene.draw_counter, scene.discard_counter, scene.exhaust_counter]
		var counter: PileCounterUI = counters[rng.randi_range(0, 2)]
		var was_open := scene.pile_viewer.is_open()
		counter.clicked.emit(counter.pile_name)
		_stats["piles_opened"] += 1 if scene.pile_viewer.is_open() and not was_open else 0
		return "bấm bộ đếm %s" % counter.pile_name
	if roll < 72:
		scene.pile_viewer.close_button.pressed.emit()
		return "đóng pile"
	if roll < 86:
		return _hover(scene, rng, true)
	if roll < 93:
		return _hover(scene, rng, false)
	scene._on_potion_slot_clicked(rng.randi_range(3, 9))  # ô không tồn tại
	return "bấm ô potion không tồn tại"


## Vào/ra hover một nguồn tooltip ngẫu nhiên.
func _hover(scene: BattleScene, rng: RandomNumberGenerator, entering: bool) -> String:
	var pick := rng.randi_range(0, 5)
	var signal_name := "mouse_entered" if entering else "mouse_exited"
	match pick:
		0:
			scene.relic_bar_ui.icon_uis[rng.randi_range(0, scene.relic_bar_ui.icon_uis.size() - 1)].emit_signal(signal_name)
			return "%s relic" % signal_name
		1:
			scene.potion_belt_ui.slot_uis[rng.randi_range(0, 2)].emit_signal(signal_name)
			return "%s potion" % signal_name
		2:
			var icons := scene.hero_ui.status_row.get_children()
			if not icons.is_empty():
				icons[rng.randi_range(0, icons.size() - 1)].emit_signal(signal_name)
			return "%s status hero" % signal_name
		3:
			var enemy_ui := scene.enemy_uis[rng.randi_range(0, scene.enemy_uis.size() - 1)]
			var icons := enemy_ui.combatant_ui.status_row.get_children()
			if not icons.is_empty():
				icons[rng.randi_range(0, icons.size() - 1)].emit_signal(signal_name)
			return "%s status quái" % signal_name
		4:
			var enemy_ui := scene.enemy_uis[rng.randi_range(0, scene.enemy_uis.size() - 1)]
			if entering:
				var at := enemy_ui._intent_rect().get_center()
				var motion := InputEventMouseMotion.new()
				motion.position = at
				motion.global_position = at
				enemy_ui._gui_input(motion)
			else:
				enemy_ui._notification(Control.NOTIFICATION_MOUSE_EXIT)
			return "%s ý định" % signal_name
		_:
			if not scene.hand_ui.card_uis.is_empty():
				scene.hand_ui.card_uis[rng.randi_range(0, scene.hand_ui.card_uis.size() - 1)].emit_signal(signal_name)
			return "%s thẻ" % signal_name


func _check(scene: BattleScene, controller: BattleController, previous_potions: int, label: String) -> void:
	scene.hand_ui.flush_pending_refresh()
	assert_eq(scene.energy_ui.label.text, "%d/%d" % [controller.energy, controller.config.max_energy], label + " | năng lượng")
	assert_eq(scene.end_turn_button.disabled, not controller.state.is_player_turn(), label + " | nút End Turn")
	assert_eq(scene.result_overlay.visible, controller.state.is_terminal(), label + " | lớp phủ kết quả")
	assert_eq(scene.hero_ui.health_bar.hp_label.text, "%d/%d" % [controller.player.hp, controller.player.max_hp], label + " | máu")
	assert_true(controller.potions.count() <= previous_potions, label + " | số potion không được tăng")
	_check_belt(scene, controller, label)
	assert_eq(scene.relic_bar_ui.icon_uis.size(), controller.relics.size(), label + " | số relic")
	_check_exclusive_targeting(scene, controller, label)
	_check_overlays(scene, label)
	_check_effects(scene, label)


func _check_belt(scene: BattleScene, controller: BattleController, label: String) -> void:
	var views := PotionView.build_all(controller)
	assert_eq(scene.potion_belt_ui.slot_uis.size(), views.size(), label + " | số ô potion")
	for i in views.size():
		var slot_ui := scene.potion_belt_ui.slot_uis[i]
		assert_eq(slot_ui.view.is_empty, views[i].is_empty, label + " | ô %d trống" % i)
		assert_eq(slot_ui.view.potion_id, views[i].potion_id, label + " | ô %d id" % i)
		assert_eq(slot_ui.view.usable, views[i].usable, label + " | ô %d dùng được" % i)
		if not views[i].is_empty:
			var dimmed := slot_ui.modulate.a < 1.0
			assert_eq(dimmed, not views[i].usable and not slot_ui.selected, label + " | ô %d mờ <-> không dùng được" % i)
		assert_eq(slot_ui.selected, scene.potion_intent.selected_slot == i, label + " | ô %d viền chọn" % i)


func _check_exclusive_targeting(scene: BattleScene, controller: BattleController, label: String) -> void:
	assert_false(scene.intent.is_targeting() and scene.potion_intent.is_targeting(), label + " | thẻ và potion cùng chờ mục tiêu")
	var targetable: Array[EnemyUnit] = []
	for enemy_ui in scene.enemy_uis:
		if enemy_ui.art_rect.color == EnemyUI.ART_TARGETABLE_COLOR:
			targetable.append(enemy_ui.unit)
	if scene.potion_intent.is_targeting():
		var slot := scene.potion_intent.selected_slot
		assert_eq(PotionIntent.slot_blocker(slot, controller), &"", label + " | potion đang chọn phải còn dùng được")
		var valid := controller.valid_potion_targets(slot)
		assert_eq(targetable.size(), valid.size(), label + " | tô nổi đúng mục tiêu hợp lệ của potion")
		for unit in valid:
			assert_true(targetable.has(unit), label + " | mục tiêu hợp lệ phải nổi")
	elif not scene.intent.is_targeting() and not scene.is_dragging():
		assert_eq(targetable.size(), 0, label + " | không chọn gì thì không quái nào nổi")


func _check_overlays(scene: BattleScene, label: String) -> void:
	if scene.pile_viewer.is_open() or scene.is_dragging():
		assert_false(scene.tooltip_ui.visible, label + " | tooltip hiện khi đang mở pile/kéo thẻ")
	if scene.tooltip_ui.visible:
		var has_content := scene.tooltip_ui.title_label.visible or scene.tooltip_ui.body_label.visible \
				or scene.tooltip_ui.entries_box.visible
		assert_true(has_content, label + " | tooltip rỗng đang hiện")
	assert_false(scene.is_dragging(), label + " | cảnh còn trạng thái kéo")


func _check_effects(scene: BattleScene, label: String) -> void:
	var layer := scene.effects_layer
	_stats["fx_peak"] = maxi(_stats["fx_peak"], layer.get_child_count())
	assert_true(layer.get_child_count() < 3000, label + " | chữ nổi tích tụ quá nhiều")
	for child in layer.get_children():
		var text := child as FloatingTextUI
		assert_true(text != null and not text.text.is_empty(), label + " | chữ nổi rỗng")
		assert_true(text.modulate.a >= 0.0 and text.modulate.a <= 1.0, label + " | độ mờ ngoài [0,1]")
		assert_true(is_finite(text.position.x) and is_finite(text.position.y), label + " | vị trí không hữu hạn")
		assert_true(text.get_meta(EffectsLayerUI.OWNER_META, null) is Combatant, label + " | chữ nổi mất chủ")
	for enemy_ui in scene.enemy_uis:
		assert_true(enemy_ui.art_rect.scale.x >= 1.0 and enemy_ui.art_rect.scale.x <= UiFx.POP_SCALE + 0.0001, label + " | scale hình quái lạ")
