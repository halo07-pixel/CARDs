extends "res://tests/test_case.gd"

var _cards: CardRegistry
var _enemies: EnemyRegistry
var _statuses: StatusRegistry
var _warrior: CharacterData


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")
	_warrior = (load("res://data/characters/warrior.tres") as CharacterData).duplicate() as CharacterData


## Dựng trận thật với một quái rồi bắt đầu trận để quái có ý định.
func _unit(enemy_id: StringName) -> EnemyUnit:
	var ids: Array[StringName] = [enemy_id]
	var player := BattleFactory.create_player(_warrior)
	var controller := BattleFactory.create(_warrior, player, _warrior.starting_deck, ids, _cards, _enemies, _statuses)
	controller.start_battle()
	return controller.enemies[0]


func _enemy_ui(unit: EnemyUnit) -> EnemyUI:
	var enemy_ui := EnemyUI.new()
	enemy_ui.bind(unit)
	return enemy_ui


func test_bind_shows_name_art_statuses_and_intent() -> void:
	var unit := _unit(&"spiker")
	var enemy_ui := _enemy_ui(unit)
	assert_eq(enemy_ui.combatant_ui.name_label.text, "Spiker")
	assert_eq(enemy_ui.art_label.text, "S")
	assert_eq(enemy_ui.combatant_ui.status_row.get_child_count(), 1, "Spiker mang sẵn Thorns")
	assert_eq(enemy_ui.intent_label.text, "7", "Spiker mở màn bằng Bash 7")
	enemy_ui.free()


func test_show_intent_replaces_instead_of_accumulating() -> void:
	var enemy_ui := _enemy_ui(_unit(&"toxic_slug"))
	var icons_before := enemy_ui.intent_row.get_child_count()
	assert_eq(icons_before, 3, "attack + debuff + nhãn số")
	var view := IntentView.build(null)
	enemy_ui.show_intent(view)
	enemy_ui.show_intent(view)
	assert_eq(enemy_ui.intent_row.get_child_count(), 2, "một icon '?' + nhãn")
	assert_eq(enemy_ui.intent_label.text, IntentView.UNKNOWN_TEXT)
	enemy_ui.free()


func test_show_null_intent_changes_nothing() -> void:
	var enemy_ui := _enemy_ui(_unit(&"spiker"))
	enemy_ui.show_intent(null)
	assert_eq(enemy_ui.intent_label.text, "7")
	enemy_ui.free()


func test_death_hides_intent_and_dims() -> void:
	var unit := _unit(&"slime")
	var enemy_ui := _enemy_ui(unit)
	assert_almost_eq(enemy_ui.intent_row.modulate.a, 1.0)
	unit.combatant.take_damage(9999)
	assert_almost_eq(enemy_ui.intent_row.modulate.a, 0.0, 0.0001, "ý định ẩn đi")
	assert_true(enemy_ui.intent_row.visible, "nhưng vẫn giữ chỗ trong bố cục")
	assert_almost_eq(enemy_ui.modulate.a, EnemyUI.DEFEATED_ALPHA)
	enemy_ui.free()


func test_rebinding_to_another_unit_ignores_the_old_one_dying() -> void:
	var old_unit := _unit(&"slime")
	var new_unit := _unit(&"goblin")
	var enemy_ui := _enemy_ui(old_unit)
	enemy_ui.bind(new_unit)
	old_unit.combatant.take_damage(9999)
	assert_almost_eq(enemy_ui.intent_row.modulate.a, 1.0, 0.0001, "quái cũ chết không được làm ẩn ý định của quái mới")
	assert_eq(enemy_ui.combatant_ui.name_label.text, "Goblin")
	enemy_ui.free()


func test_binding_null_keeps_current_unit() -> void:
	var enemy_ui := _enemy_ui(_unit(&"spiker"))
	enemy_ui.bind(null)
	assert_eq(enemy_ui.combatant_ui.name_label.text, "Spiker")
	enemy_ui.free()


func test_rebinding_leaves_no_died_connection_on_the_old_unit() -> void:
	var old_unit := _unit(&"slime")
	var enemy_ui := _enemy_ui(old_unit)
	assert_eq(old_unit.combatant.died.get_connections().size(), 2, "EnemyUI + CombatantUI")
	enemy_ui.bind(_unit(&"goblin"))
	assert_eq(old_unit.combatant.died.get_connections().size(), 0)
	enemy_ui.free()


func test_show_intent_does_not_leak_nodes() -> void:
	var enemy_ui := _enemy_ui(_unit(&"toxic_slug"))
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 5:
		enemy_ui.show_intent(IntentView.build(null))
		enemy_ui.show_intent(IntentView.build(enemy_ui.unit.intent))
	assert_almost_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, 0.0001,
			"icon ý định cũ phải được giải phóng")
	enemy_ui.free()
