extends SceneTree
## Sinh thẻ mẫu của Warrior. Chạy: godot --headless --path . -s res://tools/generate_starter_cards.gd
## KHÔNG ghi đè file đã có (file .tres là nguồn dữ liệu chính, đã có thể được chỉnh tay/trong editor).
## Ngoại lệ DUY NHẤT: nếu thẻ gốc đã có file nhưng thiếu dòng upgraded_id, generator vá đúng dòng đó
## (sửa văn bản, không lưu lại Resource nên không đổi id ngẫu nhiên của sub-resource).

const OUT_DIR := "res://data/cards/"
const T := EffectData.Type
const G := EffectData.Target
const C := CardData.CardType
const R := CardData.Rarity
const M := CardData.TargetMode


func _initialize() -> void:
	var ok := true
	for card in _all_cards():
		ok = _save(card) and ok
	quit(0 if ok else 1)


func _all_cards() -> Array[CardData]:
	return [
		# --- Khởi đầu ---
		_make(&"strike", "Strike", "Deal {damage} damage.", C.ATTACK, [_dmg(6)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER, "upgraded_id": &"strike+"}),
		_make(&"strike+", "Strike+", "Deal {damage} damage.", C.ATTACK, [_dmg(9)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER}),
		_make(&"defend", "Defend", "Gain {block} Block.", C.SKILL, [_block(5)], M.SELF,
				{"rarity": R.STARTER, "upgraded_id": &"defend+"}),
		_make(&"defend+", "Defend+", "Gain {block} Block.", C.SKILL, [_block(8)], M.SELF,
				{"rarity": R.STARTER}),
		_make(&"bash", "Bash", "Deal {damage} damage. Apply {vulnerable} Vulnerable.", C.ATTACK,
				[_dmg(8), _status(2, &"vulnerable", G.TARGET_ENEMY)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER, "cost": 2, "upgraded_id": &"bash+"}),
		_make(&"bash+", "Bash+", "Deal {damage} damage. Apply {vulnerable} Vulnerable.", C.ATTACK,
				[_dmg(10), _status(3, &"vulnerable", G.TARGET_ENEMY)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER, "cost": 2}),
		# --- Thẻ thường ---
		_make(&"cleave", "Cleave", "Deal {damage} damage to ALL enemies.", C.ATTACK,
				[_dmg(8, G.ALL_ENEMIES)], M.ALL_ENEMIES, {"upgraded_id": &"cleave+"}),
		_make(&"cleave+", "Cleave+", "Deal {damage} damage to ALL enemies.", C.ATTACK,
				[_dmg(11, G.ALL_ENEMIES)], M.ALL_ENEMIES, {}),
		_make(&"iron_wave", "Iron Wave", "Gain {block} Block. Deal {damage} damage.", C.ATTACK,
				[_block(5), _dmg(5)], M.SINGLE_ENEMY, {"upgraded_id": &"iron_wave+"}),
		_make(&"iron_wave+", "Iron Wave+", "Gain {block} Block. Deal {damage} damage.", C.ATTACK,
				[_block(7), _dmg(7)], M.SINGLE_ENEMY, {}),
		_make(&"pommel_strike", "Pommel Strike", "Deal {damage} damage. Draw {draw} card.", C.ATTACK,
				[_dmg(9), _draw(1)], M.SINGLE_ENEMY, {"upgraded_id": &"pommel_strike+"}),
		_make(&"pommel_strike+", "Pommel Strike+", "Deal {damage} damage. Draw {draw} cards.", C.ATTACK,
				[_dmg(10), _draw(2)], M.SINGLE_ENEMY, {}),
		_make(&"shrug_it_off", "Shrug It Off", "Gain {block} Block. Draw {draw} card.", C.SKILL,
				[_block(8), _draw(1)], M.SELF, {"upgraded_id": &"shrug_it_off+"}),
		_make(&"shrug_it_off+", "Shrug It Off+", "Gain {block} Block. Draw {draw} card.", C.SKILL,
				[_block(11), _draw(1)], M.SELF, {}),
		_make(&"twin_strike", "Twin Strike", "Deal {damage} damage twice.", C.ATTACK,
				[EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY, 2)], M.SINGLE_ENEMY, {"upgraded_id": &"twin_strike+"}),
		_make(&"twin_strike+", "Twin Strike+", "Deal {damage} damage twice.", C.ATTACK,
				[EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY, 2)], M.SINGLE_ENEMY, {}),
		_make(&"thunderclap", "Thunderclap", "Deal {damage} damage and apply {vulnerable} Vulnerable to ALL enemies.",
				C.ATTACK, [_dmg(4, G.ALL_ENEMIES), _status(1, &"vulnerable", G.ALL_ENEMIES)],
				M.ALL_ENEMIES, {"upgraded_id": &"thunderclap+"}),
		_make(&"thunderclap+", "Thunderclap+", "Deal {damage} damage and apply {vulnerable} Vulnerable to ALL enemies.",
				C.ATTACK, [_dmg(7, G.ALL_ENEMIES), _status(1, &"vulnerable", G.ALL_ENEMIES)], M.ALL_ENEMIES, {}),
		_make(&"deadly_poison", "Deadly Poison", "Apply {poison} Poison.", C.SKILL,
				[_status(5, &"poison", G.TARGET_ENEMY)], M.SINGLE_ENEMY, {"upgraded_id": &"deadly_poison+"}),
		_make(&"deadly_poison+", "Deadly Poison+", "Apply {poison} Poison.", C.SKILL,
				[_status(7, &"poison", G.TARGET_ENEMY)], M.SINGLE_ENEMY, {}),
		_make(&"bandage_up", "Bandage Up", "Heal {heal} HP. Exhaust.", C.SKILL,
				[EffectData.create(T.HEAL, 4, G.SELF)], M.SELF, {"cost": 0, "exhaust": true, "upgraded_id": &"bandage_up+"}),
		_make(&"bandage_up+", "Bandage Up+", "Heal {heal} HP. Exhaust.", C.SKILL,
				[EffectData.create(T.HEAL, 6, G.SELF)], M.SELF, {"cost": 0, "exhaust": true}),
		# --- Thẻ không phổ biến ---
		_make(&"adrenaline", "Adrenaline", "Gain {energy} Energy. Draw {draw} cards. Exhaust.", C.SKILL,
				[EffectData.create(T.GAIN_ENERGY, 1, G.SELF), _draw(2)], M.SELF,
				{"rarity": R.UNCOMMON, "cost": 0, "exhaust": true, "upgraded_id": &"adrenaline+"}),
		_make(&"adrenaline+", "Adrenaline+", "Gain {energy} Energy. Draw {draw} cards. Exhaust.", C.SKILL,
				[EffectData.create(T.GAIN_ENERGY, 2, G.SELF), _draw(2)], M.SELF,
				{"rarity": R.UNCOMMON, "cost": 0, "exhaust": true}),
		_make(&"inflame", "Inflame", "Gain {strength} Strength.", C.POWER,
				[_status(2, &"strength", G.SELF)], M.SELF, {"rarity": R.UNCOMMON, "upgraded_id": &"inflame+"}),
		_make(&"inflame+", "Inflame+", "Gain {strength} Strength.", C.POWER,
				[_status(3, &"strength", G.SELF)], M.SELF, {"rarity": R.UNCOMMON}),
		_make(&"metallicize", "Metallicize", "At the end of your turn, gain {metallicize} Block.", C.POWER,
				[_status(3, &"metallicize", G.SELF)], M.SELF, {"rarity": R.UNCOMMON, "upgraded_id": &"metallicize+"}),
		_make(&"metallicize+", "Metallicize+", "At the end of your turn, gain {metallicize} Block.", C.POWER,
				[_status(4, &"metallicize", G.SELF)], M.SELF, {"rarity": R.UNCOMMON}),
		_make(&"bloodletting", "Bloodletting", "Lose {hp} HP. Gain {energy} Energy.", C.SKILL,
				[EffectData.create(T.LOSE_HP, 3, G.SELF), EffectData.create(T.GAIN_ENERGY, 2, G.SELF)], M.SELF,
				{"rarity": R.UNCOMMON, "cost": 0, "upgraded_id": &"bloodletting+"}),
		_make(&"bloodletting+", "Bloodletting+", "Lose {hp} HP. Gain {energy} Energy.", C.SKILL,
				[EffectData.create(T.LOSE_HP, 3, G.SELF), EffectData.create(T.GAIN_ENERGY, 3, G.SELF)], M.SELF,
				{"rarity": R.UNCOMMON, "cost": 0}),
		_make(&"whirlwind", "Whirlwind", "Deal {damage} damage to ALL enemies X times.", C.ATTACK,
				[_x(EffectData.create(T.DAMAGE, 5, G.ALL_ENEMIES))], M.ALL_ENEMIES,
				{"rarity": R.UNCOMMON, "cost": 0, "is_x_cost": true, "upgraded_id": &"whirlwind+"}),
		_make(&"whirlwind+", "Whirlwind+", "Deal {damage} damage to ALL enemies X times.", C.ATTACK,
				[_x(EffectData.create(T.DAMAGE, 8, G.ALL_ENEMIES))], M.ALL_ENEMIES,
				{"rarity": R.UNCOMMON, "cost": 0, "is_x_cost": true}),
		_make(&"skewer", "Skewer", "Deal {damage} damage X times.", C.ATTACK,
				[_x(EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY))], M.SINGLE_ENEMY,
				{"rarity": R.UNCOMMON, "cost": 0, "is_x_cost": true, "upgraded_id": &"skewer+"}),
		_make(&"skewer+", "Skewer+", "Deal {damage} damage X times.", C.ATTACK,
				[_x(EffectData.create(T.DAMAGE, 10, G.TARGET_ENEMY))], M.SINGLE_ENEMY,
				{"rarity": R.UNCOMMON, "cost": 0, "is_x_cost": true}),
		# --- Thẻ hiếm ---
		_make(&"demon_form", "Demon Form", "At the start of your turn, gain {demon_form} Strength.", C.POWER,
				[_status(2, &"demon_form", G.SELF)], M.SELF, {"rarity": R.RARE, "cost": 3, "upgraded_id": &"demon_form+"}),
		_make(&"demon_form+", "Demon Form+", "At the start of your turn, gain {demon_form} Strength.", C.POWER,
				[_status(3, &"demon_form", G.SELF)], M.SELF, {"rarity": R.RARE, "cost": 3}),
		_make(&"barricade", "Barricade", "Block is not removed at the start of your turn.", C.POWER,
				[_status(1, &"barricade", G.SELF)], M.SELF, {"rarity": R.RARE, "cost": 3, "upgraded_id": &"barricade+"}),
		_make(&"barricade+", "Barricade+", "Block is not removed at the start of your turn.", C.POWER,
				[_status(1, &"barricade", G.SELF)], M.SELF, {"rarity": R.RARE, "cost": 2}),
	]


func _dmg(amount: int, target: EffectData.Target = G.TARGET_ENEMY) -> EffectData:
	return EffectData.create(T.DAMAGE, amount, target)


func _block(amount: int) -> EffectData:
	return EffectData.create(T.BLOCK, amount, G.SELF)


func _draw(amount: int) -> EffectData:
	return EffectData.create(T.DRAW, amount, G.SELF)


func _status(amount: int, status_id: StringName, target: EffectData.Target) -> EffectData:
	return EffectData.create(T.APPLY_STATUS, amount, target, 1, status_id)


func _x(effect: EffectData) -> EffectData:
	effect.scales_with_x = true
	return effect


func _make(id: StringName, display_name: String, description: String, card_type: CardData.CardType,
		effects: Array[EffectData], target_mode: CardData.TargetMode, props: Dictionary) -> CardData:
	var card := CardData.new()
	card.id = id
	card.display_name = display_name
	card.description = description
	card.card_type = card_type
	card.rarity = R.COMMON
	card.character_id = &"warrior"
	card.cost = 1
	card.target_mode = target_mode
	card.effects = effects
	card.icon_id = StringName(String(id).trim_suffix("+"))
	for key: String in props:
		card.set(key, props[key])
	return card


func _file_name(card: CardData) -> String:
	return String(card.id).replace("+", "_plus") + ".tres"


func _save(card: CardData) -> bool:
	var errors := card.validate()
	if not errors.is_empty():
		printerr("Thẻ %s không hợp lệ: %s" % [card.id, errors])
		return false
	var path := OUT_DIR + _file_name(card)
	if FileAccess.file_exists(path):
		if _backfill_upgraded_id(card, path):
			print("đã vá upgraded_id cho ", _file_name(card))
		else:
			print("đã có, bỏ qua ", _file_name(card))
		return true
	var err := ResourceSaver.save(card, path)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [_file_name(card), err])
		return false
	print("đã tạo ", _file_name(card))
	return true


## Thêm đúng một dòng upgraded_id (trước icon_id, đúng thứ tự Godot ghi) vào file thẻ gốc đã có.
func _backfill_upgraded_id(card: CardData, path: String) -> bool:
	if card.upgraded_id.is_empty():
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.contains("upgraded_id"):
		return false
	var line := "upgraded_id = &\"%s\"\n" % card.upgraded_id
	var index := text.find("\nicon_id = ")
	text = (text.rstrip("\n") + "\n" + line) if index == -1 else text.insert(index + 1, line)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	return true
