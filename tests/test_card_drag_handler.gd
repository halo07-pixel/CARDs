extends "res://tests/test_case.gd"
## CardDragHandler: máy trạng thái kéo thả thẻ (kiểm riêng, không qua BattleScene): bắt đầu, bám con trỏ, thả, huỷ, dọn.

var _controller: BattleController
var _hand_ui: HandUI
var _play_zone: PlayZoneUI
var _arrow: TargetArrowUI
var _enemy_uis: Array[EnemyUI] = []
var _handler: CardDragHandler
var _log: Array = []
var _decisions: Array = []
var _nodes: Array[Node] = []
var _hand_dragging_when_started := false


func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes = []
	_enemy_uis = []


func _add(node: Node) -> Node:
	Engine.get_main_loop().root.add_child(node)
	_nodes.append(node)
	return node


## Trận thật của Warrior (tay có Strike, Bash, Defend) với 3 quái đã bố cục để có toạ độ thật.
func _build(bind_controller: bool = true) -> void:
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemies: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
	_controller = BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemies, GameData.load_default(), 5)
	_controller.start_battle()
	_hand_ui = _add(HandUI.new())
	_hand_ui.bind(_controller)
	_play_zone = _add(PlayZoneUI.new())
	_arrow = _add(TargetArrowUI.new())
	for i in _controller.enemies.size():
		var enemy_ui := _add(EnemyUI.new())
		enemy_ui.bind(_controller.enemies[i])
		enemy_ui.position = Vector2(300 + 320 * i, 80)
		_enemy_uis.append(enemy_ui)
	await Engine.get_main_loop().process_frame
	_hand_ui.flush_pending_refresh()
	_handler = CardDragHandler.new(_hand_ui, _play_zone, _arrow, _enemy_uis)
	_log = []
	_decisions = []
	_handler.started.connect(func(_c: CardInstance) -> void:
		_hand_dragging_when_started = _hand_ui.is_dragging()
		_log.append("started"))
	_handler.rejected.connect(func(_c: CardInstance, reason: StringName) -> void: _log.append("rejected:%s" % reason))
	_handler.dropped.connect(func(decision: PlayIntent.Decision) -> void:
		_log.append("dropped")
		_decisions.append(decision))
	_handler.finished.connect(func() -> void: _log.append("finished"))
	if bind_controller:
		_handler.bind(_controller)


func _card(card_id: StringName) -> CardInstance:
	for card in _controller.deck.get_pile(Deck.HAND):
		if card.data.id == card_id:
			return card
	return null


func _over_enemy(index: int) -> Vector2:
	return _enemy_uis[index].get_global_rect().get_center()


## Trong vùng thả (60% phía trên màn hình) nhưng không đè lên quái nào.
func _in_zone() -> Vector2:
	return Vector2(1500, 300)


## Ngoài vùng thả (khu vực tay bài) và không đè lên quái nào.
const OUTSIDE := Vector2(960, 1000)


## --- start ---

func test_starting_a_targeted_card_shows_the_arrow_and_marks_the_valid_enemies() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, _over_enemy(1))
	assert_true(_handler.is_dragging())
	assert_true(_arrow.visible)
	assert_false(_play_zone.visible, "thẻ nhắm không dùng vùng thả")
	assert_true(_hand_ui.is_dragging())
	for enemy_ui in _enemy_uis:
		assert_true(enemy_ui.art_rect.color == EnemyUI.ART_TARGETABLE_COLOR, "mọi quái sống đều là mục tiêu")
	assert_eq(_log, ["started"])


func test_starting_a_non_targeted_card_shows_the_play_zone_and_no_arrow() -> void:
	await _build()
	_handler.start(_card(&"defend"), _in_zone())
	assert_true(_handler.is_dragging())
	assert_true(_play_zone.visible)
	assert_true(_play_zone.active, "con trỏ đang ở trong vùng thả")
	assert_false(_arrow.visible)


func test_started_is_announced_before_anything_is_built() -> void:
	await _build()
	_handler.start(_card(&"strike"), OUTSIDE)
	assert_false(_hand_dragging_when_started, "bên nghe còn dọn được lựa chọn cũ trước khi dựng gì")


func test_an_unaffordable_card_is_rejected_and_nothing_starts() -> void:
	await _build()
	var bash := _card(&"bash")  # tốn 2 năng lượng
	for card in _controller.deck.get_pile(Deck.HAND):
		if _controller.energy <= 1:
			break
		if card.data.id == &"strike":
			_controller.play_card(card, _controller.enemies[0])
	assert_eq(_controller.energy, 1)
	_hand_ui.flush_pending_refresh()
	_log = []
	_handler.start(bash, OUTSIDE)
	assert_false(_handler.is_dragging())
	assert_false(_hand_ui.is_dragging())
	assert_false(_arrow.visible)
	assert_eq(_log, ["rejected:%s" % BattleController.REASON_NOT_ENOUGH_ENERGY], "không có started")


func test_starting_without_a_bound_battle_does_nothing() -> void:
	await _build(false)
	_handler.start(_card(&"strike"), _over_enemy(0))
	assert_false(_handler.is_dragging())
	assert_eq(_log, [])
	assert_false(_arrow.visible)


## --- move ---

func test_the_arrow_turns_valid_only_while_over_a_valid_enemy() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, OUTSIDE)
	assert_false(_arrow.on_valid_target)
	_handler.move(strike, _over_enemy(2))
	assert_true(_arrow.on_valid_target)
	_handler.move(strike, OUTSIDE)
	assert_false(_arrow.on_valid_target)


func test_moving_a_different_card_is_ignored() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, OUTSIDE)
	_handler.move(_card(&"defend"), _over_enemy(0))
	assert_false(_arrow.on_valid_target)


func test_the_zone_follows_the_pointer_for_non_targeted_cards() -> void:
	await _build()
	var defend := _card(&"defend")
	_handler.start(defend, OUTSIDE)
	assert_false(_play_zone.active)
	_handler.move(defend, _in_zone())
	assert_true(_play_zone.active)
	_handler.move(defend, OUTSIDE)
	assert_false(_play_zone.active)


func test_moving_with_no_drag_in_progress_does_nothing() -> void:
	await _build()
	_handler.move(_card(&"strike"), _over_enemy(0))
	assert_false(_arrow.visible)


## --- end ---

func test_dropping_on_an_enemy_plays_the_card_on_it_and_cleans_up_before_dropped() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, OUTSIDE)
	_log = []
	_handler.end(strike, _over_enemy(1))
	assert_eq(_log, ["finished", "dropped"], "dọn xong rồi mới thực thi")
	assert_eq(_decisions[0].outcome, PlayIntent.Outcome.PLAY_NOW)
	assert_true(_decisions[0].target == _controller.enemies[1])
	assert_false(_handler.is_dragging())
	assert_false(_arrow.visible)
	assert_false(_play_zone.visible)
	assert_false(_hand_ui.is_dragging())


func test_dropping_outside_cancels() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, OUTSIDE)
	_handler.end(strike, OUTSIDE)
	assert_eq(_decisions[0].outcome, PlayIntent.Outcome.CANCELLED)


func test_dropping_a_non_targeted_card_in_the_zone_plays_it_and_outside_cancels() -> void:
	await _build()
	var defend := _card(&"defend")
	_handler.start(defend, OUTSIDE)
	_handler.end(defend, _in_zone())
	assert_eq(_decisions[0].outcome, PlayIntent.Outcome.PLAY_NOW)
	_handler.start(defend, OUTSIDE)
	_handler.end(defend, OUTSIDE)
	assert_eq(_decisions[1].outcome, PlayIntent.Outcome.CANCELLED)


func test_the_decision_always_matches_drop_intent_for_every_card_and_place() -> void:
	await _build()
	var places := [OUTSIDE, _in_zone(), _over_enemy(0), _over_enemy(1), _over_enemy(2)]
	for card in _controller.deck.get_pile(Deck.HAND):
		for place: Vector2 in places:
			_handler.start(card, OUTSIDE)
			var unit := EnemyHitTest.unit_at(place, _enemy_uis)
			var expected := DropIntent.decide(card, unit, DropIntent.is_in_play_zone(place, DropIntent.DESIGN_SCREEN), _controller)
			_handler.end(card, place)
			var got: PlayIntent.Decision = _decisions.back()
			assert_eq(got.outcome, expected.outcome, "%s tại %s" % [card.data.id, place])
			assert_true(got.target == expected.target, "mục tiêu %s tại %s" % [card.data.id, place])


func test_ending_the_wrong_card_or_without_a_drag_does_nothing() -> void:
	await _build()
	_handler.end(_card(&"strike"), _over_enemy(0))
	assert_eq(_log, [])
	var strike := _card(&"strike")
	_handler.start(strike, OUTSIDE)
	_log = []
	_handler.end(_card(&"defend"), _over_enemy(0))
	assert_eq(_log, [])
	assert_true(_handler.is_dragging(), "vẫn đang kéo thẻ cũ")


## --- cancel / finish / unbind ---

func test_cancelling_cleans_up_without_dropping() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, _over_enemy(0))
	_log = []
	_handler.cancel(strike)
	assert_eq(_log, ["finished"])
	assert_false(_handler.is_dragging())
	assert_false(_arrow.visible)
	assert_false(_hand_ui.is_dragging())


func test_cancelling_a_different_card_does_nothing() -> void:
	await _build()
	_handler.start(_card(&"strike"), OUTSIDE)
	_log = []
	_handler.cancel(_card(&"defend"))
	assert_eq(_log, [])
	assert_true(_handler.is_dragging())


func test_finish_is_safe_when_idle_and_repeatable() -> void:
	await _build()
	_handler.finish()
	_handler.finish()
	assert_eq(_log, ["finished", "finished"])
	assert_false(_handler.is_dragging())


func test_unbind_cleans_an_active_drag_and_later_starts_do_nothing() -> void:
	await _build()
	_handler.start(_card(&"defend"), _in_zone())
	_log = []
	_handler.unbind()
	assert_false(_handler.is_dragging())
	assert_false(_play_zone.visible)
	assert_eq(_log, ["finished"])
	_log = []
	_handler.start(_card(&"strike"), OUTSIDE)
	assert_eq(_log, [], "đã gỡ khỏi trận")
	_handler.unbind()  # lần hai an toàn


func test_rebinding_works_after_unbind() -> void:
	await _build()
	_handler.unbind()
	_handler.bind(_controller)
	_handler.start(_card(&"strike"), OUTSIDE)
	assert_true(_handler.is_dragging())


func test_a_second_drag_after_a_finished_one_starts_clean() -> void:
	await _build()
	var strike := _card(&"strike")
	_handler.start(strike, _over_enemy(0))
	_handler.end(strike, _over_enemy(0))
	_handler.start(strike, OUTSIDE)
	assert_true(_handler.is_dragging())
	assert_false(_arrow.on_valid_target, "không còn dấu vết mục tiêu cũ")


func _card_text(card: CardInstance) -> String:
	for card_ui in _hand_ui.card_uis:
		if card_ui.view.uid == card.uid:
			return card_ui.view.description
	return ""


func test_the_damage_preview_follows_the_enemy_under_the_pointer_and_resets_between_drags() -> void:
	await _build()
	var statuses := StatusRegistry.load_from_dir("res://data/statuses")
	_controller.enemies[1].combatant.add_status(statuses.get_status(&"vulnerable"), 2)  # đòn vào quái này mạnh hơn
	var strike := _card(&"strike")
	var base_text := _card_text(strike)
	_handler.start(strike, OUTSIDE)
	assert_eq(_card_text(strike), base_text, "chưa trỏ quái nào: số gốc")
	_handler.move(strike, _over_enemy(1))
	var preview_text := _card_text(strike)
	assert_ne(preview_text, base_text, "trỏ quái đang Vulnerable: số xem trước đổi")
	_handler.cancel(strike)
	_hand_ui.flush_pending_refresh()
	assert_eq(_card_text(strike), base_text, "kéo xong: về số gốc")
	_handler.start(strike, _over_enemy(1))  # kéo lại, vẫn trỏ đúng quái đó: phải xem trước lại
	assert_eq(_card_text(strike), preview_text, "không còn dấu vết xem trước của lần kéo cũ")


func test_a_non_targeted_card_follows_the_pointer_but_a_targeted_one_stays_in_the_hand() -> void:
	await _build()
	var defend := _card(&"defend")
	_handler.start(defend, OUTSIDE)
	var before := _hand_ui.card_anchor(defend)
	_handler.move(defend, _in_zone())
	assert_ne(_hand_ui.card_anchor(defend), before, "thẻ thường bám theo con trỏ")
	_handler.cancel(defend)
	var strike := _card(&"strike")
	_handler.start(strike, OUTSIDE)
	var strike_before := _hand_ui.card_anchor(strike)
	_handler.move(strike, _over_enemy(0))
	assert_eq(_hand_ui.card_anchor(strike), strike_before, "thẻ nhắm đứng yên, chỉ có mũi tên chạy")
