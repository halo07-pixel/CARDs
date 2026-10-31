extends RefCounted
## Ghi lại mọi Signal của BattleController thành chuỗi để test so sánh thứ tự/số lần.

var events: Array = []


func _init(controller: BattleController) -> void:
	controller.state.changed.connect(_on_state)
	controller.energy_changed.connect(_on_energy)
	controller.turn_started.connect(_on_turn)
	controller.intent_changed.connect(_on_intent)
	controller.card_played.connect(_on_played)
	controller.enemy_acted.connect(_on_enemy_acted)
	controller.enemy_defeated.connect(_on_defeated)
	controller.action_rejected.connect(_on_rejected)
	controller.battle_ended.connect(_on_ended)
	controller.triggered.connect(_on_triggered)
	controller.potion_used.connect(_on_potion)


## Các sự kiện bắt đầu bằng prefix (ví dụ "state:", "ended:").
func with_prefix(prefix: String) -> Array:
	return events.filter(func(e: String) -> bool: return e.begins_with(prefix))


func count(prefix: String) -> int:
	return with_prefix(prefix).size()


func has_event(event: String) -> bool:
	return events.has(event)


func last_rejection() -> String:
	var rejected := with_prefix("rejected:")
	return "" if rejected.is_empty() else String(rejected[-1]).trim_prefix("rejected:")


func _on_state(from_phase: int, to_phase: int) -> void:
	events.append("state:%s>%s" % [BattleState.Phase.keys()[from_phase], BattleState.Phase.keys()[to_phase]])


func _on_energy(old_energy: int, new_energy: int) -> void:
	events.append("energy:%d>%d" % [old_energy, new_energy])


func _on_turn(turn_number: int, is_player: bool) -> void:
	events.append("turn:%d:%s" % [turn_number, "player" if is_player else "enemy"])


func _on_intent(unit: EnemyUnit) -> void:
	events.append("intent:%s:%d" % [unit.combatant.id, unit.intent.total_damage])


func _on_played(card: CardInstance, _target: EnemyUnit, _results: Array) -> void:
	events.append("played:%s" % card.data.id)


func _on_enemy_acted(unit: EnemyUnit, move: EnemyMove, _results: Array) -> void:
	events.append("acted:%s:%s" % [unit.combatant.id, move.id])


func _on_defeated(unit: EnemyUnit) -> void:
	events.append("defeated:%s" % unit.combatant.id)


func _on_rejected(reason: StringName) -> void:
	events.append("rejected:%s" % reason)


func _on_ended(victory: bool) -> void:
	events.append("ended:%s" % victory)


func _on_triggered(owner: Combatant, source_key: StringName, _results: Array) -> void:
	events.append("triggered:%s:%s" % [owner.id, source_key])


func _on_potion(slot: int, potion: PotionData, _target: EnemyUnit, _results: Array) -> void:
	events.append("potion:%s:slot%d" % [potion.id, slot])
