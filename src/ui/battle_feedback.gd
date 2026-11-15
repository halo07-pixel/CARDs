class_name BattleFeedback
extends RefCounted
## Phản hồi trình diễn của màn chiến đấu: chữ nổi, nảy khi trúng đòn, rung khi bị từ chối, âm thanh.
## BattleScene chỉ báo "chuyện gì vừa xảy ra" (card_played, rejected...) và không biết cách dựng cue, chọn âm thanh hay
## hiệu ứng hình. Âm thanh báo lên bằng tín hiệu sfx_requested (không phụ thuộc hiệu ứng hình); hiệu ứng hình tắt khi
## EffectsConfig tắt. Giữ tham chiếu tới các phần giao diện (không sở hữu chúng) và tới trận đang diễn ra (bind/unbind).

signal sfx_requested(sfx_name: StringName)

var _effects: EffectsConfig
var _layer: EffectsLayerUI
var _hero_ui: Control
var _enemy_uis: Array[EnemyUI]  ## cùng đối tượng mảng với BattleScene.enemy_uis (chỉ clear/append nên tham chiếu bền)
var _hand_ui: HandUI
var _belt_ui: PotionBeltUI
var _controller: BattleController = null


func _init(effects: EffectsConfig, layer: EffectsLayerUI, hero_ui: Control, enemy_uis: Array[EnemyUI], hand_ui: HandUI,
		belt_ui: PotionBeltUI) -> void:
	_effects = effects
	_layer = layer
	_hero_ui = hero_ui
	_enemy_uis = enemy_uis
	_hand_ui = hand_ui
	_belt_ui = belt_ui


func bind(controller: BattleController) -> void:
	_controller = controller


## Gỡ khỏi trận và dọn các chữ nổi đang bay.
func unbind() -> void:
	_controller = null
	_layer.clear()


## Kết quả hiệu ứng của lõi (thẻ, potion, quái, trigger): âm thanh theo từng loại cue, chữ nổi, nảy/nháy nơi bị trúng.
## Tắt hiệu ứng hình thì chỉ còn âm thanh.
func results(results: Array[EffectResult]) -> void:
	if _controller == null:
		return
	var cues := EffectCueBuilder.build(results, _controller.player, _controller.get_status_data)
	for sfx in SfxMap.for_cues(cues):
		sfx_requested.emit(sfx)
	if not _effects.is_enabled():
		return
	_layer.show_cues(cues, _anchor_of)
	for cue in cues:
		if cue.kind == EffectCue.Kind.DAMAGE or cue.kind == EffectCue.Kind.LOSE_HP:
			UiFx.pop(_visual_of(cue.target), _effects, _enemy_ui_of(cue.target) != null)


func card_played(card_results: Array[EffectResult]) -> void:
	sfx_requested.emit(SfxMap.CARD_PLAY)
	results(card_results)


func potion_used(potion_results: Array[EffectResult]) -> void:
	sfx_requested.emit(SfxMap.POTION)
	results(potion_results)


func end_turn() -> void:
	sfx_requested.emit(SfxMap.END_TURN)


func battle_ended(victory: bool) -> void:
	sfx_requested.emit(SfxMap.for_battle_end(victory))


## Bị từ chối nhưng không có gì để rung (vd. lõi từ chối một hành động).
func rejected() -> void:
	sfx_requested.emit(SfxMap.REJECT)


func card_rejected(card: CardInstance) -> void:
	sfx_requested.emit(SfxMap.REJECT)
	_hand_ui.shake_card(card, _effects)


func potion_rejected(slot: int) -> void:
	sfx_requested.emit(SfxMap.REJECT)
	_belt_ui.shake_slot(slot, _effects)


## Quái sắp đi (chưa đi): nảy nhẹ để người chơi biết quái nào.
func enemy_windup(unit: EnemyUnit) -> void:
	var enemy_ui := _enemy_ui_of(unit.combatant)
	if enemy_ui != null:
		UiFx.pop(enemy_ui.art_rect, _effects)


## Vùng toàn cục để chữ nổi bám theo: hình quái, hoặc khung người chơi.
func _anchor_of(combatant: Combatant) -> Rect2:
	return _visual_of(combatant).get_global_rect()


func _visual_of(combatant: Combatant) -> Control:
	var enemy_ui := _enemy_ui_of(combatant)
	return enemy_ui.art_rect if enemy_ui != null else _hero_ui


func _enemy_ui_of(combatant: Combatant) -> EnemyUI:
	for enemy_ui in _enemy_uis:
		if enemy_ui.unit.combatant == combatant:
			return enemy_ui
	return null
