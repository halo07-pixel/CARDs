extends "res://tests/test_case.gd"
## BattleFeedback: chữ nổi, nảy, rung, âm thanh được dựng/chọn ĐÚNG (kiểm riêng, không qua BattleScene).

const Hud := preload("res://tests/hud_factory.gd")

var _effects := EffectsConfig.new()
var _layer: EffectsLayerUI
var _hero_ui: CombatantUI
var _enemy_uis: Array[EnemyUI] = []
var _hand_ui: HandUI
var _belt_ui: PotionBeltUI
var _controller: BattleController
var _feedback: BattleFeedback
var _heard: Array = []
var _nodes: Array[Node] = []


func before_each() -> void:
	_effects.speed = EffectsConfig.NORMAL_SPEED
	_heard = []
	_enemy_uis = []
	_nodes = []
	_controller = Hud.controller([&"block_potion"], [], 2)
	_layer = _add(EffectsLayerUI.new())
	_layer.config = _effects
	_hero_ui = _add(CombatantUI.new())
	_hero_ui.bind(_controller.player)
	for unit in _controller.enemies:
		var enemy_ui := _add(EnemyUI.new())
		enemy_ui.bind(unit)
		_enemy_uis.append(enemy_ui)
	_hand_ui = _add(HandUI.new())
	_hand_ui.bind(_controller)
	_belt_ui = _add(PotionBeltUI.new())
	_belt_ui.bind(_controller)
	_feedback = BattleFeedback.new(_effects, _layer, _hero_ui, _enemy_uis, _hand_ui, _belt_ui)
	_feedback.sfx_requested.connect(func(sfx_name: StringName) -> void: _heard.append(String(sfx_name)))
	_feedback.bind(_controller)


func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()


func _add(node: Node) -> Node:
	Engine.get_main_loop().root.add_child(node)
	_nodes.append(node)
	return node


func _result(type: EffectData.Type, target: Combatant, amount: int = 0) -> EffectResult:
	var result := EffectResult.new()
	result.type = type
	result.source = _controller.player
	result.target = target
	result.amount = amount
	return result


func _damage(target: Combatant, hp_lost: int, blocked: int = 0) -> EffectResult:
	var result := _result(EffectData.Type.DAMAGE, target, hp_lost + blocked)
	result.damage = DamageResult.new()
	result.damage.accepted = true
	result.damage.hp_lost = hp_lost
	result.damage.blocked = blocked
	return result


func _typed(list: Array) -> Array[EffectResult]:
	var typed: Array[EffectResult] = []
	typed.assign(list)
	return typed


func _has_fx(control: Control) -> bool:
	return control.has_meta(UiFx.TWEEN_META)


## --- results ---

func test_damage_on_an_enemy_plays_hit_shows_a_number_and_pops_the_art() -> void:
	var enemy := _controller.enemies[0].combatant
	_feedback.results(_typed([_damage(enemy, 7)]))
	assert_eq(_heard, ["hit"])
	assert_eq(_layer.get_child_count(), 1)
	assert_eq((_layer.get_child(0) as FloatingTextUI).text, "7")
	assert_true(_has_fx(_enemy_uis[0].art_rect))
	assert_false(_has_fx(_enemy_uis[1].art_rect), "chỉ quái bị trúng")
	assert_false(_has_fx(_hero_ui))


func test_damage_on_the_hero_pops_the_hero_frame_without_flash() -> void:
	var before := _hero_ui.modulate
	_feedback.results(_typed([_damage(_controller.player, 5)]))
	assert_true(_has_fx(_hero_ui))
	assert_eq(_hero_ui.modulate, before, "khung người chơi không nháy sáng")
	assert_eq(_enemy_uis[0].art_rect.modulate, Color.WHITE)


func test_enemy_hit_flashes_its_art_but_block_gain_pops_nothing() -> void:
	_feedback.results(_typed([_damage(_controller.enemies[1].combatant, 3)]))
	assert_eq(_enemy_uis[1].art_rect.modulate, UiFx.FLASH_COLOR, "quái trúng đòn nháy sáng")
	_feedback.results(_typed([_result(EffectData.Type.BLOCK, _controller.player, 5)]))
	assert_eq(_heard, ["hit", "block_gain"])
	assert_false(_has_fx(_hero_ui), "thêm giáp không phải trúng đòn")


func test_one_sound_per_kind_in_a_batch_in_first_seen_order() -> void:
	var enemy := _controller.enemies[0].combatant
	_feedback.results(_typed([_damage(enemy, 4), _damage(enemy, 4), _result(EffectData.Type.BLOCK, _controller.player, 5), _damage(enemy, 2)]))
	assert_eq(_heard, ["hit", "block_gain"])
	assert_eq(_layer.get_child_count(), 4, "nhưng mỗi cue vẫn có chữ nổi riêng")


func test_with_visual_effects_off_only_the_sounds_remain() -> void:
	_effects.speed = 0.0
	_feedback.results(_typed([_damage(_controller.enemies[0].combatant, 7)]))
	assert_eq(_heard, ["hit"])
	assert_eq(_layer.get_child_count(), 0)
	assert_false(_has_fx(_enemy_uis[0].art_rect))


func test_nothing_happens_without_a_bound_battle() -> void:
	_feedback.unbind()
	_feedback.results(_typed([_damage(_controller.enemies[0].combatant, 7)]))
	assert_eq(_heard, [])
	assert_eq(_layer.get_child_count(), 0)
	_feedback.bind(_controller)
	_feedback.results(_typed([_damage(_controller.enemies[0].combatant, 7)]))
	assert_eq(_heard, ["hit"], "gắn lại thì chạy tiếp")


func test_a_combatant_with_no_ui_falls_back_to_the_hero_frame() -> void:
	var stranger := Combatant.create(&"stranger", "Stranger", 10)
	_feedback.results(_typed([_damage(stranger, 3)]))
	assert_true(_has_fx(_hero_ui))
	assert_eq(_layer.get_child_count(), 1)


func test_enemy_uis_added_after_construction_are_seen_through_the_shared_array() -> void:
	var late_units: Array[EnemyUI] = []
	var feedback := BattleFeedback.new(_effects, _layer, _hero_ui, late_units, _hand_ui, _belt_ui)
	feedback.bind(_controller)
	late_units.append(_enemy_uis[0])  # như BattleScene.setup: chỉ append vào cùng mảng
	feedback.results(_typed([_damage(_controller.enemies[0].combatant, 7)]))
	assert_true(_has_fx(_enemy_uis[0].art_rect))
	assert_false(_has_fx(_hero_ui))


## --- Các sự kiện có tên ---

func test_card_played_plays_the_card_sound_before_the_effect_sounds() -> void:
	_feedback.card_played(_typed([_damage(_controller.enemies[0].combatant, 6)]))
	assert_eq(_heard, ["card_play", "hit"])


func test_potion_used_plays_the_potion_sound_before_the_effect_sounds() -> void:
	_feedback.potion_used(_typed([_result(EffectData.Type.BLOCK, _controller.player, 12)]))
	assert_eq(_heard, ["potion", "block_gain"])


func test_end_turn_battle_end_and_plain_rejection_are_sound_only() -> void:
	_feedback.end_turn()
	_feedback.battle_ended(true)
	_feedback.battle_ended(false)
	_feedback.rejected()
	assert_eq(_heard, ["end_turn", "victory", "defeat", "reject"])
	assert_eq(_layer.get_child_count(), 0)
	for card_ui in _hand_ui.card_uis:
		assert_false(_has_fx(card_ui))


## --- Từ chối kèm rung ---

func test_a_rejected_card_plays_reject_and_shakes_exactly_that_card() -> void:
	var hand := _controller.deck.get_pile(Deck.HAND)
	var card := hand[hand.size() - 1]
	_feedback.card_rejected(card)
	assert_eq(_heard, ["reject"])
	for card_ui in _hand_ui.card_uis:
		assert_eq(_has_fx(card_ui), card_ui.view.uid == card.uid)


func test_a_rejected_card_that_is_not_in_hand_still_plays_the_sound_without_error() -> void:
	var stranger := CardInstance.create(CardRegistry.load_from_dir("res://data/cards").get_card(&"strike"))
	_feedback.card_rejected(stranger)
	assert_eq(_heard, ["reject"])
	for card_ui in _hand_ui.card_uis:
		assert_false(_has_fx(card_ui))


func test_a_rejected_potion_slot_plays_reject_and_shakes_that_slot() -> void:
	_feedback.potion_rejected(2)
	assert_eq(_heard, ["reject"])
	assert_true(_has_fx(_belt_ui.slot_uis[2]))
	assert_false(_has_fx(_belt_ui.slot_uis[0]))
	_feedback.potion_rejected(99)  # ô không tồn tại: chỉ có tiếng
	assert_eq(_heard, ["reject", "reject"])


func test_rejections_with_effects_off_are_sound_only() -> void:
	_effects.speed = 0.0
	_feedback.card_rejected(_controller.deck.get_pile(Deck.HAND)[0])
	_feedback.potion_rejected(2)
	assert_eq(_heard, ["reject", "reject"])
	assert_false(_has_fx(_belt_ui.slot_uis[2]))
	for card_ui in _hand_ui.card_uis:
		assert_false(_has_fx(card_ui))


## --- Quái sắp đi ---

func test_enemy_windup_pops_only_that_enemys_art() -> void:
	_feedback.enemy_windup(_controller.enemies[1])
	assert_true(_has_fx(_enemy_uis[1].art_rect))
	assert_false(_has_fx(_enemy_uis[0].art_rect))
	assert_eq(_enemy_uis[1].art_rect.modulate, Color.WHITE, "chuẩn bị không nháy sáng")
	assert_eq(_heard, [], "không có tiếng")


func test_enemy_windup_for_an_unknown_unit_or_with_effects_off_does_nothing() -> void:
	var stranger := EnemyUnit.create(EnemyRegistry.load_from_dir("res://data/enemies").get_enemy(&"slime"), RandomNumberGenerator.new())
	_feedback.enemy_windup(stranger)
	_effects.speed = 0.0
	_feedback.enemy_windup(_controller.enemies[0])
	for enemy_ui in _enemy_uis:
		assert_false(_has_fx(enemy_ui.art_rect))


## --- Vòng đời ---

func test_unbind_clears_the_floating_texts() -> void:
	_feedback.results(_typed([_damage(_controller.enemies[0].combatant, 7)]))
	assert_eq(_layer.get_child_count(), 1)
	_feedback.unbind()
	assert_eq(_layer.get_child_count(), 0)
