extends "res://tests/test_case.gd"
## EffectCueBuilder: đổi EffectResult của lõi thành cue hiển thị (hàm thuần, chỉ đọc số có sẵn).

const Factory := preload("res://tests/combat_factory.gd")

var _player: Combatant
var _enemy: Combatant
var _statuses: StatusRegistry


func before_each() -> void:
	_player = Factory.combatant(&"player", 50)
	_enemy = Factory.combatant(&"enemy", 30)
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _result(type: EffectData.Type, target: Combatant, amount: int = 0) -> EffectResult:
	var result := EffectResult.new()
	result.type = type
	result.source = _player
	result.target = target
	result.amount = amount
	return result


func _damage(target: Combatant, hp_lost: int, blocked: int = 0, accepted: bool = true) -> EffectResult:
	var result := _result(EffectData.Type.DAMAGE, target, hp_lost + blocked)
	result.damage = DamageResult.new()
	result.damage.accepted = accepted
	result.damage.incoming = hp_lost + blocked
	result.damage.hp_lost = hp_lost
	result.damage.blocked = blocked
	return result


func _build(results: Array, lookup: Callable = Callable()) -> Array[EffectCue]:
	var typed: Array[EffectResult] = []
	typed.assign(results)
	return EffectCueBuilder.build(typed, _player, lookup)


func test_empty_input_gives_no_cues() -> void:
	assert_eq(_build([]).size(), 0)


func test_damage_shows_the_hp_actually_lost() -> void:
	var cues := _build([_damage(_enemy, 7)])
	assert_eq(cues.size(), 1)
	assert_eq(cues[0].kind, EffectCue.Kind.DAMAGE)
	assert_eq(cues[0].text, "7")
	assert_true(cues[0].target == _enemy)


func test_partly_blocked_damage_shows_only_the_hp_lost() -> void:
	var cues := _build([_damage(_enemy, 4, 3)])
	assert_eq(cues.size(), 1)
	assert_eq(cues[0].kind, EffectCue.Kind.DAMAGE)
	assert_eq(cues[0].text, "4")


func test_fully_blocked_damage_says_blocked() -> void:
	var cues := _build([_damage(_player, 0, 6)])
	assert_eq(cues[0].kind, EffectCue.Kind.BLOCKED)
	assert_eq(cues[0].text, EffectCueBuilder.BLOCKED_TEXT)


func test_zero_damage_without_block_still_shows_zero() -> void:
	var cues := _build([_damage(_enemy, 0, 0)])
	assert_eq(cues[0].kind, EffectCue.Kind.DAMAGE)
	assert_eq(cues[0].text, "0")


func test_rejected_or_missing_damage_gives_no_cue() -> void:
	assert_eq(_build([_damage(_enemy, 5, 0, false)]).size(), 0)
	assert_eq(_build([_result(EffectData.Type.DAMAGE, _enemy, 5)]).size(), 0, "không có DamageResult")


func test_multi_hit_gives_one_cue_per_hit_in_order() -> void:
	var cues := _build([_damage(_enemy, 4), _damage(_enemy, 4), _damage(_enemy, 2)])
	assert_eq(cues.size(), 3)
	assert_eq([cues[0].text, cues[1].text, cues[2].text], ["4", "4", "2"])


func test_block_heal_and_lose_hp() -> void:
	var cues := _build([_result(EffectData.Type.BLOCK, _player, 5), _result(EffectData.Type.HEAL, _player, 6),
			_result(EffectData.Type.LOSE_HP, _player, 3)])
	assert_eq([cues[0].kind, cues[0].text], [EffectCue.Kind.BLOCK_GAIN, "+5 Block"])
	assert_eq([cues[1].kind, cues[1].text], [EffectCue.Kind.HEAL, "+6"])
	assert_eq([cues[2].kind, cues[2].text], [EffectCue.Kind.LOSE_HP, "-3"])


func test_zero_amounts_give_no_cue() -> void:
	var cues := _build([_result(EffectData.Type.BLOCK, _player, 0), _result(EffectData.Type.HEAL, _player, 0),
			_result(EffectData.Type.LOSE_HP, _player, 0), _result(EffectData.Type.DRAW, null, 0),
			_result(EffectData.Type.GAIN_ENERGY, null, 0)])
	assert_eq(cues.size(), 0)


func test_status_uses_the_display_name_from_the_lookup() -> void:
	var lookup := func(status_id: StringName) -> StatusData: return _statuses.get_status(status_id)
	var result := _result(EffectData.Type.APPLY_STATUS, _enemy, 2)
	result.status_id = &"vulnerable"
	var cues := _build([result], lookup)
	assert_eq(cues[0].kind, EffectCue.Kind.STATUS)
	assert_eq(cues[0].text, "%s +2" % _statuses.get_status(&"vulnerable").display_name)


func test_status_without_a_lookup_falls_back_to_the_capitalized_id_and_signs_negative_amounts() -> void:
	var result := _result(EffectData.Type.APPLY_STATUS, _player, -2)
	result.status_id = &"strength"
	assert_eq(_build([result])[0].text, "Strength -2")
	var unknown := _result(EffectData.Type.APPLY_STATUS, _player, 1)
	unknown.status_id = &"nope"
	var lookup := func(_id: StringName) -> StatusData: return null
	assert_eq(_build([unknown], lookup)[0].text, "Nope +1", "lookup không có status: dùng id")


func test_draw_and_energy_belong_to_the_player() -> void:
	var cues := _build([_result(EffectData.Type.DRAW, null, 2), _result(EffectData.Type.GAIN_ENERGY, null, 1)])
	assert_eq([cues[0].kind, cues[0].text], [EffectCue.Kind.DRAW, "Draw 2"])
	assert_eq([cues[1].kind, cues[1].text], [EffectCue.Kind.ENERGY, "+1 Energy"])
	assert_true(cues[0].target == _player and cues[1].target == _player)


func test_null_results_are_skipped_and_the_input_is_not_changed() -> void:
	var results: Array[EffectResult] = [null, _damage(_enemy, 3), null]
	var cues := EffectCueBuilder.build(results, _player)
	assert_eq(cues.size(), 1)
	assert_eq(results.size(), 3)


func test_cue_order_follows_result_order_across_targets() -> void:
	var cues := _build([_damage(_enemy, 6), _result(EffectData.Type.BLOCK, _player, 5)])
	assert_true(cues[0].target == _enemy and cues[1].target == _player)
