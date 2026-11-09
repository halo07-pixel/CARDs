extends "res://tests/test_case.gd"
## EffectsLayerUI + FloatingTextUI: chữ nổi sinh đúng chỗ, xếp dòng, tự giải phóng.

const Factory := preload("res://tests/combat_factory.gd")

var _layer: EffectsLayerUI = null
var _config := EffectsConfig.new()
var _hero: Combatant
var _enemy: Combatant
var _anchors := {}


func before_each() -> void:
	_config.speed = EffectsConfig.NORMAL_SPEED
	_hero = Factory.combatant(&"hero", 50)
	_enemy = Factory.combatant(&"enemy", 30)
	_anchors = {_hero: Rect2(100, 400, 200, 120), _enemy: Rect2(800, 100, 190, 190)}
	_layer = EffectsLayerUI.new()
	_layer.config = _config
	Engine.get_main_loop().root.add_child(_layer)


func after_each() -> void:
	_layer.free()


func _anchor_of(combatant: Combatant) -> Rect2:
	return _anchors[combatant]


func _cues(specs: Array) -> Array[EffectCue]:
	var cues: Array[EffectCue] = []
	for spec: Array in specs:
		cues.append(EffectCue.create(spec[0], spec[1], spec[2]))
	return cues


func _frame() -> void:
	await Engine.get_main_loop().process_frame


## Chờ tới khi lớp phủ rỗng (tối đa max_frames khung).
func _drain(max_frames: int = 400) -> void:
	for i in max_frames:
		if _layer.get_child_count() == 0:
			return
		await _frame()


func test_ignores_the_mouse_and_floating_text_too() -> void:
	assert_eq(_layer.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "7"]]), _anchor_of)
	assert_eq((_layer.get_child(0) as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_spawns_one_floating_text_per_cue_with_text_and_color() -> void:
	var count := _layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "7"], [EffectCue.Kind.HEAL, _hero, "+6"]]), _anchor_of)
	assert_eq(count, 2)
	assert_eq(_layer.get_child_count(), 2)
	var damage := _layer.get_child(0) as FloatingTextUI
	var heal := _layer.get_child(1) as FloatingTextUI
	assert_eq(damage.text, "7")
	assert_eq(heal.text, "+6")
	assert_eq(damage.get_theme_color("font_color"), EffectsLayerUI.COLORS[EffectCue.Kind.DAMAGE])
	assert_eq(heal.get_theme_color("font_color"), EffectsLayerUI.COLORS[EffectCue.Kind.HEAL])


func test_every_cue_kind_has_a_color() -> void:
	for kind in EffectCue.Kind.values():
		assert_true(EffectsLayerUI.COLORS.has(kind), "kind %d" % kind)


func test_text_is_centered_on_the_anchor_and_starts_mid_height() -> void:
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "7"]]), _anchor_of)
	var text := _layer.get_child(0) as FloatingTextUI
	var anchor: Rect2 = _anchors[_enemy]
	assert_almost_eq(text.position.x + text.size.x / 2.0, anchor.get_center().x, 0.01)
	assert_almost_eq(text.position.y + text.size.y, anchor.position.y + anchor.size.y * EffectsLayerUI.START_HEIGHT_RATIO, 0.01)


func test_texts_of_the_same_owner_stack_into_separate_lines_even_across_batches() -> void:
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _hero, "3"], [EffectCue.Kind.STATUS, _hero, "Poison +3"]]), _anchor_of)
	_layer.show_cues(_cues([[EffectCue.Kind.BLOCKED, _hero, "Blocked"]]), _anchor_of)
	var y0 := (_layer.get_child(0) as Control).position.y + (_layer.get_child(0) as Control).size.y
	var y1 := (_layer.get_child(1) as Control).position.y + (_layer.get_child(1) as Control).size.y
	var y2 := (_layer.get_child(2) as Control).position.y + (_layer.get_child(2) as Control).size.y
	assert_almost_eq(y1 - y0, EffectsLayerUI.LINE_STEP, 0.01)
	assert_almost_eq(y2 - y1, EffectsLayerUI.LINE_STEP, 0.01, "lô sau xếp tiếp dưới lô trước")


func test_different_owners_do_not_push_each_other_down() -> void:
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _hero, "3"], [EffectCue.Kind.DAMAGE, _enemy, "9"]]), _anchor_of)
	var hero_text := _layer.get_child(0) as Control
	var enemy_text := _layer.get_child(1) as Control
	assert_almost_eq(hero_text.position.y + hero_text.size.y, 400 + 60.0, 0.01, "dòng đầu của hero")
	assert_almost_eq(enemy_text.position.y + enemy_text.size.y, 100 + 95.0, 0.01, "dòng đầu của quái")


func test_texts_are_invisible_until_their_delay_passes() -> void:
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "1"], [EffectCue.Kind.DAMAGE, _enemy, "2"]]), _anchor_of)
	for child in _layer.get_children():
		assert_almost_eq((child as Control).modulate.a, 0.0, 0.0001)


func test_off_or_missing_config_spawns_nothing() -> void:
	_config.speed = 0.0
	assert_eq(_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "7"]]), _anchor_of), 0)
	assert_eq(_layer.get_child_count(), 0)
	_layer.config = null
	assert_eq(_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "7"]]), _anchor_of), 0)


func test_floating_text_with_an_off_config_frees_itself() -> void:
	var off := EffectsConfig.new()
	var text := FloatingTextUI.new()
	_layer.add_child(text)
	text.play("x", Color.WHITE, Vector2(10, 10), 0.0, off)
	assert_true(text.is_queued_for_deletion())


func test_texts_rise_fade_and_free_themselves() -> void:
	_config.speed = 200.0
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "7"], [EffectCue.Kind.BLOCKED, _hero, "Blocked"]]), _anchor_of)
	await _drain()
	assert_eq(_layer.get_child_count(), 0, "mọi chữ đã tự giải phóng")


func test_a_text_actually_moves_up_while_playing() -> void:
	var text := FloatingTextUI.new()
	_layer.add_child(text)
	text.play("7", Color.WHITE, Vector2(300, 300), 0.0, _config)
	var start_y := text.position.y
	var tween_children := text.get_tree().get_processed_tweens()
	assert_true(tween_children.size() >= 1, "có tween đang chạy")
	for tween in tween_children:
		tween.pause()
		tween.custom_step(FloatingTextUI.DURATION * 0.5)
	assert_true(text.position.y < start_y, "đã bay lên")
	assert_almost_eq(text.modulate.a, 1.0, 0.0001, "đã hiện")
	for tween in tween_children:
		tween.custom_step(FloatingTextUI.DURATION * 2.0)
	await _frame()
	assert_true(not is_instance_valid(text) or text.is_queued_for_deletion())


func test_clear_frees_everything_at_once() -> void:
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "1"], [EffectCue.Kind.DAMAGE, _enemy, "2"]]), _anchor_of)
	_layer.clear()
	assert_eq(_layer.get_child_count(), 0)
	assert_eq(_layer.active_count_for(_enemy), 0)


func test_many_spawns_do_not_leak_nodes_once_drained() -> void:
	_config.speed = 300.0
	_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "1"]]), _anchor_of)
	await _drain()
	await _frame()
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 6:
		_layer.show_cues(_cues([[EffectCue.Kind.DAMAGE, _enemy, "1"], [EffectCue.Kind.HEAL, _hero, "+2"]]), _anchor_of)
		await _drain()
	await _frame()
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001)
