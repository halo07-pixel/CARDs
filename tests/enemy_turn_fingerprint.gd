extends RefCounted
## "Dấu vân tay" của một trận mô phỏng: mọi sự kiện của controller, mọi thay đổi máu/giáp/status của từng bên, kết quả
## từng hiệu ứng và trạng thái cuối. Dùng để chứng minh cách chạy lượt quái KHÔNG đổi hành vi khi tách thành từng bước
## (golden ghi từ code TRƯỚC khi tách). Không phải file test (không bắt đầu bằng "test_").

const Recorder := preload("res://tests/battle_recorder.gd")

const RELIC_IDS: Array[StringName] = [&"burning_blood", &"anchor", &"vajra", &"bronze_scales"]
const POTION_IDS: Array[StringName] = [&"fire_potion", &"weak_potion", &"block_potion"]
const TURN_CAP := 12
const STEP_LIMIT := 600

## Các kịch bản (seed, bộ quái, loại bot). Đủ thắng, thua, chạm trần lượt, quái chết giữa lượt, Poison...
const ENEMY_SETS: Array = [
	[&"slime", &"goblin", &"acolyte"],
	[&"spiker", &"toxic_slug"],
	[&"slime"],
	[&"toxic_slug", &"toxic_slug", &"spiker"],
]


static func scenarios() -> Array:
	var list: Array = []
	for seed_value in range(1, 41):
		var bot: StringName = BattleSimulator.BOT_GREEDY if seed_value % 2 == 0 else BattleSimulator.BOT_RANDOM
		var enemy_ids: Array[StringName] = []
		enemy_ids.assign(ENEMY_SETS[seed_value % ENEMY_SETS.size()])
		list.append({
			"seed": seed_value, "enemies": enemy_ids, "bot": bot,
			"hp": 9 if seed_value % 3 == 0 else -1,    ## máu thấp: người chơi chết giữa lượt quái
			"cap": 3 if seed_value % 5 == 0 else TURN_CAP,  ## trần lượt thấp: kết thúc vì chạm trần
		})
	return list


## Chạy một kịch bản bằng end_player_turn() (qua bot) và trả sha256 của toàn bộ nhật ký.
static func fingerprint(scenario: Dictionary, game_data: GameData) -> String:
	return run(scenario, game_data)["hash"]


## Như fingerprint nhưng trả cả kết cục để biết kịch bản bao phủ nhánh nào: {hash, reason, turn, acted}.
static func run(scenario: Dictionary, game_data: GameData) -> Dictionary:
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var controller := BattleFactory.create_from_game_data(warrior, warrior.starting_deck, scenario["enemies"], game_data,
			scenario["seed"], RELIC_IDS, POTION_IDS, scenario["hp"], scenario["cap"])
	var log := PackedStringArray()
	var recorder := Recorder.new(controller)
	_watch(controller.player, "player", log)
	for unit in controller.enemies:
		_watch(unit.combatant, unit.combatant.id, log)
	controller.enemy_acted.connect(func(unit: EnemyUnit, move: EnemyMove, results: Array[EffectResult]) -> void:
		log.append("acted-results:%s:%s:%s" % [unit.combatant.id, move.id, _results_text(results)]))
	controller.card_played.connect(func(card: CardInstance, _t: EnemyUnit, results: Array[EffectResult]) -> void:
		log.append("played-results:%s:%s" % [card.data.id, _results_text(results)]))
	var bot_rng := RandomNumberGenerator.new()
	bot_rng.seed = int(scenario["seed"]) * 7919 + 13
	var bot := BattleSimulator.make_bot(scenario["bot"], bot_rng)
	controller.start_battle()
	var steps := 0
	while not controller.state.is_terminal() and steps < STEP_LIMIT:
		steps += 1
		bot.act(controller)
	log.append("steps:%d" % steps)
	log.append_array(PackedStringArray(recorder.events))
	log.append(_snapshot(controller))
	return {"hash": "\n".join(log).sha256_text(), "reason": controller.end_reason, "turn": controller.turn,
			"acted": recorder.count("acted:")}


static func _watch(combatant: Combatant, name: String, log: PackedStringArray) -> void:
	combatant.health_changed.connect(func(old_hp: int, new_hp: int) -> void: log.append("hp:%s:%d>%d" % [name, old_hp, new_hp]))
	combatant.block_changed.connect(func(old_block: int, new_block: int) -> void: log.append("block:%s:%d>%d" % [name, old_block, new_block]))
	combatant.status_changed.connect(func(status_id: StringName, old_amount: int, new_amount: int) -> void:
		log.append("status:%s:%s:%d>%d" % [name, status_id, old_amount, new_amount]))
	combatant.died.connect(func() -> void: log.append("died:%s" % name))


static func _results_text(results: Array[EffectResult]) -> String:
	var parts: PackedStringArray = []
	for result in results:
		var damage := ""
		if result.damage != null:
			damage = "/%d,%d,%d,%s" % [result.damage.incoming, result.damage.blocked, result.damage.hp_lost, result.damage.killed]
		parts.append("%d:%s:%d:%s%s" % [result.type, result.target.id if result.target != null else "-", result.amount, result.status_id, damage])
	return ";".join(parts)


static func _snapshot(controller: BattleController) -> String:
	var parts := PackedStringArray()
	parts.append("turn=%d end=%s energy=%d state=%d" % [controller.turn, controller.end_reason, controller.energy, controller.state.phase])
	parts.append(_combatant_text(controller.player))
	for unit in controller.enemies:
		parts.append(_combatant_text(unit.combatant) + " intent=%s" % [unit.current_move.id if unit.current_move != null else "-"])
	for pile in Deck.PILES:
		var ids := PackedStringArray()
		for card in controller.deck.get_pile(pile):
			ids.append(String(card.data.id))  # không ghi uid: CardInstance._next_uid là biến static toàn cục nên uid tuyệt đối phụ thuộc lịch sử tiến trình
		parts.append("%s=%s" % [pile, ",".join(ids)])
	var potions := PackedStringArray()
	for i in controller.potions.capacity:
		var potion := controller.potions.get_at(i)
		potions.append(String(potion.id) if potion != null else "-")
	parts.append("potions=%s" % ",".join(potions))
	return "\n".join(parts)


static func _combatant_text(combatant: Combatant) -> String:
	var statuses := PackedStringArray()
	var ids := combatant.get_status_ids()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))  # sort() thường so StringName theo con trỏ nội bộ: không tất định giữa các tiến trình
	for status_id in ids:
		statuses.append("%s:%d" % [status_id, combatant.get_status(status_id)])
	return "%s hp=%d/%d block=%d [%s]" % [combatant.id, combatant.hp, combatant.max_hp, combatant.block, ",".join(statuses)]
