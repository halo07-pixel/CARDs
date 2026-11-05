class_name GameData
extends RefCounted
## Gom mọi registry của game (thẻ, quái, status, relic, potion) để nạp MỘT lần và truyền đi một đối tượng.
## Dữ liệu trong registry là Resource dùng chung (cache): không được sửa.

const CARDS_DIR := "res://data/cards"
const ENEMIES_DIR := "res://data/enemies"
const STATUSES_DIR := "res://data/statuses"
const RELICS_DIR := "res://data/relics"
const POTIONS_DIR := "res://data/potions"

var cards: CardRegistry = null
var enemies: EnemyRegistry = null
var statuses: StatusRegistry = null
var relics: RelicRegistry = null
var potions: PotionRegistry = null


static func load_default() -> GameData:
	var data := GameData.new()
	data.cards = CardRegistry.load_from_dir(CARDS_DIR)
	data.enemies = EnemyRegistry.load_from_dir(ENEMIES_DIR)
	data.statuses = StatusRegistry.load_from_dir(STATUSES_DIR)
	data.relics = RelicRegistry.load_from_dir(RELICS_DIR)
	data.potions = PotionRegistry.load_from_dir(POTIONS_DIR)
	return data


## Mọi registry đã nạp và không rỗng.
func is_complete() -> bool:
	for registry in [cards, enemies, statuses, relics, potions]:
		if registry == null or registry.size() == 0:
			return false
	return true
