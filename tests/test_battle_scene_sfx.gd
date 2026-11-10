extends "res://tests/test_case.gd"
## BattleScene phát âm thanh qua EventBus.sfx_requested (UI không biết gì về AudioManager). Âm thanh KHÔNG phụ thuộc
## hiệu ứng hình: tắt hay bật hiệu ứng, cùng thao tác thì cùng danh sách âm thanh.

const Hud := preload("res://tests/hud_factory.gd")
const Factory := preload("res://tests/combat_factory.gd")
const CardFactory := preload("res://tests/card_factory.gd")

var _scene: BattleScene = null
var _heard: Array = []
var _listener: Callable


func before_each() -> void:
	_heard = []
	_listener = func(sfx_name: StringName) -> void: _heard.append(String(sfx_name))
	EventBus.sfx_requested.connect(_listener)


func after_each() -> void:
	EventBus.sfx_requested.disconnect(_listener)
	if _scene != null:
		_scene.free()
		_scene = null


func _scene_for(controller: BattleController, speed: float = 0.0, in_tree: bool = true) -> BattleScene:
	_scene = BattleScene.new()
	_scene.effects.speed = speed
	if in_tree:
		Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(controller)
	_heard = []  # bỏ qua tiếng lúc dựng
	return _scene


func _warrior_battle(enemy_ids: Array, potion_ids: Array = []) -> BattleController:
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var enemies: Array[StringName] = []
	enemies.assign(enemy_ids)
	var potions: Array[StringName] = []
	potions.assign(potion_ids)
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, enemies, GameData.load_default(), 5,
			[] as Array[StringName], potions)
	controller.start_battle()
	return controller


func _hand_card(controller: BattleController, card_id: StringName) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if card.data.id == card_id:
			return card
	return null


func _finish_enemy_turn(scene: BattleScene) -> void:
	for i in 40:
		if not scene.enemy_turn_player.is_playing():
			return
		scene.enemy_turn_player.fire_now()


## --- Chơi thẻ, dùng potion ---

func test_an_attack_card_plays_card_then_hit() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	assert_eq(_heard, ["card_play", "hit"])


func test_a_block_card_plays_card_then_block_gain() -> void:
	var controller := _warrior_battle([&"slime"])
	var scene := _scene_for(controller)
	scene.hand_ui.card_clicked.emit(_hand_card(controller, &"defend"))
	assert_eq(_heard, ["card_play", "block_gain"])


func test_a_card_with_only_silent_effects_makes_just_the_card_sound() -> void:
	var cards: Array[CardInstance] = []
	for i in 10:
		var draw: Array[EffectData] = [EffectData.create(EffectData.Type.DRAW, 2, EffectData.Target.SELF)]
		cards.append(CardFactory.instance(&"drawer", {"effects": draw, "target_mode": CardData.TargetMode.SELF, "cost": 0}))
	var controller := BattleController.create_from_data(Factory.combatant(&"player", 80), cards,
			[Factory.dummy_enemy(&"dummy", 40, 6)] as Array[EnemyData], Factory.registry(), 1)
	controller.start_battle()
	var scene := _scene_for(controller)
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	assert_eq(_heard, ["card_play"], "rút bài im lặng có chủ ý")


func test_potions_play_potion_then_their_effect_sound() -> void:
	for case: Array in [[&"block_potion", "block_gain"], [&"weak_potion", "status"], [&"fire_potion", "hit"]]:
		var controller := Hud.controller([case[0]], [], 1)
		var scene := _scene_for(controller)
		scene.potion_belt_ui.slot_uis[0].pressed.emit()
		assert_eq(_heard, ["potion", case[1]], "potion %s" % case[0])
		scene.free()
		_scene = null


## --- Lượt quái ---

func test_end_turn_then_each_enemy_hit_with_effects_off() -> void:
	var controller := Hud.controller([], [], 2)
	var scene := _scene_for(controller, 0.0)
	scene.end_turn_button.pressed.emit()
	assert_eq(_heard, ["end_turn", "hit", "hit"])


func test_the_same_sounds_come_one_enemy_at_a_time_with_effects_on() -> void:
	var controller := Hud.controller([], [], 2)
	var scene := _scene_for(controller, EffectsConfig.NORMAL_SPEED)
	scene.end_turn_button.pressed.emit()
	assert_eq(_heard, ["end_turn"], "chưa quái nào đánh")
	scene.enemy_turn_player.fire_now()
	assert_eq(_heard, ["end_turn", "hit"])
	_finish_enemy_turn(scene)
	assert_eq(_heard, ["end_turn", "hit", "hit"])


func test_a_blocked_attack_makes_the_blocked_sound() -> void:
	var controller := Hud.controller([&"block_potion"], [], 1)
	var scene := _scene_for(controller)
	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	_heard = []
	scene.end_turn_button.pressed.emit()
	assert_eq(_heard, ["end_turn", "blocked"])


func test_sounds_do_not_depend_on_visual_effects() -> void:
	var lists: Array = []
	for speed in [0.0, EffectsConfig.NORMAL_SPEED]:
		var controller := _warrior_battle([&"slime", &"spiker"], [&"block_potion"])
		var scene := _scene_for(controller, speed)
		scene.hand_ui.card_clicked.emit(_hand_card(controller, &"defend"))
		scene.hand_ui.card_clicked.emit(_hand_card(controller, &"strike"))
		scene.enemy_uis[0].clicked.emit(controller.enemies[0])
		scene.potion_belt_ui.slot_uis[0].pressed.emit()
		scene.end_turn_button.pressed.emit()
		_finish_enemy_turn(scene)
		lists.append(_heard.duplicate())
		scene.free()
		_scene = null
	assert_true(lists[0].size() > 5)
	assert_eq(lists[0], lists[1])


## --- Từ chối ---

func _exhaust_energy(scene: BattleScene, controller: BattleController) -> void:
	for i in controller.config.max_energy:
		scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
		scene.hand_ui.flush_pending_refresh()


func test_an_unaffordable_card_click_rejects_once() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_exhaust_energy(scene, controller)
	_heard = []
	scene.hand_ui.card_clicked.emit(controller.deck.get_pile(Deck.HAND)[0])
	assert_eq(_heard, ["reject"])


func test_starting_a_drag_on_an_unaffordable_card_rejects_once() -> void:
	var controller := Hud.controller([], [], 1)
	var scene := _scene_for(controller)
	_exhaust_energy(scene, controller)
	_heard = []
	scene._on_drag_started(controller.deck.get_pile(Deck.HAND)[0], Vector2(500, 300))
	assert_eq(_heard, ["reject"])


func test_an_empty_potion_slot_rejects_once() -> void:
	var scene := _scene_for(Hud.controller([&"block_potion"]))
	scene.potion_belt_ui.slot_uis[2].pressed.emit()
	assert_eq(_heard, ["reject"])


func test_a_controller_level_rejection_rejects_once_not_twice() -> void:
	var controller := Hud.controller([], [], 2)
	var scene := _scene_for(controller, EffectsConfig.NORMAL_SPEED)
	scene.end_turn_button.pressed.emit()  # quái đang đi
	_heard = []
	var card := controller.deck.get_pile(Deck.HAND)
	controller.play_card(CardInstance.create(CardFactory.card(&"loose")), controller.enemies[0])  # bị lõi từ chối
	assert_eq(_heard, ["reject"])
	assert_eq(card.size(), 0, "tay đã bỏ khi sang lượt quái")


func test_pressing_end_turn_when_it_is_not_your_turn_rejects_without_the_end_turn_sound() -> void:
	var controller := Hud.controller([], [], 2)
	var scene := _scene_for(controller, EffectsConfig.NORMAL_SPEED)
	scene.end_turn_button.pressed.emit()
	_heard = []
	scene.end_turn_button.pressed.emit()
	assert_eq(_heard, ["reject"])


## --- Kết thúc trận ---

func test_victory_sound_comes_after_the_killing_blow() -> void:
	var controller := Hud.controller([&"fire_potion"], [], 1, true, 20)
	var scene := _scene_for(controller)
	scene.potion_belt_ui.slot_uis[0].pressed.emit()
	assert_eq(_heard, ["potion", "hit", "victory"])


func test_defeat_sound_comes_after_the_killing_hit() -> void:
	var controller := Hud.controller([], [], 1)
	controller.player.lose_hp(controller.player.hp - 3)
	var scene := _scene_for(controller)
	scene.end_turn_button.pressed.emit()
	assert_eq(_heard, ["end_turn", "hit", "defeat"])


func test_relic_trigger_at_battle_start_is_heard_too() -> void:
	var controller := Hud.controller([], [&"anchor"], 1, false)
	var scene := _scene_for(controller)
	controller.start_battle()
	assert_true(_heard.has("block_gain"), "Anchor: %s" % [_heard])


func test_building_the_scene_makes_no_sound() -> void:
	_scene = BattleScene.new()
	Engine.get_main_loop().root.add_child(_scene)
	_scene.setup(Hud.controller([&"fire_potion"], [&"anchor"]))
	assert_eq(_heard, [])
	_scene._on_pile_clicked(Deck.DRAW)
	assert_eq(_heard, [])
