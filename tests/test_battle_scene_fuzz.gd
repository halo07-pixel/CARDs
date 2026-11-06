extends "res://tests/test_case.gd"
## UI điều khiển ngẫu nhiên (click thẻ/quái/End Turn/huỷ/thẻ không có trong tay), sau MỖI bước so sánh
## mọi thứ hiển thị trên màn hình với trạng thái của controller. Mọi chỗ lệch = lỗi (kèm seed + bước để tái hiện).

const UiInput := preload("res://tests/ui_input.gd")

const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const STEPS_PER_SEED := 150
const EXTRA_STEPS_AFTER_END := 4
const CARD_CLICK_PERCENT := 40
const DRAG_PERCENT := 65
const ENEMY_CLICK_PERCENT := 77
const END_TURN_PERCENT := 85
const CANCEL_PERCENT := 89
const STALE_CARD_PERCENT := 92
const DRAG_DROP_PERCENT := 70   # còn lại: nửa Esc, nửa chuột phải
const DRAG_ESCAPE_PERCENT := 85
const ZONE_X_RANGE := Vector2(100, 1800)
const ZONE_Y_RANGE := Vector2(100, 600)
const BELOW_ZONE_Y_RANGE := Vector2(700, 1000)
const ENEMY_SETS: Array = [
	[&"slime", &"goblin", &"acolyte"],
	[&"spiker", &"toxic_slug"],
	[&"slime"],
]

var _data: GameData
var _log: String = ""
var _stats := {"played": 0, "targeting": 0, "turns": 0, "ended": 0, "victories": 0, "rejected": 0,
		"drags": 0, "dropped": 0, "drag_cancelled": 0}


func before_each() -> void:
	_data = GameData.load_default()


func test_ui_always_matches_the_controller_under_random_play() -> void:
	for seed_value in SEEDS:
		await _run_seed(seed_value)
	print("  [fuzz] ", _stats)
	# Chứng minh test không rỗng: thật sự đã chơi thẻ, chọn mục tiêu, qua lượt, kết thúc trận và bị từ chối.
	assert_true(_stats["played"] >= 100, "ít thẻ được chơi: %s" % [_stats])
	assert_true(_stats["targeting"] >= 20, "ít lần vào chế độ chọn mục tiêu: %s" % [_stats])
	assert_true(_stats["turns"] >= 30, "ít lượt: %s" % [_stats])
	assert_true(_stats["ended"] >= 6, "ít trận kết thúc: %s" % [_stats])
	assert_true(_stats["victories"] >= 1 and _stats["victories"] < _stats["ended"], "phải có cả thắng lẫn thua: %s" % [_stats])
	assert_true(_stats["drags"] >= 40, "ít lần kéo thả: %s" % [_stats])
	assert_true(_stats["dropped"] >= 20, "ít lần nhả thẻ: %s" % [_stats])
	assert_true(_stats["drag_cancelled"] >= 8, "ít lần huỷ kéo: %s" % [_stats])
	assert_true(_stats["rejected"] >= 50, "ít lần bị từ chối: %s" % [_stats])


func _run_seed(seed_value: int) -> void:
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemy_ids: Array[StringName] = []
	enemy_ids.assign(ENEMY_SETS[seed_value % ENEMY_SETS.size()])
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemy_ids, _data, seed_value)
	var scene := BattleScene.new()
	Engine.get_main_loop().root.add_child(scene)  # cần nằm trong cây để có toạ độ thật cho kéo thả
	scene.setup(controller)
	scene.hand_ui.drag_ended.connect(func(_c: CardInstance, _p: Vector2) -> void: _stats["dropped"] += 1)
	scene.hand_ui.drag_cancelled.connect(func(_c: CardInstance) -> void: _stats["drag_cancelled"] += 1)
	controller.card_played.connect(func(_c: CardInstance, _t: EnemyUnit, _r: Array[EffectResult]) -> void: _stats["played"] += 1)
	controller.turn_started.connect(func(_n: int, is_player: bool) -> void: _stats["turns"] += 1 if is_player else 0)
	controller.battle_ended.connect(func(victory: bool) -> void:
		_stats["ended"] += 1
		_stats["victories"] += 1 if victory else 0)
	controller.start_battle()
	var initial_total := controller.deck.total_count()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var extra := 0
	await Engine.get_main_loop().process_frame  # chờ bố cục xong
	_check(scene, controller, initial_total, "seed %d: sau khi bắt đầu" % seed_value)
	for step in STEPS_PER_SEED:
		if controller.state.is_terminal():
			extra += 1
			if extra > EXTRA_STEPS_AFTER_END:
				break
		_log = "seed %d bước %d: %s" % [seed_value, step, _random_action(scene, controller, rng)]
		_stats["targeting"] += 1 if scene.intent.is_targeting() else 0
		_stats["rejected"] += 1 if not scene.message_label.text.is_empty() and scene.message_label.text != RejectionText.CHOOSE_TARGET else 0
		_check(scene, controller, initial_total, _log)
	scene.free()


## Thực hiện một thao tác ngẫu nhiên qua giao diện; trả mô tả để ghi log.
func _random_action(scene: BattleScene, controller: BattleController, rng: RandomNumberGenerator) -> String:
	var roll := rng.randi_range(0, 99)
	var hand := controller.deck.get_pile(Deck.HAND)
	if roll < CARD_CLICK_PERCENT and not hand.is_empty():
		var card := hand[rng.randi_range(0, hand.size() - 1)]
		scene.hand_ui.card_clicked.emit(card)
		return "bấm thẻ %s" % card.data.id
	if roll < DRAG_PERCENT and not hand.is_empty():
		return _random_drag(scene, hand[rng.randi_range(0, hand.size() - 1)], rng)
	if roll < ENEMY_CLICK_PERCENT:
		var index := rng.randi_range(0, scene.enemy_uis.size() - 1)
		scene.enemy_uis[index].clicked.emit(scene.enemy_uis[index].unit)
		return "bấm quái %d" % index
	if roll < END_TURN_PERCENT:
		scene.end_turn_button.pressed.emit()
		return "End Turn"
	if roll < CANCEL_PERCENT:
		scene.cancel_targeting()
		return "huỷ chọn"
	if roll < STALE_CARD_PERCENT:
		var spent := controller.deck.get_pile(Deck.DISCARD)
		if not spent.is_empty():
			scene._on_card_clicked(spent[0])
			return "bấm thẻ đã bỏ %s" % spent[0].data.id
		return "không làm gì"
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_input(escape)
	return "Esc"


## Kéo một thẻ bằng chuỗi sự kiện chuột giả: bấm, đi ra xa, (đi qua một điểm), rồi nhả / Esc / chuột phải.
func _random_drag(scene: BattleScene, card: CardInstance, rng: RandomNumberGenerator) -> String:
	var card_ui: CardUI = null
	for candidate in scene.hand_ui.card_uis:
		if candidate.view.uid == card.uid:
			card_ui = candidate
	if card_ui == null:
		return "kéo thẻ %s (không có UI)" % card.data.id
	var origin := card_ui.get_global_rect().get_center()
	card_ui._gui_input(UiInput.press(origin))
	card_ui._gui_input(UiInput.motion(origin + Vector2(0, -60)))
	if scene.is_dragging():
		_stats["drags"] += 1
	var end := _random_point(scene, rng)
	card_ui._gui_input(UiInput.motion(_random_point(scene, rng)))
	card_ui._gui_input(UiInput.motion(end))
	var how := rng.randi_range(0, 99)
	if how < DRAG_DROP_PERCENT:
		card_ui._gui_input(UiInput.release(end))
		return "kéo thẻ %s rồi nhả ở %s" % [card.data.id, end]
	if how < DRAG_ESCAPE_PERCENT:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		scene._unhandled_input(escape)
		card_ui._gui_input(UiInput.release(end))
		return "kéo thẻ %s rồi Esc" % card.data.id
	card_ui._gui_input(UiInput.press(end, MOUSE_BUTTON_RIGHT))
	card_ui._gui_input(UiInput.release(end))
	return "kéo thẻ %s rồi chuột phải" % card.data.id


## Điểm ngẫu nhiên: trên một quái (kể cả đã chết), trong vùng thả, hoặc dưới vùng thả (khu tay bài).
func _random_point(scene: BattleScene, rng: RandomNumberGenerator) -> Vector2:
	var pick := rng.randi_range(0, 2)
	if pick == 0 and not scene.enemy_uis.is_empty():
		return scene.enemy_uis[rng.randi_range(0, scene.enemy_uis.size() - 1)].get_global_rect().get_center()
	if pick == 1:
		return Vector2(rng.randf_range(ZONE_X_RANGE.x, ZONE_X_RANGE.y), rng.randf_range(ZONE_Y_RANGE.x, ZONE_Y_RANGE.y))
	return Vector2(rng.randf_range(ZONE_X_RANGE.x, ZONE_X_RANGE.y), rng.randf_range(BELOW_ZONE_Y_RANGE.x, BELOW_ZONE_Y_RANGE.y))


func _check(scene: BattleScene, controller: BattleController, initial_total: int, label: String) -> void:
	scene.hand_ui.flush_pending_refresh()
	var player := controller.player
	assert_eq(scene.energy_ui.label.text, "%d/%d" % [controller.energy, controller.config.max_energy], label + " | năng lượng")
	assert_true(controller.energy >= 0, label + " | năng lượng âm")
	assert_eq(scene.turn_label.text, "Turn %d" % controller.turn, label + " | nhãn lượt")
	assert_eq(scene.end_turn_button.disabled, not controller.state.is_player_turn(), label + " | nút End Turn")
	assert_eq(scene.result_overlay.visible, controller.state.is_terminal(), label + " | lớp phủ kết quả")
	assert_eq(scene.hero_ui.health_bar.hp_label.text, "%d/%d" % [player.hp, player.max_hp], label + " | máu người chơi")
	assert_eq(scene.hero_ui.health_bar.block_box.visible, player.block > 0, label + " | giáp người chơi")
	assert_eq(controller.deck.total_count(), initial_total, label + " | tổng số thẻ phải giữ nguyên")
	assert_true(controller.deck.count(Deck.HAND) <= Deck.MAX_HAND_SIZE, label + " | tay quá 10 thẻ")
	_check_no_stuck_drag(scene, label)
	_check_piles(scene, controller, label)
	_check_hand(scene, controller, label)
	_check_enemies(scene, controller, label)
	_check_targeting(scene, controller, label)


func _check_piles(scene: BattleScene, controller: BattleController, label: String) -> void:
	assert_eq(scene.draw_counter.count_label.text, str(controller.deck.count(Deck.DRAW)), label + " | pile rút")
	assert_eq(scene.discard_counter.count_label.text, str(controller.deck.count(Deck.DISCARD)), label + " | pile bỏ")
	assert_eq(scene.exhaust_counter.count_label.text, str(controller.deck.count(Deck.EXHAUST)), label + " | pile exhaust")


func _check_hand(scene: BattleScene, controller: BattleController, label: String) -> void:
	var hand := controller.deck.get_pile(Deck.HAND)
	assert_eq(scene.hand_ui.card_uis.size(), hand.size(), label + " | số thẻ trên tay")
	for i in mini(hand.size(), scene.hand_ui.card_uis.size()):
		var card_ui := scene.hand_ui.card_uis[i]
		assert_eq(card_ui.view.uid, hand[i].uid, label + " | thứ tự thẻ %d" % i)
		var dimmed := card_ui.modulate.a < 1.0
		assert_eq(dimmed, not controller.can_play(hand[i]), label + " | thẻ mờ <-> không chơi được (%s)" % hand[i].data.id)


func _check_enemies(scene: BattleScene, controller: BattleController, label: String) -> void:
	assert_eq(scene.enemy_uis.size(), controller.enemies.size(), label + " | số quái")
	for enemy_ui in scene.enemy_uis:
		var unit := enemy_ui.unit
		assert_eq(enemy_ui.combatant_ui.health_bar.hp_label.text, "%d/%d" % [unit.combatant.hp, unit.combatant.max_hp],
				label + " | máu %s" % unit.data.id)
		assert_eq(enemy_ui.combatant_ui.health_bar.block_box.visible, unit.combatant.block > 0, label + " | giáp %s" % unit.data.id)
		if unit.is_alive():
			assert_eq(enemy_ui.intent_label.text, IntentView.build(unit.intent).text, label + " | ý định %s" % unit.data.id)
			assert_eq(enemy_ui.intent_row.get_child_count(), IntentView.build(unit.intent).icon_ids.size() + 1,
					label + " | số icon ý định %s" % unit.data.id)
			assert_almost_eq(enemy_ui.intent_row.modulate.a, 1.0, 0.0001, label + " | ý định hiện %s" % unit.data.id)
		else:
			assert_almost_eq(enemy_ui.intent_row.modulate.a, 0.0, 0.0001, label + " | quái chết ẩn ý định %s" % unit.data.id)


func _check_targeting(scene: BattleScene, controller: BattleController, label: String) -> void:
	var highlighted: Array[int] = []
	for card_ui in scene.hand_ui.card_uis:
		if card_ui.highlighted:
			highlighted.append(card_ui.view.uid)
	if scene.intent.is_targeting():
		var selected := scene.intent.selected
		assert_true(controller.deck.get_pile(Deck.HAND).has(selected), label + " | thẻ đang chọn phải còn trong tay")
		assert_true(controller.can_play(selected), label + " | thẻ đang chọn phải còn chơi được")
		assert_eq(highlighted, [selected.uid] as Array[int], label + " | chỉ thẻ đang chọn được tô sáng")
		var valid := controller.valid_targets(selected)
		for enemy_ui in scene.enemy_uis:
			assert_eq(enemy_ui.art_rect.color == EnemyUI.ART_TARGETABLE_COLOR, valid.has(enemy_ui.unit),
					label + " | tô nổi mục tiêu hợp lệ")
	else:
		assert_eq(highlighted.size(), 0, label + " | không chọn thì không thẻ nào sáng")
		for enemy_ui in scene.enemy_uis:
			assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_COLOR, label + " | không chọn thì không quái nào nổi")


## Sau MỖI thao tác không được còn dấu vết kéo thả nào (mũi tên, vùng thả, thẻ bám con trỏ, viền sáng do kéo).
func _check_no_stuck_drag(scene: BattleScene, label: String) -> void:
	assert_false(scene.is_dragging(), label + " | cảnh còn trạng thái kéo")
	assert_false(scene.hand_ui.is_dragging(), label + " | tay bài còn trạng thái kéo")
	assert_false(scene.target_arrow.visible, label + " | mũi tên còn hiện")
	assert_false(scene.play_zone.visible, label + " | vùng thả còn hiện")
