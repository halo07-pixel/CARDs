class_name BattleSimulator
extends RefCounted
## Chạy hàng loạt trận bằng bot, kiểm tra điều kiện bất biến sau MỖI bước và thu số liệu cân bằng.
## Cùng seed => cùng kết quả. Không phụ thuộc node/autoload nên chạy được hoàn toàn headless.

const STEP_LIMIT := 2000
const MAX_RECORDED_VIOLATIONS := 20
const BOT_RANDOM := &"random"
const BOT_GREEDY := &"greedy"

var character: CharacterData
var cards: CardRegistry
var enemies: EnemyRegistry
var statuses: StatusRegistry
var deck_ids: Array[StringName] = []
var relic_ids: Array[StringName] = []  ## relic người chơi mang theo trong mọi trận mô phỏng
var relics: RelicRegistry = null
var potions: PotionRegistry = null
var potion_count: int = 0  ## mỗi trận người chơi mang ngẫu nhiên (theo seed) từng này potion khác nhau
var turn_cap: int = 60  ## trận bế tắc kết thúc (tính là thua) thay vì chạy vô hạn


func _init(p_character: CharacterData, p_cards: CardRegistry, p_enemies: EnemyRegistry,
		p_statuses: StatusRegistry, p_deck_ids: Array[StringName] = []) -> void:
	character = p_character
	cards = p_cards
	enemies = p_enemies
	statuses = p_statuses
	deck_ids = p_deck_ids if not p_deck_ids.is_empty() else p_character.starting_deck


static func make_bot(kind: StringName, rng: RandomNumberGenerator) -> BattleBot:
	match kind:
		BOT_RANDOM:
			return RandomBot.new(rng)
		BOT_GREEDY:
			return GreedyBot.new()
		_:
			push_error("BattleSimulator: bot '%s' không tồn tại" % kind)
			return null


func run_scenario(scenario_name: String, enemy_ids: Array[StringName], bot_kind: StringName,
		battle_count: int, base_seed: int = 1) -> ScenarioStats:
	var stats := ScenarioStats.new()
	stats.scenario = scenario_name
	stats.bot = bot_kind
	for i in battle_count:
		_run_battle(enemy_ids, bot_kind, base_seed + i, stats)
	return stats


func _run_battle(enemy_ids: Array[StringName], bot_kind: StringName, seed_value: int, stats: ScenarioStats) -> void:
	var player := BattleFactory.create_player(character)
	var potion_ids := _roll_potions(seed_value)
	var controller := BattleFactory.create(character, player, deck_ids, enemy_ids,
			cards, enemies, statuses, seed_value, turn_cap, relic_ids, relics, potion_ids, potions)
	var bot_rng := RandomNumberGenerator.new()
	bot_rng.seed = seed_value * 7919 + 13
	var bot := make_bot(bot_kind, bot_rng)
	if controller == null or bot == null:
		_record_violation(stats, "seed %d: không dựng được trận/bot" % seed_value)
		return
	var invariants := BattleInvariants.new(controller)
	controller.start_battle()
	var steps := 0
	while not controller.state.is_terminal() and steps < STEP_LIMIT:
		steps += 1
		bot.act(controller)
		var violations := invariants.check()
		if not violations.is_empty():
			_record_violation(stats, "seed %d bước %d: %s" % [seed_value, steps, violations])
			return
	if not controller.state.is_terminal():
		_record_violation(stats, "seed %d: không kết thúc sau %d bước" % [seed_value, steps])
		return
	stats.record(controller.end_reason, controller.turn, player.max_hp - player.hp,
			potion_ids.size() - controller.potions.count())


func _record_violation(stats: ScenarioStats, message: String) -> void:
	if stats.violations.size() < MAX_RECORDED_VIOLATIONS:
		stats.violations.append(message)


## Chọn ngẫu nhiên (theo seed trận, nên tái lập được) potion_count potion KHÁC NHAU.
func _roll_potions(seed_value: int) -> Array[StringName]:
	var picked: Array[StringName] = []
	if potions == null or potion_count <= 0:
		return picked
	var pool := potions.all_ids()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 104729 + 7
	while picked.size() < potion_count and not pool.is_empty():
		picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return picked
