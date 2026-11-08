extends RefCounted
## Dựng trận có potion/relic cho test HUD (không phải file test vì không bắt đầu bằng "test_").

const Factory := preload("res://tests/combat_factory.gd")


## potion_ids/relic_ids lấy từ data/ thật. enemy_count quái giả cùng id "dummy" (unit id dummy_0, dummy_1...).
static func controller(potion_ids: Array = [], relic_ids: Array = [], enemy_count: int = 2, start: bool = true,
		enemy_hp: int = 40) -> BattleController:
	var potions := PotionRegistry.load_from_dir("res://data/potions")
	var relics := RelicRegistry.load_from_dir("res://data/relics")
	var ids: Array[StringName] = []
	ids.assign(potion_ids)
	var relic_list: Array[RelicData] = []
	for id in relic_ids:
		relic_list.append(relics.get_relic(id))
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(&"dummy", enemy_hp, 6))
	var battle := BattleController.create_from_data(Factory.combatant(&"player", 80), Factory.fillers(10), datas,
			Factory.registry(), 1, null, relic_list, PotionBelt.from_ids(ids, potions))
	if start:
		battle.start_battle()
	return battle
