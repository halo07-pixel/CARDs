extends SceneTree
## Mô phỏng hàng loạt trận bằng bot, in số liệu cân bằng, thoát mã 1 nếu có vi phạm bất biến.
## Chạy: godot --headless --path . -s res://tools/simulate_battles.gd -- --battles=300 --seed=1
##   --deck=starter|all   (starter: bộ bài khởi đầu của Warrior; all: mỗi thẻ trong data/cards một lần x2)
##   --relics=none|all    (all: người chơi mang mọi relic trong data/relics)
##   --potions=N          (mỗi trận người chơi mang N potion khác nhau, chọn ngẫu nhiên theo seed)

const SCENARIOS := [
	["slime", [&"slime"]],
	["goblin", [&"goblin"]],
	["acolyte", [&"acolyte"]],
	["slime x2", [&"slime", &"slime"]],
	["goblin + slime", [&"goblin", &"slime"]],
	["acolyte + goblin", [&"acolyte", &"goblin"]],
	["trio", [&"slime", &"goblin", &"acolyte"]],
]


func _initialize() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var battle_count: int = int(args.get("battles", "300"))
	var base_seed: int = int(args.get("seed", "1"))
	var warrior := load("res://data/characters/warrior.tres") as CharacterData
	var cards := CardRegistry.load_from_dir("res://data/cards")
	var deck_ids: Array[StringName] = warrior.starting_deck
	if args.get("deck", "starter") == "all":
		deck_ids = _all_cards_deck(cards)
	var sim := BattleSimulator.new(warrior, cards, EnemyRegistry.load_from_dir("res://data/enemies"),
			StatusRegistry.load_from_dir("res://data/statuses"), deck_ids)
	if args.get("relics", "none") == "all":
		sim.relics = RelicRegistry.load_from_dir("res://data/relics")
		sim.relic_ids = sim.relics.all_ids()
	sim.potion_count = int(args.get("potions", "0"))
	if sim.potion_count > 0:
		sim.potions = PotionRegistry.load_from_dir("res://data/potions")
	print("Mô phỏng %d trận mỗi dòng | seed %d | bộ bài: %d thẻ (%s) | relic: %d | potion: %d\n" % [
		battle_count, base_seed, deck_ids.size(), args.get("deck", "starter"), sim.relic_ids.size(), sim.potion_count])
	var total_violations := 0
	for bot_kind in [BattleSimulator.BOT_GREEDY, BattleSimulator.BOT_RANDOM]:
		for scenario: Array in SCENARIOS:
			var enemy_ids: Array[StringName] = []
			enemy_ids.assign(scenario[1])
			var stats := sim.run_scenario(scenario[0], enemy_ids, bot_kind, battle_count, base_seed)
			print(stats.summary_line())
			for violation in stats.violations:
				printerr("   VI PHẠM: ", violation)
			total_violations += stats.violations.size()
		print("")
	print("Tổng vi phạm bất biến: %d" % total_violations)
	quit(1 if total_violations > 0 else 0)


func _all_cards_deck(cards: CardRegistry) -> Array[StringName]:
	var ids: Array[StringName] = []
	var dir := DirAccess.get_files_at("res://data/cards")
	for file_name in dir:
		if file_name.get_extension() == "tres":
			var card := load("res://data/cards/" + file_name) as CardData
			if card != null and not card.is_upgrade():
				ids.append(card.id)
				ids.append(card.id)
	return ids


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var parsed := {}
	for arg in raw:
		if arg.begins_with("--") and arg.contains("="):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			parsed[parts[0]] = parts[1]
	return parsed
