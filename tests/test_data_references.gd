extends "res://tests/test_case.gd"
## Kiểm tra tham chiếu chéo giữa các file dữ liệu: gõ sai id ở bất kỳ đâu sẽ bị bắt ngay tại đây,
## thay vì đến lúc chơi mới phát hiện.

var _statuses: StatusRegistry
var _cards: CardRegistry
var _enemies: EnemyRegistry
var _relics: RelicRegistry


func before_each() -> void:
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")
	_relics = RelicRegistry.load_from_dir("res://data/relics")


func _check_effects(effects: Array[EffectData], owner: String) -> void:
	for effect in effects:
		if effect.type == EffectData.Type.APPLY_STATUS:
			assert_true(_statuses.has_status(effect.status_id), "%s trỏ tới status không tồn tại: %s" % [owner, effect.status_id])


func _check_triggers(triggers: Array[TriggerData], owner: String) -> void:
	for trigger in triggers:
		_check_effects(trigger.effects, owner)


func test_card_effects_only_reference_existing_statuses() -> void:
	for id in _cards.all_ids():
		_check_effects(_cards.get_card(id).effects, "thẻ " + String(id))


func test_enemy_moves_only_reference_existing_statuses() -> void:
	for id in _enemies.all_ids():
		for move in _enemies.get_enemy(id).moves:
			_check_effects(move.effects, "quái %s/%s" % [id, move.id])


func test_status_triggers_only_reference_existing_statuses() -> void:
	for id in _statuses.all_ids():
		_check_triggers(_statuses.get_status(id).triggers, "status " + String(id))


func test_relic_triggers_only_reference_existing_statuses() -> void:
	for id in _relics.all_ids():
		_check_triggers(_relics.get_relic(id).triggers, "relic " + String(id))


func test_every_status_used_by_content_is_actually_defined() -> void:
	assert_true(_statuses.size() >= 11)
	assert_eq(_cards.link_errors(), [] as Array[String])


func test_potion_effects_only_reference_existing_statuses() -> void:
	var potions := PotionRegistry.load_from_dir("res://data/potions")
	assert_true(potions.size() >= 8)
	for id in potions.all_ids():
		_check_effects(potions.get_potion(id).effects, "potion " + String(id))
