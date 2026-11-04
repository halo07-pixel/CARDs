extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const T := EffectData.Type
const G := EffectData.Target

var _statuses: StatusRegistry
var _enemies: EnemyRegistry


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")


func _move(effects: Array[EffectData]) -> EnemyMove:
	var move := EnemyMove.new()
	move.id = &"test_move"
	move.effects = effects
	return move


func _view(move: EnemyMove, source: Combatant = null, target: Combatant = null) -> IntentView:
	var src := source if source != null else Factory.combatant(&"enemy", 30)
	var tgt := target if target != null else Factory.combatant(&"player", 50)
	return IntentView.build(IntentInfo.build(move, src, tgt))


func test_null_info_is_hidden_intent() -> void:
	var view := IntentView.build(null)
	assert_eq(view.icon_ids, [IntentView.ICON_UNKNOWN] as Array[StringName])
	assert_eq(view.text, IntentView.UNKNOWN_TEXT)


func test_single_hit_shows_plain_number() -> void:
	var view := _view(_move([EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY)] as Array[EffectData]))
	assert_eq(view.icon_ids, [IntentView.ICON_ATTACK] as Array[StringName])
	assert_eq(view.text, "7")


func test_multi_hit_shows_times_format() -> void:
	var view := _view(_move([EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY, 2)] as Array[EffectData]))
	assert_eq(view.text, "6 x 2")


func test_numbers_include_strength_and_vulnerable() -> void:
	var strong := Factory.combatant(&"enemy", 30)
	strong.add_status(_statuses.get_status(&"strength"), 3)
	var exposed := Factory.combatant(&"player", 50)
	exposed.add_status(_statuses.get_status(&"vulnerable"), 1)
	var move := _move([EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY)] as Array[EffectData])
	assert_eq(_view(move, strong).text, "10", "7 + 3 Strength")
	assert_eq(_view(move, null, exposed).text, "10", "7 x 1.5 Vulnerable (làm tròn xuống)")


func test_attack_and_debuff_show_both_icons_in_order() -> void:
	var view := _view(_enemies.get_enemy(&"toxic_slug").find_move(&"spit"))
	assert_eq(view.icon_ids, [IntentView.ICON_ATTACK, IntentView.ICON_DEBUFF] as Array[StringName])
	assert_eq(view.text, "4")


func test_self_buff_only_has_icon_but_no_number() -> void:
	var view := _view(_enemies.get_enemy(&"spiker").find_move(&"bristle"))
	assert_eq(view.icon_ids, [IntentView.ICON_BUFF] as Array[StringName])
	assert_eq(view.text, "")


func test_block_move_shows_defend_icon() -> void:
	var view := _view(_move([EffectData.create(T.BLOCK, 8, G.SELF)] as Array[EffectData]))
	assert_eq(view.icon_ids, [IntentView.ICON_DEFEND] as Array[StringName])


func test_move_without_known_effects_is_hidden_intent() -> void:
	var view := _view(_move([] as Array[EffectData]))
	assert_eq(view.icon_ids, [IntentView.ICON_UNKNOWN] as Array[StringName])
	assert_eq(view.text, IntentView.UNKNOWN_TEXT)
