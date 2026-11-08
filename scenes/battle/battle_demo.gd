extends Control
## Scene demo để chơi thử trận chiến (mở scenes/battle/battle_demo.tscn rồi bấm F6 trong Godot).
## Giai đoạn 5 sẽ thay bằng luồng menu/bản đồ. "Play again" dựng một trận mới với seed mới.

const ENEMY_IDS: Array[StringName] = [&"slime", &"spiker", &"toxic_slug"]
## Relic và potion để thử thanh relic, dây potion và tooltip (Giai đoạn 4 sẽ lấy từ lượt chạy thật).
const RELIC_IDS: Array[StringName] = [&"burning_blood", &"anchor", &"vajra", &"bronze_scales"]
const POTION_IDS: Array[StringName] = [&"fire_potion", &"weak_potion", &"block_potion"]
const CHARACTER_PATH := "res://data/characters/warrior.tres"

var battle_scene: BattleScene = null
var _game_data: GameData = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_data = GameData.load_default()
	_start_battle()


func _start_battle() -> void:
	if battle_scene != null:
		battle_scene.queue_free()
		battle_scene = null
	var character := load(CHARACTER_PATH) as CharacterData
	var controller := BattleFactory.create_from_game_data(character, character.starting_deck, ENEMY_IDS,
			_game_data, randi(), RELIC_IDS, POTION_IDS)
	if controller == null:
		push_error("BattleDemo: không dựng được trận")
		return
	battle_scene = BattleScene.new()
	add_child(battle_scene)
	battle_scene.setup(controller)
	battle_scene.restart_requested.connect(_start_battle, CONNECT_DEFERRED)  # tránh giải phóng cảnh trong tín hiệu của chính nó
	controller.start_battle()
