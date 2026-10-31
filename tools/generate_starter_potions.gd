extends SceneTree
## Sinh potion mẫu. Chạy: godot --headless --path . -s res://tools/generate_starter_potions.gd
## KHÔNG ghi đè file đã có.

const OUT_DIR := "res://data/potions/"
const T := EffectData.Type
const G := EffectData.Target
const M := CardData.TargetMode
const R := PotionData.Rarity


func _initialize() -> void:
	var potions: Array[PotionData] = [
		_make(&"fire_potion", "Fire Potion", "Deal 20 damage to target enemy.", R.COMMON, M.SINGLE_ENEMY,
				[EffectData.create(T.DAMAGE, 20, G.TARGET_ENEMY)]),
		_make(&"explosive_potion", "Explosive Potion", "Deal 10 damage to ALL enemies.", R.COMMON, M.ALL_ENEMIES,
				[EffectData.create(T.DAMAGE, 10, G.ALL_ENEMIES)]),
		_make(&"block_potion", "Block Potion", "Gain 12 Block.", R.COMMON, M.SELF,
				[EffectData.create(T.BLOCK, 12, G.SELF)]),
		_make(&"strength_potion", "Strength Potion", "Gain 2 Strength.", R.COMMON, M.SELF,
				[EffectData.create(T.APPLY_STATUS, 2, G.SELF, 1, &"strength")]),
		_make(&"energy_potion", "Energy Potion", "Gain 2 Energy.", R.COMMON, M.SELF,
				[EffectData.create(T.GAIN_ENERGY, 2, G.SELF)]),
		_make(&"swift_potion", "Swift Potion", "Draw 3 cards.", R.COMMON, M.SELF,
				[EffectData.create(T.DRAW, 3, G.SELF)]),
		_make(&"weak_potion", "Weak Potion", "Apply 3 Weak to target enemy.", R.COMMON, M.SINGLE_ENEMY,
				[EffectData.create(T.APPLY_STATUS, 3, G.TARGET_ENEMY, 1, &"weak")]),
		_make(&"blood_potion", "Blood Potion", "Heal 12 HP.", R.UNCOMMON, M.SELF,
				[EffectData.create(T.HEAL, 12, G.SELF)]),
	]
	var ok := true
	for potion in potions:
		ok = _save(potion) and ok
	quit(0 if ok else 1)


func _make(id: StringName, display_name: String, description: String, rarity: PotionData.Rarity,
		target_mode: CardData.TargetMode, effects: Array[EffectData]) -> PotionData:
	var potion := PotionData.new()
	potion.id = id
	potion.display_name = display_name
	potion.description = description
	potion.rarity = rarity
	potion.target_mode = target_mode
	potion.effects = effects
	potion.icon_id = id
	return potion


func _save(potion: PotionData) -> bool:
	var errors := potion.validate()
	if not errors.is_empty():
		printerr("Potion %s không hợp lệ: %s" % [potion.id, errors])
		return false
	var path := OUT_DIR + String(potion.id) + ".tres"
	if FileAccess.file_exists(path):
		print("đã có, bỏ qua ", potion.id)
		return true
	var err := ResourceSaver.save(potion, path)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [potion.id, err])
		return false
	print("đã tạo ", potion.id)
	return true
