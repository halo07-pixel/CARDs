extends SceneTree
## Sinh các quái mẫu. Chạy: godot --headless --path . -s res://tools/generate_starter_enemies.gd
## Sau khi sinh, các file .tres là nguồn dữ liệu chính (sửa tay hoặc trong editor đều được).
## File đã tồn tại thì BỎ QUA (không ghi đè, không làm nhiễu diff); thêm `-- --force` để ghi đè tất cả.

const OUT_DIR := "res://data/enemies/"
const T := EffectData.Type
const G := EffectData.Target


func _initialize() -> void:
	var ok := true
	ok = _save(_slime()) and ok
	ok = _save(_goblin()) and ok
	ok = _save(_acolyte()) and ok
	ok = _save(_spiker()) and ok
	ok = _save(_toxic_slug()) and ok
	quit(0 if ok else 1)


func _slime() -> EnemyData:
	var tackle := _move(&"tackle", "Tackle", [EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY)], 6, 2)
	var smear := _move(&"smear", "Smear", [
		EffectData.create(T.DAMAGE, 3, G.TARGET_ENEMY),
		EffectData.create(T.APPLY_STATUS, 1, G.TARGET_ENEMY, 1, &"weak"),
	], 4, 1)
	return _enemy(&"slime", "Slime", 22, EnemyData.PatternKind.WEIGHTED, [tackle, smear], [])


func _goblin() -> EnemyData:
	var stab := _move(&"stab", "Stab", [EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY)])
	var guard := _move(&"guard", "Guard", [EffectData.create(T.BLOCK, 8, G.SELF)])
	return _enemy(&"goblin", "Goblin", 30, EnemyData.PatternKind.SEQUENCE, [stab, guard], [])


func _acolyte() -> EnemyData:
	var ritual := _move(&"ritual", "Ritual", [EffectData.create(T.APPLY_STATUS, 2, G.SELF, 1, &"strength")])
	var slash := _move(&"slash", "Slash", [EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY)])
	var order: Array[StringName] = [&"ritual", &"slash", &"slash"]
	return _enemy(&"acolyte", "Acolyte", 38, EnemyData.PatternKind.SEQUENCE, [ritual, slash], order)


## Vào trận với 3 Thorns: đánh nó bằng nhiều đòn nhỏ thì tự hại mình. Chiêu xen kẽ đánh và tăng Thorns.
func _spiker() -> EnemyData:
	var bash := _move(&"bash", "Bash", [EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY)])
	var bristle := _move(&"bristle", "Bristle", [EffectData.create(T.APPLY_STATUS, 2, G.SELF, 1, &"thorns")])
	var data := _enemy(&"spiker", "Spiker", 28, EnemyData.PatternKind.SEQUENCE, [bash, bristle], [])
	data.opening_move_id = &"bash"
	data.starting_statuses = {&"thorns": 3}
	return data


## Mở màn bằng Spit (gắn Poison), sau đó bốc ngẫu nhiên: ưu tiên Spit, không lặp Spit quá 2 lần liền.
func _toxic_slug() -> EnemyData:
	var spit := _move(&"spit", "Spit", [
		EffectData.create(T.DAMAGE, 4, G.TARGET_ENEMY),
		EffectData.create(T.APPLY_STATUS, 3, G.TARGET_ENEMY, 1, &"poison"),
	], 3, 2)
	var tackle := _move(&"tackle", "Tackle", [EffectData.create(T.DAMAGE, 7, G.TARGET_ENEMY)], 2, 0)
	var data := _enemy(&"toxic_slug", "Toxic Slug", 20, EnemyData.PatternKind.WEIGHTED, [spit, tackle], [])
	data.opening_move_id = &"spit"
	return data


func _move(id: StringName, display_name: String, effects: Array[EffectData],
		weight: int = 1, max_consecutive: int = 0) -> EnemyMove:
	var move := EnemyMove.new()
	move.id = id
	move.display_name = display_name
	move.effects = effects
	move.weight = weight
	move.max_consecutive = max_consecutive
	return move


func _enemy(id: StringName, display_name: String, max_hp: int, pattern: EnemyData.PatternKind,
		moves: Array[EnemyMove], sequence: Array[StringName]) -> EnemyData:
	var data := EnemyData.new()
	data.id = id
	data.display_name = display_name
	data.max_hp = max_hp
	data.pattern = pattern
	data.moves = moves
	data.sequence = sequence
	data.icon_id = id
	return data


func _save(data: EnemyData) -> bool:
	var path := OUT_DIR + String(data.id) + ".tres"
	if FileAccess.file_exists(path) and not OS.get_cmdline_user_args().has("--force"):
		print("bỏ qua ", data.id, " (đã tồn tại)")
		return true
	var errors := data.validate()
	if not errors.is_empty():
		printerr("Quái %s không hợp lệ: %s" % [data.id, errors])
		return false
	var err := ResourceSaver.save(data, path)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [data.id, err])
		return false
	print("đã tạo ", data.id)
	return true
