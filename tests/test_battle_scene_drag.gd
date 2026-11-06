extends "res://tests/test_case.gd"
## Kéo thả thẻ qua BattleScene thật (chuỗi sự kiện chuột giả lên CardUI): chơi, huỷ, vùng thả, mũi tên, xem trước.

const Factory := preload("res://tests/combat_factory.gd")
const UiInput := preload("res://tests/ui_input.gd")

var _scene: BattleScene = null


func after_each() -> void:
	if _scene != null:
		_scene.free()
		_scene = null


func _controller(enemy_count: int = 2, enemy_hp: int = 40) -> BattleController:
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(&"dummy", enemy_hp, 6))
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


## Cảnh nằm trong cây scene và đã bố cục xong (cần để biết toạ độ thật của thẻ/quái).
func _scene_in_tree(controller: BattleController) -> BattleScene:
	_scene = BattleScene.new()
	Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(controller)
	await Engine.get_main_loop().process_frame
	_scene.hand_ui.flush_pending_refresh()
	return _scene


func _card_ui(scene: BattleScene, card: CardInstance) -> CardUI:
	for card_ui in scene.hand_ui.card_uis:
		if card_ui.view.uid == card.uid:
			return card_ui
	return null


func _enemy_center(scene: BattleScene, index: int) -> Vector2:
	return scene.enemy_uis[index].get_global_rect().get_center()


func _start_drag(scene: BattleScene, card: CardInstance, far_enough: Vector2 = Vector2(0, -80)) -> CardUI:
	var card_ui := _card_ui(scene, card)
	var origin := card_ui.get_global_rect().get_center()
	card_ui._gui_input(UiInput.press(origin))
	card_ui._gui_input(UiInput.motion(origin + far_enough))
	return card_ui


func _drag_to(card_ui: CardUI, point: Vector2) -> void:
	card_ui._gui_input(UiInput.motion(point))


func _drop(card_ui: CardUI, point: Vector2) -> void:
	card_ui._gui_input(UiInput.release(point))


func _assert_drag_state_is_clean(scene: BattleScene, label: String) -> void:
	assert_false(scene.is_dragging(), label + " | còn trạng thái kéo")
	assert_false(scene.hand_ui.is_dragging(), label + " | tay bài còn trạng thái kéo")
	assert_false(scene.target_arrow.visible, label + " | mũi tên còn hiện")
	assert_false(scene.play_zone.visible, label + " | vùng thả còn hiện")
	for enemy_ui in scene.enemy_uis:
		assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_COLOR, label + " | quái còn nổi bật")
	for card_ui in scene.hand_ui.card_uis:
		assert_false(card_ui.highlighted, label + " | thẻ còn sáng viền")


## --- Thẻ nhắm một quái ---

func test_dragging_an_attack_onto_an_enemy_plays_it_on_that_enemy() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	assert_true(scene.is_dragging())
	assert_true(scene.target_arrow.visible)
	assert_true(card_ui.highlighted, "thẻ đang kéo sáng viền")
	for enemy_ui in scene.enemy_uis:
		assert_eq(enemy_ui.art_rect.color, EnemyUI.ART_TARGETABLE_COLOR, "mọi quái hợp lệ được tô nổi")
	var target := _enemy_center(scene, 1)
	_drag_to(card_ui, target)
	assert_true(scene.target_arrow.on_valid_target)
	_drop(card_ui, target)
	assert_eq(controller.enemies[1].combatant.hp, 34)
	assert_eq(controller.enemies[0].combatant.hp, 40)
	assert_eq(controller.energy, 2)
	scene.hand_ui.flush_pending_refresh()
	_assert_drag_state_is_clean(scene, "sau khi chơi")


func test_dropping_an_attack_on_empty_space_cancels_without_cost() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var hand_before := controller.deck.count(Deck.HAND)
	var card_ui := _start_drag(scene, card)
	_drag_to(card_ui, Vector2(1600, 350))
	assert_false(scene.target_arrow.on_valid_target, "chưa trúng quái thì mũi tên chưa đỏ")
	_drop(card_ui, Vector2(1600, 350))
	assert_eq(controller.energy, 3)
	assert_eq(controller.deck.count(Deck.HAND), hand_before)
	assert_eq(controller.enemies[0].combatant.hp, 40)
	assert_eq(controller.enemies[1].combatant.hp, 40)
	_assert_drag_state_is_clean(scene, "sau khi huỷ")
	assert_eq(scene.message_label.text, "")


func test_arrow_color_follows_whether_the_pointer_is_over_a_valid_enemy() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	_drag_to(card_ui, _enemy_center(scene, 0))
	assert_eq(scene.target_arrow.current_color(), TargetArrowUI.VALID_COLOR)
	_drag_to(card_ui, Vector2(1600, 350))
	assert_eq(scene.target_arrow.current_color(), TargetArrowUI.NEUTRAL_COLOR)
	card_ui.cancel_drag()


func test_the_arrow_starts_at_the_dragged_card() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	var pointer := _enemy_center(scene, 0)
	_drag_to(card_ui, pointer)
	var expected := ArrowGeometry.build(scene.hand_ui.card_anchor(card), pointer)
	assert_eq(scene.target_arrow.shape.head, expected.head)
	card_ui.cancel_drag()


func test_hovering_a_vulnerable_enemy_previews_the_boosted_number_and_clears_after() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var ids: Array[StringName] = [&"strike"]
	var strike := CardRegistry.load_from_dir("res://data/cards").create_instances(ids)[0]
	controller.deck.add_to_hand(strike)
	controller.enemies[0].combatant.add_status(StatusRegistry.load_from_dir("res://data/statuses").get_status(&"vulnerable"), 1)
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, strike)
	assert_true(card_ui.description_label.text.contains("6"))
	_drag_to(card_ui, _enemy_center(scene, 0))
	assert_true(card_ui.description_label.text.contains("9"), "6 x 1.5 Vulnerable")
	_drag_to(card_ui, _enemy_center(scene, 1))
	assert_true(card_ui.description_label.text.contains("6"), "quái không Vulnerable: số thường")
	_drag_to(card_ui, _enemy_center(scene, 0))
	card_ui.cancel_drag()
	var restored := _card_ui(scene, strike)
	assert_false(restored.description_label.text.contains("9"), "huỷ kéo thì xem trước được xoá")


func test_a_dead_enemy_is_not_a_drop_target() -> void:
	var controller := _controller(3)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var dead_spot := _enemy_center(scene, 0)
	controller.enemies[0].combatant.take_damage(999)
	var card_ui := _start_drag(scene, card)
	_drag_to(card_ui, dead_spot)
	assert_false(scene.target_arrow.on_valid_target)
	_drop(card_ui, dead_spot)
	assert_eq(controller.energy, 3, "thả lên quái đã chết không chơi thẻ")
	_assert_drag_state_is_clean(scene, "sau khi thả lên quái chết")


func test_with_a_single_living_enemy_dropping_inside_the_zone_targets_it() -> void:
	var controller := _controller(1)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	_drop(card_ui, Vector2(300, 300))
	assert_eq(controller.enemies[0].combatant.hp, 34)
	var card2 := Factory.inject(controller, Factory.strike(&"second"))
	scene.hand_ui.flush_pending_refresh()
	var card_ui2 := _start_drag(scene, card2)
	_drop(card_ui2, Vector2(300, 900))
	assert_eq(controller.enemies[0].combatant.hp, 34, "ngoài vùng thả thì không tự nhắm")


## --- Thẻ không nhắm ---

func test_dragging_a_skill_into_the_zone_plays_it() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.defend())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	assert_true(scene.play_zone.visible, "kéo thẻ không nhắm thì hiện vùng thả")
	assert_false(scene.target_arrow.visible, "và không có mũi tên")
	var inside := Vector2(960, 250)
	_drag_to(card_ui, inside)
	assert_true(scene.play_zone.active, "con trỏ trong vùng thả thì vùng sáng")
	assert_almost_eq(card_ui.get_global_rect().get_center().distance_to(inside), 0.0, 1.0, "thẻ bám theo con trỏ")
	_drop(card_ui, inside)
	assert_eq(controller.player.block, 5)
	assert_eq(controller.energy, 2)
	scene.hand_ui.flush_pending_refresh()
	_assert_drag_state_is_clean(scene, "sau khi chơi kỹ năng")


func test_dropping_a_skill_outside_the_zone_cancels() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.defend())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	_drag_to(card_ui, Vector2(960, 900))
	assert_false(scene.play_zone.active, "con trỏ ngoài vùng thả thì vùng không sáng")
	_drop(card_ui, Vector2(960, 900))
	assert_eq(controller.player.block, 0)
	assert_eq(controller.energy, 3)
	_assert_drag_state_is_clean(scene, "sau khi thả ngoài vùng")


func test_dropping_a_skill_on_top_of_an_enemy_inside_the_zone_still_plays_it() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.defend())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	var over_enemy := _enemy_center(scene, 0)
	_drag_to(card_ui, over_enemy)
	_drop(card_ui, over_enemy)
	assert_eq(controller.player.block, 5, "thẻ không nhắm không bị quái chặn")
	assert_eq(controller.enemies[0].combatant.hp, 40)


func test_an_all_enemies_card_plays_from_the_zone() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var effects: Array[EffectData] = [Factory.damage_effect(5, EffectData.Target.ALL_ENEMIES)]
	var card := Factory.inject(controller, Factory.card_inst(&"aoe", effects, CardData.TargetMode.ALL_ENEMIES))
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	_drop(card_ui, Vector2(960, 250))
	assert_eq(controller.enemies[0].combatant.hp, 35)
	assert_eq(controller.enemies[1].combatant.hp, 35)


## --- Không thể kéo / huỷ ---

func test_an_unaffordable_card_cannot_be_dragged() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike(&"big", 6, {"cost": 9}))
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	assert_eq(scene.message_label.text, "Not enough energy")
	assert_false(scene.is_dragging())
	_assert_drag_state_is_clean(scene, "thẻ không đủ năng lượng")
	_drop(card_ui, _enemy_center(scene, 0))
	assert_eq(controller.energy, 3)
	assert_eq(controller.enemies[0].combatant.hp, 40)


func test_escape_cancels_a_drag_and_the_following_release_does_nothing() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_input(escape)
	_assert_drag_state_is_clean(scene, "sau Esc")
	_drop(card_ui, _enemy_center(scene, 0))
	assert_eq(controller.energy, 3)
	assert_eq(controller.enemies[0].combatant.hp, 40)


func test_right_click_cancels_a_drag() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.defend())
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	card_ui._gui_input(UiInput.press(Vector2(960, 250), MOUSE_BUTTON_RIGHT))
	_assert_drag_state_is_clean(scene, "sau chuột phải")
	_drop(card_ui, Vector2(960, 250))
	assert_eq(controller.player.block, 0)


func test_tearing_down_in_the_middle_of_a_drag_cleans_up() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	_start_drag(scene, card)
	assert_true(scene.is_dragging())
	scene.teardown()
	_assert_drag_state_is_clean(scene, "sau teardown")


func test_a_rebuild_of_the_hand_during_a_drag_cancels_it_cleanly() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike())
	scene.hand_ui.flush_pending_refresh()
	_start_drag(scene, card)
	scene.hand_ui.refresh()
	_assert_drag_state_is_clean(scene, "sau khi tay bài dựng lại")


## --- Click vẫn hoạt động ---

func test_a_plain_click_still_selects_a_card_and_a_drag_discards_that_selection() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var first := Factory.inject(controller, Factory.strike(&"first"))
	var second := Factory.inject(controller, Factory.defend())
	scene.hand_ui.flush_pending_refresh()
	var first_ui := _card_ui(scene, first)
	var center := first_ui.get_global_rect().get_center()
	first_ui._gui_input(UiInput.press(center))
	first_ui._gui_input(UiInput.release(center))
	assert_true(scene.intent.is_targeting(), "bấm-nhả tại chỗ vẫn là click")
	assert_eq(scene.message_label.text, RejectionText.CHOOSE_TARGET)
	var second_ui := _start_drag(scene, second)
	assert_false(scene.intent.is_targeting(), "bắt đầu kéo thẻ khác thì bỏ lựa chọn bằng click")
	second_ui.cancel_drag()


func test_repeated_drags_do_not_leak_nodes() -> void:
	var controller := _controller(2)
	var scene := await _scene_in_tree(controller)
	var card := Factory.inject(controller, Factory.strike(&"cycle", 6, {"cost": 0}))
	scene.hand_ui.flush_pending_refresh()
	var card_ui := _start_drag(scene, card)
	_drag_to(card_ui, _enemy_center(scene, 0))
	_drop(card_ui, Vector2(1600, 350))
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 5:
		scene.hand_ui.flush_pending_refresh()
		card_ui = _start_drag(scene, card)
		_drag_to(card_ui, _enemy_center(scene, 0))
		_drop(card_ui, Vector2(1600, 350))
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)
